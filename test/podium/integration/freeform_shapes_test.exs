defmodule Podium.Integration.FreeformShapesTest do
  use ExUnit.Case, async: true

  alias Podium.Freeform
  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"

  describe "simple closed triangle with fill" do
    test "creates a closed triangle shape with fill color" do
      prs = Podium.new(title: "Freeform Shapes Demo", author: "Podium")
      {prs, slide} = Podium.add_slide(prs, layout: :title_only)
      slide = Podium.set_placeholder(slide, :title, "Simple Triangle")

      slide =
        Freeform.new({3.67, :inches}, {5.5, :inches})
        |> Freeform.line_to({6.67, :inches}, {1.5, :inches})
        |> Freeform.line_to({9.67, :inches}, {5.5, :inches})
        |> Freeform.close()
        |> Podium.add_freeform(slide, fill: "4472C4")

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "freeform_simple_triangle.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide XML contains freeform shape
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "p:sp"
      assert slide_xml =~ "a:custGeom"
      assert slide_xml =~ "a:pathLst"
      assert slide_xml =~ "a:path"
      assert slide_xml =~ "a:moveTo"
      assert slide_xml =~ "a:lnTo"
      assert slide_xml =~ "a:close"

      # Verify fill color
      assert slide_xml =~ "4472C4"

      # Verify title
      assert slide_xml =~ "Simple Triangle"
    end
  end

  describe "star shape using line segments" do
    test "creates a star shape with multiple line segments" do
      prs = Podium.new(title: "Freeform Shapes Demo", author: "Podium")
      {prs, slide} = Podium.add_slide(prs, layout: :title_only)
      slide = Podium.set_placeholder(slide, :title, "Star Shape")

      slide =
        Freeform.new({6.67, :inches}, {1.5, :inches})
        |> Freeform.add_line_segments(
          [
            {{4.77, :inches}, {5.5, :inches}},
            {{10.17, :inches}, {3, :inches}},
            {{3.17, :inches}, {3, :inches}},
            {{8.57, :inches}, {5.5, :inches}}
          ],
          close: true
        )
        |> Podium.add_freeform(slide, fill: "FFD700", line: "CC9900")

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "freeform_star_shape.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide XML contains freeform shape
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "a:custGeom"
      assert slide_xml =~ "a:pathLst"
      assert slide_xml =~ "a:moveTo"
      assert slide_xml =~ "a:lnTo"
      assert slide_xml =~ "a:close"

      # Verify fill and line colors
      assert slide_xml =~ "FFD700"
      assert slide_xml =~ "CC9900"

      # Verify title
      assert slide_xml =~ "Star Shape"
    end
  end

  describe "multiple contours (square with cutout)" do
    test "creates a shape with multiple contours" do
      prs = Podium.new(title: "Freeform Shapes Demo", author: "Podium")
      {prs, slide} = Podium.add_slide(prs, layout: :title_only)
      slide = Podium.set_placeholder(slide, :title, "Multiple Contours")

      slide =
        Freeform.new({3.67, :inches}, {1.5, :inches})
        |> Freeform.add_line_segments([
          {{9.67, :inches}, {1.5, :inches}},
          {{9.67, :inches}, {5.5, :inches}},
          {{3.67, :inches}, {5.5, :inches}}
        ])
        |> Freeform.close()
        |> Freeform.move_to({5.17, :inches}, {2.5, :inches})
        |> Freeform.add_line_segments([
          {{8.17, :inches}, {2.5, :inches}},
          {{8.17, :inches}, {4.5, :inches}},
          {{5.17, :inches}, {4.5, :inches}}
        ])
        |> Freeform.close()
        |> Podium.add_freeform(slide, fill: "70AD47")

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "freeform_multiple_contours.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide XML contains freeform shape with multiple paths
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "a:custGeom"
      assert slide_xml =~ "a:pathLst"

      # Should have multiple moveTo elements for multiple contours
      moveto_count = length(Regex.scan(~r/<a:moveTo/, slide_xml))
      assert moveto_count >= 2

      # Should have multiple close elements
      close_count = length(Regex.scan(~r/<a:close/, slide_xml))
      assert close_count >= 2

      # Verify fill color
      assert slide_xml =~ "70AD47"

      # Verify title
      assert slide_xml =~ "Multiple Contours"
    end
  end

  describe "shapes using custom scale and origin" do
    test "creates shapes with custom scale factor and origin positioning" do
      prs = Podium.new(title: "Freeform Shapes Demo", author: "Podium")
      {prs, slide} = Podium.add_slide(prs, layout: :title_only)
      slide = Podium.set_placeholder(slide, :title, "Custom Scale & Origin")

      # Triangle using scale factor (1 unit = 0.01 inches)
      slide =
        Freeform.new(0, 0, scale: 9144)
        |> Freeform.line_to(300, 0)
        |> Freeform.line_to(150, 260)
        |> Freeform.close()
        |> Podium.add_freeform(slide,
          origin_x: {2.5, :inches},
          origin_y: {2, :inches},
          fill: "ED7D31"
        )

      # Diamond using scale factor
      slide =
        Freeform.new(100, 0, scale: 9144)
        |> Freeform.line_to(200, 100)
        |> Freeform.line_to(100, 200)
        |> Freeform.line_to(0, 100)
        |> Freeform.close()
        |> Podium.add_freeform(slide,
          origin_x: {8.5, :inches},
          origin_y: {2, :inches},
          fill: "5B9BD5"
        )

      prs = Podium.put_slide(prs, slide)

      # Save to disk for manual inspection
      output_path = Path.join(@output_dir, "freeform_custom_scale_origin.pptx")
      File.mkdir_p!(@output_dir)
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory for XML assertions
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide XML contains both freeform shapes
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "a:custGeom"
      assert slide_xml =~ "a:pathLst"

      # Should have two shapes on the slide
      shape_count = length(Regex.scan(~r/<p:sp/, slide_xml))
      assert shape_count >= 2

      # Verify both fill colors are present
      assert slide_xml =~ "ED7D31"
      assert slide_xml =~ "5B9BD5"

      # Verify title (& is encoded as &amp; in XML)
      assert slide_xml =~ "Custom Scale &amp; Origin"
    end
  end
end
