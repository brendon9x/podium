defmodule Podium.LayoutTest do
  use ExUnit.Case, async: true

  alias Podium.Layout
  alias Podium.Layout.{Grid, Row}
  alias Podium.Units

  @slide_width Units.default_slide_width()
  @slide_height Units.default_slide_height()
  @slide %{slide_width: @slide_width, slide_height: @slide_height}

  describe "grid/2 — default config" do
    test "creates grid with default margins, gutter, and 12 columns" do
      grid = Layout.grid(@slide)

      assert %Grid{} = grid
      assert grid.col_count == 12

      # 5% margins
      expected_margin_h = Units.resolve_percent({5, :percent}, @slide_width)
      expected_margin_v = Units.resolve_percent({5, :percent}, @slide_height)

      assert grid.content_x == expected_margin_h
      assert grid.content_y == expected_margin_v
      assert grid.content_width == @slide_width - 2 * expected_margin_h
      assert grid.content_height == @slide_height - 2 * expected_margin_v

      # cursor starts at content_y
      assert grid.cursor_y == grid.content_y

      # 2% gutter (of content_width)
      expected_gutter = Units.resolve_percent({2, :percent}, grid.content_width)
      assert grid.gutter == expected_gutter

      # unit_width = (content_width - 11 * gutter) / 12
      expected_unit = div(grid.content_width - 11 * expected_gutter, 12)
      assert grid.unit_width == expected_unit
    end
  end

  describe "grid/2 — custom config" do
    test "custom column count" do
      grid = Layout.grid(@slide, columns: 16)
      assert grid.col_count == 16

      expected_unit = div(grid.content_width - 15 * grid.gutter, 16)
      assert grid.unit_width == expected_unit
    end

    test "custom margin as uniform dimension" do
      grid = Layout.grid(@slide, margin: {10, :percent})

      expected_margin_h = Units.resolve_percent({10, :percent}, @slide_width)
      expected_margin_v = Units.resolve_percent({10, :percent}, @slide_height)

      assert grid.content_x == expected_margin_h
      assert grid.content_y == expected_margin_v
      assert grid.content_width == @slide_width - 2 * expected_margin_h
      assert grid.content_height == @slide_height - 2 * expected_margin_v
    end

    test "custom margin in absolute units" do
      grid = Layout.grid(@slide, margin: {1, :inches})

      margin_emu = Units.to_emu({1, :inches})
      assert grid.content_x == margin_emu
      assert grid.content_y == margin_emu
      assert grid.content_width == @slide_width - 2 * margin_emu
      assert grid.content_height == @slide_height - 2 * margin_emu
    end

    test "custom gutter" do
      grid = Layout.grid(@slide, gutter: {1, :percent})

      expected_gutter = Units.resolve_percent({1, :percent}, grid.content_width)
      assert grid.gutter == expected_gutter
    end

    test "gutter applies to both axes by default" do
      grid = Layout.grid(@slide, gutter: {3, :percent})

      expected_col_gutter = Units.resolve_percent({3, :percent}, grid.content_width)
      expected_row_gutter = Units.resolve_percent({3, :percent}, grid.content_height)

      assert grid.gutter == expected_col_gutter
      assert grid.row_gutter == expected_row_gutter
    end

    test "column_gutter overrides horizontal gutter" do
      grid =
        Layout.grid(@slide,
          gutter: {2, :percent},
          column_gutter: {4, :percent}
        )

      assert grid.gutter == Units.resolve_percent({4, :percent}, grid.content_width)
      assert grid.row_gutter == Units.resolve_percent({2, :percent}, grid.content_height)
    end

    test "row_gutter overrides vertical gutter" do
      grid =
        Layout.grid(@slide, gutter: {2, :percent}, row_gutter: {5, :percent})

      assert grid.gutter == Units.resolve_percent({2, :percent}, grid.content_width)
      assert grid.row_gutter == Units.resolve_percent({5, :percent}, grid.content_height)
    end

    test "asymmetric margins" do
      grid =
        Layout.grid(@slide,
          margin: [
            left: {3, :percent},
            top: {5, :percent},
            right: {7, :percent},
            bottom: {10, :percent}
          ]
        )

      left = Units.resolve_percent({3, :percent}, @slide_width)
      top = Units.resolve_percent({5, :percent}, @slide_height)
      right = Units.resolve_percent({7, :percent}, @slide_width)
      bottom = Units.resolve_percent({10, :percent}, @slide_height)

      assert grid.content_x == left
      assert grid.content_y == top
      assert grid.content_width == @slide_width - left - right
      assert grid.content_height == @slide_height - top - bottom
    end
  end

  describe "grid/2 — slide struct convenience" do
    test "extracts dimensions from slide struct" do
      slide = Podium.Slide.new()
      grid = Layout.grid(slide)

      assert %Grid{} = grid
      assert grid.content_width > 0
      assert grid.content_height > 0
    end

    test "passes options through" do
      slide = Podium.Slide.new()
      grid = Layout.grid(slide, columns: 8, gutter: {1, :percent})

      assert grid.col_count == 8
    end
  end

  describe "row/2 — explicit height" do
    setup do
      %{grid: Layout.grid(@slide)}
    end

    test "percent height resolves against content_height", %{grid: grid} do
      {row, updated_grid} = Layout.row(grid, height: {20, :percent})

      expected_height = Units.resolve_percent({20, :percent}, grid.content_height)

      assert %Row{} = row
      assert row.y == grid.cursor_y
      assert row.height == expected_height
      assert row.x == grid.content_x
      assert row.width == grid.content_width

      # Row inherits column config
      assert row.col_count == grid.col_count
      assert row.gutter == grid.gutter
      assert row.unit_width == grid.unit_width

      # Cursor advances
      assert updated_grid.cursor_y == grid.cursor_y + expected_height
    end

    test "absolute height", %{grid: grid} do
      {row, _grid} = Layout.row(grid, height: {2, :inches})
      assert row.height == Units.to_emu({2, :inches})
    end
  end

  describe "row/2 — auto height" do
    test "takes remaining vertical space (minus row gutter)" do
      grid = Layout.grid(@slide)
      {_row1, grid} = Layout.row(grid, height: {50, :percent})
      {row2, _grid} = Layout.row(grid)

      # Second row starts after the first row + row gutter
      remaining = grid.content_y + grid.content_height - grid.cursor_y - grid.row_gutter
      assert row2.height == remaining
    end

    test "raises when no space remains" do
      grid = Layout.grid(@slide)
      {_row, grid} = Layout.row(grid, height: {100, :percent})

      assert_raise ArgumentError, ~r/no vertical space remaining/, fn ->
        Layout.row(grid)
      end
    end
  end

  describe "row/2 — cursor advancement" do
    test "multiple rows stack vertically with row gutter between them" do
      grid = Layout.grid(@slide)
      {row1, grid} = Layout.row(grid, height: {30, :percent})
      {row2, grid} = Layout.row(grid, height: {30, :percent})
      {row3, _grid} = Layout.row(grid)

      assert row2.y == row1.y + row1.height + grid.row_gutter
      assert row3.y == row2.y + row2.height + grid.row_gutter
    end

    test "explicit height exceeding remaining space is allowed" do
      grid = Layout.grid(@slide)
      {_row, grid} = Layout.row(grid, height: {80, :percent})

      # This should not raise — matching existing percent > 100% behavior
      {row, _grid} = Layout.row(grid, height: {50, :percent})
      assert row.height == Units.resolve_percent({50, :percent}, grid.content_height)
    end

    test "first row has no gutter before it" do
      grid = Layout.grid(@slide)
      {row1, _grid} = Layout.row(grid, height: {30, :percent})

      assert row1.y == grid.content_y
    end
  end

  describe "cols/2 — column layout" do
    setup do
      grid = Layout.grid(@slide)
      {row, _grid} = Layout.row(grid)
      %{row: row, grid: grid}
    end

    test "col-12 spans full width", %{row: row} do
      [col] = Layout.cols(row, ["col-12"])

      assert col[:x] == row.x
      assert col[:y] == row.y
      assert col[:width] == 12 * row.unit_width + 11 * row.gutter
      assert col[:height] == row.height
    end

    test "col-6 + col-6 splits evenly", %{row: row} do
      [left, right] = Layout.cols(row, ["col-6", "col-6"])

      assert left[:x] == row.x
      assert left[:width] == 6 * row.unit_width + 5 * row.gutter

      expected_right_x = row.x + 6 * (row.unit_width + row.gutter)
      assert right[:x] == expected_right_x
      assert right[:width] == left[:width]
    end

    test "col-8 + col-4 split", %{row: row} do
      [left, right] = Layout.cols(row, ["col-8", "col-4"])

      assert left[:width] == 8 * row.unit_width + 7 * row.gutter
      assert right[:width] == 4 * row.unit_width + 3 * row.gutter
    end

    test "three equal columns", %{row: row} do
      [c1, c2, c3] = Layout.cols(row, ["col-4", "col-4", "col-4"])

      assert c1[:width] == c2[:width]
      assert c2[:width] == c3[:width]

      # Each column starts after the previous one + gutter
      assert c2[:x] == c1[:x] + c1[:width] + row.gutter
      assert c3[:x] == c2[:x] + c2[:width] + row.gutter
    end

    test "offset centering", %{row: row} do
      [centered] = Layout.cols(row, ["col-6 offset-3"])

      expected_x = row.x + 3 * (row.unit_width + row.gutter)
      assert centered[:x] == expected_x
      assert centered[:width] == 6 * row.unit_width + 5 * row.gutter
    end

    test "output format is keyword list with EMU integers", %{row: row} do
      [col] = Layout.cols(row, ["col-12"])

      assert is_list(col)
      assert is_integer(col[:x])
      assert is_integer(col[:y])
      assert is_integer(col[:width])
      assert is_integer(col[:height])
    end

    test "gutter appears between columns, not at edges", %{row: row} do
      [left, right] = Layout.cols(row, ["col-6", "col-6"])

      # Left column starts at row x
      assert left[:x] == row.x

      # Gap between columns is exactly one gutter
      gap = right[:x] - (left[:x] + left[:width])
      assert gap == row.gutter
    end
  end

  describe "cols/2 — validation" do
    setup do
      grid = Layout.grid(@slide)
      {row, _grid} = Layout.row(grid)
      %{row: row}
    end

    test "raises when total spans exceed col_count", %{row: row} do
      assert_raise ArgumentError, ~r/exceed column count/, fn ->
        Layout.cols(row, ["col-8", "col-6"])
      end
    end

    test "raises when spans + offsets exceed col_count", %{row: row} do
      assert_raise ArgumentError, ~r/exceed column count/, fn ->
        Layout.cols(row, ["col-6 offset-8"])
      end
    end

    test "raises on col-0", %{row: row} do
      assert_raise ArgumentError, ~r/col-0 is not valid/, fn ->
        Layout.cols(row, ["col-0"])
      end
    end

    test "raises on col-N exceeding column count", %{row: row} do
      assert_raise ArgumentError, ~r/exceeds column count/, fn ->
        Layout.cols(row, ["col-13"])
      end
    end

    test "raises on invalid spec token" do
      assert_raise ArgumentError, ~r/invalid column spec token/, fn ->
        Layout.parse_col_spec("col-6 foo", 12)
      end
    end

    test "raises on missing col-N" do
      assert_raise ArgumentError, ~r/missing col-N/, fn ->
        Layout.parse_col_spec("offset-3", 12)
      end
    end

    test "raises on non-integer col value" do
      assert_raise ArgumentError, ~r/invalid column spec/, fn ->
        Layout.parse_col_spec("col-abc", 12)
      end
    end

    test "raises on negative offset value" do
      assert_raise ArgumentError, ~r/invalid offset spec/, fn ->
        Layout.parse_col_spec("col-6 offset--1", 12)
      end
    end
  end

  describe "grid/2 — single column" do
    test "columns: 1 works and col-1 spans full width" do
      grid = Layout.grid(@slide, columns: 1)
      {row, _grid} = Layout.row(grid)
      [col] = Layout.cols(row, ["col-1"])

      assert col[:x] == row.x
      assert col[:width] == row.unit_width
      assert col[:width] == grid.content_width
    end
  end

  describe "cols/2 — offset-0 no-op" do
    test "offset-0 behaves identically to no offset" do
      grid = Layout.grid(@slide)
      {row, _grid} = Layout.row(grid)

      [without_offset] = Layout.cols(row, ["col-6"])
      [with_offset] = Layout.cols(row, ["col-6 offset-0"])

      assert without_offset == with_offset
    end
  end

  describe "integration — output works with add_text_box" do
    test "grid-computed positions produce valid shapes" do
      slide = Podium.Slide.new()
      grid = Layout.grid(slide)

      {row, _grid} = Layout.row(grid, height: {20, :percent})
      [header] = Layout.cols(row, ["col-12"])

      # Should not raise — the keyword list is valid opts for add_text_box
      slide = Podium.add_text_box(slide, "Header Text", header)
      assert length(slide.shapes) == 1
    end

    test "multiple columns produce distinct non-overlapping shapes" do
      slide = Podium.Slide.new()
      grid = Layout.grid(slide)

      {row, _grid} = Layout.row(grid)
      [left, right] = Layout.cols(row, ["col-6", "col-6"])

      slide =
        slide
        |> Podium.add_text_box("Left", left)
        |> Podium.add_text_box("Right", right)

      assert length(slide.shapes) == 2

      [shape1, shape2] = slide.shapes
      # Left shape ends before right shape starts
      assert shape1.x + shape1.width < shape2.x
    end

    test "additional opts can be merged with grid output" do
      slide = Podium.Slide.new()
      grid = Layout.grid(slide)

      {row, _grid} = Layout.row(grid, height: {50, :percent})
      [col] = Layout.cols(row, ["col-12"])

      # Grid output ++ additional opts works
      slide = Podium.add_text_box(slide, "Styled", col ++ [fill: "003366", alignment: :center])
      assert length(slide.shapes) == 1
    end
  end
end
