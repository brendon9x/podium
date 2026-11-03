defmodule Podium.Chart.XmlWriterTest do
  use ExUnit.Case, async: true

  alias Podium.Chart
  alias Podium.Chart.{BubbleChartData, ChartData, XmlWriter, XyChartData}

  import SweetXml, only: [sigil_x: 2]

  setup do
    chart_data =
      ChartData.new()
      |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
      |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167])
      |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000])

    %{chart_data: chart_data}
  end

  describe "column_clustered" do
    test "generates valid chart XML", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)

      assert xml =~ ~s(<?xml version="1.0")
      assert xml =~ "c:chartSpace"
      assert xml =~ ~s(c:barDir val="col")
      assert xml =~ ~s(c:grouping val="clustered")
      assert xml =~ "c:barChart"
    end

    test "includes series data with cell references", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)

      # Series names reference Excel cells
      assert xml =~ "Sheet1!$B$1"
      assert xml =~ "Sheet1!$C$1"
      assert xml =~ "Revenue"
      assert xml =~ "Expenses"

      # Category references
      assert xml =~ "Sheet1!$A$2:$A$5"
      assert xml =~ "Q1"
      assert xml =~ "Q4"

      # Value references
      assert xml =~ "Sheet1!$B$2:$B$5"
      assert xml =~ "Sheet1!$C$2:$C$5"
      assert xml =~ "1500"
      assert xml =~ "3000"
    end

    test "includes axes", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)

      assert xml =~ "c:catAx"
      assert xml =~ "c:valAx"
    end

    test "includes externalData reference", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)

      assert xml =~ ~s(c:externalData r:id="rId1")
      assert xml =~ ~s(c:autoUpdate val="0")
    end
  end

  describe "column_stacked" do
    test "generates stacked column chart with overlap", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_stacked, chart_data)

      assert xml =~ ~s(c:barDir val="col")
      assert xml =~ ~s(c:grouping val="stacked")
      assert xml =~ ~s(c:overlap val="100")
    end
  end

  describe "bar_stacked" do
    test "generates stacked bar chart with overlap", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:bar_stacked, chart_data)

      assert xml =~ ~s(c:barDir val="bar")
      assert xml =~ ~s(c:grouping val="stacked")
      assert xml =~ ~s(c:overlap val="100")
      # Horizontal bars have category axis on left, value axis on bottom
      assert xml =~ ~s(c:axPos val="l")
      assert xml =~ ~s(c:axPos val="b")
    end
  end

  describe "bar_clustered" do
    test "generates horizontal bar chart XML", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:bar_clustered, chart_data)

      assert xml =~ ~s(c:barDir val="bar")
      assert xml =~ ~s(c:grouping val="clustered")
    end
  end

  describe "line" do
    test "generates line chart XML", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:line, chart_data)

      assert xml =~ "c:lineChart"
      assert xml =~ ~s(c:grouping val="standard")
      assert xml =~ ~s(c:smooth val="0")
      # Line without markers has marker symbol=none
      assert xml =~ ~s(c:symbol val="none")
    end
  end

  describe "line_markers" do
    test "generates line chart XML with markers", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:line_markers, chart_data)

      assert xml =~ "c:lineChart"
      # Should NOT have marker symbol=none
      refute xml =~ ~s(c:symbol val="none")
    end
  end

  describe "pie" do
    test "generates pie chart XML", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:pie, chart_data)

      assert xml =~ "c:pieChart"
      assert xml =~ ~s(c:varyColors val="1")
      # Pie charts don't have axes
      refute xml =~ "c:catAx"
      refute xml =~ "c:valAx"
    end
  end

  describe "chart title" do
    test "no title produces autoTitleDeleted", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)
      assert xml =~ ~s(<c:autoTitleDeleted val="1"/>)
      refute xml =~ "<c:title>"
    end

    test "string title generates title element", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: "Quarterly Revenue"
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:title>"
      assert xml =~ "Quarterly Revenue"
      refute xml =~ "autoTitleDeleted"
    end
  end

  describe "legend" do
    test "no legend by default", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)
      refute xml =~ "<c:legend>"
    end

    test "legend with position", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: :right
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:legendPos val="r"/>)
    end

    test "legend: false produces no legend", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: false
      }

      xml = XmlWriter.to_xml(chart)
      refute xml =~ "<c:legend>"
    end

    test "legend positions", %{chart_data: chart_data} do
      for {pos, expected} <- [left: "l", right: "r", top: "t", bottom: "b"] do
        chart = %Chart{chart_type: :pie, chart_data: chart_data, legend: pos}
        xml = XmlWriter.to_xml(chart)
        assert xml =~ ~s(c:legendPos val="#{expected}")
      end
    end
  end

  describe "data labels" do
    test "no data labels by default", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)
      refute xml =~ "<c:dLbls>"
    end

    test "value labels", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [:value]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ "<c:dLbls>"
      assert xml =~ ~s(<c:showVal val="1"/>)
      assert xml =~ ~s(<c:showCatName val="0"/>)
    end

    test "category and percent labels", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :pie,
        chart_data: chart_data,
        data_labels: [:category, :percent]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:showCatName val="1"/>)
      assert xml =~ ~s(<c:showPercent val="1"/>)
      assert xml =~ ~s(<c:showVal val="0"/>)
    end
  end

  describe "axis customization" do
    test "category axis title", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [title: "Quarter"]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ "Quarter"
    end

    test "value axis with full options", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [
          title: "Revenue ($)",
          number_format: "$#,##0",
          major_gridlines: true,
          min: 0,
          max: 20000,
          major_unit: 5000
        ]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ "Revenue ($)"
      assert xml =~ ~s(formatCode="$#,##0")
      assert xml =~ ~s(<c:min val="0"/>)
      assert xml =~ ~s(<c:max val="20000"/>)
      assert xml =~ ~s(<c:majorUnit val="5000"/>)
      assert xml =~ "<c:majorGridlines/>"
    end

    test "value axis without gridlines", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [major_gridlines: false]
      }

      xml = XmlWriter.to_xml(chart)
      refute xml =~ "<c:majorGridlines/>"
    end
  end

  describe "series formatting" do
    test "series without color has no spPr", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)
      refute xml =~ "c:spPr"
    end

    test "bar series with color gets solidFill" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20], color: "4472C4")

      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:spPr><a:solidFill><a:srgbClr val="4472C4"/></a:solidFill></c:spPr>)
    end

    test "line series with color gets line fill" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20], color: "FF0000")

      chart = %Chart{chart_type: :line, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~
               ~s(<c:spPr><a:ln><a:solidFill><a:srgbClr val="FF0000"/></a:solidFill></a:ln></c:spPr>)
    end

    test "series with pattern fill" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20],
          fill: {:pattern, :dn_diag, foreground: "FF0000", background: "FFFFFF"}
        )

      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<a:pattFill prst="dnDiag">)
      assert xml =~ ~s(<a:fgClr><a:srgbClr val="FF0000"/></a:fgClr>)
      assert xml =~ ~s(<a:bgClr><a:srgbClr val="FFFFFF"/></a:bgClr>)
    end

    test "per-point formatting" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30], point_colors: %{0 => "FF0000", 2 => "00FF00"})

      chart = %Chart{chart_type: :pie, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:dPt>)
      assert xml =~ ~s(<c:idx val="0"/>)
      assert xml =~ ~s(val="FF0000")
      assert xml =~ ~s(<c:idx val="2"/>)
      assert xml =~ ~s(val="00FF00")
    end
  end

  describe "chart title with font formatting" do
    test "keyword list title with font opts", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [text: "Styled Title", font_size: 20, bold: true]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:title>"
      assert xml =~ "Styled Title"
      assert xml =~ ~s(sz="2000")
      assert xml =~ ~s(b="1")
    end
  end

  describe "legend with font formatting" do
    test "keyword list legend with font opts", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: [position: :bottom, font_size: 10, bold: true, color: "333333"]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(c:legendPos val="b")
      assert xml =~ ~s(sz="1000")
      assert xml =~ ~s(b="1")
      assert xml =~ ~s(val="333333")
      assert xml =~ "c:txPr"
    end
  end

  describe "data label positioning and number format" do
    test "keyword data labels with position", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [show: [:value], position: :center]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:dLblPos val="ctr"/>)
      assert xml =~ ~s(<c:showVal val="1"/>)
    end

    test "data labels with number format", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [show: [:value], number_format: "0.00%"]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(formatCode="0.00%")
    end
  end

  describe "axis crossing and label rotation" do
    test "category axis label rotation", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [label_rotation: 45]
      }

      xml = XmlWriter.to_xml(chart)

      # 45 * 60000 = 2700000
      assert xml =~ ~s(rot="2700000")
    end

    test "value axis label rotation", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [label_rotation: -45]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(rot="-2700000")
    end

    test "axis crosses at max", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [crosses: :max]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:crosses val="max"/>)
    end

    test "axis crosses at specific value", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [crosses: 1000]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:crossesAt val="1000"/>)
      # Numeric crossing should not also emit <c:crosses> on the same axis
      refute xml =~ ~s(<c:crosses val="autoZero"/><c:crossesAt)
    end
  end

  describe "axis and data label color" do
    test "category axis with color", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [color: "FFFFFF"]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:catAx>)
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>)
    end

    test "value axis with color", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [color: "CCCCCC"]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:valAx>)
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="CCCCCC"/></a:solidFill>)
    end

    test "data labels with color", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [show: [:value], color: "FFFFFF"]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:dLbls>)
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>)
    end

    test "axis color combined with label_rotation", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [label_rotation: 45, color: "FF0000"]
      }

      xml = XmlWriter.to_xml(chart)
      # Both rotation and color should be present in the txPr
      assert xml =~ ~s(rot="2700000")
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
    end

    test "category axis line", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [line: "AAAAAA"]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~
               ~s(<c:spPr><a:ln><a:solidFill><a:srgbClr val="AAAAAA"/></a:solidFill></a:ln></c:spPr>)
    end

    test "value axis line", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [line: "BBBBBB"]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~
               ~s(<c:spPr><a:ln><a:solidFill><a:srgbClr val="BBBBBB"/></a:solidFill></a:ln></c:spPr>)
    end

    test "major gridlines color", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [major_gridlines: [line: "444444"]]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~
               ~s(<c:majorGridlines><c:spPr><a:ln><a:solidFill><a:srgbClr val="444444"/></a:solidFill></a:ln></c:spPr></c:majorGridlines>)
    end

    test "minor gridlines color", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [minor_gridlines: [line: "555555"]]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~
               ~s(<c:minorGridlines><c:spPr><a:ln><a:solidFill><a:srgbClr val="555555"/></a:solidFill></a:ln></c:spPr></c:minorGridlines>)
    end
  end

  describe "table cell anchor" do
    test "cell with vertical anchor" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [[{"Middle", anchor: :middle}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)
      assert xml =~ ~s(anchor="ctr")
    end
  end

  describe "combined cell merge" do
    test "2x2 merge produces hMerge and vMerge" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [
            [{"Big Cell", col_span: 2, row_span: 2}, :merge, "C"],
            [:merge, :merge, "D"],
            ["E", "F", "G"]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {3, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(gridSpan="2")
      assert xml =~ ~s(rowSpan="2")
      assert xml =~ ~s(hMerge="1")
      assert xml =~ ~s(vMerge="1")
      assert xml =~ ~s(hMerge="1" vMerge="1")
    end
  end

  describe "axis extras" do
    test "minor gridlines on value axis", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [minor_gridlines: true]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ "<c:minorGridlines/>"
    end

    test "minor unit on value axis", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [minor_unit: 500]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:minorUnit val="500"/>)
    end

    test "tick mark atoms", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [major_tick_mark: :cross, minor_tick_mark: :in],
        value_axis: [major_tick_mark: :none, minor_tick_mark: :out]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:majorTickMark val="cross"/>)
      assert xml =~ ~s(<c:minorTickMark val="in"/>)
      assert xml =~ ~s(<c:majorTickMark val="none"/>)
    end

    test "reverse order on category axis", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [reverse: true]
      }

      xml = XmlWriter.to_xml(chart)
      # catAx should have maxMin orientation
      assert xml =~ ~s(<c:orientation val="maxMin"/>)
    end

    test "reverse order on value axis", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [reverse: true]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<c:orientation val="maxMin"/>)
    end

    test "hidden axis", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [visible: false],
        value_axis: [visible: false]
      }

      xml = XmlWriter.to_xml(chart)
      # Both axes should have delete="1"
      [_, _] = Regex.scan(~r/<c:delete val="1"\/>/, xml)
    end

    test "default axes are visible", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)
      # Both axes should have delete="0"
      matches = Regex.scan(~r/<c:delete val="0"\/>/, xml)
      assert length(matches) == 2
    end
  end

  describe "series markers" do
    test "marker with style and size" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30], marker: [style: :diamond, size: 8])

      chart = %Chart{chart_type: :line_markers, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:marker>)
      assert xml =~ ~s(<c:symbol val="diamond"/>)
      assert xml =~ ~s(<c:size val="8"/>)
    end

    test "marker with fill and line" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30],
          marker: [style: :circle, fill: "FF0000", line: "000000"]
        )

      chart = %Chart{chart_type: :line_markers, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:marker>)
      assert xml =~ ~s(<c:symbol val="circle"/>)
      assert xml =~ ~s(<c:spPr>)
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
      assert xml =~ ~s(<a:ln><a:solidFill><a:srgbClr val="000000"/></a:solidFill></a:ln>)
    end

    test "no-marker line chart unchanged" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])

      chart = %Chart{chart_type: :line, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:symbol val="none"/>)
    end

    test "line_markers without series marker has no marker element" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])

      chart = %Chart{chart_type: :line_markers, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      refute xml =~ ~s(<c:symbol val="none"/>)
      refute xml =~ ~s(<c:marker>)
    end
  end

  describe "per-point line format" do
    test "per-point line color via point_formats" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30],
          point_formats: %{0 => [fill: "FF0000", line: "000000"], 2 => [line: "0000FF"]}
        )

      chart = %Chart{chart_type: :pie, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      # Point 0 has both fill and line
      assert xml =~ ~s(<c:dPt>)
      assert xml =~ ~s(<c:idx val="0"/>)
      assert xml =~ ~s(val="FF0000")
      assert xml =~ ~s(<a:ln><a:solidFill><a:srgbClr val="000000"/></a:solidFill></a:ln>)

      # Point 2 has line only
      assert xml =~ ~s(<c:idx val="2"/>)
      assert xml =~ ~s(val="0000FF")
    end

    test "per-point line with width opts" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20],
          point_formats: %{
            0 => [fill: "FF0000", line: [color: "000000", width: {2, :pt}]]
          }
        )

      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<a:ln w="25400">)
      assert xml =~ ~s(val="000000")
    end

    test "point_colors backwards compatibility with point_formats" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30],
          point_colors: %{0 => "FF0000"},
          point_formats: %{1 => [line: "0000FF"]}
        )

      chart = %Chart{chart_type: :pie, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      # Point 0 from point_colors → fill
      assert xml =~ ~s(<c:idx val="0"/>)
      assert xml =~ ~s(val="FF0000")

      # Point 1 from point_formats → line
      assert xml =~ ~s(<c:idx val="1"/>)
      assert xml =~ ~s(val="0000FF")
    end
  end

  describe "date axis type" do
    test "date axis generates dateAx element", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [
          type: :date,
          base_time_unit: :days,
          major_time_unit: :months,
          minor_time_unit: :days
        ]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:dateAx>"
      assert xml =~ "</c:dateAx>"
      assert xml =~ ~s(<c:baseTimeUnit val="days"/>)
      assert xml =~ ~s(<c:majorTimeUnit val="months"/>)
      assert xml =~ ~s(<c:minorTimeUnit val="days"/>)
      refute xml =~ "<c:catAx>"
    end

    test "date axis with units", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [
          type: :date,
          base_time_unit: :months,
          major_unit: 3,
          minor_unit: 1
        ]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:majorUnit val="3"/>)
      assert xml =~ ~s(<c:minorUnit val="1"/>)
    end

    test "default category axis still uses catAx", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_clustered, chart_data)

      assert xml =~ "<c:catAx>"
      refute xml =~ "<c:dateAx>"
    end

    test "explicit type: :category uses catAx", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [type: :category, title: "Quarter"]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:catAx>"
      assert xml =~ "Quarter"
      refute xml =~ "<c:dateAx>"
    end
  end

  describe "per-point data label overrides" do
    test "series-level data labels with per-point overrides" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30],
          data_labels: %{
            0 => [show: [:value], position: :center],
            2 => [show: [:value, :category], number_format: "0%"]
          }
        )

      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      # Should have series-level <c:dLbls> with <c:dLbl> entries
      assert xml =~ "<c:dLbls>"
      assert xml =~ "<c:dLbl>"

      # Point 0 label
      assert xml =~ ~s(<c:idx val="0"/>)
      assert xml =~ ~s(<c:dLblPos val="ctr"/>)

      # Point 2 label with number format and category
      assert xml =~ ~s(<c:idx val="2"/>)
      assert xml =~ ~s(formatCode="0%")
      assert xml =~ ~s(<c:showCatName val="1"/>)
    end

    test "series without data_labels has no series dLbls" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])

      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      # No <c:dLbls> within <c:ser> (there could be a chart-wide one, but not series-level)
      refute xml =~ "<c:dLbl>"
    end

    test "per-point label with show empty hides label" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20], data_labels: %{0 => [show: []]})

      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:dLbl>"
      assert xml =~ ~s(<c:showVal val="0"/>)
      assert xml =~ ~s(<c:showCatName val="0"/>)
    end
  end

  describe "legend font typeface" do
    test "legend with custom font", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: [position: :bottom, font: "Arial"]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(<a:latin typeface="Arial"/>)
    end
  end

  describe "chart text" do
    @full_font [
      font_size: 11,
      bold: false,
      italic: true,
      underline: :double,
      strikethrough: true,
      superscript: true,
      color: "123456",
      font: "Georgia",
      lang: "de-DE"
    ]

    @full_attrs [
      ~s(lang="de-DE"),
      ~s(sz="1100"),
      ~s(b="0"),
      ~s(i="1"),
      ~s(u="dbl"),
      ~s(strike="sngStrike"),
      ~s(baseline="30000"),
      ~s(<a:solidFill><a:srgbClr val="123456"/></a:solidFill>),
      ~s(<a:latin typeface="Georgia"/>)
    ]

    test "every chart text element takes the full run vocabulary" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20],
          data_labels: %{1 => [show: [:value]] ++ @full_font}
        )

      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [text: "Title"] ++ @full_font,
        legend: [position: :bottom] ++ @full_font,
        data_labels: [show: [:value]] ++ @full_font,
        category_axis: [title: [text: "Cat"] ++ @full_font] ++ @full_font,
        value_axis: [title: [text: "Val"] ++ @full_font] ++ @full_font,
        text: @full_font
      }

      xml = XmlWriter.to_xml(chart)

      for {label, fragment} <- [
            title: fragment(xml, "c:title"),
            legend: fragment(xml, "c:legend"),
            chart_labels: xml |> fragments("c:dLbls") |> List.last(),
            point_label: fragment(xml, "c:dLbl"),
            category_axis: fragment(xml, "c:catAx"),
            value_axis: fragment(xml, "c:valAx"),
            chart_space: xml |> fragments("c:txPr") |> List.last()
          ],
          attr <- @full_attrs do
        assert fragment =~ attr, "#{label} is missing #{attr}"
      end

      # Axis title runs carry the formatting on their <a:rPr>
      assert [_, _] =
               Regex.scan(
                 ~r/<a:rPr lang="de-DE" sz="1100" b="0" i="1"/,
                 fragment(xml, "c:plotArea")
               )
    end

    test "chart and axis titles follow :text, keeping their own size", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        text: [font_size: 11, font: "Georgia", color: "404040"],
        title: "Revenue",
        category_axis: [title: [text: "Quarter", color: "C00000"]]
      }

      xml = XmlWriter.to_xml(chart)

      assert fragment(xml, "c:title") =~
               ~s(<a:rPr lang="en-US" dirty="0"><a:solidFill><a:srgbClr val="404040"/></a:solidFill><a:latin typeface="Georgia"/></a:rPr><a:t>Revenue</a:t>)

      cat_title = xml |> fragment("c:catAx") |> then(&fragment(&1, "c:title"))
      assert cat_title =~ ~s(<a:srgbClr val="C00000"/>)
      assert cat_title =~ ~s(<a:latin typeface="Georgia"/>)
      refute xml =~ ~s(sz="1100" dirty="0")
    end

    test "titles are unchanged when :text gives only a size", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        text: [font_size: 11],
        title: "Revenue"
      }

      assert fragment(XmlWriter.to_xml(chart), "c:title") =~
               ~s(<a:rPr lang="en-US" dirty="0"/><a:t>Revenue</a:t>)
    end

    test "chart text is 18pt when :text is absent", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(%Chart{chart_type: :column_clustered, chart_data: chart_data})

      assert xml =~
               ~s(</c:chart><c:txPr><a:bodyPr/><a:lstStyle/><a:p><a:pPr><a:defRPr sz="1800"/></a:pPr>)
    end

    test ":text without :font_size keeps the 18pt default", %{chart_data: chart_data} do
      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data, text: [bold: true]}

      assert xml_after_chart(chart) =~ ~s(<a:defRPr sz="1800" b="1"/>)
    end

    test ":text sets the chart-wide size", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        text: [font_size: 10.5]
      }

      assert xml_after_chart(chart) =~ ~s(<a:defRPr sz="1050"/>)
    end

    test "an element turns off what :text turns on", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        text: [bold: true],
        legend: [bold: false]
      }

      xml = XmlWriter.to_xml(chart)
      assert fragment(xml, "c:legend") =~ ~s(<a:defRPr b="0"/>)
      assert xml_after_chart(chart) =~ ~s(b="1")
    end

    test "a legend styled without a position sits on the right", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: [font_size: 9]
      }

      legend = fragment(XmlWriter.to_xml(chart), "c:legend")
      assert legend =~ ~s(<c:legendPos val="r"/>)
      assert legend =~ ~s(<a:defRPr sz="900"/>)
    end

    test "styled data labels without :show label the values", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [font_size: 9, color: "FFFFFF"]
      }

      labels = fragment(XmlWriter.to_xml(chart), "c:dLbls")
      assert labels =~ ~s(<c:showVal val="1"/>)
      assert labels =~ ~s(<a:defRPr sz="900"><a:solidFill><a:srgbClr val="FFFFFF"/>)
    end

    test "tick labels take rotation and font together", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [label_rotation: -45, font_size: 8, italic: true, font: "Arial"]
      }

      assert fragment(XmlWriter.to_xml(chart), "c:catAx") =~
               ~s(<c:txPr><a:bodyPr rot="-2700000"/><a:lstStyle/><a:p><a:pPr><a:defRPr sz="800" i="1"><a:latin typeface="Arial"/></a:defRPr>)
    end

    test "date axis tick labels take a font", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [type: :date, font_size: 8, underline: true]
      }

      assert fragment(XmlWriter.to_xml(chart), "c:dateAx") =~ ~s(<a:defRPr sz="800" u="sng"/>)
    end

    test "an unstyled axis writes no txPr", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(%Chart{chart_type: :column_clustered, chart_data: chart_data})
      refute fragment(xml, "c:catAx") =~ "c:txPr"
      refute fragment(xml, "c:valAx") =~ "c:txPr"
    end
  end

  describe "rich-text titles" do
    test "a chart title takes runs", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [[{"Revenue", bold: true}, " (USD)"]]
      }

      title = fragment(XmlWriter.to_xml(chart), "c:title")

      assert title =~
               ~s(<a:p><a:r><a:rPr lang="en-US" b="1" dirty="0"/><a:t>Revenue</a:t></a:r>) <>
                 ~s|<a:r><a:rPr lang="en-US" dirty="0"/><a:t> (USD)</a:t></a:r><a:endParaRPr lang="en-US"/></a:p>|
    end

    test "a chart title takes several paragraphs with alignment", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [["Revenue"], {[{"FY2026", italic: true, font_size: 12}], alignment: :right}]
      }

      title = fragment(XmlWriter.to_xml(chart), "c:title")
      assert [_, _] = Regex.scan(~r/<a:p>|<a:p /, title)
      assert title =~ ~s(<a:pPr algn="r"/>)
      assert title =~ ~s(<a:rPr lang="en-US" sz="1200" i="1" dirty="0"/><a:t>FY2026</a:t>)
    end

    test "title font options apply under each run's own", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [
          text: [[{"Revenue", color: "C00000"}, " by quarter"]],
          font_size: 20,
          color: "333333"
        ]
      }

      title = fragment(XmlWriter.to_xml(chart), "c:title")
      assert title =~ ~s(sz="2000" dirty="0"><a:solidFill><a:srgbClr val="C00000"/>)
      assert title =~ ~s(sz="2000" dirty="0"><a:solidFill><a:srgbClr val="333333"/>)
    end

    test "a plain-string title is unchanged", %{chart_data: chart_data} do
      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data, title: "Revenue"}

      assert fragment(XmlWriter.to_xml(chart), "c:title") ==
               ~s(<c:title><c:tx><c:rich><a:bodyPr/><a:lstStyle/><a:p><a:r><a:rPr lang="en-US" dirty="0"/>) <>
                 ~s(<a:t>Revenue</a:t></a:r><a:endParaRPr lang="en-US"/></a:p></c:rich></c:tx>) <>
                 ~s(<c:overlay val="0"/></c:title>)
    end

    test "a line break in a title string becomes <a:br/>", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: "Revenue\nFY2026"
      }

      assert fragment(XmlWriter.to_xml(chart), "c:title") =~ "</a:r><a:br/><a:r>"
    end

    test "axis titles take rich text", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [title: [[{"Quarter", bold: true}, " (FY)"]]],
        value_axis: [title: [text: [["Revenue ", {"$K", italic: true}]], font_size: 10]]
      }

      xml = XmlWriter.to_xml(chart)

      assert fragment(xml, "c:catAx") =~
               ~s(<a:rPr lang="en-US" b="1" dirty="0"/><a:t>Quarter</a:t>)

      assert fragment(xml, "c:valAx") =~
               ~s(<a:rPr lang="en-US" sz="1000" i="1" dirty="0"/><a:t>$K</a:t>)
    end

    test "a rich-text title follows :text under its runs' own options",
         %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        text: [font: "Georgia", color: "404040"],
        title: [[{"Revenue", color: "C00000"}, " by quarter"]]
      }

      title = fragment(XmlWriter.to_xml(chart), "c:title")
      assert title =~ ~s(<a:srgbClr val="C00000"/></a:solidFill><a:latin typeface="Georgia"/>)
      assert title =~ ~s(<a:srgbClr val="404040"/></a:solidFill><a:latin typeface="Georgia"/>)
    end

    test "a hyperlink in a title raises", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [[{"Revenue", hyperlink: "https://example.com"}]]
      }

      assert_raise ArgumentError, ~r/hyperlinks/, fn -> XmlWriter.to_xml(chart) end
    end
  end

  describe "fill and line" do
    @red_fill ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
    @blue_line ~s(<a:ln><a:solidFill><a:srgbClr val="0000FF"/></a:solidFill></a:ln>)

    test "chart area background :none is transparent with no border",
         %{chart_data: chart_data} do
      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data, background: :none}

      assert xml_after_chart(chart) =~
               ~s(<c:spPr><a:noFill/><a:ln><a:noFill/></a:ln></c:spPr><c:txPr>)
    end

    test "chart area background takes a fill, leaving the border",
         %{chart_data: chart_data} do
      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data, background: "FF0000"}
      assert xml_after_chart(chart) =~ ~s(<c:spPr>#{@red_fill}</c:spPr>)
    end

    test "chart area background takes a gradient", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        background: {:gradient, [{0, "FFFFFF"}, {100_000, "D9E2F3"}], angle: 5_400_000}
      }

      assert xml_after_chart(chart) =~ ~s(<c:spPr><a:gradFill)
    end

    test "chart area background takes fill and line", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        background: [fill: "FF0000", line: [color: "0000FF", width: {1, :pt}]]
      }

      assert xml_after_chart(chart) =~
               ~s(<c:spPr>#{@red_fill}<a:ln w="12700"><a:solidFill><a:srgbClr val="0000FF"/>)
    end

    test "chartSpace children keep schema order", %{chart_data: chart_data} do
      chart = %Chart{chart_type: :column_clustered, chart_data: chart_data, background: :none}

      assert child_names(XmlWriter.to_xml(chart), "chartSpace") ==
               ["c:date1904", "c:chart", "c:spPr", "c:txPr", "c:externalData"]
    end

    test "plot area takes fill and line as its last child", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        plot_area: [fill: "FF0000", line: "0000FF"]
      }

      xml = XmlWriter.to_xml(chart)
      assert List.last(child_names(xml, "plotArea")) == "c:spPr"
      assert xml =~ ~s(<c:spPr>#{@red_fill}#{@blue_line}</c:spPr></c:plotArea>)
    end

    test "chart title takes fill and line after overlay", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [text: "T", fill: "FF0000", line: "0000FF"]
      }

      xml = XmlWriter.to_xml(chart)
      assert child_names(xml, "title") == ["c:tx", "c:overlay", "c:spPr"]
      assert fragment(xml, "c:title") =~ ~s(<c:spPr>#{@red_fill}#{@blue_line}</c:spPr>)
    end

    test "axis titles take fill and line", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [title: [text: "V", fill: :none, line: "0000FF"]]
      }

      assert fragment(XmlWriter.to_xml(chart), "c:valAx") =~
               ~s(<c:overlay val="0"/><c:spPr><a:noFill/>#{@blue_line}</c:spPr></c:title>)
    end

    test "legend takes fill and line between overlay and txPr", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: [position: :top, fill: "FF0000", line: "0000FF", font_size: 9]
      }

      xml = XmlWriter.to_xml(chart)
      assert child_names(xml, "legend") == ["c:legendPos", "c:overlay", "c:spPr", "c:txPr"]
    end

    test "axes take a line with width and dash, and :none", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [line: [color: "0000FF", width: {2, :pt}, dash_style: :dash]],
        value_axis: [line: :none]
      }

      xml = XmlWriter.to_xml(chart)

      assert fragment(xml, "c:catAx") =~
               ~s(<c:spPr><a:ln w="25400"><a:solidFill><a:srgbClr val="0000FF"/></a:solidFill><a:prstDash val="dash"/></a:ln></c:spPr>)

      assert fragment(xml, "c:valAx") =~ ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr>)
    end

    test "value axis gridlines take a formatted line", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [
          major_gridlines: [line: [color: "D9D9D9", width: {0.5, :pt}]],
          minor_gridlines: [line: [color: "EEEEEE", dash_style: :sys_dot]]
        ]
      }

      val_ax = fragment(XmlWriter.to_xml(chart), "c:valAx")

      assert val_ax =~
               ~s(<c:majorGridlines><c:spPr><a:ln w="6350"><a:solidFill><a:srgbClr val="D9D9D9"/>)

      assert val_ax =~ ~s(<c:minorGridlines><c:spPr><a:ln><a:solidFill><a:srgbClr val="EEEEEE"/>)
      assert val_ax =~ ~s(<a:prstDash val="sysDot"/>)
    end

    test "category axis gridlines are off by default and can be turned on",
         %{chart_data: chart_data} do
      plain = XmlWriter.to_xml(%Chart{chart_type: :column_clustered, chart_data: chart_data})
      refute fragment(plain, "c:catAx") =~ "Gridlines"

      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [major_gridlines: [line: "D9D9D9"], minor_gridlines: true, title: "Q"]
      }

      names = child_names(XmlWriter.to_xml(chart), "catAx")

      assert Enum.take(names, 7) ==
               ~w(c:axId c:scaling c:delete c:axPos c:majorGridlines c:minorGridlines c:title)
    end

    test "date axis gridlines", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :line,
        chart_data: chart_data,
        category_axis: [type: :date, major_gridlines: true]
      }

      assert fragment(XmlWriter.to_xml(chart), "c:dateAx") =~ "<c:majorGridlines/>"
    end

    test "chart-level data labels take fill and line before txPr", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [show: [:value], fill: "FFFFFF", line: "0000FF", font_size: 9]
      }

      assert Enum.take(child_names(XmlWriter.to_xml(chart), "dLbls"), 3) ==
               ["c:spPr", "c:txPr", "c:showLegendKey"]
    end

    test "per-point data labels take fill and line" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20],
          data_labels: %{1 => [show: [:value], fill: "FF0000", number_format: "0"]}
        )

      xml = XmlWriter.to_xml(%Chart{chart_type: :column_clustered, chart_data: chart_data})
      assert Enum.take(child_names(xml, "dLbl"), 3) == ["c:idx", "c:numFmt", "c:spPr"]
    end

    test "an invalid fill raises", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: [fill: :transparent]
      }

      assert_raise ArgumentError, ~r/fill must be/, fn -> XmlWriter.to_xml(chart) end
    end
  end

  describe "series fill and line" do
    defp one_series(chart_type, opts) do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, -20, 30], opts)

      XmlWriter.to_xml(%Chart{chart_type: chart_type, chart_data: chart_data})
    end

    defp xy_series(chart_type, opts) do
      chart_data = XyChartData.add_series(XyChartData.new(), "S1", [1, 2, 3], [4, 5, 6], opts)
      XmlWriter.to_xml(%Chart{chart_type: chart_type, chart_data: chart_data})
    end

    defp bubble_series(opts) do
      chart_data =
        BubbleChartData.add_series(BubbleChartData.new(), "S1", [1, 2], [3, -4], [5, 6], opts)

      XmlWriter.to_xml(%Chart{chart_type: :bubble, chart_data: chart_data})
    end

    defp series_sp_pr(xml),
      do: xml |> elements("c:ser") |> hd() |> children() |> Enum.count(&(&1 == "c:spPr"))

    test "a plain colour is unchanged on bars and lines" do
      assert one_series(:column_clustered, color: "4472C4") =~
               ~s(</c:tx><c:spPr><a:solidFill><a:srgbClr val="4472C4"/></a:solidFill></c:spPr>)

      assert one_series(:line, color: "4472C4") =~
               ~s(</c:tx><c:spPr><a:ln><a:solidFill><a:srgbClr val="4472C4"/></a:solidFill></a:ln></c:spPr>)
    end

    test "color: :none leaves a bar unfilled and a line undrawn" do
      assert one_series(:column_clustered, color: :none) =~ ~s(<c:spPr><a:noFill/></c:spPr>)
      assert one_series(:line, color: :none) =~ ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr>)
      refute one_series(:line, color: :none) =~ ~s(srgbClr val="none")
    end

    test ":fill takes a gradient on a bar series" do
      xml =
        one_series(:column_clustered, fill: {:gradient, [{0, "FFFFFF"}, {100_000, "4472C4"}], []})

      assert xml =~ ~s(<c:spPr><a:gradFill)
    end

    test ":fill wins over :color for the fill" do
      xml = one_series(:column_clustered, color: "FF0000", fill: "00FF00")
      assert xml =~ ~s(<c:spPr><a:solidFill><a:srgbClr val="00FF00"/></a:solidFill></c:spPr>)
    end

    test "a bar series takes an outline in the same spPr as its fill" do
      xml =
        one_series(:column_clustered, color: :none, line: [color: "4472C4", width: {1.5, :pt}])

      assert xml =~
               ~s(<c:spPr><a:noFill/><a:ln w="19050"><a:solidFill><a:srgbClr val="4472C4"/></a:solidFill></a:ln></c:spPr>)

      assert series_sp_pr(xml) == 1
    end

    test "a line series with line: :none shows markers only" do
      xml = one_series(:line_markers, color: "4472C4", line: :none, marker: [style: :dash])
      assert xml =~ ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr><c:marker><c:symbol val="dash"/>)
      refute xml =~ ~s(<a:srgbClr val="4472C4"/>)
    end

    test "a line series takes width and dash, in place of :color" do
      xml =
        one_series(:line,
          color: "FF0000",
          line: [color: "0000FF", width: {3, :pt}, dash_style: :dash]
        )

      assert xml =~ ~s(<a:ln w="38100"><a:solidFill><a:srgbClr val="0000FF"/>)
      refute xml =~ ~s(val="FF0000")
    end

    test "area, pie and doughnut series take an outline" do
      for type <- [:area, :pie, :doughnut] do
        xml = one_series(type, color: "4472C4", line: "FFFFFF")

        assert xml =~
                 ~s(<c:spPr><a:solidFill><a:srgbClr val="4472C4"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="FFFFFF"/>),
               "#{type}"
      end
    end

    test "a radar line series' colour is its line, a filled radar's its fill" do
      assert one_series(:radar, color: "4472C4") =~
               ~s(<c:spPr><a:ln><a:solidFill><a:srgbClr val="4472C4"/>)

      assert one_series(:radar_markers, color: "4472C4") =~ ~s(<c:spPr><a:ln><a:solidFill>)

      assert one_series(:radar_filled, color: "4472C4") =~
               ~s(<c:spPr><a:solidFill><a:srgbClr val="4472C4"/>)
    end

    test "markers and points take :none" do
      xml =
        one_series(:line_markers,
          marker: [style: :circle, fill: :none, line: "4472C4"],
          point_formats: %{1 => [line: :none]}
        )

      assert xml =~ ~s(<c:marker><c:symbol val="circle"/><c:spPr><a:noFill/><a:ln>)

      assert xml =~
               ~s(<c:dPt><c:idx val="1"/><c:marker><c:spPr><a:ln><a:noFill/></a:ln></c:spPr></c:marker></c:dPt>)
    end

    test "invert_if_negative: true on a bar series and its points" do
      xml = one_series(:bar_clustered, invert_if_negative: true, point_colors: %{1 => "FF0000"})
      assert [_, _] = Regex.scan(~r/<c:invertIfNegative val="1"\/>/, xml)
      refute xml =~ ~s(<c:invertIfNegative val="0"/>)
    end

    test "scatter_lines series take :line and :none" do
      xml = xy_series(:scatter_lines, line: [color: "4472C4", width: {2, :pt}])
      assert xml =~ ~s(<c:spPr><a:ln w="25400"><a:solidFill><a:srgbClr val="4472C4"/>)

      assert xy_series(:scatter_lines, line: :none) =~
               ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr>)
    end

    test "a markers-only scatter series with a colour draws coloured markers and no line" do
      xml = xy_series(:scatter, color: "C00000")
      assert series_sp_pr(xml) == 1
      assert xml =~ ~s(<c:spPr><a:ln><a:noFill/></a:ln></c:spPr><c:marker><c:spPr>)

      assert xml =~
               ~s(<c:marker><c:spPr><a:solidFill><a:srgbClr val="C00000"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="C00000"/>)
    end

    test "a markers-only scatter marker keeps its own fill" do
      xml = xy_series(:scatter, color: "C00000", marker: [style: :square, fill: "FFFFFF"])
      assert xml =~ ~s(<c:symbol val="square"/><c:spPr><a:solidFill><a:srgbClr val="FFFFFF"/>)
    end

    test "scatter series render point colours" do
      xml = xy_series(:scatter_lines, point_colors: %{2 => "FF0000"})
      names = xml |> elements("c:ser") |> hd() |> children()
      assert Enum.take_while(names, &(&1 != "c:xVal")) |> Enum.take(-1) == ["c:dPt"]

      assert xml =~
               ~s(<c:dPt><c:idx val="2"/><c:marker><c:spPr><a:solidFill><a:srgbClr val="FF0000"/></a:solidFill><a:ln><a:solidFill><a:srgbClr val="FF0000"/>)
    end

    test "a point colour on a line, scatter or radar series colours its marker" do
      for {xml, type} <- [
            {one_series(:line_markers, point_colors: %{1 => "70AD47"}), :line_markers},
            {one_series(:radar_markers, point_colors: %{1 => "70AD47"}), :radar_markers},
            {xy_series(:scatter, color: "C00000", point_colors: %{1 => "70AD47"}), :scatter}
          ] do
        point = fragment(xml, "c:dPt")
        assert point =~ ~s(<c:marker><c:spPr><a:solidFill><a:srgbClr val="70AD47"/>), "#{type}"
        refute point =~ "</c:marker><c:spPr>", "#{type}"
      end
    end

    test "a point format sets its marker's style, size, fill and line" do
      xml =
        one_series(:line_markers,
          point_formats: %{
            2 => [fill: "FFFFFF", line: "C00000", marker: [style: :diamond, size: 12]]
          }
        )

      assert fragment(xml, "c:dPt") ==
               ~s(<c:dPt><c:idx val="2"/><c:marker><c:symbol val="diamond"/><c:size val="12"/>) <>
                 ~s(<c:spPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>) <>
                 ~s(<a:ln><a:solidFill><a:srgbClr val="C00000"/></a:solidFill></a:ln></c:spPr></c:marker></c:dPt>)
    end

    test "a point colour on a bar, pie, area or bubble still fills the shape" do
      for type <- [:column_clustered, :pie, :area, :radar_filled] do
        point = one_series(type, point_colors: %{1 => "70AD47"}) |> fragment("c:dPt")
        assert point =~ ~s(<c:spPr><a:solidFill><a:srgbClr val="70AD47"/>), "#{type}"
        refute point =~ "c:marker", "#{type}"
      end
    end

    test "bubble series take fill, line, point colours and invert_if_negative" do
      xml =
        bubble_series(
          fill: "4472C4",
          line: :none,
          invert_if_negative: true,
          point_colors: %{0 => "FF0000"}
        )

      names = xml |> elements("c:ser") |> hd() |> children()

      assert Enum.take(names, 6) ==
               ~w(c:idx c:order c:tx c:spPr c:invertIfNegative c:dPt)

      assert xml =~
               ~s(<c:spPr><a:solidFill><a:srgbClr val="4472C4"/></a:solidFill><a:ln><a:noFill/></a:ln></c:spPr>)

      assert xml =~ ~s(<c:dPt><c:idx val="0"/><c:invertIfNegative val="1"/>)
    end
  end

  describe "manual layout" do
    defp chart_with(chart_data, opts) do
      Chart.new(:column_clustered, chart_data, [x: 0, y: 0, width: 100, height: 100] ++ opts)
    end

    test "plot area layout positions the inner plot area", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(plot_area: [x: 0.1, y: 0.05, w: 0.8, h: 0.75])
        |> XmlWriter.to_xml()

      assert hd(child_names(xml, "plotArea")) == "c:layout"

      assert xml =~
               ~s(<c:plotArea><c:layout><c:manualLayout><c:layoutTarget val="inner"/>) <>
                 ~s(<c:xMode val="edge"/><c:yMode val="edge"/><c:x val="0.1"/><c:y val="0.05"/>) <>
                 ~s(<c:w val="0.8"/><c:h val="0.75"/></c:manualLayout></c:layout>)
    end

    test "plot area layout can target the outer area", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(plot_area: [x: 0, y: 0, w: 1, h: 1, target: :outer])
        |> XmlWriter.to_xml()

      assert xml =~ ~s(<c:layoutTarget val="outer"/>)
    end

    test "plot area layout and fill together", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(plot_area: [x: 0.1, y: 0.1, w: 0.8, h: 0.8, fill: "F2F2F2"])
        |> XmlWriter.to_xml()

      names = child_names(xml, "plotArea")
      assert hd(names) == "c:layout"
      assert List.last(names) == "c:spPr"
    end

    test "legend takes a position and an optional size", %{chart_data: chart_data} do
      xml = chart_data |> chart_with(legend: [x: 0.8, y: 0.1]) |> XmlWriter.to_xml()
      legend = fragment(xml, "c:legend")
      assert legend =~ ~s(<c:x val="0.8"/><c:y val="0.1"/></c:manualLayout>)
      refute legend =~ "layoutTarget"

      xml =
        chart_data |> chart_with(legend: [x: 0.8, y: 0.1, w: 0.15, h: 0.3]) |> XmlWriter.to_xml()

      assert fragment(xml, "c:legend") =~ ~s(<c:w val="0.15"/><c:h val="0.3"/>)
    end

    test "legend children keep schema order", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(
          legend: [position: :right, x: 0.8, y: 0.1, overlay: true, fill: "FFFFFF", bold: true]
        )
        |> XmlWriter.to_xml()

      assert child_names(xml, "legend") ==
               ["c:legendPos", "c:layout", "c:overlay", "c:spPr", "c:txPr"]

      assert fragment(xml, "c:legend") =~ ~s(<c:overlay val="1"/>)
    end

    test "chart title takes a position and overlay", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(title: [text: "T", x: 0.05, y: 0.02, overlay: true, fill: "FFFFFF"])
        |> XmlWriter.to_xml()

      assert child_names(xml, "title") == ["c:tx", "c:layout", "c:overlay", "c:spPr"]
      assert fragment(xml, "c:title") =~ ~s(<c:x val="0.05"/><c:y val="0.02"/></c:manualLayout>)
      assert fragment(xml, "c:title") =~ ~s(<c:overlay val="1"/>)
    end

    test "axis titles take a position", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(value_axis: [title: [text: "Sales", x: 0.0, y: 0.4]])
        |> XmlWriter.to_xml()

      assert fragment(xml, "c:valAx") =~ ~s(<c:x val="0.0"/><c:y val="0.4"/>)
    end

    test "no layout is written by default", %{chart_data: chart_data} do
      xml =
        chart_data
        |> chart_with(
          title: [text: "T"],
          legend: [position: :bottom],
          plot_area: [fill: "FFFFFF"]
        )
        |> XmlWriter.to_xml()

      refute xml =~ "c:layout"
    end

    test "layout errors", %{chart_data: chart_data} do
      for {opts, message} <- [
            {[plot_area: [x: 0.1, y: 0.1]], ~r/:plot_area needs all of :x, :y, :w and :h/},
            {[plot_area: [x: 0.1, y: 0.1, w: 1.2, h: 0.5]], ~r/fractions between 0 and 1/},
            {[plot_area: [x: 0, y: 0, w: 1, h: 1, target: :middle]], ~r/:target must be/},
            {[legend: [x: 0.5]], ~r/:legend needs :x and :y together/},
            {[legend: [x: 0.5, y: 0.5, w: 0.2]], ~r/:legend needs :w and :h together/},
            {[title: [text: "T", x: 0.1, y: 0.1, w: 0.5, h: 0.1]],
             ~r/:title takes :x and :y only/},
            {[value_axis: [title: [text: "V", y: 0.5]]], ~r/:value_axis :title needs :x and :y/},
            {[legend: [x: -0.1, y: 0.5]], ~r/fractions between 0 and 1/}
          ] do
        assert_raise ArgumentError, message, fn -> chart_with(chart_data, opts) end
      end
    end
  end

  describe "schema order" do
    test "chart-level dLbls writes numFmt, txPr and dLblPos before the show flags",
         %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        data_labels: [show: [:value], position: :outside_end, number_format: "0%", font_size: 9]
      }

      assert child_names(XmlWriter.to_xml(chart), "dLbls") == [
               "c:numFmt",
               "c:txPr",
               "c:dLblPos",
               "c:showLegendKey",
               "c:showVal",
               "c:showCatName",
               "c:showSerName",
               "c:showPercent"
             ]
    end

    test "per-point dLbl writes numFmt and dLblPos before the show flags" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20],
          data_labels: %{1 => [show: [:value], position: :center, number_format: "0.0"]}
        )

      xml = XmlWriter.to_xml(%Chart{chart_type: :column_clustered, chart_data: chart_data})

      assert child_names(xml, "dLbl") == [
               "c:idx",
               "c:numFmt",
               "c:dLblPos",
               "c:showLegendKey",
               "c:showVal",
               "c:showCatName",
               "c:showSerName",
               "c:showPercent"
             ]
    end

    test "series dLbls of per-point labels closes with the show flags" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [10, 20, 30],
          data_labels: %{0 => [show: [:value]], 2 => [show: [:value]]}
        )

      xml = XmlWriter.to_xml(%Chart{chart_type: :column_clustered, chart_data: chart_data})

      assert child_names(xml, "dLbls") == [
               "c:dLbl",
               "c:dLbl",
               "c:showLegendKey",
               "c:showVal",
               "c:showCatName",
               "c:showSerName",
               "c:showPercent"
             ]

      # The other points stay unlabelled
      assert xml =~
               ~s(</c:dLbl><c:showLegendKey val="0"/><c:showVal val="0"/>)
    end

    for {axis, local_name, opts} <- [
          {"category", "catAx", [category_axis: [label_rotation: 45, line: "000000"]]},
          {"date", "dateAx", [category_axis: [type: :date, label_rotation: 45, line: "000000"]]},
          {"value", "valAx", [value_axis: [color: "FF0000", line: "000000"]]}
        ] do
      test "#{axis} axis writes txPr between spPr and crossAx", %{chart_data: chart_data} do
        chart =
          struct(%Chart{chart_type: :column_clustered, chart_data: chart_data}, unquote(opts))

        names = child_names(XmlWriter.to_xml(chart), unquote(local_name))

        assert ["c:spPr", "c:txPr", "c:crossAx"] ==
                 Enum.filter(names, &(&1 in ["c:spPr", "c:txPr", "c:crossAx"]))
      end
    end

    test "value axis scaling writes max before min", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        value_axis: [min: 0, max: 100]
      }

      value_scaling = chart |> XmlWriter.to_xml() |> elements("c:scaling") |> List.last()
      assert children(value_scaling) == ["c:orientation", "c:max", "c:min"]
    end

    test "a coloured bar point states invertIfNegative before its spPr" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, -20],
          point_colors: %{1 => "FF0000"},
          point_formats: %{0 => [line: "000000"]}
        )

      xml = XmlWriter.to_xml(%Chart{chart_type: :bar_clustered, chart_data: chart_data})

      assert child_names(xml, "dPt") == ["c:idx", "c:invertIfNegative", "c:spPr"]
      assert xpath_count(xml, "//*[local-name()='dPt']/*[local-name()='invertIfNegative']") == 2
    end

    test "a coloured line point carries no invertIfNegative" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, -20], point_colors: %{1 => "FF0000"})

      xml = XmlWriter.to_xml(%Chart{chart_type: :line_markers, chart_data: chart_data})

      assert child_names(xml, "dPt") == ["c:idx", "c:marker"]
    end
  end

  describe "number formatting" do
    test "fractional font sizes write whole hundredths", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        title: [text: "T", font_size: 10.5],
        data_labels: [show: [:value], font_size: 8.5]
      }

      xml = XmlWriter.to_xml(chart)
      assert xml =~ ~s(sz="1050")
      assert xml =~ ~s(sz="850")
      refute xml =~ ~r/sz="[0-9]+\.[0-9]+"/
    end

    test "fractional label rotation writes whole 60000ths", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        category_axis: [label_rotation: -22.5]
      }

      assert XmlWriter.to_xml(chart) =~ ~s(<a:bodyPr rot="-1350000"/>)
    end

    test "typefaces are escaped", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_clustered,
        chart_data: chart_data,
        legend: [position: :bottom, font: "Fish & Chips"]
      }

      assert XmlWriter.to_xml(chart) =~ ~s(<a:latin typeface="Fish &amp; Chips"/>)
    end
  end

  # The first <tag>...</tag> in xml, and all of them.
  defp fragment(xml, tag), do: xml |> fragments(tag) |> hd()

  defp fragments(xml, tag) do
    ~r{<#{tag}>.*?</#{tag}>}s |> Regex.scan(xml) |> List.flatten()
  end

  defp xml_after_chart(chart) do
    chart |> XmlWriter.to_xml() |> String.split("</c:chart>") |> List.last()
  end

  # Element names of the direct children of the first <c:local_name>.
  defp child_names(xml, local_name), do: xml |> elements("c:" <> local_name) |> hd() |> children()

  defp elements(xml, name) do
    xml
    |> SweetXml.parse()
    |> SweetXml.xpath(~x"//*"l)
    |> Enum.filter(&(to_string(elem(&1, 1)) == name))
  end

  defp children(element) do
    for {:xmlElement, _, _, _, _, _, _, _, _, _, _, _} = child <- elem(element, 8),
        do: to_string(elem(child, 1))
  end

  defp xpath_count(xml, path) do
    xml |> SweetXml.parse() |> SweetXml.xpath(~x"#{path}"l) |> length()
  end
end
