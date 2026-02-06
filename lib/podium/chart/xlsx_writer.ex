defmodule Podium.Chart.XlsxWriter do
  @moduledoc false

  alias Podium.Chart.ChartData

  @doc """
  Generates an embedded Excel workbook binary from chart data.
  Uses elixlsx to create the .xlsx file.
  """
  def to_xlsx(%ChartData{} = chart_data) do
    rows = build_rows(chart_data)

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
end
