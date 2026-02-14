defmodule Podium.Integration.ChartGalleryTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.{BubbleChartData, ChartData, XyChartData}
  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"

  setup_all do
    File.mkdir_p!(@output_dir)
    :ok
  end

  describe "stacked 100% charts" do
    test "creates column_stacked_100, bar_stacked_100, line_stacked_100, line_markers_stacked_100" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Product A", [20, 35, 30, 35], color: "4472C4")
        |> ChartData.add_series("Product B", [25, 25, 35, 25], color: "ED7D31")
        |> ChartData.add_series("Product C", [55, 40, 35, 40], color: "A5A5A5")

      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(slide, "Stacked 100% Charts",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24
        )

      slide =
        Podium.add_chart(slide, :column_stacked_100, chart_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :bar_stacked_100, chart_data,
          x: {6.9, :inches},
          y: {1.2, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :line_stacked_100, chart_data,
          x: {0.5, :inches},
          y: {4.3, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :line_markers_stacked_100, chart_data,
          x: {6.9, :inches},
          y: {4.3, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "chart_gallery_stacked_100.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all 4 charts exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/charts/chart3.xml")
      assert Map.has_key?(parts, "ppt/charts/chart4.xml")

      # Verify chart types
      assert parts["ppt/charts/chart1.xml"] =~ "c:barChart"
      assert parts["ppt/charts/chart1.xml"] =~ ~s(c:grouping val="percentStacked")
      assert parts["ppt/charts/chart2.xml"] =~ "c:barChart"
      assert parts["ppt/charts/chart2.xml"] =~ ~s(c:grouping val="percentStacked")
      assert parts["ppt/charts/chart3.xml"] =~ "c:lineChart"
      assert parts["ppt/charts/chart3.xml"] =~ ~s(c:grouping val="percentStacked")
      assert parts["ppt/charts/chart4.xml"] =~ "c:lineChart"
      assert parts["ppt/charts/chart4.xml"] =~ ~s(c:grouping val="percentStacked")

      # Verify series data
      assert parts["ppt/charts/chart1.xml"] =~ "Product A"
      assert parts["ppt/charts/chart1.xml"] =~ "Product B"
      assert parts["ppt/charts/chart1.xml"] =~ "Product C"
    end
  end

  describe "area charts" do
    test "creates area, area_stacked, and area_stacked_100" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Product A", [20, 35, 30, 35], color: "4472C4")
        |> ChartData.add_series("Product B", [25, 25, 35, 25], color: "ED7D31")
        |> ChartData.add_series("Product C", [55, 40, 35, 40], color: "A5A5A5")

      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(slide, "Area Charts",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24
        )

      slide =
        Podium.add_chart(slide, :area, chart_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :area_stacked, chart_data,
          x: {4.78, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :area_stacked_100, chart_data,
          x: {9.05, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "chart_gallery_area.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all 3 charts exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/charts/chart3.xml")

      # Verify chart types
      assert parts["ppt/charts/chart1.xml"] =~ "c:areaChart"
      assert parts["ppt/charts/chart1.xml"] =~ ~s(c:grouping val="standard")
      assert parts["ppt/charts/chart2.xml"] =~ "c:areaChart"
      assert parts["ppt/charts/chart2.xml"] =~ ~s(c:grouping val="stacked")
      assert parts["ppt/charts/chart3.xml"] =~ "c:areaChart"
      assert parts["ppt/charts/chart3.xml"] =~ ~s(c:grouping val="percentStacked")
    end
  end

  describe "pie and doughnut charts" do
    test "creates pie_exploded, doughnut, and doughnut_exploded" do
      pie_data =
        ChartData.new()
        |> ChartData.add_categories(["Apples", "Bananas", "Cherries", "Dates"])
        |> ChartData.add_series("Fruit", [35, 25, 20, 20])

      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(slide, "Pie Exploded & Doughnut Charts",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24
        )

      slide =
        Podium.add_chart(slide, :pie_exploded, pie_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :doughnut, pie_data,
          x: {4.78, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :doughnut_exploded, pie_data,
          x: {9.05, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "chart_gallery_pie_doughnut.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all 3 charts exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/charts/chart3.xml")

      # Verify chart types
      assert parts["ppt/charts/chart1.xml"] =~ "c:pieChart"
      assert parts["ppt/charts/chart2.xml"] =~ "c:doughnutChart"
      assert parts["ppt/charts/chart3.xml"] =~ "c:doughnutChart"

      # Verify categories
      assert parts["ppt/charts/chart1.xml"] =~ "Apples"
      assert parts["ppt/charts/chart1.xml"] =~ "Bananas"
    end
  end

  describe "line stacked and radar charts" do
    test "creates line_stacked, line_markers_stacked, and radar variants" do
      line_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Product A", [20, 35, 30, 35], color: "4472C4")
        |> ChartData.add_series("Product B", [25, 25, 35, 25], color: "ED7D31")
        |> ChartData.add_series("Product C", [55, 40, 35, 40], color: "A5A5A5")

      radar_data =
        ChartData.new()
        |> ChartData.add_categories(["Speed", "Power", "Range", "Durability", "Precision"])
        |> ChartData.add_series("Model A", [80, 90, 70, 85, 75], color: "4472C4")
        |> ChartData.add_series("Model B", [70, 65, 95, 70, 90], color: "ED7D31")

      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(slide, "Line Stacked & Radar Charts",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24
        )

      slide =
        Podium.add_chart(slide, :line_stacked, line_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :line_markers_stacked, line_data,
          x: {6.9, :inches},
          y: {1.2, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :radar, radar_data,
          x: {0.5, :inches},
          y: {4.3, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :radar_filled, radar_data,
          x: {4.78, :inches},
          y: {4.3, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :radar_markers, radar_data,
          x: {9.05, :inches},
          y: {4.3, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "chart_gallery_line_radar.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all 5 charts exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/charts/chart3.xml")
      assert Map.has_key?(parts, "ppt/charts/chart4.xml")
      assert Map.has_key?(parts, "ppt/charts/chart5.xml")

      # Verify line charts
      assert parts["ppt/charts/chart1.xml"] =~ "c:lineChart"
      assert parts["ppt/charts/chart1.xml"] =~ ~s(c:grouping val="stacked")
      assert parts["ppt/charts/chart2.xml"] =~ "c:lineChart"
      assert parts["ppt/charts/chart2.xml"] =~ ~s(c:grouping val="stacked")

      # Verify radar charts
      assert parts["ppt/charts/chart3.xml"] =~ "c:radarChart"
      assert parts["ppt/charts/chart3.xml"] =~ ~s(c:radarStyle val="marker")
      assert parts["ppt/charts/chart4.xml"] =~ "c:radarChart"
      assert parts["ppt/charts/chart4.xml"] =~ ~s(c:radarStyle val="filled")
      assert parts["ppt/charts/chart5.xml"] =~ "c:radarChart"
      assert parts["ppt/charts/chart5.xml"] =~ ~s(c:radarStyle val="marker")
    end
  end

  describe "scatter charts" do
    test "creates scatter variants" do
      # Use non-monotonic X values to clearly demonstrate XY scatter chart behavior
      # (both axes are value axes, points positioned by coordinates, not categories)
      # X values are deliberately out of order to show scatter nature
      xy_data =
        XyChartData.new()
        |> XyChartData.add_series(
          "Series 1",
          [0.7, 3.2, 1.8, 4.5, 2.6],
          [2.3, 4.1, 3.7, 5.2, 4.8],
          color: "4472C4"
        )
        |> XyChartData.add_series(
          "Series 2",
          [1.2, 4.2, 0.5, 3.5, 2.8],
          [1.5, 3.2, 2.8, 4.5, 3.9],
          color: "ED7D31"
        )

      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(slide, "Scatter Charts",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24
        )

      slide =
        Podium.add_chart(slide, :scatter, xy_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :scatter_lines, xy_data,
          x: {6.9, :inches},
          y: {1.2, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :scatter_lines_no_markers, xy_data,
          x: {0.5, :inches},
          y: {4.3, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :scatter_smooth, xy_data,
          x: {6.9, :inches},
          y: {4.3, :inches},
          width: {5.9, :inches},
          height: {3, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "chart_gallery_scatter.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all 4 charts exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/charts/chart3.xml")
      assert Map.has_key?(parts, "ppt/charts/chart4.xml")

      # Verify chart types
      assert parts["ppt/charts/chart1.xml"] =~ "c:scatterChart"
      assert parts["ppt/charts/chart2.xml"] =~ "c:scatterChart"
      assert parts["ppt/charts/chart3.xml"] =~ "c:scatterChart"
      assert parts["ppt/charts/chart4.xml"] =~ "c:scatterChart"

      # Verify series
      assert parts["ppt/charts/chart1.xml"] =~ "Series 1"
      assert parts["ppt/charts/chart1.xml"] =~ "Series 2"
    end
  end

  describe "scatter smooth and bubble charts" do
    test "creates scatter_smooth_no_markers, bubble, and bubble_3d" do
      # Use non-monotonic X values for scatter charts
      xy_data =
        XyChartData.new()
        |> XyChartData.add_series(
          "Series 1",
          [0.7, 3.2, 1.8, 4.5, 2.6],
          [2.3, 4.1, 3.7, 5.2, 4.8],
          color: "4472C4"
        )
        |> XyChartData.add_series(
          "Series 2",
          [1.2, 4.2, 0.5, 3.5, 2.8],
          [1.5, 3.2, 2.8, 4.5, 3.9],
          color: "ED7D31"
        )

      bubble_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("Region A", [1, 3, 5, 7], [10, 25, 15, 30], [5, 12, 8, 15],
          color: "4472C4"
        )
        |> BubbleChartData.add_series("Region B", [2, 4, 6, 8], [20, 15, 30, 10], [10, 6, 14, 8],
          color: "ED7D31"
        )

      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(slide, "Scatter Smooth & Bubble Charts",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24
        )

      slide =
        Podium.add_chart(slide, :scatter_smooth_no_markers, xy_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :bubble, bubble_data,
          x: {4.78, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      slide =
        Podium.add_chart(slide, :bubble_3d, bubble_data,
          x: {9.05, :inches},
          y: {1.2, :inches},
          width: {3.78, :inches},
          height: {3, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "chart_gallery_scatter_bubble.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all 3 charts exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/charts/chart3.xml")

      # Verify chart types
      assert parts["ppt/charts/chart1.xml"] =~ "c:scatterChart"
      assert parts["ppt/charts/chart2.xml"] =~ "c:bubbleChart"
      assert parts["ppt/charts/chart3.xml"] =~ "c:bubbleChart"

      # Verify bubble series
      assert parts["ppt/charts/chart2.xml"] =~ "Region A"
      assert parts["ppt/charts/chart2.xml"] =~ "Region B"
    end
  end
end
