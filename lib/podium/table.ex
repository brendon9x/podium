defmodule Podium.Table do
  @moduledoc """
  Table struct and XML generation for slide tables.

  Tables are represented as a grid of rows and cells with optional column/row
  spans, per-cell formatting, and table style booleans.
  """

  alias Podium.OPC.Constants
  alias Podium.{Drawing, Text, Units}

  defstruct [
    :id,
    :x,
    :y,
    :width,
    :height,
    :rows,
    :col_widths,
    :row_heights,
    table_style: []
  ]

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          x: integer() | nil,
          y: integer() | nil,
          width: non_neg_integer() | nil,
          height: non_neg_integer() | nil,
          rows: [[term()]],
          col_widths: [non_neg_integer()] | nil,
          row_heights: [non_neg_integer()] | nil,
          table_style: keyword()
        }

  @doc """
  Creates a new table from a list of rows (each row is a list of cell values).

  Cell values can be:
    - Plain string: `"text"`
    - Rich text list: `[[{"bold", bold: true}]]`
    - Cell tuple with options: `{"text", col_span: 2, row_span: 2, fill: "FF0000", ...}`
    - `:merge` placeholder for cells covered by a merge span
  """
  @spec new(pos_integer(), [[term()]], keyword()) :: t()
  def new(id, rows, opts) do
    col_widths =
      case Keyword.get(opts, :col_widths) do
        nil -> nil
        ws -> Enum.map(ws, &Units.to_emu/1)
      end

    row_heights =
      case Keyword.get(opts, :row_heights) do
        nil -> nil
        hs -> Enum.map(hs, &Units.to_emu/1)
      end

    %__MODULE__{
      id: id,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: Units.to_emu(Keyword.fetch!(opts, :width)),
      height: Units.to_emu(Keyword.fetch!(opts, :height)),
      rows: rows,
      col_widths: col_widths,
      row_heights: row_heights,
      table_style: Keyword.get(opts, :table_style, [])
    }
  end

  @doc """
  Generates the <p:graphicFrame> XML for a table.
  """
  @spec to_xml(t()) :: String.t()
  def to_xml(%__MODULE__{} = table) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    row_count = length(table.rows)
    col_count = if row_count > 0, do: length(hd(table.rows)), else: 0

    col_widths = compute_col_widths(table, col_count)
    row_heights = compute_row_heights(table, row_count)

    # Build merge map: {row, col} => :h_merge | :v_merge | :hv_merge
    merge_map = build_merge_map(table.rows)

    grid_cols =
      col_widths
      |> Enum.map(fn w -> ~s(<a:gridCol w="#{w}"/>) end)
      |> Enum.join()

    rows_xml =
      table.rows
      |> Enum.with_index()
      |> Enum.map(fn {row, row_idx} ->
        row_xml(row, row_idx, Enum.at(row_heights, row_idx), merge_map)
      end)
      |> Enum.join()

    ~s(<p:graphicFrame xmlns:a="#{ns_a}" xmlns:p="#{ns_p}">) <>
      ~s(<p:nvGraphicFramePr>) <>
      ~s(<p:cNvPr id="#{table.id}" name="Table #{table.id}"/>) <>
      ~s(<p:cNvGraphicFramePr><a:graphicFrameLocks noGrp="1"/></p:cNvGraphicFramePr>) <>
      ~s(<p:nvPr/>) <>
      ~s(</p:nvGraphicFramePr>) <>
      ~s(<p:xfrm>) <>
      ~s(<a:off x="#{table.x}" y="#{table.y}"/>) <>
      ~s(<a:ext cx="#{table.width}" cy="#{table.height}"/>) <>
      ~s(</p:xfrm>) <>
      ~s(<a:graphic>) <>
      ~s(<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/table">) <>
      ~s(<a:tbl>) <>
      tbl_pr_xml(table.table_style) <>
      ~s(<a:tblGrid>#{grid_cols}</a:tblGrid>) <>
      rows_xml <>
      ~s(</a:tbl>) <>
      ~s(</a:graphicData>) <>
      ~s(</a:graphic>) <>
      ~s(</p:graphicFrame>)
  end

  defp row_xml(cells, row_idx, row_height, merge_map) do
    cells_xml =
      cells
      |> Enum.with_index()
      |> Enum.map(fn {cell, col_idx} -> cell_xml(cell, row_idx, col_idx, merge_map) end)
      |> Enum.join()

    ~s(<a:tr h="#{row_height}">#{cells_xml}</a:tr>)
  end

  defp cell_xml(:merge, row_idx, col_idx, merge_map) do
    merge_attrs = merge_type_attrs(Map.get(merge_map, {row_idx, col_idx}))

    ~s(<a:tc#{merge_attrs}>) <>
      ~s(<a:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr lang="en-US"/></a:p></a:txBody>) <>
      ~s(<a:tcPr/>) <>
      ~s(</a:tc>)
  end

  defp cell_xml({text, cell_opts}, _row_idx, _col_idx, _merge_map) when is_list(cell_opts) do
    paragraphs = Text.normalize(text)
    body_xml = Text.paragraphs_xml(paragraphs)

    col_span = Keyword.get(cell_opts, :col_span)
    row_span = Keyword.get(cell_opts, :row_span)
    span_attrs = span_attrs_xml(col_span, row_span)
    tc_pr = cell_properties_xml(cell_opts)

    ~s(<a:tc#{span_attrs}>) <>
      ~s(<a:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      body_xml <>
      ~s(</a:txBody>) <>
      tc_pr <>
      ~s(</a:tc>)
  end

  defp cell_xml(text, _row_idx, _col_idx, _merge_map) do
    paragraphs = Text.normalize(text)
    body_xml = Text.paragraphs_xml(paragraphs)

    ~s(<a:tc>) <>
      ~s(<a:txBody>) <>
      ~s(<a:bodyPr/>) <>
      ~s(<a:lstStyle/>) <>
      body_xml <>
      ~s(</a:txBody>) <>
      ~s(<a:tcPr/>) <>
      ~s(</a:tc>)
  end

  defp span_attrs_xml(nil, nil), do: ""

  defp span_attrs_xml(col_span, row_span) do
    cs = if col_span && col_span > 1, do: ~s( gridSpan="#{col_span}"), else: ""
    rs = if row_span && row_span > 1, do: ~s( rowSpan="#{row_span}"), else: ""
    cs <> rs
  end

  defp merge_type_attrs(nil), do: ""
  defp merge_type_attrs(:h_merge), do: ~s( hMerge="1")
  defp merge_type_attrs(:v_merge), do: ~s( vMerge="1")
  defp merge_type_attrs(:hv_merge), do: ~s( hMerge="1" vMerge="1")

  defp cell_properties_xml(cell_opts) do
    fill = Keyword.get(cell_opts, :fill)
    borders = Keyword.get(cell_opts, :borders)
    padding = Keyword.get(cell_opts, :padding)
    anchor = Keyword.get(cell_opts, :anchor)

    attrs = padding_attrs(padding) <> anchor_attr(anchor)
    children = border_children_xml(borders) <> cell_fill_xml(fill)

    if attrs == "" and children == "" do
      "<a:tcPr/>"
    else
      "<a:tcPr#{attrs}>#{children}</a:tcPr>"
    end
  end

  defp padding_attrs(nil), do: ""

  defp padding_attrs(padding) when is_list(padding) do
    Enum.map([:left, :right, :top, :bottom], fn side ->
      case Keyword.get(padding, side) do
        nil -> ""
        val -> ~s( #{padding_attr_name(side)}="#{Units.to_emu(val)}")
      end
    end)
    |> Enum.join()
  end

  defp padding_attr_name(:left), do: "marL"
  defp padding_attr_name(:right), do: "marR"
  defp padding_attr_name(:top), do: "marT"
  defp padding_attr_name(:bottom), do: "marB"

  defp anchor_attr(nil), do: ""
  defp anchor_attr(:top), do: ~s( anchor="t")
  defp anchor_attr(:middle), do: ~s( anchor="ctr")
  defp anchor_attr(:bottom), do: ~s( anchor="b")

  defp cell_fill_xml(nil), do: ""
  defp cell_fill_xml(fill), do: Drawing.fill_xml(fill)

  defp border_children_xml(nil), do: ""

  defp border_children_xml(borders) when is_list(borders) do
    Enum.map([:left, :right, :top, :bottom], fn side ->
      case Keyword.get(borders, side) do
        nil -> ""
        border_spec -> border_xml(side, border_spec)
      end
    end)
    |> Enum.join()
  end

  defp border_xml(side, color) when is_binary(color) do
    element = border_element(side)
    ~s(<#{element}><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></#{element}>)
  end

  defp border_xml(side, opts) when is_list(opts) do
    element = border_element(side)
    color = Keyword.fetch!(opts, :color)
    width_attr = border_width_attr(Keyword.get(opts, :width))

    ~s(<#{element}#{width_attr}><a:solidFill><a:srgbClr val="#{color}"/></a:solidFill></#{element}>)
  end

  defp border_element(:left), do: "a:lnL"
  defp border_element(:right), do: "a:lnR"
  defp border_element(:top), do: "a:lnT"
  defp border_element(:bottom), do: "a:lnB"

  defp border_width_attr(nil), do: ""
  defp border_width_attr(width), do: ~s( w="#{Units.to_emu(width)}")

  defp compute_col_widths(%{col_widths: ws}, _n) when is_list(ws), do: ws

  defp compute_col_widths(%{width: w}, n) when n > 0 do
    base = div(w, n)
    List.duplicate(base, n - 1) ++ [w - base * (n - 1)]
  end

  defp compute_col_widths(%{width: w}, _n), do: [w]

  defp compute_row_heights(%{row_heights: hs}, _n) when is_list(hs), do: hs

  defp compute_row_heights(%{height: h}, n) when n > 0 do
    base = div(h, n)
    List.duplicate(base, n - 1) ++ [h - base * (n - 1)]
  end

  defp compute_row_heights(%{height: h}, _n), do: [h]

  # Build a map of {row_idx, col_idx} => merge type for cells covered by a span.
  defp build_merge_map(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {row, row_idx}, acc ->
      row
      |> Enum.with_index()
      |> Enum.reduce(acc, fn {cell, col_idx}, acc2 ->
        case cell do
          {_text, cell_opts} when is_list(cell_opts) ->
            col_span = Keyword.get(cell_opts, :col_span, 1)
            row_span = Keyword.get(cell_opts, :row_span, 1)
            mark_merged_cells(acc2, row_idx, col_idx, row_span, col_span)

          _ ->
            acc2
        end
      end)
    end)
  end

  defp mark_merged_cells(acc, origin_row, origin_col, row_span, col_span)
       when row_span > 1 or col_span > 1 do
    for r <- origin_row..(origin_row + row_span - 1),
        c <- origin_col..(origin_col + col_span - 1),
        {r, c} != {origin_row, origin_col},
        reduce: acc do
      acc2 ->
        h = c > origin_col
        v = r > origin_row

        merge_type =
          cond do
            h and v -> :hv_merge
            h -> :h_merge
            v -> :v_merge
          end

        Map.put(acc2, {r, c}, merge_type)
    end
  end

  defp mark_merged_cells(acc, _origin_row, _origin_col, _row_span, _col_span), do: acc

  defp tbl_pr_xml(style) do
    first_row = if Keyword.get(style, :first_row, true), do: ~s( firstRow="1"), else: ""
    last_row = if Keyword.get(style, :last_row, false), do: ~s( lastRow="1"), else: ""
    first_col = if Keyword.get(style, :first_col, false), do: ~s( firstCol="1"), else: ""
    last_col = if Keyword.get(style, :last_col, false), do: ~s( lastCol="1"), else: ""
    band_row = if Keyword.get(style, :band_row, true), do: ~s( bandRow="1"), else: ""
    band_col = if Keyword.get(style, :band_col, false), do: ~s( bandCol="1"), else: ""

    ~s(<a:tblPr#{first_row}#{last_row}#{first_col}#{last_col}#{band_row}#{band_col}/>)
  end
end
