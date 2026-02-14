defmodule Podium.Integration.TableIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir Path.join([__DIR__, "output"])

  describe "table basics" do
    test "creates valid pptx with table containing rich text and merging" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        slide
        |> Podium.add_text_box("Department Summary",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.8, :inches},
          font_size: 28,
          alignment: :center
        )
        |> Podium.add_table(
          [
            # Header row: merged title spanning all columns
            [
              {[[{"Department Summary — 2025", bold: true, color: "FFFFFF"}]],
               col_span: 4, fill: "003366", anchor: :middle, padding: [left: {0.1, :inches}]},
              :merge,
              :merge,
              :merge
            ],
            # Column headers with fill and borders
            [
              {[[{"Department", bold: true, color: "FFFFFF"}]],
               fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
              {[[{"Headcount", bold: true, color: "FFFFFF"}]],
               fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
              {[[{"Budget ($K)", bold: true, color: "FFFFFF"}]],
               fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
              {[[{"Satisfaction", bold: true, color: "FFFFFF"}]],
               fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]}
            ],
            # Engineering spans 2 rows vertically with rich text
            [
              {[[{"Engineering", bold: true, color: "003366"}]],
               row_span: 2, anchor: :middle, fill: "D6E4F0", padding: [left: {0.1, :inches}]},
              "230",
              "$4,200",
              {[[{"92%", bold: true, color: "228B22"}]], anchor: :middle}
            ],
            # Merged from Engineering row above
            [
              :merge,
              "180",
              "$3,800",
              {[[{"94%", bold: true, color: "228B22"}]], anchor: :middle}
            ],
            # Regular rows
            ["Marketing", "85", "$2,100", {"87%", borders: [bottom: "CCCCCC"]}],
            ["Sales", "120", "$3,500", {"84%", borders: [bottom: "CCCCCC"]}]
          ],
          x: {0.5, :inches},
          y: {1.3, :inches},
          width: {12.33, :inches},
          height: {4.5, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "table_rich_text_merging.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for automated assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Assert on XML structure
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:tbl)
      assert slide_xml =~ ~s(gridSpan="4")
      assert slide_xml =~ ~s(rowSpan="2")
      assert slide_xml =~ ~s(Engineering)
    end
  end

  describe "table cell fills" do
    test "creates valid pptx with gradient, pattern, and solid cell fills" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        slide
        |> Podium.add_text_box("Table Cell Fills & Banding",
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches},
          font_size: 24,
          alignment: :center
        )
        |> Podium.add_table(
          [
            [
              {"Gradient Cell",
               fill: {:gradient, [{0, "4472C4"}, {100_000, "002060"}], angle: 5_400_000}},
              {"Pattern Cell",
               fill: {:pattern, :lt_horz, foreground: "ED7D31", background: "FFFFFF"}},
              {"Solid Cell", fill: "70AD47"}
            ],
            ["Plain A", "Plain B", "Plain C"]
          ],
          x: {1, :inches},
          y: {1.2, :inches},
          width: {11.33, :inches},
          height: {2, :inches},
          table_style: [first_row: true, band_row: true, band_col: true]
        )

      prs = Podium.add_slide(prs, slide)

      output_path = Path.join(@output_dir, "table_cell_fills.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:tbl)
      assert slide_xml =~ ~s(<a:gradFill)
      assert slide_xml =~ ~s(<a:pattFill)
      assert slide_xml =~ ~s(<a:solidFill)
      assert slide_xml =~ ~s(firstRow="1")
      assert slide_xml =~ ~s(bandRow="1")
      assert slide_xml =~ ~s(bandCol="1")
    end
  end

  describe "table borders and styling" do
    test "creates valid pptx with custom table borders" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [
            [
              {"Header 1", borders: [bottom: [color: "003366", width: {2, :pt}]]},
              {"Header 2", borders: [bottom: [color: "003366", width: {2, :pt}]]}
            ],
            ["Data 1", {"Data 2", borders: [bottom: "CCCCCC"]}]
          ],
          x: {1, :inches},
          y: {1.5, :inches},
          width: {10, :inches},
          height: {2, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      output_path = Path.join(@output_dir, "table_borders.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:ln)
      assert slide_xml =~ ~s(<a:tcPr)
    end
  end

  describe "table cell padding and alignment" do
    test "creates valid pptx with custom padding and vertical alignment" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [
            [
              {"Centered", anchor: :middle, fill: "D6E4F0", padding: [left: {0.1, :inches}]},
              {"Top", anchor: :top},
              {"Bottom", anchor: :bottom}
            ]
          ],
          x: {1, :inches},
          y: {1.5, :inches},
          width: {10, :inches},
          height: {2, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      output_path = Path.join(@output_dir, "table_padding_alignment.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(anchor="ctr")
      assert slide_xml =~ ~s(anchor="t")
      assert slide_xml =~ ~s(anchor="b")
    end
  end
end
