defmodule Podium.Integration.TextIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir Path.join([__DIR__, "output"])

  describe "rich text formatting" do
    test "creates valid pptx with bold, italic, underline, and color variations" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"Revenue grew ", font_size: 18},
              {"35%", bold: true, font_size: 18, color: "228B22"}
            ],
            [
              {"Customer satisfaction at ", font_size: 18},
              {"88%", bold: true, font_size: 18, color: "4472C4"}
            ],
            {[
               {"All metrics trending upward",
                italic: true, font_size: 16, color: "666666", underline: true, font: "Georgia"}
             ], alignment: :right}
          ],
          x: {1, :inches},
          y: {1.5, :inches},
          width: {11.33, :inches},
          height: {2.5, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for automated assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Assert on XML structure
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:t>35%</a:t>)
      assert slide_xml =~ ~s(b="1")
      assert slide_xml =~ ~s(i="1")
      assert slide_xml =~ ~s(u="sng")
    end

    test "creates valid pptx with strikethrough, superscript, and subscript" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            {[
               {"Strikethrough: ", font_size: 16},
               {"old price $99", font_size: 16, strikethrough: true, color: "CC0000"},
               {" → new price $79", font_size: 16, bold: true, color: "228B22"}
             ], space_after: 6},
            {[{"Superscript: E = mc", font_size: 16}, {"2", font_size: 12, superscript: true}],
             space_after: 6},
            {[
               {"Subscript: H", font_size: 16},
               {"2", font_size: 12, subscript: true},
               {"O", font_size: 16}
             ], space_after: 12, line_spacing: 1.5}
          ],
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {12.33, :inches},
          height: {2, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(strike="sngStrike")
      assert slide_xml =~ ~s(baseline="30000")
      assert slide_xml =~ ~s(baseline="-25000")
    end

    test "creates valid pptx with various underline styles" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"Single", underline: :single, font_size: 14},
              {"  Double", underline: :double, font_size: 14},
              {"  Wavy", underline: :wavy, font_size: 14},
              {"  Heavy", underline: :heavy, font_size: 14},
              {"  Dotted", underline: :dotted, font_size: 14}
            ]
          ],
          x: {3, :inches},
          y: {1.2, :inches},
          width: {9.83, :inches},
          height: {0.6, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(u="sng")
      assert slide_xml =~ ~s(u="dbl")
      assert slide_xml =~ ~s(u="wavy")
      assert slide_xml =~ ~s(u="heavy")
      assert slide_xml =~ ~s(u="dotted")
    end
  end

  describe "bullets and numbering" do
    test "creates valid pptx with bullet lists, nested bullets, and numbering" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            {[{"Bullet Lists", bold: true, font_size: 20}], space_after: 6},
            {["Revenue up 35% year-over-year"], bullet: true},
            {["North America grew fastest"], bullet: true, level: 1},
            {["APAC close behind"], bullet: true, level: 1},
            {["Customer satisfaction at all-time high"], bullet: true},
            {["Custom bullet: hiring plan on track"], bullet: "–"},
            {[{"Numbered Steps", bold: true, font_size: 20}], space_before: 12, space_after: 6},
            {["Review quarterly data"], bullet: :number},
            {["Identify growth opportunities"], bullet: :number},
            {["Present to board"], bullet: :number}
          ],
          x: {0.5, :inches},
          y: {1.5, :inches},
          width: {12.33, :inches},
          height: {4, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:buChar)
      assert slide_xml =~ ~s(<a:buAutoNum)
      assert slide_xml =~ ~s(lvl="1")
    end
  end

  describe "text alignment and spacing" do
    test "creates valid pptx with center alignment and spacing" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            {[{"Key Highlights", bold: true, font_size: 32, color: "FFFFFF"}], alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.8, :inches},
          fill: {:gradient, [{0, "001133"}, {100_000, "004488"}], angle: 5_400_000}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(algn="ctr")
    end
  end

  describe "text box fills and effects" do
    test "creates valid pptx with gradient fill and line styling" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            {[{"Text Formatting Features", bold: true, font_size: 28, color: "003366"}],
             alignment: :center, space_after: 12}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches},
          fill: {:pattern, :lt_horz, foreground: "003366", background: "E8EDF2"}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:pattFill)
    end

    test "creates valid pptx with rotated text box" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Rotated!",
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {2, :inches},
          height: {1, :inches},
          rotation: 15,
          fill: "4472C4",
          font_size: 18,
          alignment: :center
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(rot=)
    end
  end

  describe "line breaks and margins" do
    test "creates valid pptx with line breaks within paragraphs" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"Line breaks in a single paragraph:", bold: true, font_size: 14},
              :line_break,
              {"First line\nSecond line\nThird line", font_size: 14, color: "4472C4"}
            ]
          ],
          x: {0.5, :inches},
          y: {2.5, :inches},
          width: {5.5, :inches},
          height: {1.8, :inches},
          margin_left: {0.2, :inches},
          margin_top: {0.15, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:br/>)
    end

    test "creates valid pptx with custom margins" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Custom Margins",
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {2, :inches},
          height: {1, :inches},
          fill: "4472C4",
          margin_left: {0.3, :inches},
          margin_right: {0.3, :inches},
          margin_top: {0.15, :inches},
          margin_bottom: {0.15, :inches},
          font_size: 18,
          alignment: :center
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "text_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:bodyPr)
    end
  end
end
