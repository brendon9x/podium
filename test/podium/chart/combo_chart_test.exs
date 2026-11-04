defmodule Podium.Chart.ComboChartTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.{ChartData, ComboChart}
  alias Podium.Test.PptxHelpers

  import SweetXml, only: [sigil_x: 2]

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

  describe "chart text" do
    test "chart-wide text and per-axis tick label fonts" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line_markers, series: [2], secondary_axis: true}
        ])

      xml =
        combo
        |> Podium.Chart.new_combo(
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          text: [font_size: 11, font: "Arial"],
          category_axis: [font_size: 9],
          value_axis: [bold: true],
          secondary_value_axis: [italic: true, color: "888888"]
        )
        |> Podium.Chart.XmlWriter.to_xml()

      [_, after_chart] = String.split(xml, "</c:chart>")
      assert after_chart =~ ~s(<a:defRPr sz="1100"><a:latin typeface="Arial"/></a:defRPr>)

      assert xml =~ ~r{<c:catAx>.*<a:defRPr sz="900"/>.*</c:catAx>}s

      [primary, secondary] = Regex.scan(~r{<c:valAx>.*?</c:valAx>}s, xml) |> List.flatten()
      assert primary =~ ~s(<a:defRPr b="1"/>)

      assert secondary =~
               ~s(<a:defRPr i="1"><a:solidFill><a:srgbClr val="888888"/></a:solidFill></a:defRPr>)
    end

    test "combo titles and the secondary axis title follow :text" do
      xml =
        sample_chart_data()
        |> ComboChart.new([
          {:column_clustered, series: [0, 1]},
          {:line_markers, series: [2], secondary_axis: true}
        ])
        |> Podium.Chart.new_combo(
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          text: [font: "Georgia"],
          title: "Combo",
          secondary_value_axis: [title: "Margin"]
        )
        |> Podium.Chart.XmlWriter.to_xml()

      assert [_, _] = Regex.scan(~r/<a:latin typeface="Georgia"\/><\/a:rPr>/, xml)
    end

    test "combo chart text is 18pt by default" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line, series: [2]}
        ])

      xml =
        combo
        |> Podium.Chart.new_combo(x: 0, y: 0, width: 100, height: 100)
        |> Podium.Chart.XmlWriter.to_xml()

      assert xml =~
               ~s(</c:chart><c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr sz="1800"/>)
    end
  end

  describe "rich-text titles" do
    test "combo chart and secondary axis titles take rich text" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line_markers, series: [2], secondary_axis: true}
        ])

      xml =
        combo
        |> Podium.Chart.new_combo(
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          title: [[{"Revenue", bold: true}, " and margin"]],
          secondary_value_axis: [title: [["Margin ", {"%", bold: true}]]]
        )
        |> Podium.Chart.XmlWriter.to_xml()

      assert xml =~ ~s(<a:rPr lang="en-US" b="1" dirty="0"/><a:t>Revenue</a:t>)
      assert xml =~ ~s(<a:rPr lang="en-US" b="1" dirty="0"/><a:t>%</a:t>)
    end
  end

  describe "fill and line" do
    test "combo charts take background, plot area, legend, axis and gridline formatting" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line_markers, series: [2], secondary_axis: true}
        ])

      xml =
        combo
        |> Podium.Chart.new_combo(
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          background: :none,
          plot_area: [fill: "F2F2F2"],
          legend: [position: :bottom, line: "000000"],
          category_axis: [line: :none, major_gridlines: true],
          value_axis: [major_gridlines: [line: "D9D9D9"]],
          secondary_value_axis: [line: [color: "C00000", width: {1, :pt}]]
        )
        |> Podium.Chart.XmlWriter.to_xml()

      [_, after_chart] = String.split(xml, "</c:chart>")
      assert after_chart =~ ~s(<c:spPr><a:noFill/><a:ln><a:noFill/></a:ln></c:spPr>)

      assert xml =~
               ~s(<c:spPr><a:solidFill><a:srgbClr val="F2F2F2"/></a:solidFill></c:spPr></c:plotArea>)

      assert xml =~ ~r{<c:legend>.*<c:spPr><a:ln>.*</c:legend>}s

      assert xml =~
               ~r{<c:catAx>.*<c:majorGridlines/>.*<c:spPr><a:ln><a:noFill/></a:ln></c:spPr>.*</c:catAx>}s

      [primary, secondary] = Regex.scan(~r{<c:valAx>.*?</c:valAx>}s, xml) |> List.flatten()
      assert primary =~ ~s(<c:majorGridlines><c:spPr><a:ln><a:solidFill><a:srgbClr val="D9D9D9"/>)
      assert secondary =~ ~s(<c:spPr><a:ln w="12700"><a:solidFill><a:srgbClr val="C00000"/>)
    end

    test "an invalid background raises" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line, series: [2]}
        ])

      assert_raise ArgumentError, ~r/:background/, fn ->
        Podium.Chart.new_combo(combo, x: 0, y: 0, width: 1, height: 1, background: :transparent)
      end
    end
  end

  describe "series fill and line" do
    test "combo series take :line, :fill and :invert_if_negative" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("Bars", [10, -5],
          fill: {:pattern, :lt_horz, foreground: "4472C4"},
          line: "000000",
          invert_if_negative: true
        )
        |> ChartData.add_series("Norm", [6, 7], line: :none, marker: [style: :dash])

      xml =
        data
        |> ComboChart.new([{:column_clustered, series: [0]}, {:line_markers, series: [1]}])
        |> Podium.Chart.new_combo(x: 0, y: 0, width: 100, height: 100)
        |> Podium.Chart.XmlWriter.to_xml()

      assert xml =~ ~s(<c:spPr><a:pattFill prst="ltHorz">)
      assert xml =~ ~s(</a:pattFill><a:ln><a:solidFill><a:srgbClr val="000000"/>)
      assert xml =~ ~s(<c:invertIfNegative val="1"/>)
      assert xml =~ ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr><c:marker><c:symbol val="dash"/>)
    end
  end

  describe "manual layout" do
    test "combo plot area, legend and title take a layout" do
      xml =
        sample_chart_data()
        |> ComboChart.new([{:column_clustered, series: [0, 1]}, {:line, series: [2]}])
        |> Podium.Chart.new_combo(
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          title: [text: "T", x: 0.4, y: 0.0],
          legend: [x: 0.85, y: 0.2, w: 0.12, h: 0.4],
          plot_area: [x: 0.05, y: 0.12, w: 0.75, h: 0.75]
        )
        |> Podium.Chart.XmlWriter.to_xml()

      assert xml =~ ~s(<c:plotArea><c:layout><c:manualLayout><c:layoutTarget val="inner"/>)
      assert xml =~ ~s(<c:x val="0.85"/><c:y val="0.2"/><c:w val="0.12"/><c:h val="0.4"/>)
      assert xml =~ ~s(<c:x val="0.4"/><c:y val="0.0"/></c:manualLayout>)
    end

    test "combo layout errors raise" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line, series: [2]}
        ])

      assert_raise ArgumentError, ~r/:plot_area needs all/, fn ->
        Podium.Chart.new_combo(combo,
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          plot_area: [x: 0.1, y: 0.1]
        )
      end
    end
  end

  describe "per-plot options" do
    defp two_bar_combo(plots, opts \\ []) do
      data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [1, 2])
        |> ChartData.add_series("S2", [3, 4])
        |> ChartData.add_series("S3", [5, 6])

      data
      |> ComboChart.new(plots)
      |> Podium.Chart.new_combo([x: 0, y: 0, width: 100, height: 100] ++ opts)
      |> Podium.Chart.XmlWriter.to_xml()
    end

    test "each bar plot takes its own gap width and overlap" do
      xml =
        two_bar_combo([
          {:column_clustered, series: [0], gap_width: 50, overlap: -10},
          {:column_clustered, series: [1], secondary_axis: true, gap_width: 300},
          {:line, series: [2]}
        ])

      [primary, secondary] = Regex.scan(~r{<c:barChart>.*?</c:barChart>}s, xml) |> List.flatten()
      assert primary =~ ~s(<c:gapWidth val="50"/><c:overlap val="-10"/>)
      assert secondary =~ ~s(<c:gapWidth val="300"/>)
      refute secondary =~ "c:overlap"
    end

    test "chart-level options are the default for plots without their own" do
      xml =
        two_bar_combo(
          [
            {:column_clustered, series: [0]},
            {:column_clustered, series: [1], secondary_axis: true, gap_width: 300},
            {:line, series: [2]}
          ],
          gap_width: 80
        )

      [primary, secondary] = Regex.scan(~r{<c:barChart>.*?</c:barChart>}s, xml) |> List.flatten()
      assert primary =~ ~s(<c:gapWidth val="80"/>)
      assert secondary =~ ~s(<c:gapWidth val="300"/>)
      refute xml =~ ~r{<c:lineChart>.*gapWidth.*</c:lineChart>}s
    end

    test "each plot takes its own data labels and vary_by_categories" do
      xml =
        two_bar_combo(
          [
            {:column_clustered,
             series: [0, 1], data_labels: [show: [:value], position: :inside_end]},
            {:line_markers, series: [2], data_labels: [], vary_by_categories: true}
          ],
          data_labels: [show: [:category]]
        )

      [bar] = Regex.scan(~r{<c:barChart>.*?</c:barChart>}s, xml) |> List.flatten()
      [line] = Regex.scan(~r{<c:lineChart>.*?</c:lineChart>}s, xml) |> List.flatten()
      assert bar =~ ~s(<c:dLblPos val="inEnd"/>)
      refute bar =~ ~s(<c:showCatName val="1"/>)
      refute line =~ "<c:dLbls>"
      assert line =~ ~s(<c:varyColors val="1"/>)
    end

    test "chart-level data labels apply to plots without their own" do
      xml =
        two_bar_combo(
          [{:column_clustered, series: [0, 1]}, {:line, series: [2]}],
          data_labels: [:value]
        )

      assert [_, _] = Regex.scan(~r/<c:dLbls>/, xml)
    end

    test "bar-only options on a line plot raise" do
      assert_raise ArgumentError, ~r/:line plot :gap_width applies to bar and column/, fn ->
        two_bar_combo([{:column_clustered, series: [0, 1]}, {:line, series: [2], gap_width: 50}])
      end
    end

    test "a chart-level gap width with no bar plot raises" do
      assert_raise ArgumentError, ~r/chart :gap_width applies to bar and column/, fn ->
        two_bar_combo([{:area, series: [0, 1]}, {:line, series: [2]}], gap_width: 50)
      end
    end

    test "per-plot range errors raise" do
      assert_raise ArgumentError, ~r/:overlap must be an integer between -100 and 100/, fn ->
        two_bar_combo([{:column_clustered, series: [0, 1], overlap: 200}, {:line, series: [2]}])
      end
    end
  end

  describe "data label validation" do
    test "chart-level labels must suit every plot that takes them" do
      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line, series: [2]}
        ])

      assert_raise ArgumentError, ~r/:line plot :data_labels position :outside_end/, fn ->
        Podium.Chart.new_combo(combo,
          x: 0,
          y: 0,
          width: 1,
          height: 1,
          data_labels: [position: :outside_end]
        )
      end

      combo =
        ComboChart.new(sample_chart_data(), [
          {:column_clustered, series: [0, 1]},
          {:line, series: [2], data_labels: [position: :top]}
        ])

      assert Podium.Chart.new_combo(combo,
               x: 0,
               y: 0,
               width: 1,
               height: 1,
               data_labels: [position: :outside_end]
             )
    end

    test "series labels in a combo are checked against their plot" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("Bars", [1, 2], data_labels: [position: :outside_end])
        |> ChartData.add_series("Line", [3, 4], data_labels: [position: :outside_end])

      combo = ComboChart.new(data, [{:column_clustered, series: [0]}, {:line, series: [1]}])

      assert_raise ArgumentError, ~r/series "Line" :data_labels position :outside_end/, fn ->
        Podium.Chart.new_combo(combo, x: 0, y: 0, width: 1, height: 1)
      end
    end

    test "a combo series' point overrides keep its plot's labels" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("Bars", [1, 2], data_labels: %{1 => [bold: true]})
        |> ChartData.add_series("Line", [3, 4])

      xml =
        data
        |> ComboChart.new([
          {:column_clustered, series: [0], data_labels: [position: :inside_end]},
          {:line, series: [1]}
        ])
        |> Podium.Chart.new_combo(x: 0, y: 0, width: 1, height: 1)
        |> Podium.Chart.XmlWriter.to_xml()

      [bar_series | _] = Regex.scan(~r{<c:ser>.*?</c:ser>}s, xml) |> List.flatten()
      assert bar_series =~ ~r{<c:dLbl>.*<c:dLblPos val="inEnd"/>.*</c:dLbl>}s

      assert bar_series =~
               ~r{</c:dLbl>.*<c:dLblPos val="inEnd"/><c:showLegendKey val="0"/><c:showVal val="1"/>}s
    end

    test "combo series take whole-series labels" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("Bars", [1, 2],
          data_labels: [show: [:value], position: :inside_end]
        )
        |> ChartData.add_series("Line", [3, 4])

      xml =
        data
        |> ComboChart.new([{:column_clustered, series: [0]}, {:line, series: [1]}])
        |> Podium.Chart.new_combo(x: 0, y: 0, width: 1, height: 1)
        |> Podium.Chart.XmlWriter.to_xml()

      assert xml =~ ~r{<c:ser>.*<c:dLbls>.*<c:dLblPos val="inEnd"/>.*</c:ser>}s
    end
  end

  describe "schema order" do
    test "combo axes write txPr between spPr and crossAx" do
      data = sample_chart_data()

      combo =
        ComboChart.new(data, [
          {:column_clustered, series: [0, 1]},
          {:line_markers, series: [2], secondary_axis: true}
        ])

      chart =
        Podium.Chart.new_combo(combo,
          x: 0,
          y: 0,
          width: 100,
          height: 100,
          category_axis: [label_rotation: 45, line: "000000"],
          value_axis: [color: "FF0000", line: "000000"],
          secondary_value_axis: [color: "00FF00", line: "000000"]
        )

      elements =
        chart |> Podium.Chart.XmlWriter.to_xml() |> SweetXml.parse() |> SweetXml.xpath(~x"//*"l)

      axes = Enum.filter(elements, &(elem(&1, 1) in [:"c:catAx", :"c:valAx"]))
      assert length(axes) == 3

      for axis <- axes do
        names =
          for {:xmlElement, name, _, _, _, _, _, _, _, _, _, _} <- elem(axis, 8),
              name in [:"c:spPr", :"c:txPr", :"c:crossAx"],
              do: name

        assert names == [:"c:spPr", :"c:txPr", :"c:crossAx"]
      end
    end
  end
end
