defmodule Podium.Grid do
  @moduledoc """
  Tailwind CSS Grid layout engine for slides.

  Parses Tailwind-style grid classes from `style:` strings to compute element
  positions. Grid configuration goes on the slide, placement goes on elements.

  ## Slide-level classes

  | Class | Meaning |
  |-------|---------|
  | `grid` | Enables grid mode |
  | `grid-cols-N` | N equal columns (default 12) |
  | `grid-rows-[H1_H2_...]` | Row height template (`%` or `auto`) |
  | `p-[N%]` | Uniform padding |
  | `px-[N%]` | Horizontal padding |
  | `py-[N%]` | Vertical padding |
  | `gap-[N%]` | Uniform gap |
  | `gap-x-[N%]` | Horizontal gap |
  | `gap-y-[N%]` | Vertical gap |

  ## Element-level classes

  | Class | Meaning |
  |-------|---------|
  | `row-N` | Place in row N (1-indexed, required) |
  | `col-span-N` | Span N columns (default 1) |
  | `col-start-N` | Start at column N (1-indexed) |

  ## Example

      slide = Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
      |> Podium.add_text_box("Title", style: "row-1 col-span-12")
      |> Podium.add_chart(:line, data, style: "row-2 col-span-8")
      |> Podium.add_text_box(html, style: "row-2 col-span-4")
  """

  alias Podium.Units

  defstruct [
    :col_count,
    :unit_width,
    :col_gap,
    :row_gap,
    :padding_left,
    :padding_top,
    :row_ys,
    :row_heights,
    row_cursors: %{}
  ]

  @type t :: %__MODULE__{
          col_count: pos_integer(),
          unit_width: non_neg_integer(),
          col_gap: non_neg_integer(),
          row_gap: non_neg_integer(),
          padding_left: non_neg_integer(),
          padding_top: non_neg_integer(),
          row_ys: %{pos_integer() => non_neg_integer()},
          row_heights: %{pos_integer() => non_neg_integer()},
          row_cursors: %{pos_integer() => pos_integer()}
        }

  @type placement :: %{
          row: pos_integer(),
          col_span: pos_integer(),
          col_start: pos_integer() | nil
        }

  @doc """
  Parses slide-level grid config from a style string.

  Returns `{%Grid{}, remaining_style}` if the string contains `grid`, or
  `{nil, style}` if it does not.
  """
  @spec parse_config(String.t(), non_neg_integer(), non_neg_integer()) ::
          {t() | nil, String.t()}
  def parse_config(style, slide_width, slide_height) do
    tokens = String.split(style)

    unless "grid" in tokens do
      {nil, style}
    else
      {grid_tokens, remaining} = Enum.split_with(tokens, &grid_config_token?/1)

      col_count = parse_grid_cols(grid_tokens)
      {pad_left, pad_top} = parse_padding(grid_tokens, slide_width, slide_height)
      {col_gap, row_gap} = parse_gaps(grid_tokens, slide_width, slide_height)

      content_width = slide_width - 2 * pad_left
      content_height = slide_height - 2 * pad_top

      unit_width = div(content_width - (col_count - 1) * col_gap, col_count)

      {row_ys, row_heights} =
        parse_row_template(grid_tokens, pad_top, content_height, row_gap)

      grid = %__MODULE__{
        col_count: col_count,
        unit_width: unit_width,
        col_gap: col_gap,
        row_gap: row_gap,
        padding_left: pad_left,
        padding_top: pad_top,
        row_ys: row_ys,
        row_heights: row_heights
      }

      remaining_style = Enum.join(remaining, " ")
      {grid, remaining_style}
    end
  end

  @doc """
  Parses element-level placement classes from a style string.

  Returns `{placement, remaining_style}` where placement is a map with
  `:row`, `:col_span`, and `:col_start` keys.
  """
  @spec parse_placement(String.t()) :: {placement(), String.t()}
  def parse_placement(style) do
    tokens = String.split(style)
    {placement_tokens, remaining} = Enum.split_with(tokens, &placement_token?/1)

    placement = %{row: nil, col_span: 1, col_start: nil}

    placement =
      Enum.reduce(placement_tokens, placement, fn token, acc ->
        cond do
          String.starts_with?(token, "row-") ->
            %{acc | row: parse_int!(token, "row-")}

          String.starts_with?(token, "col-span-") ->
            %{acc | col_span: parse_int!(token, "col-span-")}

          String.starts_with?(token, "col-start-") ->
            %{acc | col_start: parse_int!(token, "col-start-")}
        end
      end)

    {placement, Enum.join(remaining, " ")}
  end

  @doc """
  Resolves a placement to position opts and returns the updated grid.

  Returns `{[x: emu, y: emu, width: emu, height: emu], updated_grid}`.
  """
  @spec resolve(t(), placement()) :: {keyword(), t()}
  def resolve(%__MODULE__{} = grid, %{row: row, col_span: col_span, col_start: col_start}) do
    row_count = map_size(grid.row_ys)

    if row < 1 or row > row_count do
      raise ArgumentError,
            "row-#{row} is out of bounds (grid has #{row_count} row#{if row_count != 1, do: "s"})"
    end

    col_cursor = col_start || Map.get(grid.row_cursors, row, 1)

    if col_cursor + col_span - 1 > grid.col_count do
      raise ArgumentError,
            "col-span-#{col_span} at column #{col_cursor} exceeds grid column count (#{grid.col_count})"
    end

    x = grid.padding_left + (col_cursor - 1) * (grid.unit_width + grid.col_gap)
    width = col_span * grid.unit_width + (col_span - 1) * grid.col_gap
    y = Map.fetch!(grid.row_ys, row)
    height = Map.fetch!(grid.row_heights, row)

    next_cursor = col_cursor + col_span
    updated_cursors = Map.put(grid.row_cursors, row, next_cursor)
    updated_grid = %{grid | row_cursors: updated_cursors}

    {[x: x, y: y, width: width, height: height], updated_grid}
  end

  @doc """
  Returns true if the style string contains grid placement classes.
  """
  @spec has_placement?(String.t()) :: boolean()
  def has_placement?(style) do
    style
    |> String.split()
    |> Enum.any?(&placement_token?/1)
  end

  # --- Config parsing helpers ---

  defp grid_config_token?("grid"), do: true
  defp grid_config_token?("grid-cols-" <> _), do: true
  defp grid_config_token?("grid-rows-" <> _), do: true
  defp grid_config_token?("p-" <> _), do: true
  defp grid_config_token?("px-" <> _), do: true
  defp grid_config_token?("py-" <> _), do: true
  defp grid_config_token?("gap-" <> _), do: true
  defp grid_config_token?("gap-x-" <> _), do: true
  defp grid_config_token?("gap-y-" <> _), do: true
  defp grid_config_token?(_), do: false

  defp placement_token?("row-" <> _), do: true
  defp placement_token?("col-span-" <> _), do: true
  defp placement_token?("col-start-" <> _), do: true
  defp placement_token?(_), do: false

  defp parse_grid_cols(tokens) do
    Enum.find_value(tokens, 12, fn
      "grid-cols-" <> n -> String.to_integer(n)
      _ -> nil
    end)
  end

  defp parse_padding(tokens, slide_width, slide_height) do
    uniform = find_bracket_percent(tokens, "p-")
    px = find_bracket_percent(tokens, "px-")
    py = find_bracket_percent(tokens, "py-")

    pad_h = px || uniform || 0
    pad_v = py || uniform || 0

    pad_left = resolve_pct(pad_h, slide_width)
    pad_top = resolve_pct(pad_v, slide_height)

    {pad_left, pad_top}
  end

  defp parse_gaps(tokens, slide_width, slide_height) do
    uniform = find_bracket_percent(tokens, "gap-")
    gx = find_bracket_percent(tokens, "gap-x-")
    gy = find_bracket_percent(tokens, "gap-y-")

    gap_h = gx || uniform || 0
    gap_v = gy || uniform || 0

    col_gap = resolve_pct(gap_h, slide_width)
    row_gap = resolve_pct(gap_v, slide_height)

    {col_gap, row_gap}
  end

  defp parse_row_template(tokens, pad_top, content_height, row_gap) do
    template_str =
      Enum.find_value(tokens, nil, fn
        "grid-rows-[" <> rest -> String.trim_trailing(rest, "]")
        _ -> nil
      end)

    specs =
      if template_str do
        String.split(template_str, "_")
      else
        ["auto"]
      end

    row_count = length(specs)
    total_gap = (row_count - 1) * row_gap

    # First pass: resolve explicit heights
    explicit_heights =
      Enum.map(specs, fn
        "auto" -> nil
        pct_str -> resolve_pct(parse_pct_value(pct_str), content_height)
      end)

    explicit_total = explicit_heights |> Enum.reject(&is_nil/1) |> Enum.sum()
    auto_count = Enum.count(explicit_heights, &is_nil/1)

    auto_height =
      if auto_count > 0 do
        div(content_height - explicit_total - total_gap, auto_count)
      else
        0
      end

    heights =
      Enum.map(explicit_heights, fn
        nil -> auto_height
        h -> h
      end)

    {row_ys, _} =
      heights
      |> Enum.with_index(1)
      |> Enum.map_reduce(pad_top, fn {h, idx}, y ->
        {{idx, y}, y + h + row_gap}
      end)

    row_ys_map = Map.new(row_ys)
    row_heights_map = heights |> Enum.with_index(1) |> Map.new(fn {h, idx} -> {idx, h} end)

    {row_ys_map, row_heights_map}
  end

  defp find_bracket_percent(tokens, prefix) do
    Enum.find_value(tokens, nil, fn token ->
      if String.starts_with?(token, prefix) do
        rest = String.slice(token, String.length(prefix)..-1//1)

        case rest do
          "[" <> inner ->
            inner
            |> String.trim_trailing("]")
            |> parse_pct_value()

          _ ->
            nil
        end
      end
    end)
  end

  defp parse_pct_value(str) do
    str = String.trim_trailing(str, "%")

    case Float.parse(str) do
      {val, ""} -> val
      _ -> raise ArgumentError, "invalid grid value: #{inspect(str)}"
    end
  end

  defp resolve_pct(0, _reference), do: 0
  defp resolve_pct(pct, reference), do: Units.resolve_percent({pct, :percent}, reference)

  defp parse_int!(token, prefix) do
    token
    |> String.slice(String.length(prefix)..-1//1)
    |> String.to_integer()
  end
end
