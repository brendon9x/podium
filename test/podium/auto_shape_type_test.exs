defmodule Podium.AutoShapeTypeTest do
  use ExUnit.Case, async: true

  alias Podium.AutoShapeType

  describe "lookup/1" do
    test "returns correct prst and basename for known types" do
      assert AutoShapeType.lookup(:rounded_rectangle) == {"roundRect", "Rounded Rectangle"}
      assert AutoShapeType.lookup(:oval) == {"ellipse", "Oval"}
      assert AutoShapeType.lookup(:right_arrow) == {"rightArrow", "Right Arrow"}
      assert AutoShapeType.lookup(:star_5_point) == {"star5", "5-Point Star"}

      assert AutoShapeType.lookup(:flowchart_process) ==
               {"flowChartProcess", "Flowchart: Process"}

      assert AutoShapeType.lookup(:heart) == {"heart", "Heart"}
      assert AutoShapeType.lookup(:diamond) == {"diamond", "Diamond"}
      assert AutoShapeType.lookup(:hexagon) == {"hexagon", "Hexagon"}
    end

    test "raises ArgumentError for unknown atoms" do
      assert_raise ArgumentError, ~r/unknown auto shape type/, fn ->
        AutoShapeType.lookup(:nonexistent_shape)
      end
    end
  end

  describe "prst/1" do
    test "returns only the prst string" do
      assert AutoShapeType.prst(:rectangle) == "rect"
      assert AutoShapeType.prst(:cross) == "plus"
      assert AutoShapeType.prst(:isosceles_triangle) == "triangle"
    end
  end

  describe "basename/1" do
    test "returns only the basename string" do
      assert AutoShapeType.basename(:rectangle) == "Rectangle"
      assert AutoShapeType.basename(:no_symbol) == "No Symbol"
    end
  end

  describe "all_types/0" do
    test "returns a sorted list of atoms" do
      types = AutoShapeType.all_types()
      assert is_list(types)
      assert length(types) >= 180
      assert :rectangle in types
      assert :oval in types
      assert :flowchart_process in types
      assert types == Enum.sort(types)
    end
  end
end
