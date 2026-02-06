defmodule Podium.Chart.XmlWriterTest do
  use ExUnit.Case, async: true

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
end
