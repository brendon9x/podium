defmodule Podium.Chart.ChartData do
  @moduledoc """
  Category-based chart data for column, bar, line, pie, area, doughnut, and radar charts.

  Build chart data by creating a new struct, adding categories, then adding one
  or more named series with values that correspond to the categories.

  ## Example

      alias Podium.Chart.ChartData

      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")
        |> ChartData.add_series("Expenses", [10_000, 11_500, 12_000, 13_200], color: "ED7D31")

  See the [Charts](charts.md) guide for full documentation.
  """

  defstruct categories: [], series: []

  @type t :: %__MODULE__{
          categories: [String.t()],
          series: [Series.t()]
        }

  defmodule Series do
    @moduledoc false
    defstruct [
      :name,
      :index,
      :color,
      :fill,
      :line,
      :marker,
      values: [],
      point_colors: %{},
      point_formats: %{},
      data_labels: nil,
      invert_if_negative: false
    ]
  end

  @doc """
  Creates a new empty ChartData.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds categories to the chart data.
  """
  @spec add_categories(t(), [String.t()]) :: t()
  def add_categories(%__MODULE__{} = data, categories) when is_list(categories) do
    %{data | categories: categories}
  end

  @doc """
  Adds a series with a name and numeric values.

  ## Options

    * `:color` - the series colour, a hex string or `:none`. It fills bars, areas,
      slices and filled radar shapes, and colours the line of line and radar series
    * `:fill` - any fill (see "Fill types" in `Podium`), in place of `:color` for the
      fill: a gradient, a pattern such as `{:pattern, :dn_diag, foreground: "4472C4"}`,
      or `:none`
    * `:line` - the series line, or the outline of bars, areas and slices: a hex
      colour, a keyword list with `:color`, `:width` and `:dash_style`, or `:none`
      for a line or radar series drawn as markers only
    * `:marker` - marker options for line and radar series: `:style`, `:size`,
      `:fill`, `:line`
    * `:invert_if_negative` - `true` to draw negative bars in inverted colours
      (default `false`)
    * `:point_colors` - `%{index => fill}` map for per-point fills. On line and radar
      series the colour fills and outlines the point's marker
    * `:point_formats` - `%{index => [fill: ..., line: ...]}` map for per-point formatting.
      On line and radar series these format the point's marker, and `:marker` sets
      its `:style` and `:size`
    * `:data_labels` - labels for this series: a keyword list (or list of atoms) with
      the options of chart-level `:data_labels` labels every point, with per-point
      overrides under `:points`; a `%{index => opts}` map overrides those points.
      Each level takes what it does not set from the level above (chart, series,
      point). `show: []` leaves the series unlabelled under chart-level labels
  """
  @spec add_series(t(), String.t(), [number()], keyword()) :: t()
  def add_series(%__MODULE__{} = data, name, values, opts \\ []) when is_list(values) do
    unless Enum.all?(values, &is_number/1) do
      raise ArgumentError, "chart series values must be numbers, got: #{inspect(values)}"
    end

    if length(data.series) >= 25 do
      raise ArgumentError, "maximum of 25 series supported (columns B through Z)"
    end

    series = %Series{
      name: name,
      index: length(data.series),
      values: values,
      color: Keyword.get(opts, :color),
      fill: Keyword.get(opts, :fill),
      line: Keyword.get(opts, :line),
      invert_if_negative: Keyword.get(opts, :invert_if_negative, false),
      marker: Keyword.get(opts, :marker),
      point_colors: Keyword.get(opts, :point_colors, %{}),
      point_formats: Keyword.get(opts, :point_formats, %{}),
      data_labels: Keyword.get(opts, :data_labels)
    }

    %{data | series: data.series ++ [series]}
  end

  @doc """
  Returns the Excel worksheet reference for the categories range.
  e.g. "Sheet1!$A$2:$A$5" for 4 categories.
  """
  @spec categories_ref(t()) :: String.t()
  def categories_ref(%__MODULE__{} = data) do
    count = length(data.categories)
    "Sheet1!$A$2:$A$#{count + 1}"
  end

  @doc """
  Returns the Excel worksheet reference for a series name cell.
  e.g. "Sheet1!$B$1" for series index 0.
  """
  @spec series_name_ref(t(), Series.t()) :: String.t()
  def series_name_ref(%__MODULE__{}, %Series{index: index}) do
    col = column_letter(index + 1)
    "Sheet1!$#{col}$1"
  end

  @doc """
  Returns the Excel worksheet reference for a series values range.
  e.g. "Sheet1!$B$2:$B$5" for series index 0 with 4 values.
  """
  @spec series_values_ref(t(), Series.t()) :: String.t()
  def series_values_ref(%__MODULE__{}, %Series{index: index, values: values}) do
    col = column_letter(index + 1)
    count = length(values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  @doc """
  Converts a 1-based column number to an Excel column letter.
  1 -> "B", 2 -> "C", etc. (offset by 1 because column A is categories)
  """
  @spec column_letter(pos_integer()) :: String.t()
  def column_letter(series_index) when series_index >= 1 and series_index <= 25 do
    # Column A (index 0) is categories, series start at B
    col_num = series_index + 1
    <<?A + col_num - 1>>
  end
end
