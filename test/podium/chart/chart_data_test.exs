defmodule Podium.Chart.ChartDataTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.ChartData

  describe "new/0" do
    test "creates empty chart data" do
      data = ChartData.new()
      assert data.categories == []
      assert data.series == []
    end
  end

  describe "add_categories/2" do
    test "sets categories" do
      data = ChartData.new() |> ChartData.add_categories(["A", "B", "C"])
      assert data.categories == ["A", "B", "C"]
    end
  end

  describe "add_series/3" do
    test "adds a series with incrementing index" do
      data =
        ChartData.new()
        |> ChartData.add_series("S1", [1, 2])
        |> ChartData.add_series("S2", [3, 4])

      assert length(data.series) == 2
      assert hd(data.series).index == 0
      assert List.last(data.series).index == 1
    end
  end

  describe "cell references" do
    setup do
      data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3"])
        |> ChartData.add_series("Revenue", [100, 200, 300])
        |> ChartData.add_series("Cost", [50, 100, 150])

      %{data: data}
    end

    test "categories_ref/1", %{data: data} do
      assert ChartData.categories_ref(data) == "Sheet1!$A$2:$A$4"
    end

    test "series_name_ref/2", %{data: data} do
      [s1, s2] = data.series
      assert ChartData.series_name_ref(data, s1) == "Sheet1!$B$1"
      assert ChartData.series_name_ref(data, s2) == "Sheet1!$C$1"
    end

    test "series_values_ref/2", %{data: data} do
      [s1, s2] = data.series
      assert ChartData.series_values_ref(data, s1) == "Sheet1!$B$2:$B$4"
      assert ChartData.series_values_ref(data, s2) == "Sheet1!$C$2:$C$4"
    end
  end
end
