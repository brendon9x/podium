defmodule Podium.GridTest do
  use ExUnit.Case, async: true

  alias Podium.Grid
  alias Podium.Units

  @slide_width Units.default_slide_width()
  @slide_height Units.default_slide_height()

  describe "parse_config/3" do
    test "returns nil for non-grid style" do
      {grid, remaining} = Grid.parse_config("left: 5%; top: 10%", @slide_width, @slide_height)
      assert grid == nil
      assert remaining == "left: 5%; top: 10%"
    end

    test "parses basic grid with defaults" do
      {grid, _} = Grid.parse_config("grid", @slide_width, @slide_height)
      assert %Grid{} = grid
      assert grid.col_count == 12
      # default: no padding, no gap, 1 auto row
      assert grid.padding_left == 0
      assert grid.padding_top == 0
      assert grid.col_gap == 0
      assert grid.row_gap == 0
      assert map_size(grid.row_ys) == 1
      assert grid.row_heights[1] == @slide_height
    end

    test "parses grid-cols-N" do
      {grid, _} = Grid.parse_config("grid grid-cols-6", @slide_width, @slide_height)
      assert grid.col_count == 6
    end

    test "parses p-[N%] uniform padding" do
      {grid, _} = Grid.parse_config("grid p-[5%]", @slide_width, @slide_height)
      assert grid.padding_left == Units.resolve_percent({5, :percent}, @slide_width)
      assert grid.padding_top == Units.resolve_percent({5, :percent}, @slide_height)
    end

    test "parses px-[N%] and py-[N%] separately" do
      {grid, _} = Grid.parse_config("grid px-[3%] py-[7%]", @slide_width, @slide_height)
      assert grid.padding_left == Units.resolve_percent({3, :percent}, @slide_width)
      assert grid.padding_top == Units.resolve_percent({7, :percent}, @slide_height)
    end

    test "px/py override p" do
      {grid, _} = Grid.parse_config("grid p-[5%] px-[3%]", @slide_width, @slide_height)
      assert grid.padding_left == Units.resolve_percent({3, :percent}, @slide_width)
      assert grid.padding_top == Units.resolve_percent({5, :percent}, @slide_height)
    end

    test "parses gap-[N%] uniform gap" do
      {grid, _} = Grid.parse_config("grid gap-[2%]", @slide_width, @slide_height)
      assert grid.col_gap == Units.resolve_percent({2, :percent}, @slide_width)
      assert grid.row_gap == Units.resolve_percent({2, :percent}, @slide_height)
    end

    test "parses gap-x and gap-y separately" do
      {grid, _} = Grid.parse_config("grid gap-x-[1%] gap-y-[3%]", @slide_width, @slide_height)
      assert grid.col_gap == Units.resolve_percent({1, :percent}, @slide_width)
      assert grid.row_gap == Units.resolve_percent({3, :percent}, @slide_height)
    end

    test "parses grid-rows with explicit percentages" do
      {grid, _} = Grid.parse_config("grid grid-rows-[15%_85%]", @slide_width, @slide_height)
      assert map_size(grid.row_ys) == 2
      assert grid.row_heights[1] == Units.resolve_percent({15, :percent}, @slide_height)
      assert grid.row_heights[2] == Units.resolve_percent({85, :percent}, @slide_height)
    end

    test "parses grid-rows with auto" do
      {grid, _} =
        Grid.parse_config(
          "grid grid-rows-[15%_auto] p-[5%] gap-[2%]",
          @slide_width,
          @slide_height
        )

      pad_top = Units.resolve_percent({5, :percent}, @slide_height)
      content_height = @slide_height - 2 * pad_top
      row_gap = Units.resolve_percent({2, :percent}, @slide_height)

      row1_height = Units.resolve_percent({15, :percent}, content_height)
      auto_height = content_height - row1_height - row_gap

      assert grid.row_heights[1] == row1_height
      assert grid.row_heights[2] == auto_height
    end

    test "parses grid-rows with multiple auto rows" do
      {grid, _} =
        Grid.parse_config("grid grid-rows-[auto_auto_auto]", @slide_width, @slide_height)

      # 3 auto rows, no gap
      auto_height = div(@slide_height, 3)
      assert grid.row_heights[1] == auto_height
      assert grid.row_heights[2] == auto_height
      assert grid.row_heights[3] == auto_height
    end

    test "returns remaining non-grid tokens" do
      {grid, remaining} =
        Grid.parse_config(
          "grid grid-cols-12 p-[5%] background: #FF0000",
          @slide_width,
          @slide_height
        )

      assert grid != nil
      assert remaining == "background: #FF0000"
    end

    test "unit_width accounts for padding and gaps" do
      {grid, _} =
        Grid.parse_config("grid grid-cols-12 p-[5%] gap-[2%]", @slide_width, @slide_height)

      content_width = @slide_width - 2 * grid.padding_left
      expected_unit = div(content_width - 11 * grid.col_gap, 12)
      assert grid.unit_width == expected_unit
    end

    test "row ys account for padding and gaps" do
      {grid, _} =
        Grid.parse_config(
          "grid grid-rows-[20%_auto] p-[5%] gap-[2%]",
          @slide_width,
          @slide_height
        )

      assert grid.row_ys[1] == grid.padding_top
      assert grid.row_ys[2] == grid.padding_top + grid.row_heights[1] + grid.row_gap
    end
  end

  describe "parse_placement/1" do
    test "parses row-N" do
      {placement, remaining} = Grid.parse_placement("row-1 col-span-12")
      assert placement.row == 1
      assert placement.col_span == 12
      assert remaining == ""
    end

    test "parses col-start-N" do
      {placement, _} = Grid.parse_placement("row-2 col-span-4 col-start-5")
      assert placement.row == 2
      assert placement.col_span == 4
      assert placement.col_start == 5
    end

    test "defaults col_span to 1" do
      {placement, _} = Grid.parse_placement("row-1")
      assert placement.col_span == 1
      assert placement.col_start == nil
    end

    test "preserves non-placement tokens" do
      {placement, remaining} = Grid.parse_placement("row-1 col-span-6 background: #FF0000")
      assert placement.row == 1
      assert remaining == "background: #FF0000"
    end
  end

  describe "resolve/2" do
    setup do
      {grid, _} =
        Grid.parse_config(
          "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]",
          @slide_width,
          @slide_height
        )

      %{grid: grid}
    end

    test "resolves first element in row 1", %{grid: grid} do
      placement = %{row: 1, col_span: 12, col_start: nil}
      {opts, _updated} = Grid.resolve(grid, placement)

      assert opts[:x] == grid.padding_left
      assert opts[:y] == grid.row_ys[1]
      assert opts[:width] == 12 * grid.unit_width + 11 * grid.col_gap
      assert opts[:height] == grid.row_heights[1]
    end

    test "resolves elements in row 2 with cursor advancement", %{grid: grid} do
      p1 = %{row: 2, col_span: 8, col_start: nil}
      {opts1, grid} = Grid.resolve(grid, p1)

      p2 = %{row: 2, col_span: 4, col_start: nil}
      {opts2, _grid} = Grid.resolve(grid, p2)

      assert opts1[:x] == grid.padding_left
      assert opts1[:width] == 8 * grid.unit_width + 7 * grid.col_gap

      expected_x2 = grid.padding_left + 8 * (grid.unit_width + grid.col_gap)
      assert opts2[:x] == expected_x2
      assert opts2[:width] == 4 * grid.unit_width + 3 * grid.col_gap

      # Both in same row
      assert opts1[:y] == opts2[:y]
      assert opts1[:height] == opts2[:height]
    end

    test "col-start-N overrides cursor", %{grid: grid} do
      placement = %{row: 1, col_span: 6, col_start: 4}
      {opts, _grid} = Grid.resolve(grid, placement)

      expected_x = grid.padding_left + 3 * (grid.unit_width + grid.col_gap)
      assert opts[:x] == expected_x
    end

    test "raises for row out of bounds", %{grid: grid} do
      assert_raise ArgumentError, ~r/row-3 is out of bounds/, fn ->
        Grid.resolve(grid, %{row: 3, col_span: 1, col_start: nil})
      end
    end

    test "raises for column overflow", %{grid: grid} do
      assert_raise ArgumentError, ~r/exceeds grid column count/, fn ->
        Grid.resolve(grid, %{row: 1, col_span: 13, col_start: nil})
      end
    end

    test "raises for col-start + span overflow", %{grid: grid} do
      assert_raise ArgumentError, ~r/exceeds grid column count/, fn ->
        Grid.resolve(grid, %{row: 1, col_span: 6, col_start: 8})
      end
    end

    test "row cursors are independent per row", %{grid: grid} do
      # Place in row 2
      {_, grid} = Grid.resolve(grid, %{row: 2, col_span: 4, col_start: nil})
      # Place in row 1 (cursor should start at 1)
      {opts, _grid} = Grid.resolve(grid, %{row: 1, col_span: 12, col_start: nil})

      assert opts[:x] == grid.padding_left
    end
  end

  describe "has_placement?/1" do
    test "returns true for grid placement classes" do
      assert Grid.has_placement?("row-1 col-span-12")
      assert Grid.has_placement?("row-2 col-span-4 col-start-5")
      assert Grid.has_placement?("row-1")
    end

    test "returns false for non-grid styles" do
      refute Grid.has_placement?("left: 5%; top: 10%")
      refute Grid.has_placement?("")
    end
  end

  describe "integration — grid slide with add_text_box" do
    test "elements placed on a grid slide get correct positions" do
      slide =
        Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")

      assert slide.grid != nil
      assert slide.grid.col_count == 12

      slide =
        slide
        |> Podium.add_text_box(
          "Title",
          style: "row-1 col-span-12",
          alignment: :center
        )
        |> Podium.add_text_box(
          "Left content",
          style: "row-2 col-span-8"
        )
        |> Podium.add_text_box(
          "Right sidebar",
          style: "row-2 col-span-4"
        )

      assert length(slide.shapes) == 3

      [title, left, right] = slide.shapes

      # Title spans full width in row 1
      assert title.x == slide.grid.padding_left
      assert title.width == 12 * slide.grid.unit_width + 11 * slide.grid.col_gap

      # Left and right are in the same row
      assert left.y == right.y
      assert left.height == right.height

      # Right starts after left
      assert right.x > left.x + left.width
    end

    test "non-grid elements on grid slide use absolute positioning" do
      slide =
        Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[auto] p-[5%]")

      slide =
        Podium.add_text_box(slide, "Absolute",
          style: "left: 10%; top: 20%; width: 30%; height: 10%"
        )

      assert length(slide.shapes) == 1
      [shape] = slide.shapes
      assert shape.x == Units.resolve_percent({10, :percent}, @slide_width)
      assert shape.y == Units.resolve_percent({20, :percent}, @slide_height)
    end

    test "non-grid slides work exactly as before" do
      slide =
        Podium.Slide.new()
        |> Podium.add_text_box("Hello",
          style: "left: 5%; top: 5%; width: 90%; height: 15%"
        )

      assert slide.grid == nil
      assert length(slide.shapes) == 1
    end

    test "grid slide with chart placement" do
      data =
        Podium.Chart.ChartData.new()
        |> Podium.Chart.ChartData.add_categories(["A", "B"])
        |> Podium.Chart.ChartData.add_series("S1", [1, 2])

      slide =
        Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[auto] p-[5%] gap-[2%]")
        |> Podium.add_chart(:column_clustered, data, style: "row-1 col-span-12")

      assert length(slide.charts) == 1
      [chart] = slide.charts
      assert chart.x == slide.grid.padding_left
    end

    test "raises when row-N missing on grid element" do
      slide =
        Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[auto] p-[5%]")

      assert_raise ArgumentError, ~r/row-N is required/, fn ->
        Podium.add_text_box(slide, "Missing row", style: "col-span-12")
      end
    end
  end
end
