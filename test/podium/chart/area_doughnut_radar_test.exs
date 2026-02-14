defmodule Podium.Chart.AreaDoughnutRadarTest do
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

  # -- Area charts --

  describe "area" do
    test "generates areaChart with standard grouping", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:area, chart_data)

      assert xml =~ "<c:areaChart>"
      assert xml =~ ~s(c:grouping val="standard")
      assert xml =~ ~s(c:varyColors val="0")
    end

    test "has axes", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:area, chart_data)

      assert xml =~ "c:catAx"
      assert xml =~ "c:valAx"
    end

    test "emits date1904", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:area, chart_data)

      assert xml =~ ~s(<c:date1904 val="0"/>)
    end
  end

  describe "area_stacked" do
    test "generates stacked areaChart", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:area_stacked, chart_data)

      assert xml =~ "<c:areaChart>"
      assert xml =~ ~s(c:grouping val="stacked")
    end
  end

  describe "area_stacked_100" do
    test "generates percentStacked areaChart", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:area_stacked_100, chart_data)

      assert xml =~ "<c:areaChart>"
      assert xml =~ ~s(c:grouping val="percentStacked")
    end
  end

  # -- Doughnut charts --

  describe "doughnut" do
    test "generates doughnutChart with holeSize", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:doughnut, chart_data)

      assert xml =~ "<c:doughnutChart>"
      assert xml =~ ~s(<c:holeSize val="50"/>)
      assert xml =~ ~s(<c:firstSliceAng val="0"/>)
      assert xml =~ ~s(c:varyColors val="1")
    end

    test "has no axes", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:doughnut, chart_data)

      refute xml =~ "c:catAx"
      refute xml =~ "c:valAx"
    end

    test "does not emit date1904", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:doughnut, chart_data)

      refute xml =~ "c:date1904"
    end

    test "no explosion for standard doughnut", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:doughnut, chart_data)

      refute xml =~ "c:explosion"
    end
  end

  describe "doughnut_exploded" do
    test "generates doughnutChart with explosion", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:doughnut_exploded, chart_data)

      assert xml =~ "<c:doughnutChart>"
      assert xml =~ ~s(<c:explosion val="25"/>)
      assert xml =~ ~s(<c:holeSize val="50"/>)
    end
  end

  # -- Radar charts --

  describe "radar" do
    test "generates radarChart with marker style and hidden markers", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:radar, chart_data)

      assert xml =~ "<c:radarChart>"
      assert xml =~ ~s(<c:radarStyle val="marker"/>)
      assert xml =~ ~s(c:varyColors val="0")
      # hide_marker: true means markers hidden
      assert xml =~ ~s(<c:marker><c:symbol val="none"/></c:marker>)
    end

    test "has axes", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:radar, chart_data)

      assert xml =~ "c:catAx"
      assert xml =~ "c:valAx"
    end

    test "has smooth element", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:radar, chart_data)

      assert xml =~ ~s(<c:smooth val="0"/>)
    end
  end

  describe "radar_filled" do
    test "generates radarChart with filled style", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:radar_filled, chart_data)

      assert xml =~ "<c:radarChart>"
      assert xml =~ ~s(<c:radarStyle val="filled"/>)
      # hide_marker: false, no explicit marker
      refute xml =~ ~s(<c:symbol val="none"/>)
    end
  end

  describe "radar_markers" do
    test "generates radarChart with marker style and visible markers", %{chart_data: chart_data} do
      xml = XmlWriter.to_xml(:radar_markers, chart_data)

      assert xml =~ "<c:radarChart>"
      assert xml =~ ~s(<c:radarStyle val="marker"/>)
      # hide_marker: false, no explicit marker
      refute xml =~ ~s(<c:symbol val="none"/>)
    end
  end

  # -- Integration --

  describe "area chart integration" do
    test "area chart with title and axes options", %{chart_data: chart_data} do
      chart = %Chart{
        chart_type: :area,
        chart_data: chart_data,
        title: "Area Chart",
        legend: :bottom,
        category_axis: [title: "Quarter"],
        value_axis: [title: "Amount"]
      }

      xml = XmlWriter.to_xml(chart)

      assert xml =~ "Area Chart"
      assert xml =~ "Quarter"
      assert xml =~ "Amount"
      assert xml =~ ~s(c:legendPos val="b")
    end
  end

  describe "doughnut chart integration" do
    test "full pptx with doughnut chart" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B", "C"])
        |> ChartData.add_series("S1", [30, 50, 20])

      slide =
        Podium.Slide.new()
        |> Podium.add_chart(:doughnut, chart_data,
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = Podium.Test.PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:doughnutChart"
      assert chart_xml =~ ~s(c:holeSize val="50")
    end
  end
end
