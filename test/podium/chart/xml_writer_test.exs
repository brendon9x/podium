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
  end
end
