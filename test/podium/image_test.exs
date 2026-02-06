defmodule Podium.ImageTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  # Minimal valid PNG (1x1 pixel, RGBA)
  @png_binary <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
                0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
                0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
                0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27,
                0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
                0x82>>

  # Minimal JPEG (just the header bytes + padding)
  @jpeg_binary <<0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00>>

  describe "add_image/4" do
    test "adds a PNG image to a slide" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      assert length(slide.images) == 1
      assert prs.next_image_index == 2

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Image media file exists
      assert Map.has_key?(parts, "ppt/media/image1.png")
      assert parts["ppt/media/image1.png"] == @png_binary

      # Slide XML has p:pic element
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:pic"
      assert slide_xml =~ "a:blip"

      # Slide rels reference the image
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "image1.png"

      # Content types include png
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "image/png"
    end

    test "detects JPEG format" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @jpeg_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.jpeg")
    end

    test "rejects unsupported format" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs)

      assert_raise ArgumentError, ~r/unsupported image format/, fn ->
        Podium.add_image(prs, slide, "not an image",
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )
      end
    end

    test "multiple images get incrementing indices" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {5, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.png")
      assert Map.has_key?(parts, "ppt/media/image2.png")
    end
  end
end
