defmodule Podium.Integration.ImageIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"
  @fixtures_dir "test/fixtures"

  describe "image with explicit dimensions and cropping" do
    test "creates image with crop parameters" do
      image_binary = File.read!(Path.join(@fixtures_dir, "acme.jpg"))

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Image Support Demo",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.8, :inches},
          font_size: 28,
          alignment: :center
        )

      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {3.67, :inches},
          y: {1.5, :inches},
          width: {6, :inches},
          height: {4.5, :inches},
          crop: [top: 5000, bottom: 5000]
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "image_with_crop.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify image media file exists
      assert Map.has_key?(parts, "ppt/media/image1.jpeg")

      # Verify slide contains picture shape
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:pic"
      assert slide_xml =~ "Image Support Demo"

      # Verify crop parameters in XML
      assert slide_xml =~ "srcRect"
      assert slide_xml =~ "t=\"5000\""
      assert slide_xml =~ "b=\"5000\""

      # Verify slide rels include image relationship
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "image1.jpeg"

      # Verify content types include image
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "image/jpeg"
    end
  end

  describe "image auto-scale" do
    test "auto-calculates height when only width is specified" do
      image_binary = File.read!(Path.join(@fixtures_dir, "acme.jpg"))

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Image Auto-Scale (native size from PNG header)",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24,
          alignment: :center
        )

      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {2.67, :inches},
          y: {1.5, :inches},
          width: {8, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "image_auto_scale.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify image media file exists
      assert Map.has_key?(parts, "ppt/media/image1.jpeg")

      # Verify slide contains picture shape
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:pic"

      # Verify proper dimensions in slide XML
      assert slide_xml =~ "cx="
      assert slide_xml =~ "cy="
    end
  end

  describe "image masking with shapes" do
    test "creates images masked with ellipse, diamond, and round_rect shapes" do
      image_binary = File.read!(Path.join(@fixtures_dir, "acme.jpg"))

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Tier 1 Feature Showcase",
          x: {0.5, :inches},
          y: {0.2, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 28,
          alignment: :center
        )

      # Image masking — ellipse shape
      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {0.67, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: :ellipse
        )

      # Image masking — diamond shape
      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {5.17, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: :diamond
        )

      # Image masking — rounded rectangle
      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {9.67, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: :round_rect
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "image_masking.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify only one image file exists (deduped)
      image_files =
        parts
        |> Map.keys()
        |> Enum.filter(&(String.contains?(&1, "media") and String.ends_with?(&1, ".jpeg")))

      assert length(image_files) == 1

      # Verify slide contains three picture shapes
      slide_xml = parts["ppt/slides/slide1.xml"]
      pic_count = length(Regex.scan(~r/<p:pic /, slide_xml))
      assert pic_count == 3

      # Verify shape presets are present
      assert slide_xml =~ "ellipse"
      assert slide_xml =~ "diamond"
      assert slide_xml =~ "roundRect"
    end
  end

  describe "picture fill text box" do
    test "creates text box with picture fill" do
      image_binary = File.read!(Path.join(@fixtures_dir, "acme.jpg"))

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Picture Fill Demo",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24,
          alignment: :center
        )

      {prs, slide} =
        Podium.add_picture_fill_text_box(
          prs,
          slide,
          [[{"Picture Fill!", bold: true, font_size: 24, color: "FFFFFF"}]],
          image_binary,
          x: {0.5, :inches},
          y: {4.5, :inches},
          width: {5, :inches},
          height: {2, :inches},
          alignment: :center,
          fill_mode: :stretch
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "picture_fill_text_box.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify image media file exists (picture fill uses different naming)
      image_files =
        parts
        |> Map.keys()
        |> Enum.filter(&(String.contains?(&1, "media") and String.ends_with?(&1, ".jpeg")))

      assert length(image_files) == 1

      # Verify slide contains text box with picture fill
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "txBox=\"1\""
      assert slide_xml =~ "Picture Fill!"
      assert slide_xml =~ "a:blipFill"
      assert slide_xml =~ "a:stretch"
    end
  end

  describe "combined image features" do
    test "creates slide with multiple image features" do
      image_binary = File.read!(Path.join(@fixtures_dir, "acme.jpg"))

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      # Regular image
      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {0.5, :inches},
          y: {0.5, :inches},
          width: {4, :inches},
          height: {3, :inches}
        )

      # Masked image
      {prs, slide} =
        Podium.add_image(prs, slide, image_binary,
          x: {5, :inches},
          y: {0.5, :inches},
          width: {3, :inches},
          height: {3, :inches},
          shape: :ellipse
        )

      # Picture fill text box
      {prs, slide} =
        Podium.add_picture_fill_text_box(
          prs,
          slide,
          [[{"Combined!", bold: true, font_size: 20, color: "FFFFFF"}]],
          image_binary,
          x: {9, :inches},
          y: {0.5, :inches},
          width: {4, :inches},
          height: {3, :inches},
          alignment: :center,
          fill_mode: :stretch
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "image_combined.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify image deduplication (regular images share the same file,
      # but picture fill text box may use a separate copy)
      image_files =
        parts
        |> Map.keys()
        |> Enum.filter(&(String.contains?(&1, "media") and String.ends_with?(&1, ".jpeg")))

      # We expect at most 2 images: one for regular/masked images, one for picture fill
      assert length(image_files) <= 2

      # Verify slide contains picture shapes and text box
      slide_xml = parts["ppt/slides/slide1.xml"]
      pic_count = length(Regex.scan(~r/<p:pic /, slide_xml))
      assert pic_count == 2

      # Verify text box with picture fill
      assert slide_xml =~ "txBox=\"1\""
      assert slide_xml =~ "a:blipFill"
    end
  end
end
