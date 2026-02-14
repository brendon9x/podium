defmodule Podium.SlideTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  # A minimal 1x1 PNG for testing
  @png_binary <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
                0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02,
                0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44,
                0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00, 0x00, 0x00, 0x02, 0x00,
                0x01, 0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
                0xAE, 0x42, 0x60, 0x82>>

  describe "slide background" do
    test "solid background fill" do
      slide = Podium.Slide.new(:blank, background: "003366")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ "<p:bgPr>"
      assert slide_xml =~ ~s(<a:solidFill><a:srgbClr val="003366"/></a:solidFill>)
      assert slide_xml =~ "<a:effectLst/>"
    end

    test "gradient background fill" do
      slide =
        Podium.Slide.new(:blank,
          background: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ ~s(<a:gradFill rotWithShape="1">)
    end

    test "no background when nil" do
      slide = Podium.Slide.new()

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      refute slide_xml =~ "<p:bg>"
    end

    test "picture background fill produces blipFill with r:embed" do
      slide = Podium.Slide.new(:blank, background: {:picture, @png_binary})

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ "<p:bgPr>"
      assert slide_xml =~ "<a:blipFill"
      assert slide_xml =~ ~s(r:embed=")
      assert slide_xml =~ "<a:stretch>"
    end

    test "picture background stores image in media" do
      slide = Podium.Slide.new(:blank, background: {:picture, @png_binary})

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Background image should be in ppt/media/
      bg_media =
        parts
        |> Map.keys()
        |> Enum.filter(&String.starts_with?(&1, "ppt/media/bg_image"))

      assert length(bg_media) == 1
      assert parts[hd(bg_media)] == @png_binary
    end

    test "picture background has image relationship in slide rels" do
      slide = Podium.Slide.new(:blank, background: {:picture, @png_binary})

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      rels_xml = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert rels_xml =~ "../media/bg_image1.png"
    end

    test "non-picture backgrounds remain unchanged" do
      slide = Podium.Slide.new(:blank, background: "FF0000")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
      refute slide_xml =~ "blipFill"
    end
  end
end
