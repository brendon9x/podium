defmodule Podium.Integration.ComboChartsTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.ChartData
  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"

  describe "column + line combo" do
    test "creates combo chart with column and line series" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167])
        |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000])
        |> ChartData.add_series("Margin %", [33, 50, 52, 5])

      prs = Podium.new(title: "Combo Charts Test", author: "Podium")
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Column + Line Combo")

      slide =
        Podium.add_combo_chart(
          slide,
          data,
          [
            {:column_clustered, series: [0, 1]},
            {:line_markers, series: [2], secondary_axis: true}
          ],
          x: {0.5, :inches},
          y: {1.5, :inches},
          width: {12.33, :inches},
          height: {5.5, :inches},
          title: "Revenue & Expenses with Margin",
          legend: :bottom,
          value_axis: [title: "Revenue / Expenses"],
          secondary_value_axis: [title: "Margin %"]
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "combo_column_line.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify chart XML exists
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:chartSpace"

      # Verify it's a combo chart with plotArea containing multiple chart types
      assert chart_xml =~ "c:plotArea"
      assert chart_xml =~ "c:barChart"
      assert chart_xml =~ "c:lineChart"

      # Verify series names
      assert chart_xml =~ "Revenue"
      assert chart_xml =~ "Expenses"
      assert chart_xml =~ "Margin %"

      # Verify chart title
      assert chart_xml =~ "Revenue &amp; Expenses with Margin"

      # Verify embedded xlsx exists
      assert Map.has_key?(parts, "ppt/embeddings/Microsoft_Excel_Sheet1.xlsx")
    end
  end

  describe "secondary axis combo" do
    test "creates combo chart with secondary axis for line series" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
        |> ChartData.add_series("Sales ($K)", [120, 150, 180, 200, 220, 250])
        |> ChartData.add_series("Units", [45, 52, 61, 68, 74, 82])

      prs = Podium.new()
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Secondary Axis Demo")

      slide =
        Podium.add_combo_chart(
          slide,
          data,
          [
            {:column_clustered, series: [0]},
            {:line_markers, series: [1], secondary_axis: true}
          ],
          x: {0.5, :inches},
          y: {1.5, :inches},
          width: {12.33, :inches},
          height: {5.5, :inches},
          title: "Sales Revenue vs Units Sold",
          legend: :bottom,
          value_axis: [title: "Sales ($K)"],
          secondary_value_axis: [title: "Units Sold"]
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "combo_secondary_axis.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]

      # Verify both chart types exist
      assert chart_xml =~ "c:barChart"
      assert chart_xml =~ "c:lineChart"

      # Verify series names
      assert chart_xml =~ "Sales ($K)"
      assert chart_xml =~ "Units"

      # Verify axis titles
      assert chart_xml =~ "Sales ($K)"
      assert chart_xml =~ "Units Sold"
    end
  end

  describe "area + line combo" do
    test "creates combo chart with area and line series" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["2020", "2021", "2022", "2023", "2024"])
        |> ChartData.add_series("Total Users", [100, 250, 500, 800, 1200])
        |> ChartData.add_series("Active Users", [80, 200, 400, 700, 1100])
        |> ChartData.add_series("Growth Rate %", [0, 150, 100, 60, 50])

      prs = Podium.new()
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Area + Line Combo")

      slide =
        Podium.add_combo_chart(
          slide,
          data,
          [
            {:area, series: [0, 1]},
            {:line_markers, series: [2], secondary_axis: true}
          ],
          x: {0.5, :inches},
          y: {1.5, :inches},
          width: {12.33, :inches},
          height: {5.5, :inches},
          title: "User Growth Trajectory",
          legend: :bottom,
          secondary_value_axis: [title: "Growth Rate %"]
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "combo_area_line.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]

      # Verify both chart types exist
      assert chart_xml =~ "c:areaChart"
      assert chart_xml =~ "c:lineChart"

      # Verify series names
      assert chart_xml =~ "Total Users"
      assert chart_xml =~ "Active Users"
      assert chart_xml =~ "Growth Rate %"

      # Verify chart title
      assert chart_xml =~ "User Growth Trajectory"
    end
  end

  describe "stacked column + line combo" do
    test "creates combo chart with stacked columns and line" do
      data =
        ChartData.new()
        |> ChartData.add_categories(["North", "South", "East", "West"])
        |> ChartData.add_series("Product A", [300, 400, 350, 280])
        |> ChartData.add_series("Product B", [200, 300, 250, 320])
        |> ChartData.add_series("Target", [550, 600, 500, 500])

      prs = Podium.new()
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Stacked Column + Line")

      slide =
        Podium.add_combo_chart(
          slide,
          data,
          [
            {:column_stacked, series: [0, 1]},
            {:line_markers, series: [2]}
          ],
          x: {0.5, :inches},
          y: {1.5, :inches},
          width: {12.33, :inches},
          height: {5.5, :inches},
          title: "Regional Sales vs Target",
          legend: :bottom
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "combo_stacked_line.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]

      # Verify both chart types exist
      assert chart_xml =~ "c:barChart"
      assert chart_xml =~ "c:lineChart"

      # Verify stacked grouping
      assert chart_xml =~ ~s(c:grouping val="stacked")

      # Verify series names
      assert chart_xml =~ "Product A"
      assert chart_xml =~ "Product B"
      assert chart_xml =~ "Target"

      # Verify chart title
      assert chart_xml =~ "Regional Sales vs Target"
    end
  end
end
