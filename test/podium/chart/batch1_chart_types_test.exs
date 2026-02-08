defmodule Podium.Chart.Batch1ChartTypesTest do
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

  describe "column_stacked_100" do
    test "generates percentStacked barChart", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_stacked_100, chart_data)

      assert xml =~ "c:barChart"
      assert xml =~ ~s(c:barDir val="col")
      assert xml =~ ~s(c:grouping val="percentStacked")
      assert xml =~ ~s(c:overlap val="100")
    end

    test "has axes", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:column_stacked_100, chart_data)

      assert xml =~ "c:catAx"
      assert xml =~ "c:valAx"
    end
  end

  describe "bar_stacked_100" do
    test "generates percentStacked horizontal barChart", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:bar_stacked_100, chart_data)

      assert xml =~ "c:barChart"
      assert xml =~ ~s(c:barDir val="bar")
      assert xml =~ ~s(c:grouping val="percentStacked")
      assert xml =~ ~s(c:overlap val="100")
    end

    test "horizontal bars have correct axis positions", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:bar_stacked_100, chart_data)

      assert xml =~ ~s(c:axPos val="l")
      assert xml =~ ~s(c:axPos val="b")
    end
  end

  describe "line_stacked" do
    test "generates stacked lineChart without markers", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:line_stacked, chart_data)

      assert xml =~ "c:lineChart"
      assert xml =~ ~s(c:grouping val="stacked")
      assert xml =~ ~s(c:symbol val="none")
    end
  end

  describe "line_markers_stacked" do
    test "generates stacked lineChart with markers", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:line_markers_stacked, chart_data)

      assert xml =~ "c:lineChart"
      assert xml =~ ~s(c:grouping val="stacked")
      refute xml =~ ~s(c:symbol val="none")
    end
  end

  describe "line_stacked_100" do
    test "generates percentStacked lineChart", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:line_stacked_100, chart_data)

      assert xml =~ "c:lineChart"
      assert xml =~ ~s(c:grouping val="percentStacked")
      assert xml =~ ~s(c:symbol val="none")
    end
  end

  describe "line_markers_stacked_100" do
    test "generates percentStacked lineChart with markers", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:line_markers_stacked_100, chart_data)

      assert xml =~ "c:lineChart"
      assert xml =~ ~s(c:grouping val="percentStacked")
      refute xml =~ ~s(c:symbol val="none")
    end
  end

  describe "pie_exploded" do
    test "generates pieChart with explosion", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:pie_exploded, chart_data)

      assert xml =~ "c:pieChart"
      assert xml =~ ~s(<c:explosion val="25"/>)
      assert xml =~ ~s(c:varyColors val="1")
    end

    test "has no axes", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:pie_exploded, chart_data)

      refute xml =~ "c:catAx"
      refute xml =~ "c:valAx"
    end

    test "does not emit date1904", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:pie_exploded, chart_data)

      refute xml =~ "c:date1904"
    end
  end

  describe "integration with Chart struct" do
    test "pie_exploded with title and legend", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :pie_exploded,
        chart_data: chart_data,
        title: "Exploded Pie",
        legend: :right
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ "Exploded Pie"
      assert xml =~ ~s(c:legendPos val="r")
      assert xml =~ ~s(<c:explosion val="25"/>)
    end

    test "column_stacked_100 with data labels", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :column_stacked_100,
        chart_data: chart_data,
        data_labels: [:value, :percent]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:showVal val="1"/>)
      assert xml =~ ~s(<c:showPercent val="1"/>)
    end
  end
end
