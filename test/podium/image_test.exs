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
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      assert length(slide.images) == 1

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

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
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@jpeg_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.jpeg")
    end

    test "detects BMP format" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@bmp_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/image1.bmp")
      assert parts["[Content_Types].xml"] =~ "image/bmp"
    end

    test "detects GIF format" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@gif_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/image1.gif")
      assert parts["[Content_Types].xml"] =~ "image/gif"
    end

    test "detects TIFF format" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@tiff_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/image1.tiff")
      assert parts["[Content_Types].xml"] =~ "image/tiff"
    end

    test "image cropping" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches},
          crop: [left: 10_000, top: 15_000, right: 20_000, bottom: 25_000]
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

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
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches},
          rotation: 90
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(rot="5400000")
    end

    test "rejects unsupported format" do
      slide = Podium.Slide.new()

      assert_raise ArgumentError, ~r/unsupported image format/, fn ->
        Podium.add_image(slide, "not an image",
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )
      end
    end

    test "different images get incrementing indices" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )
        |> Podium.add_image(@jpeg_binary,
          x: {5, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.png")
      assert Map.has_key?(parts, "ppt/media/image2.jpeg")
    end

    test "PNG auto-scale uses native size at 72 DPI" do
      # Our test PNG is 1x1 pixel with no pHYs chunk, so 72 DPI default
      # 914400 * 1 / 72 = 12700 EMU
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(cx="12700")
      assert slide_xml =~ ~s(cy="12700")
    end

    test "width-only auto-calculates height preserving aspect ratio" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # 2 inches = 1828800 EMU
      assert slide_xml =~ ~s(cx="1828800")
      # 1:1 aspect ratio, so height should also be 1828800
      assert slide_xml =~ ~s(cy="1828800")
    end

    test "height-only auto-calculates width preserving aspect ratio" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          height: {3, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # 3 inches = 2743200 EMU
      assert slide_xml =~ ~s(cy="2743200")
      assert slide_xml =~ ~s(cx="2743200")
    end

    test "EMF format detection" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@emf_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.emf")
      assert parts["[Content_Types].xml"] =~ "image/x-emf"
    end

    test "WMF format detection" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@wmf_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/media/image1.wmf")
      assert parts["[Content_Types].xml"] =~ "image/x-wmf"
    end

    test "TIFF without explicit size raises" do
      slide = Podium.Slide.new()

      assert_raise ArgumentError, ~r/explicit :width and :height are required for TIFF/, fn ->
        Podium.add_image(slide, @tiff_binary,
          x: {1, :inches},
          y: {1, :inches}
        )
      end
    end

    test "EMF without explicit size raises" do
      slide = Podium.Slide.new()

      assert_raise ArgumentError, ~r/explicit :width and :height are required for EMF/, fn ->
        Podium.add_image(slide, @emf_binary,
          x: {1, :inches},
          y: {1, :inches}
        )
      end
    end

    test "image masking with ellipse shape" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: :ellipse
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prstGeom prst="ellipse")
      refute slide_xml =~ ~s(prstGeom prst="rect")
    end

    test "image masking defaults to rect" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prstGeom prst="rect")
    end

    test "image masking with raw string preset" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: "star5"
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prstGeom prst="star5")
    end

    test "duplicate images are deduplicated" do
      slide =
        Podium.Slide.new()
        |> Podium.add_image(@png_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )
        |> Podium.add_image(@png_binary,
          x: {5, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

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

  describe "dimensions/1" do
    test "reads a PNG at its native size in EMU" do
      # 1x1 pixels, no pHYs chunk, so the default 72 DPI applies.
      assert Podium.Image.dimensions(@png_binary) == {12_700, 12_700}
    end

    test "reads a JPEG at its native size in EMU" do
      binary = File.read!("test/fixtures/acme.jpg")

      assert {width, height} = Podium.Image.dimensions(binary)
      assert width > 0 and height > 0
      # 1024 x 596 pixels, so the aspect ratio survives the DPI scaling.
      assert_in_delta width / height, 1024 / 596, 0.001
    end

    test "agrees with the size new/2 gives an image with no dimensions" do
      image = Podium.Image.new(@png_binary, x: 0, y: 0)

      assert Podium.Image.dimensions(@png_binary) == {image.width, image.height}
    end

    test "reads a JFIF density rather than the bytes before it" do
      # SOI, then APP0: length, "JFIF\0", version 1.1, unit 1 (dots per inch),
      # 96 x 96, then a baseline SOF0 of 4 x 2 pixels.
      jfif =
        <<0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10>> <>
          "JFIF" <>
          <<0, 0x01, 0x01, 0x01, 0x00, 0x60, 0x00, 0x60, 0x00, 0x00>> <>
          <<0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x02, 0x00, 0x04>> <>
          :binary.copy(<<0>>, 10)

      # 4 x 2 pixels at 96 DPI, so the aspect ratio survives.
      assert Podium.Image.dimensions(jfif) == {38_100, 19_050}
    end

    test "falls back to the default density when FF E0 is not a JFIF segment" do
      # An Exif JPEG: APP1, not APP0. Any FF E0 in it is entropy-coded data.
      exif =
        <<0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x08>> <>
          "Exif" <>
          <<0, 0>> <>
          <<0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x02, 0x00, 0x04>> <>
          <<0xFF, 0xE0, 0x01, 0x01, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07>>

      # 4 x 2 pixels at the default 72 DPI.
      assert Podium.Image.dimensions(exif) == {50_800, 25_400}
    end

    test "raises for formats whose headers are not read" do
      assert_raise ArgumentError, ~r/TIFF/, fn -> Podium.Image.dimensions(@tiff_binary) end
      assert_raise ArgumentError, ~r/EMF/, fn -> Podium.Image.dimensions(@emf_binary) end
      assert_raise ArgumentError, ~r/WMF/, fn -> Podium.Image.dimensions(@wmf_binary) end
    end

    test "raises for data in no recognised format" do
      assert_raise ArgumentError, ~r/unsupported image format/, fn ->
        Podium.Image.dimensions("not an image at all")
      end
    end
  end
end
