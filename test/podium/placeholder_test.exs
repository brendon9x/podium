defmodule Podium.PlaceholderTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  # Minimal valid PNG (1x1 pixel, RGBA)
  @png_binary <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
                0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
                0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
                0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27,
                0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
                0x82>>

  describe "set_placeholder/3" do
    test "sets title and subtitle on title_slide layout" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_slide)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Annual Report 2025")
        |> Podium.set_placeholder(:subtitle, "Engineering Division")

      assert length(slide.placeholders) == 2

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Annual Report 2025"
      assert slide_xml =~ "Engineering Division"
      assert slide_xml =~ ~s(type="ctrTitle")
      assert slide_xml =~ ~s(type="subTitle")
    end

    test "sets title and content on title_content layout" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_content)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Slide Title")
        |> Podium.set_placeholder(:content, "Some body content")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Slide Title"
      assert slide_xml =~ "Some body content"
      assert slide_xml =~ ~s(type="title")
      # content placeholder has no type attribute, only idx
      assert slide_xml =~ ~s(idx="1")
    end

    test "content placeholder on title_content emits no type attribute" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_content)

      slide = Podium.set_placeholder(slide, :content, "Content here")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # The content placeholder should have idx="1" but no type attribute
      assert slide_xml =~ ~s(<p:ph idx="1"/>)
      refute slide_xml =~ ~s(type="body" idx="1")
    end

    test "accepts integer layout index" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: 1)

      slide = Podium.set_placeholder(slide, :title, "Title")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "Title"
    end

    test "raises on unknown placeholder" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs, layout: :blank)

      assert_raise ArgumentError, ~r/unknown placeholder/, fn ->
        Podium.set_placeholder(slide, :title, "This should fail")
      end
    end

    test "placeholder text supports rich text" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_slide)

      slide =
        Podium.set_placeholder(slide, :title, [[{"Bold Title", bold: true, font_size: 44}]])

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Bold Title"
      assert slide_xml =~ ~s(b="1")
      assert slide_xml =~ ~s(sz="4400")
    end

    test "slide rels reference correct layout" do
      prs = Podium.new()
      {prs, _slide} = Podium.add_slide(prs, layout: :title_slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]

      # title_slide = layout index 1
      assert slide_rels =~ "slideLayout1.xml"
    end
  end

  describe "all 11 layouts" do
    @layouts [
      {:title_slide, 1},
      {:title_content, 2},
      {:section_header, 3},
      {:two_content, 4},
      {:comparison, 5},
      {:title_only, 6},
      {:blank, 7},
      {:content_caption, 8},
      {:picture_caption, 9},
      {:title_vertical_text, 10},
      {:vertical_title_text, 11}
    ]

    for {layout_atom, layout_index} <- @layouts do
      test "layout #{layout_atom} (index #{layout_index}) references slideLayout#{layout_index}.xml" do
        prs = Podium.new()
        {prs, _slide} = Podium.add_slide(prs, layout: unquote(layout_atom))
        {:ok, binary} = Podium.save_to_memory(prs)

        parts = PptxHelpers.unzip_pptx_binary(binary)
        slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]

        assert slide_rels =~ "slideLayout#{unquote(layout_index)}.xml"
      end
    end

    test "integer layout index also works for all 11" do
      for idx <- 1..11 do
        prs = Podium.new()
        {prs, _slide} = Podium.add_slide(prs, layout: idx)
        {:ok, binary} = Podium.save_to_memory(prs)

        parts = PptxHelpers.unzip_pptx_binary(binary)
        slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]

        assert slide_rels =~ "slideLayout#{idx}.xml"
      end
    end
  end

  describe "two_content layout" do
    test "sets title, left_content, and right_content" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :two_content)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Two Column Title")
        |> Podium.set_placeholder(:left_content, "Left side")
        |> Podium.set_placeholder(:right_content, "Right side")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Two Column Title"
      assert slide_xml =~ "Left side"
      assert slide_xml =~ "Right side"
      assert slide_xml =~ ~s(type="title")
      assert slide_xml =~ ~s(idx="1")
      assert slide_xml =~ ~s(idx="2")
    end
  end

  describe "comparison layout" do
    test "sets all 5 placeholders" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :comparison)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Comparison Title")
        |> Podium.set_placeholder(:left_heading, "Left Heading")
        |> Podium.set_placeholder(:left_content, "Left Body")
        |> Podium.set_placeholder(:right_heading, "Right Heading")
        |> Podium.set_placeholder(:right_content, "Right Body")

      assert length(slide.placeholders) == 5

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Comparison Title"
      assert slide_xml =~ "Left Heading"
      assert slide_xml =~ "Left Body"
      assert slide_xml =~ "Right Heading"
      assert slide_xml =~ "Right Body"
      # heading placeholders have type="body"
      assert slide_xml =~ ~s(type="body")
      # content placeholders have idx but no type
      assert slide_xml =~ ~s(idx="2")
      assert slide_xml =~ ~s(idx="4")
    end
  end

  describe "title_only layout" do
    test "sets just title" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_only)

      slide = Podium.set_placeholder(slide, :title, "Only a Title")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Only a Title"
      assert slide_xml =~ ~s(type="title")
    end

    test "raises on unknown placeholder for title_only" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs, layout: :title_only)

      assert_raise ArgumentError, ~r/unknown placeholder/, fn ->
        Podium.set_placeholder(slide, :body, "Should fail")
      end
    end
  end

  describe "section_header layout" do
    test "sets title and body" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :section_header)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Section Title")
        |> Podium.set_placeholder(:body, "Section description")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Section Title"
      assert slide_xml =~ "Section description"
    end
  end

  describe "content_caption layout" do
    test "sets title, content, and caption" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :content_caption)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Caption Title")
        |> Podium.set_placeholder(:content, "Main content")
        |> Podium.set_placeholder(:caption, "Caption text")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Caption Title"
      assert slide_xml =~ "Main content"
      assert slide_xml =~ "Caption text"
    end
  end

  describe "title_vertical_text layout" do
    test "sets title and body" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_vertical_text)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Vertical Title")
        |> Podium.set_placeholder(:body, "Vertical body")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]

      assert slide_rels =~ "slideLayout10.xml"
    end
  end

  describe "vertical_title_text layout" do
    test "sets title and body" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :vertical_title_text)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Vert Title Text")
        |> Podium.set_placeholder(:body, "Vert body text")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]

      assert slide_rels =~ "slideLayout11.xml"
    end
  end

  describe "picture placeholder" do
    test "picture_caption layout with picture placeholder produces p:pic with r:embed" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :picture_caption)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Picture Slide")
        |> Podium.set_placeholder(:caption, "A caption")

      {prs, slide} = Podium.set_picture_placeholder(prs, slide, :picture, @png_binary)

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # Should have p:pic element
      assert slide_xml =~ "<p:pic"
      # Should reference the image via r:embed
      assert slide_xml =~ "r:embed="
      # Should have type="pic" with idx
      assert slide_xml =~ ~s(type="pic")
      assert slide_xml =~ ~s(idx="1")
      # Image binary should be stored
      assert Map.has_key?(parts, "ppt/media/image1.png")
      # Text placeholders should also be present
      assert slide_xml =~ "Picture Slide"
      assert slide_xml =~ "A caption"
    end

    test "raises when using set_placeholder on picture placeholder" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs, layout: :picture_caption)

      assert_raise ArgumentError, ~r/picture placeholder/, fn ->
        Podium.set_placeholder(slide, :picture, "Should fail")
      end
    end

    test "raises when using set_picture_placeholder on text placeholder" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :picture_caption)

      assert_raise ArgumentError, ~r/not a picture placeholder/, fn ->
        Podium.set_picture_placeholder(prs, slide, :title, @png_binary)
      end
    end

    test "raises on unknown placeholder name for picture" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :picture_caption)

      assert_raise ArgumentError, ~r/unknown placeholder/, fn ->
        Podium.set_picture_placeholder(prs, slide, :nonexistent, @png_binary)
      end
    end
  end

  describe "footer/date/slide_number" do
    test "footer text appears in slide XML" do
      prs = Podium.new()
      prs = Podium.set_footer(prs, footer: "Acme Corp Confidential")
      {prs, _slide} = Podium.add_slide(prs, layout: :title_slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Acme Corp Confidential"
      assert slide_xml =~ ~s(type="ftr")
      assert slide_xml =~ ~s(idx="11")
    end

    test "date text appears in slide XML" do
      prs = Podium.new()
      prs = Podium.set_footer(prs, date: "February 2026")
      {prs, _slide} = Podium.add_slide(prs, layout: :blank)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "February 2026"
      assert slide_xml =~ ~s(type="dt")
      assert slide_xml =~ ~s(idx="10")
    end

    test "slide number uses a:fld with id and type slidenum" do
      prs = Podium.new()
      prs = Podium.set_footer(prs, slide_number: true)
      {prs, _slide} = Podium.add_slide(prs, layout: :blank)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(type="sldNum")
      assert slide_xml =~ ~s(idx="12")
      # a:fld must have id (GUID) and type attributes
      assert slide_xml =~ ~r/<a:fld id="\{[A-F0-9-]+\}" type="slidenum">/
    end

    test "all three footer fields on every slide" do
      prs = Podium.new()

      prs =
        Podium.set_footer(prs,
          footer: "Footer Text",
          date: "Jan 2026",
          slide_number: true
        )

      {prs, _s1} = Podium.add_slide(prs, layout: :title_slide)
      {prs, _s2} = Podium.add_slide(prs, layout: :blank)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      for slide_path <- ["ppt/slides/slide1.xml", "ppt/slides/slide2.xml"] do
        slide_xml = parts[slide_path]
        assert slide_xml =~ "Footer Text"
        assert slide_xml =~ "Jan 2026"
        assert slide_xml =~ ~s(type="sldNum")
      end
    end

    test "footer is not injected when not set" do
      prs = Podium.new()
      {prs, _slide} = Podium.add_slide(prs, layout: :blank)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      refute slide_xml =~ ~s(type="ftr")
      refute slide_xml =~ ~s(type="dt")
      refute slide_xml =~ ~s(type="sldNum")
    end

    test "footer escapes special XML characters" do
      prs = Podium.new()
      prs = Podium.set_footer(prs, footer: "A & B <Corp>")
      {prs, _slide} = Podium.add_slide(prs, layout: :blank)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "A &amp; B &lt;Corp&gt;"
    end
  end

  describe "error cases" do
    test "raises on unknown layout index > 11" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs, layout: 99)

      assert_raise ArgumentError, ~r/unknown layout index/, fn ->
        Podium.set_placeholder(slide, :title, "Should fail")
      end
    end
  end
end
