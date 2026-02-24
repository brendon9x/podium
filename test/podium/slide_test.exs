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

  describe "percent positioning" do
    test "add_text_box resolves x percent to EMU" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Hello",
          x: {50, :percent},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      [shape] = slide.shapes
      assert shape.x == 6_096_000
    end

    test "add_text_box resolves y percent to EMU" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Hello",
          x: {1, :inches},
          y: {50, :percent},
          width: {4, :inches},
          height: {1, :inches}
        )

      [shape] = slide.shapes
      assert shape.y == 3_429_000
    end

    test "add_text_box resolves width and height percent" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Hello",
          x: {0, :inches},
          y: {0, :inches},
          width: {80, :percent},
          height: {50, :percent}
        )

      [shape] = slide.shapes
      assert shape.width == 9_753_600
      assert shape.height == 3_429_000
    end

    test "mixed percent and non-percent units" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Hello",
          x: {50, :percent},
          y: {1, :inches},
          width: {4, :inches},
          height: {50, :percent}
        )

      [shape] = slide.shapes
      assert shape.x == 6_096_000
      assert shape.y == 914_400
      assert shape.width == Podium.Units.to_emu({4, :inches})
      assert shape.height == 3_429_000
    end

    test "non-percent values pass through unchanged" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Hello",
          x: {2, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      [shape] = slide.shapes
      assert shape.x == 1_828_800
      assert shape.y == 914_400
    end

    test "custom slide dimensions affect percent resolution" do
      custom_width = Podium.Units.to_emu({10, :inches})
      custom_height = Podium.Units.to_emu({7.5, :inches})

      slide =
        Podium.Slide.new(:blank, slide_width: {10, :inches}, slide_height: {7.5, :inches})
        |> Podium.Slide.add_text_box("Hello",
          x: {50, :percent},
          y: {50, :percent},
          width: {4, :inches},
          height: {1, :inches}
        )

      [shape] = slide.shapes
      assert shape.x == round(custom_width / 2)
      assert shape.y == round(custom_height / 2)
    end

    test "add_auto_shape resolves percent position" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_auto_shape(:rectangle,
          x: {25, :percent},
          y: {25, :percent},
          width: {50, :percent},
          height: {50, :percent}
        )

      [shape] = slide.shapes
      assert shape.x == 3_048_000
      assert shape.y == 1_714_500
    end

    test "add_connector resolves percent coordinates" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_connector(
          :straight,
          {10, :percent},
          {20, :percent},
          {90, :percent},
          {80, :percent},
          []
        )

      [conn] = slide.connectors
      assert conn.x == 1_219_200
      assert conn.y == 1_371_600
    end

    test "add_image resolves percent position" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_image(@png_binary,
          x: {10, :percent},
          y: {10, :percent}
        )

      [image] = slide.images
      assert image.x == 1_219_200
      assert image.y == 685_800
    end

    test "add_chart resolves percent position" do
      chart_data =
        Podium.Chart.ChartData.new()
        |> Podium.Chart.ChartData.add_categories(["A"])
        |> Podium.Chart.ChartData.add_series("S", [1])

      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_chart(:column_clustered, chart_data,
          x: {10, :percent},
          y: {20, :percent},
          width: {80, :percent},
          height: {60, :percent}
        )

      [chart] = slide.charts
      assert chart.x == 1_219_200
      assert chart.y == 1_371_600
      assert chart.width == 9_753_600
      assert chart.height == 4_114_800
    end

    test "add_table resolves percent position" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_table(
          [["A", "B"], ["1", "2"]],
          x: {10, :percent},
          y: {20, :percent},
          width: {80, :percent},
          height: {60, :percent}
        )

      [table] = slide.tables
      assert table.x == 1_219_200
      assert table.y == 1_371_600
    end

    test "presentation stamps dimensions onto slide" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Test",
          x: {50, :percent},
          y: {50, :percent},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs =
        Podium.new(slide_width: {10, :inches}, slide_height: {7.5, :inches})
        |> Podium.add_slide(slide)

      [slide] = prs.slides
      assert slide.slide_width == Podium.Units.to_emu({10, :inches})
      assert slide.slide_height == Podium.Units.to_emu({7.5, :inches})
    end

    test "add_video resolves percent position" do
      mp4_binary = <<"fakemp4data", 0x00, 0x01, 0x02>>

      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_video(mp4_binary,
          x: {10, :percent},
          y: {20, :percent},
          width: {80, :percent},
          height: {60, :percent},
          mime_type: "video/mp4"
        )

      [video] = slide.videos
      assert video.x == 1_219_200
      assert video.y == 1_371_600
      assert video.width == 9_753_600
      assert video.height == 4_114_800
    end

    test "add_combo_chart resolves percent position" do
      chart_data =
        Podium.Chart.ChartData.new()
        |> Podium.Chart.ChartData.add_categories(["A", "B"])
        |> Podium.Chart.ChartData.add_series("S1", [1, 2])
        |> Podium.Chart.ChartData.add_series("S2", [3, 4])

      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_combo_chart(
          chart_data,
          [{:column_clustered, series: [0]}, {:line_markers, series: [1]}],
          x: {5, :percent},
          y: {15, :percent},
          width: {90, :percent},
          height: {70, :percent}
        )

      [chart] = slide.charts
      assert chart.x == 609_600
      assert chart.y == 1_028_700
      assert chart.width == 10_972_800
      assert chart.height == 4_800_600
    end

    test "add_picture_fill_text_box resolves percent position" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_picture_fill_text_box(
          "Fill text",
          @png_binary,
          x: {10, :percent},
          y: {20, :percent},
          width: {80, :percent},
          height: {60, :percent}
        )

      [shape] = slide.shapes
      assert shape.x == 1_219_200
      assert shape.y == 1_371_600
      assert shape.width == 9_753_600
      assert shape.height == 4_114_800
    end

    test "percent > 100 extends beyond slide" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Overflow",
          x: {120, :percent},
          y: {0, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      [shape] = slide.shapes
      assert shape.x == 14_630_400
    end

    test "negative percent positions off-slide" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Off-slide",
          x: {-10, :percent},
          y: {-5, :percent},
          width: {4, :inches},
          height: {1, :inches}
        )

      [shape] = slide.shapes
      assert shape.x == -1_219_200
      assert shape.y == -342_900
    end

    test "add_freeform does not resolve percent (uses its own coordinate system)" do
      freeform =
        Podium.Freeform.new({1, :inches}, {1, :inches})
        |> Podium.Freeform.line_to({3, :inches}, {1, :inches})
        |> Podium.Freeform.line_to({2, :inches}, {3, :inches})
        |> Podium.Freeform.close()

      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_freeform(freeform, origin_x: {1, :inches}, origin_y: {1, :inches})

      [shape] = slide.shapes
      # Freeform position is computed from origin + bounding box, not percent-resolved
      assert shape.x > 0
      assert shape.y > 0
    end

    test "percent-positioned elements produce correct XML EMU values" do
      slide =
        Podium.Slide.new()
        |> Podium.Slide.add_text_box("Hello",
          x: {50, :percent},
          y: {50, :percent},
          width: {100, :percent},
          height: {100, :percent}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(x="6096000")
      assert slide_xml =~ ~s(y="3429000")
      assert slide_xml =~ ~s(cx="12192000")
      assert slide_xml =~ ~s(cy="6858000")
    end
  end
end
