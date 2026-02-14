defmodule Podium.Chart.XlsxWriter do
  @moduledoc """
  Embedded Excel workbook generation for chart data.

  Generates the `.xlsx` binary embedded alongside each chart, providing
  the editable data source when the chart is opened in PowerPoint.
  """

  alias Podium.Chart.{BubbleChartData, ChartData, XyChartData}

  @doc """
  Generates an embedded Excel workbook binary from chart data.
  Uses elixlsx to create the .xlsx file.
  """
  @spec to_xlsx(ChartData.t() | XyChartData.t() | BubbleChartData.t()) :: binary()
  def to_xlsx(%ChartData{} = chart_data) do
    rows = build_rows(chart_data)
    write_xlsx(rows)
  end

  def to_xlsx(%XyChartData{} = chart_data) do
    rows = build_xy_rows(chart_data)
    write_xlsx(rows)
  end

  def to_xlsx(%BubbleChartData{} = chart_data) do
    rows = build_bubble_rows(chart_data)
    write_xlsx(rows)
  end

  defp write_xlsx(rows) do
    sheet = %Elixlsx.Sheet{name: "Sheet1", rows: rows}
    workbook = %Elixlsx.Workbook{sheets: [sheet]}

    {:ok, {_filename, binary}} = Elixlsx.write_to_memory(workbook, "chart_data.xlsx")
    binary
  end

  defp build_rows(%ChartData{} = chart_data) do
    # Header row: blank cell for categories column, then series names
    header = [nil | Enum.map(chart_data.series, & &1.name)]

    # Data rows: category label in column A, then series values
    data_rows =
      chart_data.categories
      |> Enum.with_index()
      |> Enum.map(fn {category, idx} ->
        values = Enum.map(chart_data.series, fn series -> Enum.at(series.values, idx) end)
        [category | values]
      end)

    [header | data_rows]
  end

  # XY layout: 2 columns per series (X, Y)
  # Header: [nil, "Series 1", nil, "Series 2", ...]
  defp build_xy_rows(%XyChartData{} = chart_data) do
    header =
      chart_data.series
      |> Enum.flat_map(fn series -> [series.name, nil] end)

    row_count =
      chart_data.series
      |> Enum.map(fn s -> length(s.x_values) end)
      |> Enum.max(fn -> 0 end)

    data_rows =
      Enum.map(0..(row_count - 1)//1, fn idx ->
        Enum.flat_map(chart_data.series, fn series ->
          [Enum.at(series.x_values, idx), Enum.at(series.y_values, idx)]
        end)
      end)

    [header | data_rows]
  end

  # Bubble layout: 3 columns per series (X, Y, Size)
  # Header: [nil, "Series 1", nil, nil, "Series 2", ...]
  defp build_bubble_rows(%BubbleChartData{} = chart_data) do
    header =
      chart_data.series
      |> Enum.flat_map(fn series -> [series.name, nil, nil] end)

    row_count =
      chart_data.series
      |> Enum.map(fn s -> length(s.x_values) end)
      |> Enum.max(fn -> 0 end)

    data_rows =
      Enum.map(0..(row_count - 1)//1, fn idx ->
        Enum.flat_map(chart_data.series, fn series ->
          [
            Enum.at(series.x_values, idx),
            Enum.at(series.y_values, idx),
            Enum.at(series.bubble_sizes, idx)
          ]
        end)
      end)

    [header | data_rows]
  end
end
