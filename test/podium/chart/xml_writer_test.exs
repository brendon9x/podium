defmodule Podium.Chart.XmlWriterTest do
  use ExUnit.Case, async: true

  alias Podium.Chart
  alias Podium.Chart.{ChartData, XmlWriter}

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
          pattern: [type: :dn_diag, foreground: "FF0000", background: "FFFFFF"]
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
end
