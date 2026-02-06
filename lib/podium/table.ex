defmodule Podium.Table do
  @moduledoc false

  alias Podium.OPC.Constants
  alias Podium.{Text, Units}

  defstruct [
    :id,
    :x,
    :y,
    :width,
    :height,
    :rows
  ]

  @doc """
  Creates a new table from a list of rows (each row is a list of cell values).
  Cell values can be plain strings or rich text (same format as Text.normalize).
  """
  def new(id, rows, opts) do
    %__MODULE__{
      id: id,
      x: Units.to_emu(Keyword.fetch!(opts, :x)),
      y: Units.to_emu(Keyword.fetch!(opts, :y)),
      width: Units.to_emu(Keyword.fetch!(opts, :width)),
      height: Units.to_emu(Keyword.fetch!(opts, :height)),
      rows: rows
    }
  end

  @doc """
  Generates the <p:graphicFrame> XML for a table.
  """
  def to_xml(%__MODULE__{} = table) do
    ns_a = Constants.ns(:a)
    ns_p = Constants.ns(:p)

    row_count = length(table.rows)
    col_count = if row_count > 0, do: length(hd(table.rows)), else: 0
    row_height = if row_count > 0, do: div(table.height, row_count), else: table.height
    col_width = if col_count > 0, do: div(table.width, col_count), else: table.width

    grid_cols =
      1..max(col_count, 1)
      |> Enum.map(fn _ -> ~s(<a:gridCol w="#{col_width}"/>) end)
      |> Enum.join()

    rows_xml =
      table.rows
      |> Enum.map(fn row -> row_xml(row, row_height) end)
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
      ~s(<a:tblPr firstRow="1" bandRow="1"/>) <>
      ~s(<a:tblGrid>#{grid_cols}</a:tblGrid>) <>
      rows_xml <>
      ~s(</a:tbl>) <>
      ~s(</a:graphicData>) <>
      ~s(</a:graphic>) <>
      ~s(</p:graphicFrame>)
  end

  defp row_xml(cells, row_height) do
    cells_xml = Enum.map(cells, &cell_xml/1) |> Enum.join()
    ~s(<a:tr h="#{row_height}">#{cells_xml}</a:tr>)
  end

  defp cell_xml(text) do
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
end
