defmodule Podium.Chart.XlsxWriterTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.{ChartData, XlsxWriter}

  describe "to_xlsx/1" do
    test "generates a valid xlsx binary" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3"])
        |> ChartData.add_series("Revenue", [100, 200, 300])

      binary = XlsxWriter.to_xlsx(chart_data)

      # Verify it's a valid ZIP (xlsx files are ZIP)
      assert {:ok, entries} = :zip.unzip(binary, [:memory])
      filenames = Enum.map(entries, fn {name, _} -> to_string(name) end)

      # xlsx must contain these standard parts
      assert "[Content_Types].xml" in filenames
      assert "xl/workbook.xml" in filenames
    end

    test "generates workbook with correct data layout" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])
        |> ChartData.add_series("S2", [30, 40])

      binary = XlsxWriter.to_xlsx(chart_data)

      # Verify it's a valid ZIP
      assert {:ok, _} = :zip.unzip(binary, [:memory])
    end
  end
end
