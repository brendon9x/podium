defmodule Podium.PlaceholderTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

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

    test "sets title and body on title_content layout" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_content)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Slide Title")
        |> Podium.set_placeholder(:body, "Some body content")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "Slide Title"
      assert slide_xml =~ "Some body content"
      assert slide_xml =~ ~s(type="title")
      assert slide_xml =~ ~s(type="body")
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
end
