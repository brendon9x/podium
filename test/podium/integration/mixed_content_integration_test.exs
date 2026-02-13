defmodule Podium.Integration.MixedContentIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.ChartData
  alias Podium.Test.PptxHelpers

  @output_dir Path.join([__DIR__, "output"])

  describe "text and chart combinations" do
    test "creates valid pptx with text box and chart on same slide" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"])
        |> ChartData.add_series("Revenue", [12_500, 14_600, 15_156, 18_167], color: "4472C4")
        |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Quarterly Revenue Overview",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.8, :inches},
          font_size: 28,
          alignment: :center
        )

      {prs, slide} =
        Podium.add_chart(prs, slide, :column_clustered, chart_data,
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {12.33, :inches},
          height: {5, :inches},
          title: "Revenue vs Expenses",
          legend: :bottom
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "Quarterly Revenue Overview"
      assert slide_xml =~ ~s(<p:graphicFrame)
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
    end
  end

  describe "hyperlinks" do
    test "creates valid pptx with URL and mailto hyperlinks" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"Visit our website: ", font_size: 18},
              {"example.com",
               font_size: 18,
               color: "0563C1",
               underline: true,
               hyperlink: [url: "https://example.com", tooltip: "Visit Example.com"]}
            ],
            [
              {"Email us at: ", font_size: 18},
              {"support@acme.example.com",
               font_size: 18,
               color: "0563C1",
               underline: true,
               hyperlink: "mailto:support@acme.example.com"}
            ]
          ],
          x: {1, :inches},
          y: {1.5, :inches},
          width: {11.33, :inches},
          height: {2, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "example.com"
      assert slide_xml =~ "support@acme.example.com"

      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "https://example.com"
      assert slide_rels =~ "mailto:support@acme.example.com"
    end
  end

  describe "chart customization" do
    test "creates valid pptx with chart axis customization and gridlines" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
        |> ChartData.add_series("Web", [45, 48, 52, 55, 60, 63], color: "4472C4")
        |> ChartData.add_series("Mobile", [30, 35, 38, 42, 50, 55], color: "ED7D31")

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_chart(prs, slide, :line_markers, chart_data,
          x: {0.5, :inches},
          y: {0.5, :inches},
          width: {12.33, :inches},
          height: {6, :inches},
          title: "Monthly Active Users",
          legend: :top,
          value_axis: [title: "Users (thousands)", major_gridlines: true]
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:lineChart"
      assert chart_xml =~ "c:majorGridlines"
    end

    test "creates valid pptx with chart markers and tick marks" do
      marker_data =
        ChartData.new()
        |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
        |> ChartData.add_series("Series 1", [20, 35, 45, 50, 55, 70],
          color: "4472C4",
          marker: [style: :diamond, size: 10, fill: "4472C4"]
        )

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_chart(prs, slide, :line_markers, marker_data,
          x: {0.5, :inches},
          y: {0.5, :inches},
          width: {12.33, :inches},
          height: {6, :inches},
          title: "Series Markers",
          category_axis: [major_tick_mark: :cross, minor_tick_mark: :in],
          value_axis: [major_gridlines: true, minor_gridlines: true]
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:marker"
      assert chart_xml =~ "c:majorTickMark"
      assert chart_xml =~ "c:minorGridlines"
    end
  end

  describe "per-point chart formatting" do
    test "creates valid pptx with per-point colors and data labels" do
      highlight_data =
        ChartData.new()
        |> ChartData.add_categories(["Acme", "BetaCo", "Gamma", "Delta", "Echo"])
        |> ChartData.add_series("Revenue ($K)", [42, 28, 18, 35, 22],
          point_colors: %{0 => "2E75B6", 3 => "ED7D31"},
          data_labels: %{
            0 => [show: [:value], position: :outside_end],
            3 => [show: [:value], position: :outside_end]
          }
        )

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_chart(prs, slide, :column_clustered, highlight_data,
          x: {0.5, :inches},
          y: {0.5, :inches},
          width: {12.33, :inches},
          height: {6, :inches},
          title: "Per-Point Highlighting"
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:dLbls"
    end
  end

  describe "line fills" do
    test "creates valid pptx with gradient line fill" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Gradient Line",
          x: {1, :inches},
          y: {1.5, :inches},
          width: {5, :inches},
          height: {1.5, :inches},
          font_size: 18,
          alignment: :center,
          line: [
            fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000},
            width: {3, :pt}
          ]
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:gradFill)
    end

    test "creates valid pptx with pattern line fill" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Pattern Line",
          x: {7, :inches},
          y: {1.5, :inches},
          width: {5, :inches},
          height: {1.5, :inches},
          font_size: 18,
          alignment: :center,
          line: [
            fill: {:pattern, :dn_diag, foreground: "003366", background: "FFFFFF"},
            width: {3, :pt}
          ]
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:pattFill)
    end
  end

  describe "date axis charts" do
    test "creates valid pptx with date axis configuration" do
      date_data =
        ChartData.new()
        |> ChartData.add_categories(["2025-01", "2025-04", "2025-07", "2025-10", "2026-01"])
        |> ChartData.add_series("Sales", [120, 145, 190, 210, 250], color: "4472C4")

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_chart(prs, slide, :line_markers, date_data,
          x: {0.5, :inches},
          y: {0.5, :inches},
          width: {12.33, :inches},
          height: {6, :inches},
          title: "Quarterly Sales (Date Axis)",
          category_axis: [
            type: :date,
            title: "Date",
            base_time_unit: :months,
            major_time_unit: :months,
            major_unit: 3
          ],
          value_axis: [title: "Sales ($K)", major_gridlines: true]
        )

      prs = Podium.put_slide(prs, slide)

      output_path = Path.join(@output_dir, "mixed_content_integration.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:dateAx"
      assert chart_xml =~ "c:baseTimeUnit"
    end
  end
end
