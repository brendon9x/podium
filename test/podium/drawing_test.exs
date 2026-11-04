defmodule Podium.DrawingTest do
  use ExUnit.Case, async: true

  alias Podium.Drawing

  describe "fill_xml/1" do
    test ":none and nil write noFill" do
      assert Drawing.fill_xml(:none) == "<a:noFill/>"
      assert Drawing.fill_xml(nil) == "<a:noFill/>"
    end

    test "an unknown fill raises" do
      assert_raise ArgumentError, ~r/fill must be/, fn -> Drawing.fill_xml(:transparent) end
    end
  end

  describe "line_xml/1" do
    test ":none writes a line with no fill" do
      assert Drawing.line_xml(:none) == "<a:ln><a:noFill/></a:ln>"
    end

    test "nil writes nothing, leaving the default line" do
      assert Drawing.line_xml(nil) == ""
    end

    test "a keyword list with only a width keeps the default colour" do
      assert Drawing.line_xml(width: {2, :pt}) == ~s(<a:ln w="25400"></a:ln>)
    end

    test "a keyword list with only a dash style" do
      assert Drawing.line_xml(dash_style: :dash) == ~s(<a:ln><a:prstDash val="dash"/></a:ln>)
    end

    test "color: :none in a keyword list writes noFill" do
      assert Drawing.line_xml(color: :none, width: {1, :pt}) ==
               ~s(<a:ln w="12700"><a:noFill/></a:ln>)
    end

    test ":fill takes a gradient" do
      assert Drawing.line_xml(fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], []}) =~
               ~s(<a:ln><a:gradFill)
    end

    test "an unknown line raises" do
      assert_raise ArgumentError, ~r/line must be/, fn -> Drawing.line_xml(:dotted) end
    end
  end

  describe "shapes" do
    test "a shape with line: :none draws no outline" do
      slide =
        Podium.add_auto_shape(Podium.Slide.new(), :rectangle,
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          fill: "4472C4",
          line: :none
        )

      assert Podium.Shape.to_xml(hd(slide.shapes)) =~ "<a:ln><a:noFill/></a:ln>"
    end

    test "a shape with fill: :none is unfilled" do
      slide =
        Podium.add_auto_shape(Podium.Slide.new(), :rectangle,
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          fill: :none,
          line: "000000"
        )

      assert Podium.Shape.to_xml(hd(slide.shapes)) =~ "<a:noFill/><a:ln>"
    end
  end
end
