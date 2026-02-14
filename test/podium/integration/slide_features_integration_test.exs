defmodule Podium.Integration.SlideFeaturesIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"
  @fixtures_dir "test/fixtures"

  setup_all do
    File.mkdir_p!(@output_dir)
    :ok
  end

  describe "speaker notes" do
    test "creates slide with speaker notes" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        slide
        |> Podium.add_text_box(
          [
            {[{"Speaker Notes Demo", bold: true, font_size: 28, color: "003366"}],
             alignment: :center},
            {[{"Open Presenter View to see the speaker notes for this slide.", font_size: 18}],
             alignment: :center}
          ],
          x: {1, :inches},
          y: {2, :inches},
          width: {11.33, :inches},
          height: {2, :inches}
        )
        |> Podium.set_notes(
          "These are speaker notes. They are visible in Presenter View but not on the slide itself. Use them for talking points, reminders, or supplementary data."
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "speaker_notes.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify notes slide exists
      assert Map.has_key?(parts, "ppt/notesSlides/notesSlide1.xml")
      notes_xml = parts["ppt/notesSlides/notesSlide1.xml"]

      # Verify notes content
      assert notes_xml =~ "These are speaker notes"
      assert notes_xml =~ "They are visible in Presenter View"
      assert notes_xml =~ "<p:notes"
      assert notes_xml =~ ~s(type="body")

      # Verify notes master was created
      assert Map.has_key?(parts, "ppt/notesMasters/notesMaster1.xml")

      # Verify slide references notes
      assert Map.has_key?(parts, "ppt/slides/_rels/slide1.xml.rels")
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "notesSlide1.xml"
    end
  end

  describe "slide backgrounds" do
    test "creates slide with solid color background" do
      prs = Podium.new()
      slide = Podium.Slide.new(:blank, background: "E8EDF2")

      slide =
        Podium.add_text_box(
          slide,
          [
            {[{"Solid Color Background", bold: true, font_size: 28, color: "003366"}],
             alignment: :center}
          ],
          x: {0.5, :inches},
          y: {0.2, :inches},
          width: {12.33, :inches},
          height: {0.6, :inches}
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "solid_background.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify background XML
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ "<p:bgPr>"
      assert slide_xml =~ ~s(<a:solidFill><a:srgbClr val="E8EDF2"/></a:solidFill>)
      assert slide_xml =~ "Solid Color Background"
    end

    test "creates slide with picture background" do
      image_path = Path.join(@fixtures_dir, "acme.jpg")
      image_binary = File.read!(image_path)

      prs = Podium.new()
      slide = Podium.Slide.new(:blank, background: {:picture, image_binary})

      slide =
        Podium.add_text_box(
          slide,
          [[{"Picture Background", bold: true, font_size: 36, color: "FFFFFF"}]],
          x: {2, :inches},
          y: {2.5, :inches},
          width: {9.33, :inches},
          height: {1.5, :inches},
          alignment: :center,
          fill: "333333"
        )

      prs = Podium.add_slide(prs, slide)

      # Save to disk
      output_path = Path.join(@output_dir, "picture_background.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify background XML
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ "<p:bgPr>"
      assert slide_xml =~ "<a:blipFill"
      assert slide_xml =~ ~s(r:embed=")
      assert slide_xml =~ "<a:stretch>"

      # Verify background image in media
      bg_media =
        parts
        |> Map.keys()
        |> Enum.filter(&String.starts_with?(&1, "ppt/media/bg_image"))

      assert length(bg_media) == 1

      # Verify slide rels include background image
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "../media/bg_image1.jpeg"
    end
  end

  describe "footer, date, and slide number" do
    test "creates presentation with footer, date, and slide number" do
      prs = Podium.new()
      slide1 = Podium.Slide.new()

      slide1 =
        Podium.add_text_box(
          slide1,
          "Slide 1",
          x: {1, :inches},
          y: {3, :inches},
          width: {11.33, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide1)

      # Add second slide to verify footer appears on multiple slides
      slide2 = Podium.Slide.new()

      slide2 =
        Podium.add_text_box(
          slide2,
          "Slide 2",
          x: {1, :inches},
          y: {3, :inches},
          width: {11.33, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide2)

      # Set footer on the presentation
      prs =
        Podium.set_footer(prs,
          footer: "Acme Corp Confidential",
          date: "February 2026",
          slide_number: true
        )

      # Save to disk
      output_path = Path.join(@output_dir, "footer_date_slide_number.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify footer placeholders in slide XML
      slide1_xml = parts["ppt/slides/slide1.xml"]
      assert slide1_xml =~ "Acme Corp Confidential"
      assert slide1_xml =~ "February 2026"
      assert slide1_xml =~ ~s(type="ftr")
      assert slide1_xml =~ ~s(type="dt")
      assert slide1_xml =~ ~s(type="sldNum")

      # Verify footer on second slide
      slide2_xml = parts["ppt/slides/slide2.xml"]
      assert slide2_xml =~ "Acme Corp Confidential"
      assert slide2_xml =~ "February 2026"
      assert slide2_xml =~ ~s(type="ftr")
      assert slide2_xml =~ ~s(type="dt")
      assert slide2_xml =~ ~s(type="sldNum")
    end

    test "footer with only footer text (no date, no slide number)" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(
          slide,
          "Footer Only Demo",
          x: {1, :inches},
          y: {3, :inches},
          width: {11.33, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide)
      prs = Podium.set_footer(prs, footer: "Custom Footer Text")

      # Save to disk
      output_path = Path.join(@output_dir, "footer_only.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify footer placeholder
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "Custom Footer Text"
      assert slide_xml =~ ~s(type="ftr")

      # Verify date and slide number are not present (no text content)
      refute slide_xml =~ "February 2026"
    end

    test "footer with date only" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(
          slide,
          "Date Only Demo",
          x: {1, :inches},
          y: {3, :inches},
          width: {11.33, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide)
      prs = Podium.set_footer(prs, date: "January 1, 2026")

      # Save to disk
      output_path = Path.join(@output_dir, "date_only.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify date placeholder
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "January 1, 2026"
      assert slide_xml =~ ~s(type="dt")
    end

    test "footer with slide number only" do
      prs = Podium.new()
      slide = Podium.Slide.new()

      slide =
        Podium.add_text_box(
          slide,
          "Slide Number Demo",
          x: {1, :inches},
          y: {3, :inches},
          width: {11.33, :inches},
          height: {1, :inches},
          font_size: 32,
          alignment: :center
        )

      prs = Podium.add_slide(prs, slide)
      prs = Podium.set_footer(prs, slide_number: true)

      # Save to disk
      output_path = Path.join(@output_dir, "slide_number_only.pptx")
      assert :ok = Podium.save(prs, output_path)
      assert File.exists?(output_path)

      # Save to memory and verify
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Verify slide number placeholder
      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(type="sldNum")
    end
  end
end
