defmodule Podium.Chart.XyChartData do
  @moduledoc false

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
      point_colors: %{},
      point_formats: %{},
      data_labels: nil
    ]
  end

  def new, do: %__MODULE__{}

  def add_series(%__MODULE__{} = data, name, x_values, y_values, opts \\ []) do
    unless length(x_values) == length(y_values) do
      raise ArgumentError,
            "x_values and y_values must have the same length, got #{length(x_values)} and #{length(y_values)}"
    end

    unless Enum.all?(x_values, &is_number/1) do
      raise ArgumentError, "x_values must all be numbers, got: #{inspect(x_values)}"
    end

    unless Enum.all?(y_values, &is_number/1) do
      raise ArgumentError, "y_values must all be numbers, got: #{inspect(y_values)}"
    end

    series = %Series{
      name: name,
      index: length(data.series),
      x_values: x_values,
      y_values: y_values,
      color: Keyword.get(opts, :color),
      pattern: Keyword.get(opts, :pattern),
      marker: Keyword.get(opts, :marker),
      point_colors: Keyword.get(opts, :point_colors, %{}),
      point_formats: Keyword.get(opts, :point_formats, %{}),
      data_labels: Keyword.get(opts, :data_labels)
    }

    %{data | series: data.series ++ [series]}
  end

  # Excel layout: 2 columns per series (X, Y)
  # Series 0 -> cols A,B; Series 1 -> cols C,D

  def series_name_ref(%__MODULE__{}, %Series{index: index}) do
    col = xy_column_letter(index * 2)
    "Sheet1!$#{col}$1"
  end

  def series_x_values_ref(%__MODULE__{}, %Series{index: index, x_values: x_values}) do
    col = xy_column_letter(index * 2)
    count = length(x_values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  def series_y_values_ref(%__MODULE__{}, %Series{index: index, y_values: y_values}) do
    col = xy_column_letter(index * 2 + 1)
    count = length(y_values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  defp xy_column_letter(zero_based_index) do
    <<?A + zero_based_index>>
  end
end
