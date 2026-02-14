defmodule Podium.Chart.ComboChartTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.{ChartData, ComboChart}
  alias Podium.Test.PptxHelpers

  defp sample_chart_data do
    ChartData.new()
    |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
    |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167])
    |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000])
    |> ChartData.add_series("Margin %", [33, 50, 52, 5])
  end

  describe "ComboChart.new/2 validation" do
    test "rejects fewer than 2 plots" do
      data = sample_chart_data()

      assert_raise ArgumentError, ~r/at least 2 plots/, fn ->
        ComboChart.new(data, [{:column_clustered, series: [0, 1, 2]}])
      end
    end

    test "rejects unsupported chart types" do
      data = sample_chart_data()

      assert_raise ArgumentError, ~r/unsupported chart type/, fn ->
        ComboChart.new(data, [
          {:pie, series: [0]},
          {:line, series: [1, 2]}
        ])
      end

      assert_raise ArgumentError, ~r/unsupported chart type/, fn ->
        ComboChart.new(data, [
          {:doughnut, series: [0]},
          {:line, series: [1, 2]}
        ])
      end

      assert_raise ArgumentError, ~r/unsupported chart type/, fn ->
        ComboChart.new(data, [
          {:radar, series: [0]},
          {:line, series: [1, 2]}
        ])
      end

      assert_raise ArgumentError, ~r/unsupported chart type/, fn ->
        ComboChart.new(data, [
          {:scatter, series: [0]},
          {:line, series: [1, 2]}
        ])
      end

      assert_raise ArgumentError, ~r/unsupported chart type/, fn ->
        ComboChart.new(data, [
          {:bubble, series: [0]},
          {:line, series: [1, 2]}
        ])
      end
    end

    test "rejects overlapping series indices" do
      data = sample_chart_data()

      assert_raise ArgumentError, ~r/overlap/, fn ->
        ComboChart.new(data, [
          {:column_clustered, series: [0, 1]},
          {:line, series: [1, 2]}
        ])
      end
    end

    test "rejects out-of-range series indices" do
      data = sample_chart_data()

      assert_raise ArgumentError, ~r/out of range/, fn ->
        ComboChart.new(data, [
          {:column_clustered, series: [0, 1]},
          {:line, series: [5]}
        ])
      end
    end

    test "rejects mixed bar direction (bar + column)" do
      data = sample_chart_data()

      assert_raise ArgumentError, ~r/cannot mix/, fn ->
        ComboChart.new(data, [
          {:bar_clustered, series: [0]},
          {:column_clustered, series: [1, 2]}
        ])
      end
    end

    test "accepts valid column + line" do
      data = sample_chart_data()

      combo =
        ComboChart.new(data, [
          {:column_clustered, series: [0, 1]},
          {:line_markers, series: [2]}
        ])

      assert length(combo.plots) == 2
    end

    test "accepts valid bar + line" do
      data = sample_chart_data()

      combo =
        ComboChart.new(data, [
          {:bar_clustered, series: [0]},
          {:line, series: [1, 2]}
        ])

      assert length(combo.plots) == 2
    end

    test "accepts area + line" do
      data = sample_chart_data()

      combo =
        ComboChart.new(data, [
          {:area, series: [0, 1]},
          {:line_markers, series: [2]}
        ])

      assert length(combo.plots) == 2
    end
  end

  describe "XML generation" do
    test "produces two chart elements in plotArea" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line_markers, series: [2], secondary_axis: true}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:barChart"
      assert chart_xml =~ "c:lineChart"
      assert chart_xml =~ "c:plotArea"
    end

    test "series idx is global across plots" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line, series: [2]}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      # Series should have global indices 0, 1, 2
      assert chart_xml =~ ~s(<c:idx val="0"/>)
      assert chart_xml =~ ~s(<c:idx val="1"/>)
      assert chart_xml =~ ~s(<c:idx val="2"/>)
    end

    test "primary axes with correct IDs" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line, series: [2]}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      # Both plots reference the combo axis IDs
      assert chart_xml =~ ~s(<c:axId val="10000"/>)
      assert chart_xml =~ ~s(<c:axId val="10001"/>)
      # catAx and valAx present
      assert chart_xml =~ "c:catAx"
      assert chart_xml =~ "c:valAx"
    end

    test "secondary value axis present when requested" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line_markers, series: [2], secondary_axis: true}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches},
          secondary_value_axis: [title: "Margin %", number_format: ~s(0"%")]
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      # Secondary axis ID
      assert chart_xml =~ ~s(<c:axId val="10002"/>)
      # Positioned on right
      assert chart_xml =~ ~s(<c:axPos val="r"/>)
      # Secondary axis title
      assert chart_xml =~ "Margin %"
    end

    test "no secondary axis when not requested" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line, series: [2]}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      refute chart_xml =~ ~s(<c:axId val="10002"/>)
      refute chart_xml =~ ~s(<c:axPos val="r"/>)
    end

    test "title and legend work" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line, series: [2]}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches},
          title: "Revenue vs Margin",
          legend: :bottom
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "Revenue vs Margin"
      assert chart_xml =~ ~s(<c:legendPos val="b"/>)
    end
  end

  describe "integration" do
    test "valid pptx with embedded xlsx" do
      data = sample_chart_data()

      plots = [
        {:column_clustered, series: [0, 1]},
        {:line_markers, series: [2], secondary_axis: true}
      ]

      slide =
        Podium.Slide.new()
        |> Podium.add_combo_chart(data, plots,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches},
          title: "Combo Chart"
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Chart XML exists
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      # Embedded xlsx exists
      assert Map.has_key?(parts, "ppt/embeddings/Microsoft_Excel_Sheet1.xlsx")
      # Chart rels exist
      assert Map.has_key?(parts, "ppt/charts/_rels/chart1.xml.rels")
      # Slide rels reference chart
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "chart1.xml"
      # Content types include chart
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "chart+xml"
    end

    test "existing single-plot chart tests are unaffected" do
      # Create a standard single chart and a combo chart on different slides
      data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [1, 2, 3])
        |> ChartData.add_series("S2", [4, 5, 6])

      slide1 =
        Podium.Slide.new()
        |> Podium.add_chart(:column_clustered, data,
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      combo_data =
        ChartData.new()
        |> ChartData.add_categories(["X", "Y"])
        |> ChartData.add_series("A", [10, 20])
        |> ChartData.add_series("B", [30, 40])

      slide2 =
        Podium.Slide.new()
        |> Podium.add_combo_chart(
          combo_data,
          [
            {:column_clustered, series: [0]},
            {:line, series: [1]}
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide1)
        |> Podium.add_slide(slide2)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Both chart XMLs exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")

      # First chart is standard barChart
      chart1 = parts["ppt/charts/chart1.xml"]
      assert chart1 =~ "c:barChart"
      refute chart1 =~ "c:lineChart"

      # Second chart is combo
      chart2 = parts["ppt/charts/chart2.xml"]
      assert chart2 =~ "c:barChart"
      assert chart2 =~ "c:lineChart"
    end
  end
end
