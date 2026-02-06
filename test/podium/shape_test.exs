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
      xml = shape.to_xml.(shape)

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
      xml = shape.to_xml.(shape)

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
  end
end
