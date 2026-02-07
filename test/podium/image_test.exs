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

  # Minimal BMP header
  @bmp_binary <<0x42, 0x4D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

  # Minimal GIF header
  @gif_binary <<0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00, 0x00, 0x00>>

  # Minimal TIFF header (little-endian)
  @tiff_binary <<0x49, 0x49, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00>>

  # EMF: minimal valid header (record type 1 = EMR_HEADER, then padding to get signature at offset 40)
  @emf_binary <<0x01, 0x00, 0x00, 0x00>> <>
                :binary.copy(<<0x00>>, 36) <>
                <<0x20, 0x45, 0x4D, 0x46>> <>
                :binary.copy(<<0x00>>, 20)

  # WMF: placeable metafile key
  @wmf_binary <<0x9A, 0xC6, 0xCD, 0xD7, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00>>

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

    test "detects BMP format" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @bmp_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/image1.bmp")
      assert parts["[Content_Types].xml"] =~ "image/bmp"
    end

    test "detects GIF format" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @gif_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/image1.gif")
      assert parts["[Content_Types].xml"] =~ "image/gif"
    end

    test "detects TIFF format" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @tiff_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/image1.tiff")
      assert parts["[Content_Types].xml"] =~ "image/tiff"
    end

    test "image cropping" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches},
          crop: [left: 10_000, top: 15_000, right: 20_000, bottom: 25_000]
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(a:srcRect)
      assert slide_xml =~ ~s(l="10000")
      assert slide_xml =~ ~s(t="15000")
      assert slide_xml =~ ~s(r="20000")
      assert slide_xml =~ ~s(b="25000")
    end

    test "90 degree rotation" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches},
          rotation: 90
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(rot="5400000")
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

    test "different images get incrementing indices" do
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
        Podium.add_image(prs, slide, @jpeg_binary,
          x: {5, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.png")
      assert Map.has_key?(parts, "ppt/media/image2.jpeg")
    end

    test "PNG auto-scale uses native size at 72 DPI" do
      # Our test PNG is 1x1 pixel with no pHYs chunk, so 72 DPI default
      # 914400 * 1 / 72 = 12700 EMU
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(cx="12700")
      assert slide_xml =~ ~s(cy="12700")
    end

    test "width-only auto-calculates height preserving aspect ratio" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      # 1x1 pixel, so width = height when preserving aspect ratio
      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # 2 inches = 1828800 EMU
      assert slide_xml =~ ~s(cx="1828800")
      # 1:1 aspect ratio, so height should also be 1828800
      assert slide_xml =~ ~s(cy="1828800")
    end

    test "height-only auto-calculates width preserving aspect ratio" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          height: {3, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # 3 inches = 2743200 EMU
      assert slide_xml =~ ~s(cy="2743200")
      assert slide_xml =~ ~s(cx="2743200")
    end

    test "EMF format detection" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @emf_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.emf")
      assert parts["[Content_Types].xml"] =~ "image/x-emf"
    end

    test "WMF format detection" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @wmf_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.wmf")
      assert parts["[Content_Types].xml"] =~ "image/x-wmf"
    end

    test "TIFF without explicit size raises" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs)

      assert_raise ArgumentError, ~r/explicit :width and :height are required for TIFF/, fn ->
        Podium.add_image(prs, slide, @tiff_binary,
          x: {1, :inches},
          y: {1, :inches}
        )
      end
    end

    test "EMF without explicit size raises" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs)

      assert_raise ArgumentError, ~r/explicit :width and :height are required for EMF/, fn ->
        Podium.add_image(prs, slide, @emf_binary,
          x: {1, :inches},
          y: {1, :inches}
        )
      end
    end

    test "image masking with ellipse shape" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: :ellipse
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prstGeom prst="ellipse")
      refute slide_xml =~ ~s(prstGeom prst="rect")
    end

    test "image masking defaults to rect" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prstGeom prst="rect")
    end

    test "image masking with raw string preset" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_image(prs, slide, @png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: "star5"
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prstGeom prst="star5")
    end

    test "duplicate images are deduplicated" do
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

      # next_image_index should NOT have incremented for the dup
      assert prs.next_image_index == 2

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Only one media file, both references point to image1
      assert Map.has_key?(parts, "ppt/media/image1.png")
      refute Map.has_key?(parts, "ppt/media/image2.png")

      # Both images still render on the slide (two <p:pic> opening tags)
      slide_xml = parts["ppt/slides/slide1.xml"]
      pic_count = length(Regex.scan(~r/<p:pic\s/, slide_xml))
      assert pic_count == 2
    end
  end
end
