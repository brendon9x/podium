defmodule Podium.NotesTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "slide notes" do
    test "notes text appears in notesSlide XML" do
      slide =
        Podium.Slide.new()
        |> Podium.set_notes("Speaker notes text here")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      assert Map.has_key?(parts, "ppt/notesSlides/notesSlide1.xml")
      notes_xml = parts["ppt/notesSlides/notesSlide1.xml"]
      assert notes_xml =~ "Speaker notes text here"
      assert notes_xml =~ "<p:notes"
      assert notes_xml =~ ~s(type="body")
      assert notes_xml =~ ~s(type="sldImg")
    end

    test "notes master created once" do
      slide1 =
        Podium.Slide.new()
        |> Podium.set_notes("Notes for slide 1")

      slide2 =
        Podium.Slide.new()
        |> Podium.set_notes("Notes for slide 2")

      prs =
        Podium.new()
        |> Podium.add_slide(slide1)
        |> Podium.add_slide(slide2)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Notes master exists
      assert Map.has_key?(parts, "ppt/notesMasters/notesMaster1.xml")
      assert Map.has_key?(parts, "ppt/notesMasters/_rels/notesMaster1.xml.rels")

      # Both notesSlides exist
      assert Map.has_key?(parts, "ppt/notesSlides/notesSlide1.xml")
      assert Map.has_key?(parts, "ppt/notesSlides/notesSlide2.xml")

      # Only one notesMaster XML + one notesMaster rels
      master_xml_count =
        parts
        |> Map.keys()
        |> Enum.count(&(&1 == "ppt/notesMasters/notesMaster1.xml"))

      assert master_xml_count == 1
    end

    test "slide without notes has no notesSlide part" do
      prs =
        Podium.new()
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      refute Map.has_key?(parts, "ppt/notesSlides/notesSlide1.xml")
      refute Map.has_key?(parts, "ppt/notesMasters/notesMaster1.xml")
    end

    test "notes text is XML-escaped" do
      slide =
        Podium.Slide.new()
        |> Podium.set_notes("Use <b> tags & \"quotes\"")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      notes_xml = parts["ppt/notesSlides/notesSlide1.xml"]
      assert notes_xml =~ "Use &lt;b&gt; tags &amp; &quot;quotes&quot;"
    end

    test "notesSlide has rels to slide and notesMaster" do
      slide =
        Podium.Slide.new()
        |> Podium.set_notes("Some notes")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      notes_rels = parts["ppt/notesSlides/_rels/notesSlide1.xml.rels"]
      assert notes_rels =~ "../slides/slide1.xml"
      assert notes_rels =~ "../notesMasters/notesMaster1.xml"
    end

    test "slide rels contains notesSlide relationship" do
      slide =
        Podium.Slide.new()
        |> Podium.set_notes("Some notes")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert slide_rels =~ "../notesSlides/notesSlide1.xml"
    end

    test "content types include notesSlide and notesMaster" do
      slide =
        Podium.Slide.new()
        |> Podium.set_notes("Some notes")

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "notesSlide+xml"
      assert ct_xml =~ "notesMaster+xml"
    end
  end
end
