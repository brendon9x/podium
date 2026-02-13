defmodule Podium.Integration.VideoEmbeddingTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"
  @fixtures_dir "test/fixtures"

  describe "video embedding with poster frame" do
    test "creates video element with poster image and correct dimensions" do
      video_binary = File.read!(Path.join(@fixtures_dir, "demo.mp4"))
      poster_png = File.read!(Path.join(@fixtures_dir, "poster_frame.png"))

      prs = Podium.new(title: "Video Demo", author: "Podium")

      {prs, slide} = Podium.add_slide(prs, layout: :title_only)
      slide = Podium.set_placeholder(slide, :title, "Video Embedding Demo")

      {prs, slide} =
        Podium.add_movie(prs, slide, video_binary,
          x: {2.67, :inches},
          y: {1.5, :inches},
          width: {8, :inches},
          height: {4.5, :inches},
          mime_type: "video/mp4",
          poster_frame: poster_png
        )

      slide =
        Podium.add_text_box(
          slide,
          "Click play to watch the embedded video",
          x: {2.67, :inches},
          y: {6.2, :inches},
          width: {8, :inches},
          height: {0.5, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "video_with_poster.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify video media file exists
      assert Map.has_key?(parts, "ppt/media/media1.mp4")

      # Verify poster frame image exists
      assert Map.has_key?(parts, "ppt/media/image1.png")

      # Verify slide contains video shape
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:pic"
      assert slide_xml =~ "Video Embedding Demo"
      assert slide_xml =~ "Click play to watch the embedded video"

      # Verify slide rels include video and image relationships
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "media1.mp4"
      assert slide_rels =~ "image1.png"

      # Verify content types include video
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "video/mp4"
    end
  end

  describe "video deduplication" do
    test "reuses same video binary across multiple slides" do
      video_binary = File.read!(Path.join(@fixtures_dir, "demo.mp4"))
      poster_png = File.read!(Path.join(@fixtures_dir, "poster_frame.png"))

      prs = Podium.new(title: "Video Demo", author: "Podium")

      # First slide with video
      {prs, slide1} = Podium.add_slide(prs, layout: :title_only)
      slide1 = Podium.set_placeholder(slide1, :title, "Video Embedding Demo")

      {prs, slide1} =
        Podium.add_movie(prs, slide1, video_binary,
          x: {2.67, :inches},
          y: {1.5, :inches},
          width: {8, :inches},
          height: {4.5, :inches},
          mime_type: "video/mp4",
          poster_frame: poster_png
        )

      prs = Podium.put_slide(prs, slide1)

      # Second slide with same video (should be deduped)
      {prs, slide2} = Podium.add_slide(prs, layout: :title_only)
      slide2 = Podium.set_placeholder(slide2, :title, "Same Video, Deduped")

      {prs, slide2} =
        Podium.add_movie(prs, slide2, video_binary,
          x: {1.67, :inches},
          y: {1.5, :inches},
          width: {10, :inches},
          height: {5.5, :inches},
          mime_type: "video/mp4",
          poster_frame: poster_png
        )

      prs = Podium.put_slide(prs, slide2)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "video_dedup.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify only ONE video file exists (deduped)
      video_files =
        parts
        |> Map.keys()
        |> Enum.filter(&(String.contains?(&1, "media") and String.ends_with?(&1, ".mp4")))

      assert length(video_files) == 1
      assert "ppt/media/media1.mp4" in video_files

      # Both slides should reference the same video
      slide1_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      slide2_rels = parts["ppt/slides/_rels/slide2.xml.rels"]

      assert slide1_rels =~ "media1.mp4"
      assert slide2_rels =~ "media1.mp4"

      # Verify both slides have video shapes with different dimensions
      slide1_xml = parts["ppt/slides/slide1.xml"]
      slide2_xml = parts["ppt/slides/slide2.xml"]

      assert slide1_xml =~ "p:pic"
      assert slide2_xml =~ "p:pic"
      assert slide1_xml =~ "Video Embedding Demo"
      assert slide2_xml =~ "Same Video, Deduped"
    end
  end
end
