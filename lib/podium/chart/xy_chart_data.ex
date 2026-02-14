defmodule Podium.Chart.XyChartData do
  @moduledoc """
  XY (scatter) chart data with numeric X and Y value pairs per series.

  Unlike `Podium.Chart.ChartData`, scatter charts don't use named categories.
  Each series has its own set of X values paired with Y values.

  ## Example

      alias Podium.Chart.XyChartData

      data =
        XyChartData.new()
        |> XyChartData.add_series("Observations", [1.0, 2.5, 3.2, 4.8], [5.3, 7.1, 4.9, 8.2],
          color: "4472C4"
        )

  See the [Charts](charts.md) guide for full documentation.
  """

  defstruct series: []

  @type t :: %__MODULE__{series: [Series.t()]}

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

  @doc "Creates a new empty XyChartData."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds a scatter series with paired X and Y values.

  ## Options
    * `:color` - series color (hex RGB string)
    * `:pattern` - pattern fill keyword list
    * `:marker` - marker options keyword list
    * `:point_colors` - `%{index => color}` map for per-point colors
    * `:point_formats` - `%{index => opts}` map for per-point formatting
    * `:data_labels` - `%{index => opts}` map for per-point data labels
  """
  @spec add_series(t(), String.t(), [number()], [number()], keyword()) :: t()
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

  @doc "Returns the Excel cell reference for a series name."
  @spec series_name_ref(t(), Series.t()) :: String.t()
  def series_name_ref(%__MODULE__{}, %Series{index: index}) do
    col = xy_column_letter(index * 2)
    "Sheet1!$#{col}$1"
  end

  @doc "Returns the Excel range reference for a series' X values."
  @spec series_x_values_ref(t(), Series.t()) :: String.t()
  def series_x_values_ref(%__MODULE__{}, %Series{index: index, x_values: x_values}) do
    col = xy_column_letter(index * 2)
    count = length(x_values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  @doc "Returns the Excel range reference for a series' Y values."
  @spec series_y_values_ref(t(), Series.t()) :: String.t()
  def series_y_values_ref(%__MODULE__{}, %Series{index: index, y_values: y_values}) do
    col = xy_column_letter(index * 2 + 1)
    count = length(y_values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  defp xy_column_letter(zero_based_index) do
    <<?A + zero_based_index>>
  end
end
