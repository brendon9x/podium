defmodule Podium.ShapeTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "add_text_box/3" do
    test "adds a text box to a slide" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Hello World",
          x: {2, :inches},
          y: {2, :inches},
          width: {6, :inches},
          height: {1, :inches}
        )

      assert length(slide.shapes) == 1
      assert slide.next_shape_id == 3

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Hello World"
      assert slide_xml =~ ~s(txBox="1")
      assert slide_xml =~ ~s(x="1828800")
      assert slide_xml =~ ~s(y="1828800")
      assert slide_xml =~ ~s(cx="5486400")
      assert slide_xml =~ ~s(cy="914400")
    end

    test "supports font_size option" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Big Text",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          font_size: 24
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      # 24pt = 2400 hundredths of a point
      assert xml =~ ~s(sz="2400")
    end

    test "escapes special characters in text" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "A < B & C > D",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ "A &lt; B &amp; C &gt; D"
    end

    test "multiple text boxes get incrementing IDs" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        slide
        |> Podium.add_text_box("First",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )
        |> Podium.add_text_box("Second",
          x: {1, :inches},
          y: {3, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      assert length(slide.shapes) == 2
      [shape1, shape2] = slide.shapes
      assert shape1.id == 2
      assert shape2.id == 3
    end

    test "rich text with multiple paragraphs and runs" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [
            [{"Annual Report", bold: true, font_size: 36, color: "003366"}],
            [{"Dept: ", font_size: 18}, {"Engineering", bold: true, italic: true}]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {2, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      # First paragraph
      assert xml =~ ~s(sz="3600")
      assert xml =~ ~s(b="1")
      assert xml =~ ~s(val="003366")
      assert xml =~ "Annual Report"

      # Second paragraph
      assert xml =~ ~s(sz="1800")
      assert xml =~ "Dept: "
      assert xml =~ ~s(i="1")
      assert xml =~ "Engineering"
    end

    test "per-paragraph alignment" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [
            {[{"Title", bold: true}], alignment: :center},
            {[{"Body text"}], alignment: :left}
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {2, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(algn="ctr")
      assert xml =~ ~s(algn="l")
    end

    test "top-level alignment applied to all paragraphs" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Centered text",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          alignment: :center
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)
      assert xml =~ ~s(algn="ctr")
    end

    test "solid fill" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Filled",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          fill: "FF0000"
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
      refute xml =~ "<a:noFill/>"
    end

    test "line with default width" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Bordered",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          line: "000000"
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:ln><a:solidFill><a:srgbClr val="000000"/></a:solidFill></a:ln>)
    end

    test "line with custom width" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Thick border",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          line: [color: "000000", width: {2, :pt}]
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:ln w="25400">)
    end

    test "underline and font options" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [[{"Underlined", underline: true, font: "Arial"}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(u="sng")
      assert xml =~ ~s(typeface="Arial")
    end
  end
end
