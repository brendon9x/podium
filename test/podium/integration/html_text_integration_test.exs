defmodule Podium.Integration.HTMLTextIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir Path.join([__DIR__, "output"])

  describe "HTML in text boxes" do
    test "creates valid pptx with HTML bold and italic" do
      slide =
        Podium.Slide.new()
        |> Podium.add_text_box(
          {:html, "<p><b>Bold title</b></p><p>Some <i>italic</i> text</p>"},
          x: {1, :inches},
          y: {1, :inches},
          width: {10, :inches},
          height: {2, :inches}
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      output_path = Path.join(@output_dir, "html_text_bold_italic.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(<a:t>Bold title</a:t>)
      assert slide_xml =~ ~s(b="1")
      assert slide_xml =~ ~s(i="1")
      assert slide_xml =~ ~s(<a:t>italic</a:t>)
    end

    test "creates valid pptx with HTML styled spans" do
      html =
        ~s(<p><span style="color: #FF0000; font-size: 24pt; font-family: Arial">Red big Arial</span></p>)

      slide =
        Podium.Slide.new()
        |> Podium.add_text_box({:html, html},
          x: {1, :inches},
          y: {1, :inches},
          width: {10, :inches},
          height: {1, :inches}
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(<a:t>Red big Arial</a:t>)
      assert slide_xml =~ ~s(sz="2400")
      assert slide_xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
      assert slide_xml =~ ~s(<a:latin typeface="Arial"/>)
    end

    test "creates valid pptx with HTML bullet list" do
      html = "<ul><li>First item</li><li>Second item</li></ul>"

      slide =
        Podium.Slide.new()
        |> Podium.add_text_box({:html, html},
          x: {1, :inches},
          y: {1, :inches},
          width: {10, :inches},
          height: {3, :inches}
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(<a:buChar)
      assert slide_xml =~ ~s(<a:t>First item</a:t>)
      assert slide_xml =~ ~s(<a:t>Second item</a:t>)
    end

    test "creates valid pptx with HTML numbered list" do
      html = "<ol><li>Step 1</li><li>Step 2</li><li>Step 3</li></ol>"

      slide =
        Podium.Slide.new()
        |> Podium.add_text_box({:html, html},
          x: {1, :inches},
          y: {1, :inches},
          width: {10, :inches},
          height: {3, :inches}
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(<a:buAutoNum type="arabicPeriod"/>)
    end

    test "HTML with alignment and default font_size" do
      html = ~s(<p style="text-align: center"><b>Centered Title</b></p>)

      slide =
        Podium.Slide.new()
        |> Podium.add_text_box({:html, html},
          x: {1, :inches},
          y: {1, :inches},
          width: {10, :inches},
          height: {1, :inches},
          font_size: 28
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(algn="ctr")
      assert slide_xml =~ ~s(sz="2800")
      assert slide_xml =~ ~s(b="1")
    end
  end

  describe "HTML in table cells" do
    test "creates valid pptx with HTML in table cells" do
      rows = [
        ["Header", {:html, "<b>Bold Header</b>"}],
        ["Plain cell", {:html, "<i>Italic</i> and <b>bold</b>"}]
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_table(rows,
          x: {1, :inches},
          y: {1, :inches},
          width: {10, :inches},
          height: {3, :inches}
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      output_path = Path.join(@output_dir, "html_text_table.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(<a:t>Bold Header</a:t>)
      assert slide_xml =~ ~s(b="1")
      assert slide_xml =~ ~s(i="1")
    end
  end

  describe "HTML in placeholders" do
    test "creates valid pptx with HTML in placeholder" do
      slide =
        Podium.Slide.new(:title_content)
        |> Podium.set_placeholder(:title, {:html, "<b>HTML</b> Title"})
        |> Podium.set_placeholder(
          :content,
          {:html, "<ul><li>Point one</li><li>Point two</li></ul>"}
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      output_path = Path.join(@output_dir, "html_text_placeholder.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(b="1")
      assert slide_xml =~ ~s(<a:buChar)
    end
  end

  describe "HTML in auto shapes" do
    test "creates valid pptx with HTML text in auto shape" do
      slide =
        Podium.Slide.new()
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {2, :inches},
          y: {2, :inches},
          width: {8, :inches},
          height: {3, :inches},
          text: {:html, "<p><b>Important!</b></p><p>This is <i>styled</i> text in a shape.</p>"},
          fill: "E8EDF2"
        )

      prs = Podium.new() |> Podium.add_slide(slide)

      output_path = Path.join(@output_dir, "html_text_auto_shape.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(b="1")
      assert slide_xml =~ ~s(i="1")
      assert slide_xml =~ ~s(<a:t>Important!</a:t>)
    end
  end
end
