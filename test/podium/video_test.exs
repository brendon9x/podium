defmodule Podium.VideoTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers
  alias Podium.Video

  # Minimal valid PNG (1x1 pixel, RGBA) for poster frame
  @png_binary <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
                0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
                0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
                0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27,
                0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
                0x82>>

  # Fake MP4 binary
  @mp4_binary <<"fakemp4data", 0x00, 0x01, 0x02>>

  describe "Video.new/2" do
    test "creates a video with default poster" do
      video =
        Video.new(@mp4_binary,
          x: {2, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches},
          mime_type: "video/mp4"
        )

      assert video.media_index == nil
      assert video.extension == "mp4"
      assert video.mime_type == "video/mp4"
      assert video.x == round(2 * 914_400)
      assert video.y == round(1 * 914_400)
      assert video.width == round(6 * 914_400)
      assert video.height == round(4 * 914_400)
      assert video.poster_frame.image_index == nil
      assert video.poster_frame.extension == "png"
    end

    test "creates a video with custom poster frame" do
      video =
        Video.new(@mp4_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {3, :inches},
          poster_frame: @png_binary
        )

      assert video.poster_frame.binary == @png_binary
      assert video.poster_frame.extension == "png"
      assert video.poster_frame.image_index == nil
    end

    test "computes SHA1 for deduplication" do
      video =
        Video.new(@mp4_binary,
          x: 0,
          y: 0,
          width: 914_400,
          height: 914_400
        )

      expected_sha1 = :crypto.hash(:sha, @mp4_binary) |> Base.encode16(case: :lower)
      assert video.sha1 == expected_sha1
    end
  end

  describe "detect_extension/1" do
    test "maps common MIME types" do
      assert Video.detect_extension("video/mp4") == "mp4"
      assert Video.detect_extension("video/x-msvideo") == "avi"
      assert Video.detect_extension("video/x-ms-wmv") == "wmv"
      assert Video.detect_extension("video/quicktime") == "mov"
      assert Video.detect_extension("video/webm") == "webm"
      assert Video.detect_extension("video/unknown") == "bin"
    end
  end

  describe "pic_xml/5" do
    test "generates correct XML structure" do
      video =
        Video.new(@mp4_binary,
          x: {2, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches},
          mime_type: "video/mp4"
        )

      xml = Video.pic_xml(video, 5, "rId2", "rId3", "rId4")

      assert xml =~ "p:pic"
      assert xml =~ ~s(id="5")
      assert xml =~ ~s(name="Video 4")
      assert xml =~ ~s(action="ppaction://media")
      assert xml =~ ~s(a:hlinkClick r:id="" action="ppaction://media")
      assert xml =~ ~s(a:videoFile r:link="rId2")
      assert xml =~ ~s(p14:media)
      assert xml =~ ~s(r:embed="rId3")
      assert xml =~ ~s(a:blip r:embed="rId4")
      assert xml =~ ~s(prst="rect")
      assert xml =~ ~s({DAA4B4D4-6D71-4841-9C94-3DE7FCFB9230})
    end
  end

  describe "video_timing_xml/2" do
    test "generates timing element" do
      xml = Video.video_timing_xml(5, 2)

      assert xml =~ "p:video"
      assert xml =~ ~s(vol="80000")
      assert xml =~ ~s(id="2")
      assert xml =~ ~s(spid="5")
      assert xml =~ ~s(delay="indefinite")
    end
  end

  describe "media_partname/1" do
    test "returns correct path" do
      video =
        Video.new(@mp4_binary,
          x: 0,
          y: 0,
          width: 914_400,
          height: 914_400,
          mime_type: "video/mp4"
        )

      video = %{video | media_index: 3}
      assert Video.media_partname(video) == "ppt/media/media3.mp4"
    end
  end

  describe "integration" do
    test "basic video add: generates valid pptx" do
      slide =
        Podium.Slide.new()
        |> Podium.add_movie(@mp4_binary,
          x: {2, :inches},
          y: {1.5, :inches},
          width: {6, :inches},
          height: {4, :inches},
          mime_type: "video/mp4"
        )

      assert length(slide.videos) == 1

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Media file exists
      assert Map.has_key?(parts, "ppt/media/media1.mp4")
      assert parts["ppt/media/media1.mp4"] == @mp4_binary

      # Poster frame exists
      poster_key = Enum.find(Map.keys(parts), &String.starts_with?(&1, "ppt/media/image"))
      assert poster_key

      # Slide XML has video elements
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:pic"
      assert slide_xml =~ "a:videoFile"
      assert slide_xml =~ "p14:media"
      assert slide_xml =~ "ppaction://media"
      assert slide_xml =~ "p:timing"
      assert slide_xml =~ "p:video"

      # Slide rels have video relationships
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "media1.mp4"
      assert slide_rels =~ "relationships/video"
      assert slide_rels =~ "relationships/media"

      # Content types register video extension
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "video/mp4"
    end

    test "SHA1 dedup: same video binary uses one media file" do
      slide = Podium.Slide.new()

      opts = [
        x: {1, :inches},
        y: {1, :inches},
        width: {3, :inches},
        height: {2, :inches},
        mime_type: "video/mp4"
      ]

      slide = Podium.add_movie(slide, @mp4_binary, opts)
      slide = Podium.add_movie(slide, @mp4_binary, Keyword.merge(opts, x: {5, :inches}))

      assert length(slide.videos) == 2
      # Both have same SHA1, so serialization will dedup to one media file
      [v1, v2] = slide.videos
      assert v1.sha1 == v2.sha1
    end

    test "custom poster frame stored correctly" do
      slide =
        Podium.Slide.new()
        |> Podium.add_movie(@mp4_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {3, :inches},
          poster_frame: @png_binary
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Poster frame is stored as image1 (indices assigned during serialization)
      poster_path = "ppt/media/image1.png"
      assert Map.has_key?(parts, poster_path)
      assert parts[poster_path] == @png_binary
    end

    test "multiple videos on one slide" do
      slide = Podium.Slide.new()
      other_binary = <<"other_video_data">>

      slide =
        slide
        |> Podium.add_movie(@mp4_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {3, :inches},
          mime_type: "video/mp4"
        )
        |> Podium.add_movie(other_binary,
          x: {6, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {3, :inches},
          mime_type: "video/mp4"
        )

      assert length(slide.videos) == 2

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      # Multiple video elements in timing
      assert length(String.split(slide_xml, "p:video>")) >= 3
    end

    test "default mime type works" do
      slide =
        Podium.Slide.new()
        |> Podium.add_movie(@mp4_binary,
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {3, :inches}
        )

      [video] = slide.videos
      assert video.mime_type == "video/unknown"
      assert video.extension == "bin"

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/media/media1.bin")
    end
  end
end
