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

    test "rich text with bullets, spacing, strikethrough, and superscript" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [
            {[{"Strikethrough", strikethrough: true}], space_after: 6},
            {[{"E=mc", font_size: 18}, {"2", font_size: 12, superscript: true}],
             line_spacing: 1.5},
            {["Bullet one"], bullet: true},
            {["Sub-bullet"], bullet: true, level: 1},
            {["Step 1"], bullet: :number}
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {4, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(strike="sngStrike")
      assert xml =~ ~s(baseline="30000")
      assert xml =~ ~s(<a:spcAft><a:spcPts val="600"/></a:spcAft>)
      assert xml =~ ~s(<a:lnSpc><a:spcPct val="150000"/></a:lnSpc>)
      assert xml =~ ~s(<a:buChar char="&#x2022;"/>)
      assert xml =~ ~s(lvl="1")
      assert xml =~ ~s(<a:buAutoNum type="arabicPeriod"/>)
    end

    test "gradient fill" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Gradient",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:gradFill rotWithShape="1">)
      assert xml =~ ~s(<a:gs pos="0"><a:srgbClr val="FF0000"/></a:gs>)
      assert xml =~ ~s(<a:gs pos="100000"><a:srgbClr val="0000FF"/></a:gs>)
      assert xml =~ ~s(<a:lin ang="5400000" scaled="0"/>)
    end

    test "pattern fill" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Pattern",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          fill: {:pattern, :dn_diag, foreground: "FF0000", background: "FFFFFF"}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:pattFill prst="dnDiag">)
      assert xml =~ ~s(<a:fgClr><a:srgbClr val="FF0000"/></a:fgClr>)
      assert xml =~ ~s(<a:bgClr><a:srgbClr val="FFFFFF"/></a:bgClr>)
    end

    test "line with dash style" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Dashed",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          line: [color: "000000", width: {1, :pt}, dash_style: :dash]
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:prstDash val="dash"/>)
      assert xml =~ ~s(<a:ln w="12700">)
    end

    test "line with gradient fill" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Gradient line",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          line: [fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000}]
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:ln>)
      assert xml =~ ~s(<a:gradFill rotWithShape="1">)
      assert xml =~ ~s(<a:gs pos="0"><a:srgbClr val="FF0000"/></a:gs>)
    end

    test "line with pattern fill" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Pattern line",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          line: [
            fill: {:pattern, :dn_diag, foreground: "FF0000", background: "FFFFFF"},
            width: {2, :pt}
          ]
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:ln w="25400">)
      assert xml =~ ~s(<a:pattFill prst="dnDiag">)
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

    test "text frame margins" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Margins",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          margin_left: {0.5, :inches},
          margin_right: {0.5, :inches},
          margin_top: {0.25, :inches},
          margin_bottom: {0.25, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(lIns="457200")
      assert xml =~ ~s(rIns="457200")
      assert xml =~ ~s(tIns="228600")
      assert xml =~ ~s(bIns="228600")
    end

    test "omitted margins use no attrs" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "No margins",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(<a:bodyPr wrap="square" rtlCol="0"/>)
      refute xml =~ "lIns"
      refute xml =~ "rIns"
      refute xml =~ "tIns"
      refute xml =~ "bIns"
    end

    test "45 degree rotation" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Rotated",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          rotation: 45
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(rot="2700000")
    end

    test "picture fill generates blipFill XML" do
      shape =
        Podium.Shape.text_box(2, "Over Image",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {2, :inches},
          fill: {:picture_fill, 0}
        )

      shape = %{shape | fill_opts: [mode: :stretch]}
      xml = Podium.Shape.to_xml(shape, "rId5")

      assert xml =~ ~s(<a:blipFill rotWithShape="1">)
      assert xml =~ ~s(r:embed="rId5")
      assert xml =~ ~s(<a:stretch><a:fillRect/></a:stretch>)
      assert xml =~ ~s(</a:blipFill>)
    end

    test "picture fill with tile mode" do
      shape =
        Podium.Shape.text_box(2, "Tiled",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {2, :inches},
          fill: {:picture_fill, 0}
        )

      shape = %{shape | fill_opts: [mode: :tile]}
      xml = Podium.Shape.to_xml(shape, "rId3")

      assert xml =~ ~s(<a:blipFill rotWithShape="1">)
      assert xml =~ ~s(<a:tile tx="0" ty="0" sx="100000" sy="100000"/>)
    end

    test "picture fill without fill_rid falls back to noFill" do
      shape =
        Podium.Shape.text_box(2, "No RID",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {2, :inches},
          fill: {:picture_fill, 0}
        )

      shape = %{shape | fill_opts: [mode: :stretch]}
      xml = Podium.Shape.to_xml(shape)

      # Without a fill_rid, should not generate blipFill — falls through to Drawing.fill_xml
      refute xml =~ "a:blipFill"
    end

    test "picture fill end-to-end packaging" do
      # Minimal valid PNG
      png_binary =
        <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48,
          0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00,
          0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78,
          0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00,
          0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82>>

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_picture_fill_text_box(prs, slide, "Over Image", png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {2, :inches},
          fill_mode: :stretch
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Fill image media file exists
      assert Enum.any?(Map.keys(parts), &String.contains?(&1, "fill_image"))

      # Slide XML has blipFill
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "a:blipFill"
      assert slide_xml =~ "r:embed="

      # Slide rels reference the fill image
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "fill_image"

      # Content types include png
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "image/png"
    end

    test "word_wrap: false produces wrap=none" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "No wrap",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          word_wrap: false
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(wrap="none")
      refute xml =~ ~s(wrap="square")
    end

    test "word_wrap: true produces wrap=square" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Wrap",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          word_wrap: true
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(wrap="square")
    end

    test "default word wrap is square (backwards compat)" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "Default",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(wrap="square")
    end

    test "word_wrap works on auto shapes" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_auto_shape(slide, :rounded_rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          text: "No wrap",
          word_wrap: false
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(wrap="none")
    end

    test "word_wrap: false end-to-end" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "No wrap label",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          word_wrap: false
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(wrap="none")
    end

    test "no rotation when not specified" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(slide, "No rotation",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ "<a:xfrm>"
      refute xml =~ "rot="
    end
  end
end
