defmodule Podium.Integration.ShapesConnectorsTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"

  describe "auto shapes gallery" do
    test "creates slide with multiple auto shapes in rows" do
      prs = Podium.new()
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Auto Shapes Gallery")

      # Row 1
      slide =
        slide
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {0.5, :inches},
          y: {1.8, :inches},
          width: {2, :inches},
          height: {1, :inches},
          text: "Rounded Rect",
          fill: "4472C4"
        )
        |> Podium.add_auto_shape(:oval,
          x: {3, :inches},
          y: {1.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          text: "Oval",
          fill: "ED7D31"
        )
        |> Podium.add_auto_shape(:diamond,
          x: {5, :inches},
          y: {1.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          text: "Diamond",
          fill: "A5A5A5"
        )
        |> Podium.add_auto_shape(:right_arrow,
          x: {7, :inches},
          y: {1.8, :inches},
          width: {2.5, :inches},
          height: {1, :inches},
          text: "Arrow",
          fill: "FFC000"
        )
        |> Podium.add_auto_shape(:star_5_point,
          x: {10, :inches},
          y: {1.5, :inches},
          width: {1.8, :inches},
          height: {1.8, :inches},
          fill: "5B9BD5"
        )

      # Row 2
      slide =
        slide
        |> Podium.add_auto_shape(:flowchart_process,
          x: {0.5, :inches},
          y: {3.8, :inches},
          width: {2, :inches},
          height: {1, :inches},
          text: "Process",
          fill: "70AD47"
        )
        |> Podium.add_auto_shape(:flowchart_decision,
          x: {3, :inches},
          y: {3.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          text: "Decision",
          fill: "FF6384"
        )
        |> Podium.add_auto_shape(:heart,
          x: {5, :inches},
          y: {3.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          fill: "FF0000"
        )
        |> Podium.add_auto_shape(:chevron,
          x: {7, :inches},
          y: {3.8, :inches},
          width: {2, :inches},
          height: {1, :inches},
          text: "Chevron",
          fill: "9B59B6"
        )
        |> Podium.add_auto_shape(:hexagon,
          x: {10, :inches},
          y: {3.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          text: "Hex",
          fill: "1ABC9C",
          line: [color: "117864", width: {2, :pt}]
        )

      # Row 3 — shapes without fill (theme-styled)
      slide =
        slide
        |> Podium.add_auto_shape(:isosceles_triangle,
          x: {0.5, :inches},
          y: {5.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches}
        )
        |> Podium.add_auto_shape(:lightning_bolt,
          x: {2.5, :inches},
          y: {5.8, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches}
        )
        |> Podium.add_auto_shape(:cloud,
          x: {4.5, :inches},
          y: {5.8, :inches},
          width: {2, :inches},
          height: {1.2, :inches}
        )
        |> Podium.add_auto_shape(:can,
          x: {7, :inches},
          y: {5.8, :inches},
          width: {1.2, :inches},
          height: {1.5, :inches}
        )
        |> Podium.add_auto_shape(:cross,
          x: {9, :inches},
          y: {5.8, :inches},
          width: {1.2, :inches},
          height: {1.2, :inches},
          rotation: 45
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "shapes_gallery.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify some text content from various shapes
      assert slide_xml =~ "Rounded Rect"
      assert slide_xml =~ "Oval"
      assert slide_xml =~ "Diamond"
      assert slide_xml =~ "Arrow"
      assert slide_xml =~ "Process"
      assert slide_xml =~ "Decision"
      assert slide_xml =~ "Chevron"
      assert slide_xml =~ "Hex"

      # Verify fills are present
      assert slide_xml =~ "4472C4"
      assert slide_xml =~ "ED7D31"
      assert slide_xml =~ "70AD47"
    end
  end

  describe "connectors" do
    test "creates slide with straight, elbow, and curved connectors" do
      prs = Podium.new()
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Connectors")

      # Pair 1: straight connector
      slide =
        slide
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {0.5, :inches},
          y: {2, :inches},
          width: {1.5, :inches},
          height: {0.8, :inches},
          text: "Start",
          fill: "4472C4"
        )
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {4, :inches},
          y: {2, :inches},
          width: {1.5, :inches},
          height: {0.8, :inches},
          text: "End",
          fill: "4472C4"
        )
        |> Podium.add_connector(
          :straight,
          {2, :inches},
          {2.4, :inches},
          {4, :inches},
          {2.4, :inches},
          line: [color: "000000", width: {1.5, :pt}]
        )

      # Pair 2: elbow connector
      slide =
        slide
        |> Podium.add_auto_shape(:oval,
          x: {0.5, :inches},
          y: {3.8, :inches},
          width: {1.5, :inches},
          height: {1, :inches},
          text: "A",
          fill: "ED7D31"
        )
        |> Podium.add_auto_shape(:oval,
          x: {4, :inches},
          y: {4.8, :inches},
          width: {1.5, :inches},
          height: {1, :inches},
          text: "B",
          fill: "ED7D31"
        )
        |> Podium.add_connector(
          :elbow,
          {2, :inches},
          {4.3, :inches},
          {4, :inches},
          {5.3, :inches},
          line: [color: "FF0000", width: {2, :pt}, dash_style: :dash]
        )

      # Pair 3: curved connector
      slide =
        slide
        |> Podium.add_auto_shape(:diamond,
          x: {7, :inches},
          y: {2, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          text: "X",
          fill: "70AD47"
        )
        |> Podium.add_auto_shape(:diamond,
          x: {10, :inches},
          y: {4, :inches},
          width: {1.5, :inches},
          height: {1.5, :inches},
          text: "Y",
          fill: "70AD47"
        )
        |> Podium.add_connector(
          :curved,
          {8.5, :inches},
          {2.75, :inches},
          {10, :inches},
          {4.75, :inches},
          line: [color: "5B9BD5", width: {2.5, :pt}]
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "connectors.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify shape text content
      assert slide_xml =~ "Start"
      assert slide_xml =~ "End"
      assert slide_xml =~ "A"
      assert slide_xml =~ "B"
      assert slide_xml =~ "X"
      assert slide_xml =~ "Y"

      # Verify line colors are present
      assert slide_xml =~ "000000"
      assert slide_xml =~ "FF0000"
      assert slide_xml =~ "5B9BD5"
    end
  end

  describe "text auto-size" do
    test "creates slide with different auto-size modes" do
      prs = Podium.new()
      slide = Podium.Slide.new(:title_only)
      slide = Podium.set_placeholder(slide, :title, "Text Auto-Size")

      # No auto-size (fixed)
      slide =
        slide
        |> Podium.add_text_box(
          [
            [{"auto_size: :none", bold: true, font_size: 14}],
            [
              {"Text stays the same size regardless of box dimensions. Overflow is clipped."}
            ]
          ],
          x: {0.5, :inches},
          y: {2, :inches},
          width: {3.5, :inches},
          height: {1.5, :inches},
          fill: "F2F2F2",
          line: "D9D9D9",
          auto_size: :none
        )

      # Text to fit shape (shrink text)
      slide =
        slide
        |> Podium.add_text_box(
          [
            [{"auto_size: :text_to_fit_shape", bold: true, font_size: 14}],
            [
              {"Text shrinks automatically to fit within the shape boundaries. Useful for variable-length content."}
            ]
          ],
          x: {4.5, :inches},
          y: {2, :inches},
          width: {3.5, :inches},
          height: {1.5, :inches},
          fill: "E2EFDA",
          line: "A9D18E",
          auto_size: :text_to_fit_shape
        )

      # Shape to fit text (grow shape)
      slide =
        slide
        |> Podium.add_text_box(
          [
            [{"auto_size: :shape_to_fit_text", bold: true, font_size: 14}],
            [
              {"The shape grows or shrinks to fit the text content. The box height adjusts automatically."}
            ]
          ],
          x: {8.5, :inches},
          y: {2, :inches},
          width: {3.5, :inches},
          height: {1.5, :inches},
          fill: "DAEEF3",
          line: "9DC3E6",
          auto_size: :shape_to_fit_text
        )

      # Auto shape with auto-size
      slide =
        slide
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {2, :inches},
          y: {4.5, :inches},
          width: {8, :inches},
          height: {1.5, :inches},
          text: "Auto shape with :text_to_fit_shape — text shrinks to fit the rounded rectangle",
          fill: "4472C4",
          font_size: 20,
          auto_size: :text_to_fit_shape
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "text_auto_size.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]

      # Verify text content exists
      assert slide_xml =~ "auto_size: :none"
      assert slide_xml =~ "auto_size: :text_to_fit_shape"
      assert slide_xml =~ "auto_size: :shape_to_fit_text"
      assert slide_xml =~ "text shrinks to fit the rounded rectangle"

      # Verify different bodyPr attributes for auto-size modes
      # none: no special attributes
      # text_to_fit_shape: normAutofit
      # shape_to_fit_text: spAutoFit
      assert slide_xml =~ "normAutofit"
      assert slide_xml =~ "spAutoFit"
    end
  end
end
