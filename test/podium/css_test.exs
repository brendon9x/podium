defmodule Podium.CSSTest do
  use ExUnit.Case, async: true

  alias Podium.CSS

  describe "parse_position_style/1" do
    test "parses percent values" do
      assert CSS.parse_position_style("left: 10%") == [x: {10, :percent}]
      assert CSS.parse_position_style("top: 5%") == [y: {5, :percent}]
      assert CSS.parse_position_style("width: 80%") == [width: {80, :percent}]
      assert CSS.parse_position_style("height: 15%") == [height: {15, :percent}]
    end

    test "parses inch values" do
      assert CSS.parse_position_style("left: 2in") == [x: {2, :inches}]
      assert CSS.parse_position_style("top: 1.5in") == [y: {1.5, :inches}]
    end

    test "parses cm values" do
      assert CSS.parse_position_style("width: 5cm") == [width: {5, :cm}]
    end

    test "parses point values" do
      assert CSS.parse_position_style("height: 72pt") == [height: {72, :pt}]
    end

    test "parses bare numbers as EMU" do
      assert CSS.parse_position_style("left: 914400") == [x: 914_400]
    end

    test "parses multiple properties in one string" do
      result = CSS.parse_position_style("left: 10%; top: 5%; width: 80%; height: 15%")

      assert result == [
               x: {10, :percent},
               y: {5, :percent},
               width: {80, :percent},
               height: {15, :percent}
             ]
    end

    test "ignores unknown properties" do
      result = CSS.parse_position_style("left: 10%; color: red; top: 5%")
      assert result == [x: {10, :percent}, y: {5, :percent}]
    end

    test "handles extra whitespace" do
      result = CSS.parse_position_style("  left:  10%  ;  top:  5%  ")
      assert result == [x: {10, :percent}, y: {5, :percent}]
    end

    test "parses float values" do
      assert CSS.parse_position_style("left: 10.5%") == [x: {10.5, :percent}]
      assert CSS.parse_position_style("width: 2.54cm") == [width: {2.54, :cm}]
    end

    test "integer values are returned as integers, not floats" do
      assert CSS.parse_position_style("left: 10%") == [x: {10, :percent}]
      assert CSS.parse_position_style("width: 2in") == [width: {2, :inches}]
    end

    test "empty string returns empty list" do
      assert CSS.parse_position_style("") == []
    end

    test "handles trailing semicolons" do
      result = CSS.parse_position_style("left: 10%;")
      assert result == [x: {10, :percent}]
    end

    test "parses negative values" do
      assert CSS.parse_position_style("left: -10%") == [x: {-10, :percent}]
      assert CSS.parse_position_style("top: -2.5in") == [y: {-2.5, :inches}]
    end

    test "parses zero values" do
      assert CSS.parse_position_style("left: 0%") == [x: {0, :percent}]
      assert CSS.parse_position_style("left: 0") == [x: 0]
    end

    test "duplicate properties keeps first occurrence" do
      result = CSS.parse_position_style("left: 10%; left: 20%")
      # Both are returned; Keyword.get returns the first match
      assert Keyword.get(result, :x) == {10, :percent}
    end

    test "raises on invalid value with valid property" do
      assert_raise ArgumentError, ~r/invalid CSS value/, fn ->
        CSS.parse_position_style("left: abc%")
      end
    end

    test "raises on invalid bare value" do
      assert_raise ArgumentError, ~r/invalid CSS value/, fn ->
        CSS.parse_position_style("left: abc")
      end
    end
  end
end
