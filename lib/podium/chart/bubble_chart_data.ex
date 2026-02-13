defmodule Podium.Chart.BubbleChartData do
  @moduledoc """
  Bubble chart data with X values, Y values, and bubble sizes per series.

  Extends `Podium.Chart.XyChartData` with a third dimension (bubble size)
  for each data point.

  ## Example

      alias Podium.Chart.BubbleChartData

      data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("Markets",
          [10, 20, 30], [50, 40, 60], [5, 10, 15],
          color: "4472C4"
        )

  See the [Charts](charts.md) guide for full documentation.
  """

  defstruct series: []

  defmodule Series do
    @moduledoc false

    defstruct [
      :name,
      :index,
      :color,
      :pattern,
      :marker,
      x_values: [],
      y_values: [],
      bubble_sizes: [],
      point_colors: %{},
      point_formats: %{},
      data_labels: nil
    ]
  end

  def new, do: %__MODULE__{}

  def add_series(%__MODULE__{} = data, name, x_values, y_values, bubble_sizes, opts \\ []) do
    unless length(x_values) == length(y_values) and length(y_values) == length(bubble_sizes) do
      raise ArgumentError,
            "x_values, y_values, and bubble_sizes must have the same length, " <>
              "got #{length(x_values)}, #{length(y_values)}, and #{length(bubble_sizes)}"
    end

    unless Enum.all?(x_values, &is_number/1) do
      raise ArgumentError, "x_values must all be numbers, got: #{inspect(x_values)}"
    end

    unless Enum.all?(y_values, &is_number/1) do
      raise ArgumentError, "y_values must all be numbers, got: #{inspect(y_values)}"
    end

    unless Enum.all?(bubble_sizes, &is_number/1) do
      raise ArgumentError, "bubble_sizes must all be numbers, got: #{inspect(bubble_sizes)}"
    end

    series = %Series{
      name: name,
      index: length(data.series),
      x_values: x_values,
      y_values: y_values,
      bubble_sizes: bubble_sizes,
      color: Keyword.get(opts, :color),
      pattern: Keyword.get(opts, :pattern),
      marker: Keyword.get(opts, :marker),
      point_colors: Keyword.get(opts, :point_colors, %{}),
      point_formats: Keyword.get(opts, :point_formats, %{}),
      data_labels: Keyword.get(opts, :data_labels)
    }

    %{data | series: data.series ++ [series]}
  end

  # Excel layout: 3 columns per series (X, Y, Size)
  # Series 0 -> cols A,B,C; Series 1 -> cols D,E,F

  def series_name_ref(%__MODULE__{}, %Series{index: index}) do
    col = bubble_column_letter(index * 3)
    "Sheet1!$#{col}$1"
  end

  def series_x_values_ref(%__MODULE__{}, %Series{index: index, x_values: x_values}) do
    col = bubble_column_letter(index * 3)
    count = length(x_values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  def series_y_values_ref(%__MODULE__{}, %Series{index: index, y_values: y_values}) do
    col = bubble_column_letter(index * 3 + 1)
    count = length(y_values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  def series_bubble_sizes_ref(%__MODULE__{}, %Series{index: index, bubble_sizes: sizes}) do
    col = bubble_column_letter(index * 3 + 2)
    count = length(sizes)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  defp bubble_column_letter(zero_based_index) do
    <<?A + zero_based_index>>
  end
end
