defmodule Podium.Chart.ChartData do
  @moduledoc false

  defstruct categories: [], series: []

  defmodule Series do
    @moduledoc false
    defstruct [
      :name,
      :index,
      :color,
      :pattern,
      :marker,
      values: [],
      point_colors: %{},
      point_formats: %{},
      data_labels: nil
    ]
  end

  @doc """
  Creates a new empty ChartData.
  """
  def new, do: %__MODULE__{}

  @doc """
  Adds categories to the chart data.
  """
  def add_categories(%__MODULE__{} = data, categories) when is_list(categories) do
    %{data | categories: categories}
  end

  @doc """
  Adds a series with a name and numeric values.
  """
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
      pattern: Keyword.get(opts, :pattern),
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
  def categories_ref(%__MODULE__{} = data) do
    count = length(data.categories)
    "Sheet1!$A$2:$A$#{count + 1}"
  end

  @doc """
  Returns the Excel worksheet reference for a series name cell.
  e.g. "Sheet1!$B$1" for series index 0.
  """
  def series_name_ref(%__MODULE__{}, %Series{index: index}) do
    col = column_letter(index + 1)
    "Sheet1!$#{col}$1"
  end

  @doc """
  Returns the Excel worksheet reference for a series values range.
  e.g. "Sheet1!$B$2:$B$5" for series index 0 with 4 values.
  """
  def series_values_ref(%__MODULE__{}, %Series{index: index, values: values}) do
    col = column_letter(index + 1)
    count = length(values)
    "Sheet1!$#{col}$2:$#{col}$#{count + 1}"
  end

  @doc """
  Converts a 1-based column number to an Excel column letter.
  1 -> "B", 2 -> "C", etc. (offset by 1 because column A is categories)
  """
  def column_letter(series_index) when series_index >= 1 and series_index <= 25 do
    # Column A (index 0) is categories, series start at B
    col_num = series_index + 1
    <<?A + col_num - 1>>
  end
end
