defmodule Podium.Chart.XyChartDataTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.XyChartData

  describe "new/0" do
    test "creates empty data" do
      data = XyChartData.new()
      assert data.series == []
    end
  end

  describe "add_series/5" do
    test "adds a series with x and y values" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      assert length(data.series) == 1
      [series] = data.series
      assert series.name == "S1"
      assert series.index == 0
      assert series.x_values == [1, 2, 3]
      assert series.y_values == [10, 20, 30]
    end

    test "adds multiple series with incrementing index" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])
        |> XyChartData.add_series("S2", [3, 4], [30, 40])

      assert length(data.series) == 2
      assert Enum.at(data.series, 0).index == 0
      assert Enum.at(data.series, 1).index == 1
    end

    test "accepts optional color" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20], color: "FF0000")

      assert hd(data.series).color == "FF0000"
    end

    test "raises on mismatched lengths" do
      assert_raise ArgumentError, ~r/same length/, fn ->
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20])
      end
    end

    test "raises on non-numeric x_values" do
      assert_raise ArgumentError, ~r/x_values must all be numbers/, fn ->
        XyChartData.new()
        |> XyChartData.add_series("S1", ["a", "b"], [10, 20])
      end
    end

    test "raises on non-numeric y_values" do
      assert_raise ArgumentError, ~r/y_values must all be numbers/, fn ->
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], ["a", "b"])
      end
    end
  end

  describe "Excel references" do
    test "series_name_ref returns correct cell" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])
        |> XyChartData.add_series("S2", [3, 4], [30, 40])

      # Series 0 -> col A (index*2=0 -> A)
      assert XyChartData.series_name_ref(data, Enum.at(data.series, 0)) == "Sheet1!$A$1"
      # Series 1 -> col C (index*2=2 -> C)
      assert XyChartData.series_name_ref(data, Enum.at(data.series, 1)) == "Sheet1!$C$1"
    end

    test "series_x_values_ref returns correct range" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      assert XyChartData.series_x_values_ref(data, hd(data.series)) == "Sheet1!$A$2:$A$4"
    end

    test "series_y_values_ref returns correct range" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      assert XyChartData.series_y_values_ref(data, hd(data.series)) == "Sheet1!$B$2:$B$4"
    end

    test "second series uses correct columns" do
      data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])
        |> XyChartData.add_series("S2", [3, 4], [30, 40])

      s2 = Enum.at(data.series, 1)
      # Series 1: x -> col C (index=1, *2=2 -> C), y -> col D (index=1, *2+1=3 -> D)
      assert XyChartData.series_x_values_ref(data, s2) == "Sheet1!$C$2:$C$3"
      assert XyChartData.series_y_values_ref(data, s2) == "Sheet1!$D$2:$D$3"
    end
  end
end
