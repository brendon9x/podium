defmodule Podium.Integration.PlaceholderIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Chart.ChartData
  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"
  @fixtures_dir "demos"

  describe "title slide layout" do
    test "creates presentation with title and subtitle placeholders" do
      prs = Podium.new(title: "Acme Corp Annual Review", author: "Podium Demo")
      {prs, slide} = Podium.add_slide(prs, layout: :title_slide)

      slide =
        slide
        |> Podium.set_placeholder(:title, [
          [{"Acme Corp", bold: true, font_size: 44, color: "003366"}]
        ])
        |> Podium.set_placeholder(
          :subtitle,
          "2025 Annual Review — Finance & Operations Dashboard"
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "placeholder_title_slide.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify title and subtitle content
      assert slide_xml =~ "Acme Corp"
      assert slide_xml =~ "2025 Annual Review"

      # Verify placeholder references (p:ph)
      assert slide_xml =~ ~s(<p:ph type="ctrTitle")
      assert slide_xml =~ ~s(<p:ph type="subTitle")
    end
  end

  describe "title + content layout" do
    test "creates presentation with title and content placeholders" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_content)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Next Steps")
        |> Podium.set_placeholder(:content, [
          [{"Continue expanding into Asia Pacific market"}],
          [{"Invest in self-service support tools"}],
          [{"Target 95% customer satisfaction by Q4 2026"}]
        ])

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "placeholder_title_content.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify content
      assert slide_xml =~ "Next Steps"
      assert slide_xml =~ "Continue expanding into Asia Pacific market"
      assert slide_xml =~ "Invest in self-service support tools"
      assert slide_xml =~ "Target 95% customer satisfaction by Q4 2026"

      # Verify placeholder references
      assert slide_xml =~ ~s(<p:ph type="title")
      assert slide_xml =~ ~s(<p:ph idx="1")
    end
  end

  describe "two content layout" do
    test "creates presentation with left and right content placeholders" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :two_content)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Two Column Layout")
        |> Podium.set_placeholder(:left_content, [
          [{"Left Column Highlights"}],
          [{"Revenue growth: 35%"}],
          [{"Market expansion ongoing"}]
        ])
        |> Podium.set_placeholder(:right_content, [
          [{"Right Column Details"}],
          [{"Customer satisfaction: 92%"}],
          [{"NPS score improved by 15 points"}]
        ])

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "placeholder_two_content.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify content
      assert slide_xml =~ "Two Column Layout"
      assert slide_xml =~ "Left Column Highlights"
      assert slide_xml =~ "Revenue growth: 35%"
      assert slide_xml =~ "Right Column Details"
      assert slide_xml =~ "Customer satisfaction: 92%"

      # Verify placeholder references
      assert slide_xml =~ ~s(<p:ph type="title")
      assert slide_xml =~ ~s(<p:ph idx="1")
      assert slide_xml =~ ~s(<p:ph idx="2")
    end
  end

  describe "comparison layout" do
    test "creates presentation with comparison layout placeholders" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :comparison)

      slide =
        slide
        |> Podium.set_placeholder(:title, "Before vs After")
        |> Podium.set_placeholder(:left_heading, "Before (Q1)")
        |> Podium.set_placeholder(:left_content, [
          [{"Manual processes"}],
          [{"3-day turnaround"}],
          [{"High error rate"}]
        ])
        |> Podium.set_placeholder(:right_heading, "After (Q4)")
        |> Podium.set_placeholder(:right_content, [
          [{"Fully automated"}],
          [{"Same-day delivery"}],
          [{"99.9% accuracy"}]
        ])

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "placeholder_comparison.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify content
      assert slide_xml =~ "Before vs After"
      assert slide_xml =~ "Before (Q1)"
      assert slide_xml =~ "Manual processes"
      assert slide_xml =~ "After (Q4)"
      assert slide_xml =~ "Fully automated"
      assert slide_xml =~ "99.9% accuracy"

      # Verify placeholder references
      assert slide_xml =~ ~s(<p:ph type="title")
      assert slide_xml =~ ~s(<p:ph idx=)
    end
  end

  describe "picture + caption layout" do
    test "creates presentation with picture and caption placeholders" do
      # Skip test if image file doesn't exist (just pass)
      image_path = Path.join(@fixtures_dir, "acme.jpg")

      if File.exists?(image_path) do
        image_binary = File.read!(image_path)

        prs = Podium.new()
        {prs, slide} = Podium.add_slide(prs, layout: :picture_caption)

        slide =
          slide
          |> Podium.set_placeholder(:title, "Product Showcase")
          |> Podium.set_placeholder(:caption, "Our flagship product — the Acme Widget 3000")

        {prs, _slide} = Podium.set_picture_placeholder(prs, slide, :picture, image_binary)

        # Save to disk for manual inspection
        output_path = Path.join(@output_dir, "placeholder_picture_caption.pptx")
        assert :ok = Podium.save(prs, output_path)
        assert File.exists?(output_path)

        # Save to memory for XML assertions
        {:ok, binary} = Podium.save_to_memory(prs)
        parts = PptxHelpers.unzip_pptx_binary(binary)

        slide_xml = parts["ppt/slides/slide1.xml"]

        # Verify content
        assert slide_xml =~ "Product Showcase"
        assert slide_xml =~ "Our flagship product"

        # Verify placeholder references
        assert slide_xml =~ ~s(<p:ph type="title")
        assert slide_xml =~ ~s(<p:ph type="body")
        assert slide_xml =~ ~s(<p:ph type="pic")

        # Verify image relationship
        slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
        assert slide_rels =~ "image"
      end
    end
  end

  describe "chart placeholders" do
    test "creates chart in content placeholder on title_content layout" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_content)

      slide = Podium.set_placeholder(slide, :title, "Chart Placeholder Demo")

      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Revenue", [12_500, 14_600, 15_156, 18_167], color: "4472C4")
        |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")

      {prs, _slide} =
        Podium.set_chart_placeholder(prs, slide, :content, :column_clustered, chart_data,
          title: "Revenue vs Expenses",
          legend: :bottom
        )

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "placeholder_chart.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify chart placeholder content
      assert slide_xml =~ "Chart Placeholder Demo"
      assert slide_xml =~ "p:graphicFrame"

      # Verify chart exists
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "Revenue vs Expenses"
      assert chart_xml =~ "Revenue"
      assert chart_xml =~ "Expenses"
    end
  end

  describe "table placeholders" do
    test "creates table and chart in two_content layout placeholders" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :two_content)

      slide = Podium.set_placeholder(slide, :title, "Table & Chart Placeholders")

      {prs, slide} =
        Podium.set_table_placeholder(
          prs,
          slide,
          :left_content,
          [
            ["Region", "Revenue"],
            ["North America", "$12.5M"],
            ["Europe", "$8.2M"],
            ["Asia Pacific", "$5.1M"]
          ],
          table_style: [first_row: true]
        )

      chart_data =
        ChartData.new()
        |> ChartData.add_categories(["NA", "EU", "APAC"])
        |> ChartData.add_series("Revenue", [12.5, 8.2, 5.1],
          point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31"}
        )

      {prs, _slide} =
        Podium.set_chart_placeholder(prs, slide, :right_content, :pie, chart_data,
          title: "Revenue Split",
          legend: :bottom,
          data_labels: [:category, :percent]
        )

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "placeholder_table_chart.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify title (XML entity encoded)
      assert slide_xml =~ "Table &amp; Chart Placeholders"

      # Verify table content
      assert slide_xml =~ "Region"
      assert slide_xml =~ "North America"
      assert slide_xml =~ "$12.5M"
      assert slide_xml =~ "p:graphicFrame"

      # Verify table element (a:tbl)
      assert slide_xml =~ "<a:tbl"

      # Verify chart exists
      assert Map.has_key?(parts, "ppt/charts/chart1.xml")
      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "Revenue Split"
    end
  end
end
