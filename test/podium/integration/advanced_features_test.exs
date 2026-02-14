defmodule Podium.Integration.AdvancedFeaturesTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"

  describe "word wrap" do
    test "creates slides demonstrating word_wrap: true and false" do
      prs = Podium.new(title: "Word Wrap Test", author: "Podium Test")
      slide = Podium.Slide.new()

      slide =
        slide
        |> Podium.add_text_box(
          [
            {[{"Word Wrap Demo", bold: true, font_size: 28, color: "003366"}], alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_text_box(
          [{[{"wrap=\"square\" (default)", bold: true, font_size: 14}], alignment: :center}],
          x: {0.5, :inches},
          y: {1.2, :inches},
          width: {5.5, :inches},
          height: {0.4, :inches}
        )
        |> Podium.add_text_box(
          "This text box has word_wrap: true (the default). Long text will wrap to the next line when it reaches the edge of the box. This is the standard behavior for most text content in presentations.",
          x: {0.5, :inches},
          y: {1.8, :inches},
          width: {5.5, :inches},
          height: {2, :inches},
          font_size: 14,
          word_wrap: true,
          fill: "E8F0FE",
          line: "4472C4"
        )
        |> Podium.add_text_box(
          [{[{"wrap=\"none\"", bold: true, font_size: 14}], alignment: :center}],
          x: {7, :inches},
          y: {1.2, :inches},
          width: {5.5, :inches},
          height: {0.4, :inches}
        )
        |> Podium.add_text_box(
          "This text will NOT wrap — it stays on one line regardless of box width",
          x: {7, :inches},
          y: {1.8, :inches},
          width: {5.5, :inches},
          height: {2, :inches},
          font_size: 14,
          word_wrap: false,
          fill: "FFF3E0",
          line: "FF9800"
        )
        |> Podium.add_text_box(
          "Use word_wrap: false for single-line labels, badges, and button-style text",
          x: {0.5, :inches},
          y: {4.5, :inches},
          width: {12.33, :inches},
          height: {0.5, :inches},
          font_size: 12,
          alignment: :center,
          word_wrap: false,
          fill: "F0F0F0"
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "word_wrap.pptx")
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide contains text boxes
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "Word Wrap Demo"
      assert slide_xml =~ "word_wrap: true"
      assert slide_xml =~ "word_wrap: false"

      # Verify word wrap attributes in XML
      assert slide_xml =~ ~s(wrap="square") or slide_xml =~ ~s(wrap='square')
      assert slide_xml =~ ~s(wrap="none") or slide_xml =~ ~s(wrap='none')
    end
  end

  describe "table sizing" do
    test "creates table with custom column widths and row heights" do
      prs = Podium.new(title: "Table Sizing Test", author: "Podium Test")
      slide = Podium.Slide.new()

      slide =
        slide
        |> Podium.add_text_box(
          [
            {[{"Table Sizing Demo", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_table(
          [
            [
              {[[{"Rank", color: "FFFFFF", bold: true}]],
               fill: "003366", borders: [bottom: "FFFFFF"]},
              {[[{"Description", color: "FFFFFF", bold: true}]],
               fill: "003366", borders: [bottom: "FFFFFF"]},
              {[[{"Score", color: "FFFFFF", bold: true}]],
               fill: "003366", borders: [bottom: "FFFFFF"]}
            ],
            ["1", "Implemented text word wrap with wrap=none/square toggle", "100"],
            ["2", "Added per-column widths and per-row heights to tables", "95"],
            ["3", "Click actions: slide navigation and named slide jumps", "90"],
            ["4", "Updated PYTHON_PARITY.md with new features and won't-do items", "85"]
          ],
          x: {1, :inches},
          y: {1.5, :inches},
          width: {11, :inches},
          height: {4, :inches},
          col_widths: [{1.5, :inches}, {7, :inches}, {2.5, :inches}],
          row_heights: [
            {0.6, :inches},
            {0.85, :inches},
            {0.85, :inches},
            {0.85, :inches},
            {0.85, :inches}
          ]
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "table_sizing.pptx")
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide contains table
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "a:tbl"
      assert slide_xml =~ "Table Sizing Demo"

      # Verify table content
      assert slide_xml =~ "Rank"
      assert slide_xml =~ "Description"
      assert slide_xml =~ "Score"
      assert slide_xml =~ "Implemented text word wrap"
      assert slide_xml =~ "Added per-column widths"

      # Verify table grid columns exist
      assert slide_xml =~ "a:gridCol"

      # Verify table has correct number of rows (5 total: 1 header + 4 data)
      row_count = length(Regex.scan(~r/<a:tr /, slide_xml))
      assert row_count == 5
    end
  end

  describe "click actions" do
    test "creates navigation buttons with various hyperlink actions" do
      prs = Podium.new(title: "Click Actions Test", author: "Podium Test")
      slide = Podium.Slide.new()

      slide =
        slide
        |> Podium.add_text_box(
          [
            {[{"Click Actions: Navigation", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_text_box(
          "Click any button below during a slide show to navigate:",
          x: {1, :inches},
          y: {1.3, :inches},
          width: {11, :inches},
          height: {0.5, :inches},
          font_size: 16
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {1, :inches},
          y: {2.2, :inches},
          width: {2, :inches},
          height: {0.7, :inches},
          text: [[{"Next →", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :next_slide}]],
          fill: "4472C4",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {3.5, :inches},
          y: {2.2, :inches},
          width: {2, :inches},
          height: {0.7, :inches},
          text: [
            [{"← Back", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :previous_slide}]
          ],
          fill: "70AD47",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {6, :inches},
          y: {2.2, :inches},
          width: {2.2, :inches},
          height: {0.7, :inches},
          text: [
            [{"First Slide", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :first_slide}]
          ],
          fill: "ED7D31",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {8.7, :inches},
          y: {2.2, :inches},
          width: {2.2, :inches},
          height: {0.7, :inches},
          text: [
            [{"Last Slide", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :last_slide}]
          ],
          fill: "A855A8",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {4.5, :inches},
          y: {3.5, :inches},
          width: {4, :inches},
          height: {0.7, :inches},
          text: [[{"End Show", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :end_show}]],
          fill: "C00000",
          word_wrap: false
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "click_actions_navigation.pptx")
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide contains shapes with text
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "Click Actions: Navigation"
      assert slide_xml =~ "Next →"
      assert slide_xml =~ "← Back"
      assert slide_xml =~ "First Slide"
      assert slide_xml =~ "Last Slide"
      assert slide_xml =~ "End Show"

      # Verify hyperlink actions exist in XML
      assert slide_xml =~ "a:hlinkClick"

      # Verify navigation action types (not slide jump, just show navigation)
      assert slide_xml =~ "ppaction://hlinkshowjump"
    end

    test "creates slide jump buttons with {:slide, target} references" do
      prs = Podium.new(title: "Slide Jump Test", author: "Podium Test")

      # Create target slides first
      slide1 = Podium.Slide.new()

      slide1 =
        Podium.add_text_box(slide1, "Target Slide 1",
          x: {1, :inches},
          y: {3, :inches},
          width: {8, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide1)

      slide2 = Podium.Slide.new()

      slide2 =
        Podium.add_text_box(slide2, "Target Slide 2",
          x: {1, :inches},
          y: {3, :inches},
          width: {8, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide2)

      # Create navigation slide with jump buttons
      slide3 = Podium.Slide.new()

      slide3 =
        slide3
        |> Podium.add_text_box(
          [
            {[{"Click Actions: Slide Jump", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_text_box(
          "This slide demonstrates jumping to a specific slide by reference:",
          x: {1, :inches},
          y: {1.3, :inches},
          width: {11, :inches},
          height: {0.5, :inches},
          font_size: 16
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {3.5, :inches},
          y: {2.5, :inches},
          width: {6, :inches},
          height: {1, :inches},
          text: [
            {[
               {"Jump to Target Slide 1",
                bold: true, font_size: 18, color: "FFFFFF", hyperlink: {:slide, slide1}}
             ], alignment: :center}
          ],
          fill: "ED7D31",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {3.5, :inches},
          y: {4, :inches},
          width: {6, :inches},
          height: {1, :inches},
          text: [
            {[
               {"Jump to Target Slide 2",
                bold: true, font_size: 18, color: "000000", hyperlink: {:slide, slide2}}
             ], alignment: :center}
          ],
          fill: "FFC000",
          word_wrap: false
        )

      prs = Podium.add_slide(prs, slide3)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "click_actions_slide_jump.pptx")
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all slides exist
      assert Map.has_key?(parts, "ppt/slides/slide1.xml")
      assert Map.has_key?(parts, "ppt/slides/slide2.xml")
      assert Map.has_key?(parts, "ppt/slides/slide3.xml")

      # Verify navigation slide contains jump buttons
      slide3_xml = parts["ppt/slides/slide3.xml"]
      assert slide3_xml =~ "Click Actions: Slide Jump"
      assert slide3_xml =~ "Jump to Target Slide 1"
      assert slide3_xml =~ "Jump to Target Slide 2"

      # Verify hyperlinks exist
      assert slide3_xml =~ "a:hlinkClick"

      # Verify relationships exist for slide jumps
      slide3_rels = parts["ppt/slides/_rels/slide3.xml.rels"]
      assert slide3_rels =~ "slide1.xml"
      assert slide3_rels =~ "slide2.xml"
    end
  end

  describe "full advanced features" do
    test "creates a complete presentation with all Tier 3 extras features" do
      prs = Podium.new(title: "Tier 3 Extras Full Demo", author: "Podium Integration Test")

      # Slide 1: Word Wrap
      slide1 = Podium.Slide.new()

      slide1 =
        slide1
        |> Podium.add_text_box(
          [
            {[{"Word Wrap Demo", bold: true, font_size: 28, color: "003366"}], alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_text_box(
          "This text box has word_wrap: true (the default). Long text will wrap to the next line when it reaches the edge of the box.",
          x: {0.5, :inches},
          y: {1.8, :inches},
          width: {5.5, :inches},
          height: {2, :inches},
          font_size: 14,
          word_wrap: true,
          fill: "E8F0FE"
        )
        |> Podium.add_text_box(
          "This text will NOT wrap — it stays on one line regardless of box width",
          x: {7, :inches},
          y: {1.8, :inches},
          width: {5.5, :inches},
          height: {2, :inches},
          font_size: 14,
          word_wrap: false,
          fill: "FFF3E0"
        )

      prs = Podium.add_slide(prs, slide1)

      # Slide 2: Table Sizing
      slide2 = Podium.Slide.new()

      slide2 =
        slide2
        |> Podium.add_text_box(
          [
            {[{"Table Sizing Demo", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_table(
          [
            [
              {[[{"Rank", color: "FFFFFF", bold: true}]],
               fill: "003366", borders: [bottom: "FFFFFF"]},
              {[[{"Description", color: "FFFFFF", bold: true}]],
               fill: "003366", borders: [bottom: "FFFFFF"]},
              {[[{"Score", color: "FFFFFF", bold: true}]],
               fill: "003366", borders: [bottom: "FFFFFF"]}
            ],
            ["1", "Implemented text word wrap", "100"],
            ["2", "Added table sizing", "95"],
            ["3", "Click actions", "90"]
          ],
          x: {1, :inches},
          y: {1.5, :inches},
          width: {11, :inches},
          height: {4, :inches},
          col_widths: [{1.5, :inches}, {7, :inches}, {2.5, :inches}],
          row_heights: [{0.6, :inches}, {0.85, :inches}, {0.85, :inches}, {0.85, :inches}]
        )

      prs = Podium.add_slide(prs, slide2)

      # Slide 3: Navigation buttons
      slide3 = Podium.Slide.new()

      slide3 =
        slide3
        |> Podium.add_text_box(
          [
            {[{"Click Actions: Navigation", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {1, :inches},
          y: {2.2, :inches},
          width: {2, :inches},
          height: {0.7, :inches},
          text: [[{"Next →", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :next_slide}]],
          fill: "4472C4",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {3.5, :inches},
          y: {2.2, :inches},
          width: {2, :inches},
          height: {0.7, :inches},
          text: [
            [{"← Back", bold: true, font_size: 16, color: "FFFFFF", hyperlink: :previous_slide}]
          ],
          fill: "70AD47",
          word_wrap: false
        )

      prs = Podium.add_slide(prs, slide3)

      # Slide 4: Slide Jump
      slide4 = Podium.Slide.new()

      slide4 =
        slide4
        |> Podium.add_text_box(
          [
            {[{"Click Actions: Slide Jump", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.3, :inches},
          width: {12.33, :inches},
          height: {0.7, :inches}
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {3.5, :inches},
          y: {2.5, :inches},
          width: {6, :inches},
          height: {1, :inches},
          text: [
            {[
               {"Jump to Word Wrap slide (Slide 1)",
                bold: true, font_size: 18, color: "FFFFFF", hyperlink: {:slide, slide1}}
             ], alignment: :center}
          ],
          fill: "ED7D31",
          word_wrap: false
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {3.5, :inches},
          y: {4, :inches},
          width: {6, :inches},
          height: {1, :inches},
          text: [
            {[
               {"Jump to Table Sizing (Slide 2)",
                bold: true, font_size: 18, color: "000000", hyperlink: {:slide, slide2}}
             ], alignment: :center}
          ],
          fill: "FFC000",
          word_wrap: false
        )

      prs = Podium.add_slide(prs, slide4)

      # Slide 5: Summary
      slide5 = Podium.Slide.new()

      slide5 =
        slide5
        |> Podium.add_text_box(
          [
            {[{"All Tier 3 Extras Complete", bold: true, font_size: 32, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.5, :inches},
          width: {12.33, :inches},
          height: {0.8, :inches}
        )
        |> Podium.add_text_box(
          [
            {[{"Text Word Wrap", bold: true, font_size: 18, color: "228B22"}], space_after: 4},
            [{"word_wrap: false for wrap=\"none\", default wrap=\"square\"", font_size: 14}],
            {[{"Table Column/Row Sizing", bold: true, font_size: 18, color: "228B22"}],
             space_before: 12, space_after: 4},
            [{"col_widths and row_heights with {value, unit} tuples", font_size: 14}],
            {[{"Click Actions", bold: true, font_size: 18, color: "228B22"}],
             space_before: 12, space_after: 4},
            [
              {"Navigation: :next_slide, :previous_slide, :first_slide, :last_slide, :end_show",
               font_size: 14}
            ],
            [{"Slide jump: {:slide, target_slide} with internal relationships", font_size: 14}]
          ],
          x: {1.5, :inches},
          y: {1.8, :inches},
          width: {10, :inches},
          height: {4.5, :inches}
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {4.5, :inches},
          y: {6.2, :inches},
          width: {4, :inches},
          height: {0.7, :inches},
          text: [
            {[
               {"← Back to Start",
                bold: true, font_size: 16, color: "FFFFFF", hyperlink: :first_slide}
             ], alignment: :center}
          ],
          fill: "70AD47",
          word_wrap: false
        )

      prs = Podium.add_slide(prs, slide5)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "advanced_features_full.pptx")
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify all slides exist
      assert Map.has_key?(parts, "ppt/slides/slide1.xml")
      assert Map.has_key?(parts, "ppt/slides/slide2.xml")
      assert Map.has_key?(parts, "ppt/slides/slide3.xml")
      assert Map.has_key?(parts, "ppt/slides/slide4.xml")
      assert Map.has_key?(parts, "ppt/slides/slide5.xml")

      # Verify slide content
      assert parts["ppt/slides/slide1.xml"] =~ "Word Wrap Demo"
      assert parts["ppt/slides/slide2.xml"] =~ "Table Sizing Demo"
      assert parts["ppt/slides/slide3.xml"] =~ "Click Actions: Navigation"
      assert parts["ppt/slides/slide4.xml"] =~ "Click Actions: Slide Jump"
      assert parts["ppt/slides/slide5.xml"] =~ "All Tier 3 Extras Complete"

      # Verify word wrap attributes
      slide1_xml = parts["ppt/slides/slide1.xml"]
      assert slide1_xml =~ "wrap=\"square\"" or slide1_xml =~ "wrap='square'"
      assert slide1_xml =~ "wrap=\"none\"" or slide1_xml =~ "wrap='none'"

      # Verify table exists
      slide2_xml = parts["ppt/slides/slide2.xml"]
      assert slide2_xml =~ "a:tbl"
      assert slide2_xml =~ "a:gridCol"

      # Verify hyperlinks exist
      slide3_xml = parts["ppt/slides/slide3.xml"]
      assert slide3_xml =~ "a:hlinkClick"
      assert slide3_xml =~ "ppaction://hlinkshowjump"

      # Verify slide jump relationships
      slide4_rels = parts["ppt/slides/_rels/slide4.xml.rels"]
      assert slide4_rels =~ "slide1.xml"
      assert slide4_rels =~ "slide2.xml"

      # Verify content types
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "application/vnd.openxmlformats-officedocument.presentationml.slide+xml"

      # Verify presentation contains all slide references
      assert Map.has_key?(parts, "ppt/presentation.xml")
      pres_xml = parts["ppt/presentation.xml"]
      slide_id_count = length(Regex.scan(~r/<p:sldId /, pres_xml))
      assert slide_id_count == 5
    end
  end
end
