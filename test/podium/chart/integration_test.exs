defmodule Podium.Chart.IntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.ChartData
  alias Podium.Test.PptxHelpers

  describe "full chart integration" do
    test "creates a pptx with a column chart containing correct structure" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167])
        |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000])

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_chart(prs, slide, :column_clustered, chart_data,
          x: {1, :inches},
          y: {2, :inches},
          width: {8, :inches},
          height: {4.5, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify chart XML exists
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:chartSpace"
      assert chart_xml =~ "c:barChart"
      assert chart_xml =~ "Revenue"

      # Verify chart rels exist (chart -> embedded xlsx)
      assert Map.has_key?(parts, "ppt/charts/_rels/chart1.xml.rels")
      chart_rels = parts["ppt/charts/_rels/chart1.xml.rels"]
      assert chart_rels =~ "Microsoft_Excel_Sheet1.xlsx"

      # Verify embedded xlsx exists
      assert Map.has_key?(parts, "ppt/embeddings/Microsoft_Excel_Sheet1.xlsx")
      xlsx_binary = parts["ppt/embeddings/Microsoft_Excel_Sheet1.xlsx"]
      assert {:ok, _} = :zip.unzip(xlsx_binary, [:memory])

      # Verify slide references the chart via graphic frame
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:graphicFrame"
      assert slide_xml =~ "c:chart"

      # Verify slide rels include chart relationship
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "chart1.xml"

      # Verify content types include chart
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "/ppt/charts/chart1.xml"
      assert ct_xml =~ "drawingml.chart+xml"

      # Verify externalData element links chart to xlsx
      assert chart_xml =~ ~s(c:externalData r:id="rId1")
    end

    test "creates pptx with text box and chart on same slide" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("Values", [10, 20])

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Chart Title",
          x: {1, :inches},
          y: {0.5, :inches},
          width: {8, :inches},
          height: {1, :inches},
          font_size: 28
        )

      {prs, slide} =
        Podium.add_chart(prs, slide, :pie, chart_data,
          x: {2, :inches},
          y: {2, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # Both text box and chart should be present
      assert slide_xml =~ "Chart Title"
      assert slide_xml =~ "p:graphicFrame"
      assert slide_xml =~ ~s(txBox="1")
    end

    test "creates pptx with multiple charts on separate slides" do
      chart_data1 =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])

      chart_data2 =
        ChartData.new()
        |> ChartData.add_categories(["X", "Y"])
        |> ChartData.add_series("S2", [30, 40])

      prs = Podium.new()
      {prs, slide1} = Podium.add_slide(prs)
      {prs, slide2} = Podium.add_slide(prs)

      {prs, slide1} =
        Podium.add_chart(prs, slide1, :column_clustered, chart_data1,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      {prs, slide2} =
        Podium.add_chart(prs, slide2, :line, chart_data2,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      prs =
        prs
        |> Podium.put_slide(slide1)
        |> Podium.put_slide(slide2)

      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Both charts should exist
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")
      assert Map.has_key?(parts, "ppt/embeddings/Microsoft_Excel_Sheet1.xlsx")
      assert Map.has_key?(parts, "ppt/embeddings/Microsoft_Excel_Sheet2.xlsx")

      # Chart 1 is bar, chart 2 is line
      assert parts["ppt/charts/chart1.xml"] =~ "c:barChart"
      assert parts["ppt/charts/chart2.xml"] =~ "c:lineChart"
    end

    test "creates pptx with multiple charts on the same slide" do
      chart_data1 =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])

      chart_data2 =
        ChartData.new()
        |> ChartData.add_categories(["X", "Y"])
        |> ChartData.add_series("S2", [30, 40])

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, slide} =
        Podium.add_chart(prs, slide, :column_clustered, chart_data1,
          x: {0.5, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {4, :inches}
        )

      {prs, slide} =
        Podium.add_chart(prs, slide, :pie, chart_data2,
          x: {5, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {4, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Both charts on one slide
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert Map.has_key?(parts, "ppt/charts/chart2.xml")

      # Slide rels should reference both charts
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "chart1.xml"
      assert slide_rels =~ "chart2.xml"

      # Slide XML should have two graphic frames
      slide_xml = parts["ppt/slides/slide1.xml"]
      graphic_frame_count = length(Regex.scan(~r/<p:graphicFrame /, slide_xml))
      assert graphic_frame_count == 2
    end

    test "stacked column chart includes overlap element" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A", "B"])
        |> ChartData.add_series("S1", [10, 20])
        |> ChartData.add_series("S2", [30, 40])

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      {prs, _slide} =
        Podium.add_chart(prs, slide, :column_stacked, chart_data,
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: {5, :inches}
        )

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ ~s(c:grouping val="stacked")
      assert chart_xml =~ ~s(c:overlap val="100")
    end

    test "add_chart auto-updates slide in presentation" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["A"])
        |> ChartData.add_series("S1", [10])

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      # add_chart should auto-update the slide inside prs
      {prs, _slide} =
        Podium.add_chart(prs, slide, :pie, chart_data,
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      # Save WITHOUT calling put_slide — should still work
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      assert parts["ppt/slides/slide1.xml"] =~ "p:graphicFrame"
    end

    test "matches the target API from the plan" do
      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167])
        |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000])

      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "Hello World",
          x: {2, :inches},
          y: {2, :inches},
          width: {6, :inches},
          height: {1, :inches},
          font_size: 24
        )

      {prs, slide} =
        Podium.add_chart(prs, slide, :column_clustered, chart_data,
          x: {1, :inches},
          y: {2, :inches},
          width: {8, :inches},
          height: {4.5, :inches}
        )

      prs = Podium.put_slide(prs, slide)

      tmp_path = Path.join(System.tmp_dir!(), "podium_api_test.pptx")
      on_exit(fn -> File.rm(tmp_path) end)

      assert :ok = Podium.save(prs, tmp_path)
      assert File.exists?(tmp_path)

      # Verify it's a valid zip
      parts = PptxHelpers.unzip_pptx(tmp_path)
      assert map_size(parts) > 0
    end
  end
end
