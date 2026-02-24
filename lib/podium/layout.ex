defmodule Podium.Layout do
  @moduledoc """
  Bootstrap-style 12-column grid layout calculator.

  Computes `[x:, y:, width:, height:]` keyword lists that get passed directly
  as opts to existing `add_*` functions — no coordinate math required.

  This module is primarily infrastructure for the DSL (Phase 5), which will
  wrap it in `row do / col "col-N" do` macro blocks. The direct API is also
  usable standalone for dynamic/programmatic layouts where macros don't fit.

  ## Example

      grid = Layout.grid(slide, margin: {5, :percent}, gutter: {2, :percent})

      {row1, grid} = Layout.row(grid, height: {20, :percent})
      [header] = Layout.cols(row1, ["col-12"])

      {row2, _grid} = Layout.row(grid)
      [left, right] = Layout.cols(row2, ["col-8", "col-4"])

      slide
      |> Podium.add_text_box("Title", header)
      |> Podium.add_chart(:line, data, left ++ [title: "Sales"])
      |> Podium.add_text_box(html, right ++ [fill: "003366"])
  """

  alias Podium.Units

  defmodule Grid do
    @moduledoc false
    @enforce_keys [
      :content_x,
      :content_y,
      :content_width,
      :content_height,
      :cursor_y,
      :col_count,
      :gutter,
      :row_gutter,
      :unit_width
    ]
    defstruct [
      :content_x,
      :content_y,
      :content_width,
      :content_height,
      :cursor_y,
      :col_count,
      :gutter,
      :row_gutter,
      :unit_width,
      row_count: 0
    ]
  end

  defmodule Row do
    @moduledoc false
    @enforce_keys [:x, :y, :width, :height, :col_count, :gutter, :unit_width]
    defstruct [:x, :y, :width, :height, :col_count, :gutter, :unit_width]
  end

  @doc """
  Creates a grid from a slide struct.

  Resolves margins and gutter to EMU, computes the content area, and derives
  the unit column width.

  ## Options

    * `:margin` — single dimension (uniform) or keyword list `[left:, top:, right:, bottom:]`
      for asymmetric margins. Percent resolves against width for left/right, height for
      top/bottom. Default: `{5, :percent}`.
    * `:gutter` — single dimension applied to both axes (like Bootstrap's `g-*`). Percent
      resolves against content width for columns and content height for rows.
      Default: `{2, :percent}`.
    * `:column_gutter` — overrides the horizontal gutter between columns. Default: same as `:gutter`.
    * `:row_gutter` — overrides the vertical gutter between rows. Default: same as `:gutter`.
    * `:columns` — integer column count. Default: `12`.

  ## Examples

      grid = Layout.grid(slide)
      grid = Layout.grid(slide, columns: 16, margin: {3, :percent})
  """
  @spec grid(%{slide_width: pos_integer(), slide_height: pos_integer()}, keyword()) :: %Grid{}
  def grid(%{slide_width: slide_width, slide_height: slide_height} = _slide, opts \\ []) do
    col_count = Keyword.get(opts, :columns, 12)
    margin_opt = Keyword.get(opts, :margin, {5, :percent})

    {margin_left, margin_top, margin_right, margin_bottom} =
      resolve_margins(margin_opt, slide_width, slide_height)

    content_x = margin_left
    content_y = margin_top
    content_width = slide_width - margin_left - margin_right
    content_height = slide_height - margin_top - margin_bottom

    gutter_opt = Keyword.get(opts, :gutter, {2, :percent})
    col_gutter = resolve_dim(Keyword.get(opts, :column_gutter, gutter_opt), content_width)
    row_gutter = resolve_dim(Keyword.get(opts, :row_gutter, gutter_opt), content_height)

    unit_width = div(content_width - (col_count - 1) * col_gutter, col_count)

    %Grid{
      content_x: content_x,
      content_y: content_y,
      content_width: content_width,
      content_height: content_height,
      cursor_y: content_y,
      col_count: col_count,
      gutter: col_gutter,
      row_gutter: row_gutter,
      unit_width: unit_width
    }
  end

  @doc """
  Claims vertical space from a grid to create a row.

  Returns `{row, updated_grid}` where the grid's cursor has advanced.

  ## Options

    * `:height` — a dimension (percent of content_height or absolute). When omitted,
      the row takes all remaining vertical space.

  ## Examples

      {row, grid} = Layout.row(grid, height: {20, :percent})
      {row, grid} = Layout.row(grid)  # takes remaining space
  """
  @spec row(%Grid{}, keyword()) :: {%Row{}, %Grid{}}
  def row(%Grid{} = grid, opts \\ []) do
    # Add row gutter before every row except the first
    cursor_y =
      if grid.row_count > 0,
        do: grid.cursor_y + grid.row_gutter,
        else: grid.cursor_y

    remaining = grid.content_y + grid.content_height - cursor_y

    row_height =
      case Keyword.get(opts, :height) do
        nil ->
          if remaining <= 0 do
            raise ArgumentError, "no vertical space remaining in grid"
          end

          remaining

        dim ->
          resolve_dim(dim, grid.content_height)
      end

    row = %Row{
      x: grid.content_x,
      y: cursor_y,
      width: grid.content_width,
      height: row_height,
      col_count: grid.col_count,
      gutter: grid.gutter,
      unit_width: grid.unit_width
    }

    updated_grid = %{grid | cursor_y: cursor_y + row_height, row_count: grid.row_count + 1}

    {row, updated_grid}
  end

  @doc """
  Computes column positions within a row.

  Parses Bootstrap-style column spec strings (`"col-N"`, `"col-N offset-M"`)
  and returns a list of `[x:, y:, width:, height:]` keyword lists, one per column.

  ## Column Specs

    * `"col-N"` — span N columns (1-12 by default)
    * `"col-N offset-M"` — span N columns, shifted right by M columns

  ## Examples

      [full] = Layout.cols(row, ["col-12"])
      [left, right] = Layout.cols(row, ["col-8", "col-4"])
      [centered] = Layout.cols(row, ["col-6 offset-3"])
  """
  @spec cols(%Row{}, [String.t()]) :: [[{atom(), integer()}]]
  def cols(%Row{} = row, col_specs) when is_list(col_specs) do
    parsed = Enum.map(col_specs, &parse_col_spec(&1, row.col_count))

    # Validate total doesn't exceed col_count
    total = Enum.reduce(parsed, 0, fn {span, offset}, acc -> acc + span + offset end)

    if total > row.col_count do
      raise ArgumentError,
            "column spans + offsets (#{total}) exceed column count (#{row.col_count})"
    end

    {results, _cursor} =
      Enum.map_reduce(parsed, 0, fn {span, offset}, col_cursor ->
        col_cursor = col_cursor + offset
        col_x = row.x + col_cursor * (row.unit_width + row.gutter)
        col_width = span * row.unit_width + (span - 1) * row.gutter

        result = [x: col_x, y: row.y, width: col_width, height: row.height]
        {result, col_cursor + span}
      end)

    results
  end

  @doc false
  @spec parse_col_spec(String.t(), pos_integer()) :: {pos_integer(), non_neg_integer()}
  def parse_col_spec(spec, col_count) do
    {span, offset} =
      spec
      |> String.split()
      |> Enum.reduce({nil, 0}, &classify_token(&1, &2, col_count))

    unless span do
      raise ArgumentError, "column spec missing col-N: #{inspect(spec)}"
    end

    {span, offset}
  end

  defp classify_token("col-" <> _ = token, {_span, offset}, col_count) do
    {parse_col_number(token, col_count), offset}
  end

  defp classify_token("offset-" <> _ = token, {span, offset}, col_count) do
    {span, offset + parse_offset_number(token, col_count)}
  end

  defp classify_token(token, _acc, _col_count) do
    raise ArgumentError, "invalid column spec token: #{inspect(token)}"
  end

  defp parse_col_number("col-" <> n_str, col_count) do
    case Integer.parse(n_str) do
      {n, ""} when n >= 1 and n <= col_count ->
        n

      {0, ""} ->
        raise ArgumentError, "col-0 is not valid — column span must be at least 1"

      {n, ""} when n > col_count ->
        raise ArgumentError,
              "col-#{n} exceeds column count (#{col_count})"

      _ ->
        raise ArgumentError, "invalid column spec: #{inspect("col-" <> n_str)}"
    end
  end

  defp parse_offset_number("offset-" <> m_str, col_count) do
    case Integer.parse(m_str) do
      {m, ""} when m >= 0 and m <= col_count ->
        m

      {m, ""} when m > col_count ->
        raise ArgumentError,
              "offset-#{m} exceeds column count (#{col_count})"

      _ ->
        raise ArgumentError, "invalid offset spec: #{inspect("offset-" <> m_str)}"
    end
  end

  defp resolve_margins(margin, slide_width, slide_height) when is_list(margin) do
    left = resolve_dim(Keyword.fetch!(margin, :left), slide_width)
    top = resolve_dim(Keyword.fetch!(margin, :top), slide_height)
    right = resolve_dim(Keyword.fetch!(margin, :right), slide_width)
    bottom = resolve_dim(Keyword.fetch!(margin, :bottom), slide_height)
    {left, top, right, bottom}
  end

  defp resolve_margins(margin, slide_width, slide_height) do
    h = resolve_dim(margin, slide_width)
    v = resolve_dim(margin, slide_height)
    {h, v, h, v}
  end

  defp resolve_dim({value, :percent}, reference),
    do: Units.resolve_percent({value, :percent}, reference)

  defp resolve_dim(dim, _reference), do: Units.to_emu(dim)
end
