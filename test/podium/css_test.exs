defmodule Podium.CSSTest do
  use ExUnit.Case, async: true

  alias Podium.CSS

  describe "parse_style/1 — dimension properties" do
    test "parses percent values" do
      assert CSS.parse_style("left: 10%") == [x: {10, :percent}]
      assert CSS.parse_style("top: 5%") == [y: {5, :percent}]
      assert CSS.parse_style("width: 80%") == [width: {80, :percent}]
      assert CSS.parse_style("height: 15%") == [height: {15, :percent}]
    end

    test "parses inch values" do
      assert CSS.parse_style("left: 2in") == [x: {2, :inches}]
      assert CSS.parse_style("top: 1.5in") == [y: {1.5, :inches}]
    end

    test "parses cm values" do
      assert CSS.parse_style("width: 5cm") == [width: {5, :cm}]
    end

    test "parses point values" do
      assert CSS.parse_style("height: 72pt") == [height: {72, :pt}]
    end

    test "parses bare numbers as EMU" do
      assert CSS.parse_style("left: 914400") == [x: 914_400]
    end

    test "parses multiple properties in one string" do
      result = CSS.parse_style("left: 10%; top: 5%; width: 80%; height: 15%")

      assert result == [
               x: {10, :percent},
               y: {5, :percent},
               width: {80, :percent},
               height: {15, :percent}
             ]
    end

    test "ignores unknown properties" do
      result = CSS.parse_style("left: 10%; color: red; top: 5%")
      assert result == [x: {10, :percent}, y: {5, :percent}]
    end

    test "handles extra whitespace" do
      result = CSS.parse_style("  left:  10%  ;  top:  5%  ")
      assert result == [x: {10, :percent}, y: {5, :percent}]
    end

    test "parses float values" do
      assert CSS.parse_style("left: 10.5%") == [x: {10.5, :percent}]
      assert CSS.parse_style("width: 2.54cm") == [width: {2.54, :cm}]
    end

    test "integer values are returned as integers, not floats" do
      assert CSS.parse_style("left: 10%") == [x: {10, :percent}]
      assert CSS.parse_style("width: 2in") == [width: {2, :inches}]
    end

    test "empty string returns empty list" do
      assert CSS.parse_style("") == []
    end

    test "handles trailing semicolons" do
      result = CSS.parse_style("left: 10%;")
      assert result == [x: {10, :percent}]
    end

    test "parses negative values" do
      assert CSS.parse_style("left: -10%") == [x: {-10, :percent}]
      assert CSS.parse_style("top: -2.5in") == [y: {-2.5, :inches}]
    end

    test "parses zero values" do
      assert CSS.parse_style("left: 0%") == [x: {0, :percent}]
      assert CSS.parse_style("left: 0") == [x: 0]
    end

    test "duplicate properties keeps first occurrence" do
      result = CSS.parse_style("left: 10%; left: 20%")
      # Both are returned; Keyword.get returns the first match
      assert Keyword.get(result, :x) == {10, :percent}
    end

    test "raises on invalid value with valid property" do
      assert_raise ArgumentError, ~r/invalid CSS value/, fn ->
        CSS.parse_style("left: abc%")
      end
    end

    test "raises on invalid bare value" do
      assert_raise ArgumentError, ~r/invalid CSS value/, fn ->
        CSS.parse_style("left: abc")
      end
    end
  end

  describe "parse_style/1 — text-align" do
    test "parses center" do
      assert CSS.parse_style("text-align: center") == [alignment: :center]
    end

    test "parses left" do
      assert CSS.parse_style("text-align: left") == [alignment: :left]
    end

    test "parses right" do
      assert CSS.parse_style("text-align: right") == [alignment: :right]
    end

    test "parses justify" do
      assert CSS.parse_style("text-align: justify") == [alignment: :justify]
    end

    test "raises on invalid value" do
      assert_raise ArgumentError, ~r/invalid text-align value/, fn ->
        CSS.parse_style("text-align: start")
      end
    end
  end

  describe "parse_style/1 — vertical-align" do
    test "parses top" do
      assert CSS.parse_style("vertical-align: top") == [anchor: :top]
    end

    test "parses middle" do
      assert CSS.parse_style("vertical-align: middle") == [anchor: :middle]
    end

    test "parses bottom" do
      assert CSS.parse_style("vertical-align: bottom") == [anchor: :bottom]
    end

    test "raises on invalid value" do
      assert_raise ArgumentError, ~r/invalid vertical-align value/, fn ->
        CSS.parse_style("vertical-align: baseline")
      end
    end
  end

  describe "parse_style/1 — background" do
    test "parses hex color with #" do
      assert CSS.parse_style("background: #FF0000") == [fill: "FF0000"]
    end

    test "parses hex color without #" do
      assert CSS.parse_style("background: FF0000") == [fill: "FF0000"]
    end

    test "normalizes to uppercase" do
      assert CSS.parse_style("background: #ff0000") == [fill: "FF0000"]
    end

    test "raises on invalid hex" do
      assert_raise ArgumentError, ~r/invalid background color/, fn ->
        CSS.parse_style("background: red")
      end
    end

    test "raises on short hex" do
      assert_raise ArgumentError, ~r/invalid background color/, fn ->
        CSS.parse_style("background: #F00")
      end
    end
  end

  describe "parse_style/1 — padding" do
    test "single value sets all four margins" do
      assert CSS.parse_style("padding: 12pt") == [
               margin_left: {12, :pt},
               margin_right: {12, :pt},
               margin_top: {12, :pt},
               margin_bottom: {12, :pt}
             ]
    end

    test "padding with inches" do
      assert CSS.parse_style("padding: 0.5in") == [
               margin_left: {0.5, :inches},
               margin_right: {0.5, :inches},
               margin_top: {0.5, :inches},
               margin_bottom: {0.5, :inches}
             ]
    end

    test "raises on multi-value padding" do
      assert_raise ArgumentError, ~r/multi-value padding shorthand is not supported/, fn ->
        CSS.parse_style("padding: 12pt 6pt")
      end
    end
  end

  describe "parse_style/1 — individual padding properties" do
    test "padding-left" do
      assert CSS.parse_style("padding-left: 0.5in") == [margin_left: {0.5, :inches}]
    end

    test "padding-right" do
      assert CSS.parse_style("padding-right: 12pt") == [margin_right: {12, :pt}]
    end

    test "padding-top" do
      assert CSS.parse_style("padding-top: 1cm") == [margin_top: {1, :cm}]
    end

    test "padding-bottom" do
      assert CSS.parse_style("padding-bottom: 12pt") == [margin_bottom: {12, :pt}]
    end

    test "raises on percent values" do
      assert_raise ArgumentError, ~r/percent values are not supported for padding/, fn ->
        CSS.parse_style("padding-left: 5%")
      end
    end

    test "raises on percent in padding shorthand" do
      assert_raise ArgumentError, ~r/percent values are not supported for padding/, fn ->
        CSS.parse_style("padding: 10%")
      end
    end
  end

  describe "parse_style/1 — mixed properties" do
    test "position + non-position properties in one string" do
      result =
        CSS.parse_style(
          "left: 10%; top: 5%; width: 80%; height: 15%; text-align: center; vertical-align: middle; background: #003366"
        )

      assert result == [
               x: {10, :percent},
               y: {5, :percent},
               width: {80, :percent},
               height: {15, :percent},
               alignment: :center,
               anchor: :middle,
               fill: "003366"
             ]
    end

    test "padding with position properties" do
      result = CSS.parse_style("left: 1in; top: 2in; width: 4in; height: 1in; padding: 12pt")

      assert result == [
               x: {1, :inches},
               y: {2, :inches},
               width: {4, :inches},
               height: {1, :inches},
               margin_left: {12, :pt},
               margin_right: {12, :pt},
               margin_top: {12, :pt},
               margin_bottom: {12, :pt}
             ]
    end
  end
end
