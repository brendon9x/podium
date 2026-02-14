defmodule PodiumTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "new/1" do
    test "creates a presentation with default 16:9 dimensions" do
      prs = Podium.new()
      assert %Podium.Presentation{} = prs
      assert prs.slides == []
      assert prs.slide_width == 12_192_000
      assert prs.slide_height == 6_858_000
    end

    test "accepts custom slide dimensions" do
      prs = Podium.new(slide_width: {10, :inches}, slide_height: {7.5, :inches})
      assert prs.slide_width == 9_144_000
      assert prs.slide_height == 6_858_000
    end

    test "dimensions appear in presentation XML" do
      prs =
        Podium.new()
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      pres_xml = parts["ppt/presentation.xml"]

      assert pres_xml =~ ~s(cx="12192000")
      assert pres_xml =~ ~s(cy="6858000")
    end

    test "4:3 dimensions in presentation XML" do
      prs =
        Podium.new(slide_width: 9_144_000, slide_height: 6_858_000)
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      pres_xml = parts["ppt/presentation.xml"]

      assert pres_xml =~ ~s(cx="9144000")
      assert pres_xml =~ ~s(cy="6858000")
    end
  end

  describe "add_slide/2" do
    test "adds a slide to the presentation" do
      slide = Podium.Slide.new()
      prs = Podium.new() |> Podium.add_slide(slide)

      assert length(prs.slides) == 1
    end

    test "adds multiple slides" do
      slide1 = Podium.Slide.new()
      slide2 = Podium.Slide.new()

      prs =
        Podium.new()
        |> Podium.add_slide(slide1)
        |> Podium.add_slide(slide2)

      assert length(prs.slides) == 2
    end
  end

  describe "save/2" do
    test "saves an empty presentation (no added slides)" do
      prs = Podium.new()
      tmp_path = Path.join(System.tmp_dir!(), "podium_empty_test.pptx")
      on_exit(fn -> File.rm(tmp_path) end)

      assert :ok = Podium.save(prs, tmp_path)

      parts = PptxHelpers.unzip_pptx(tmp_path)
      assert Map.has_key?(parts, "ppt/presentation.xml")
      assert Map.has_key?(parts, "[Content_Types].xml")
    end

    test "saves presentation with blank slides" do
      prs =
        Podium.new()
        |> Podium.add_slide(Podium.Slide.new())
        |> Podium.add_slide(Podium.Slide.new())
        |> Podium.add_slide(Podium.Slide.new())

      tmp_path = Path.join(System.tmp_dir!(), "podium_slides_test.pptx")
      on_exit(fn -> File.rm(tmp_path) end)

      assert :ok = Podium.save(prs, tmp_path)

      parts = PptxHelpers.unzip_pptx(tmp_path)

      # Verify slides exist
      assert Map.has_key?(parts, "ppt/slides/slide1.xml")
      assert Map.has_key?(parts, "ppt/slides/slide2.xml")
      assert Map.has_key?(parts, "ppt/slides/slide3.xml")

      # Verify slide relationships exist
      assert Map.has_key?(parts, "ppt/slides/_rels/slide1.xml.rels")
      assert Map.has_key?(parts, "ppt/slides/_rels/slide2.xml.rels")
      assert Map.has_key?(parts, "ppt/slides/_rels/slide3.xml.rels")

      # Verify presentation.xml references slides
      pres_xml = parts["ppt/presentation.xml"]
      assert pres_xml =~ "sldIdLst"
      assert pres_xml =~ "sldId"

      # Verify content types include slides
      ct_xml = parts["[Content_Types].xml"]
      assert ct_xml =~ "/ppt/slides/slide1.xml"
      assert ct_xml =~ "/ppt/slides/slide2.xml"
      assert ct_xml =~ "/ppt/slides/slide3.xml"
    end
  end

  describe "save_to_memory/1" do
    test "produces a valid zip binary" do
      prs =
        Podium.new()
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      assert Map.has_key?(parts, "ppt/slides/slide1.xml")
    end
  end

  describe "put_slide/2" do
    test "replaces a slide in the presentation" do
      slide = Podium.Slide.new()
      prs = Podium.new() |> Podium.add_slide(slide)

      updated_slide = %{slide | layout_index: 1}
      prs = Podium.put_slide(prs, updated_slide)

      assert hd(prs.slides).layout_index == 1
    end
  end
end
