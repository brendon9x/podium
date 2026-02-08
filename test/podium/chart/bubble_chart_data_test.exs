defmodule Podium.Chart.BubbleChartDataTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.BubbleChartData

  describe "new/0" do
    test "creates empty data" do
      data = BubbleChartData.new()
      assert data.series == []
    end
  end

  describe "add_series/6" do
    test "adds a series with x, y, and bubble sizes" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2, 3], [10, 20, 30], [5, 10, 15])

      assert length(data.series) == 1
      [series] = data.series
      assert series.name == "S1"
      assert series.index == 0
      assert series.x_values == [1, 2, 3]
      assert series.y_values == [10, 20, 30]
      assert series.bubble_sizes == [5, 10, 15]
    end

    test "adds multiple series" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])
        |> BubbleChartData.add_series("S2", [3, 4], [30, 40], [15, 20])

      assert length(data.series) == 2
      assert Enum.at(data.series, 1).index == 1
    end

    test "raises on mismatched lengths" do
      assert_raise ArgumentError, ~r/same length/, fn ->
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2, 3], [10, 20], [5, 10])
      end
    end

    test "raises on non-numeric bubble_sizes" do
      assert_raise ArgumentError, ~r/bubble_sizes must all be numbers/, fn ->
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], ["a", "b"])
      end
    end
  end

  describe "Excel references" do
    test "series_name_ref for first series" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])

      assert BubbleChartData.series_name_ref(data, hd(data.series)) == "Sheet1!$A$1"
    end

    test "series_x_values_ref for first series" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2, 3], [10, 20, 30], [5, 10, 15])

      assert BubbleChartData.series_x_values_ref(data, hd(data.series)) == "Sheet1!$A$2:$A$4"
    end

    test "series_y_values_ref for first series" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2, 3], [10, 20, 30], [5, 10, 15])

      assert BubbleChartData.series_y_values_ref(data, hd(data.series)) == "Sheet1!$B$2:$B$4"
    end

    test "series_bubble_sizes_ref for first series" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2, 3], [10, 20, 30], [5, 10, 15])

      assert BubbleChartData.series_bubble_sizes_ref(data, hd(data.series)) == "Sheet1!$C$2:$C$4"
    end

    test "second series uses correct columns (3 cols per series)" do
      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])
        |> BubbleChartData.add_series("S2", [3, 4], [30, 40], [15, 20])

      s2 = Enum.at(data.series, 1)
      # Series 1: x -> col D (index=1, *3=3 -> D), y -> col E, size -> col F
      assert BubbleChartData.series_x_values_ref(data, s2) == "Sheet1!$D$2:$D$3"
      assert BubbleChartData.series_y_values_ref(data, s2) == "Sheet1!$E$2:$E$3"
      assert BubbleChartData.series_bubble_sizes_ref(data, s2) == "Sheet1!$F$2:$F$3"
    end
  end
end
