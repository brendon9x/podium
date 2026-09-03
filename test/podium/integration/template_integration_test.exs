defmodule Podium.Integration.TemplateIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"
  @fixture "test/fixtures/skeleton_16x9"

  describe "rendering into a customer skeleton" do
    setup do
      slide1 =
        Podium.Slide.new(2)
        |> Podium.add_text_box("Category performance",
          x: {0.75, :inches},
          y: {0.5, :inches},
          width: {10, :inches},
          height: {1, :inches},
          font_size: 36,
          bold: true
        )
        |> Podium.add_text_box("Volume grew 4.2% against a flat category.",
          x: {0.75, :inches},
          y: {2, :inches},
          width: {10, :inches},
          height: {1, :inches},
          font_size: 20
        )
        |> Podium.set_notes("Lead with the volume number, then the category context.")

      slide2 =
        Podium.Slide.new(3)
        |> Podium.add_text_box("Thank you",
          x: {0.75, :inches},
          y: {2.8, :inches},
          width: {10, :inches},
          height: {1.5, :inches},
          font_size: 44
        )

      prs =
        @fixture
        |> PptxHelpers.zip_dir()
        |> Podium.from_template(title: "Skeleton report", author: "Podium")
        |> Podium.add_slide(slide1)
        |> Podium.add_slide(slide2)

      output_path = Path.join(@output_dir, "skeleton_16x9.pptx")
      assert :ok = Podium.save(prs, output_path)

      %{parts: PptxHelpers.unzip_pptx(output_path)}
    end

    test "keeps the template's slide size and presentation settings", %{parts: parts} do
      xml = to_string(parts["ppt/presentation.xml"])

      assert xml =~ ~s(<p:sldSz cx="12192000" cy="6858000"/>)
      assert xml =~ ~s(<p:notesSz cx="6858000" cy="9144000"/>)
      assert xml =~ ~s(<p:sldMasterId id="2147483648" r:id="rId1"/>)
      assert xml =~ "<p:defaultTextStyle>"
      assert xml =~ ~s(saveSubsetFonts="1")
    end

    test "strips the section list that would reference reissued slide ids", %{parts: parts} do
      xml = to_string(parts["ppt/presentation.xml"])

      refute xml =~ "sectionLst"
      refute xml =~ "521415D9"
      refute xml =~ "<p:extLst>"
    end

    test "lists both slides with relationship ids that exist", %{parts: parts} do
      xml = to_string(parts["ppt/presentation.xml"])
      rels = Podium.OPC.Relationships.parse(to_string(parts["ppt/_rels/presentation.xml.rels"]))
      declared = MapSet.new(rels.rels, &elem(&1, 0))

      entries = Regex.scan(~r/<p:sldId id="(\d+)" r:id="(rId\d+)"\/>/, xml)

      assert [[_, "256", rid1], [_, "257", rid2]] = entries
      assert MapSet.member?(declared, rid1)
      assert MapSet.member?(declared, rid2)
    end

    test "reuses the template's notes master rather than adding one", %{parts: parts} do
      xml = to_string(parts["ppt/presentation.xml"])

      assert length(Regex.scan(~r/<p:notesMasterIdLst>/, xml)) == 1
      assert xml =~ ~s(<p:notesMasterIdLst><p:notesMasterId r:id="rId4"/></p:notesMasterIdLst>)

      notes_masters = Enum.filter(Map.keys(parts), &String.starts_with?(&1, "ppt/notesMasters/"))

      assert Enum.sort(notes_masters) == [
               "ppt/notesMasters/_rels/notesMaster1.xml.rels",
               "ppt/notesMasters/notesMaster1.xml"
             ]

      refute Map.has_key?(parts, "ppt/theme/theme3.xml")

      notes_rels = to_string(parts["ppt/notesSlides/_rels/notesSlide1.xml.rels"])
      assert notes_rels =~ ~s(Target="../notesMasters/notesMaster1.xml")
    end

    test "leaves master and layout coordinates unscaled", %{parts: parts} do
      master = to_string(parts["ppt/slideMasters/slideMaster1.xml"])
      layout = to_string(parts["ppt/slideLayouts/slideLayout2.xml"])

      assert master =~ ~s(<a:off x="685800" y="365125"/>)
      assert master =~ ~s(<a:ext cx="12192000" cy="76200"/>)
      assert layout =~ ~s(<a:off x="685800" y="1825625"/>)
    end

    test "keeps the template's media and every layout", %{parts: parts} do
      assert Map.has_key?(parts, "ppt/media/logo.png")

      for n <- 1..3 do
        assert Map.has_key?(parts, "ppt/slideLayouts/slideLayout#{n}.xml")
        assert Map.has_key?(parts, "ppt/slideLayouts/_rels/slideLayout#{n}.xml.rels")
      end
    end

    test "declares content types for everything it added", %{parts: parts} do
      ct = Podium.OPC.ContentTypes.parse(to_string(parts["[Content_Types].xml"]))
      alias Podium.OPC.Constants

      assert ct.overrides["/ppt/slides/slide1.xml"] == Constants.ct(:slide)
      assert ct.overrides["/ppt/slides/slide2.xml"] == Constants.ct(:slide)
      assert ct.overrides["/ppt/notesSlides/notesSlide1.xml"] == Constants.ct(:notes_slide)
      assert ct.overrides["/ppt/notesMasters/notesMaster1.xml"] == Constants.ct(:notes_master)
      assert ct.overrides["/docProps/core.xml"] == Constants.ct(:core_properties)
      assert ct.overrides["/ppt/presentation.xml"] == Constants.ct(:presentation)
      assert ct.defaults["png"] == Constants.ct(:png)
    end

    test "writes the core properties from the options", %{parts: parts} do
      core = to_string(parts["docProps/core.xml"])

      assert core =~ "Skeleton report"
      assert core =~ "Podium"
    end

    test "leaves no dangling relationships", %{parts: parts} do
      PptxHelpers.assert_rels_resolve(parts)
    end
  end

  describe "the bundled template path" do
    test "also leaves no dangling relationships" do
      slide =
        Podium.Slide.new(:title_content)
        |> Podium.set_placeholder(:title, "Bundled template")
        |> Podium.set_notes("Notes force a notes master to be created.")

      {:ok, binary} =
        Podium.new(title: "Bundled")
        |> Podium.add_slide(slide)
        |> Podium.save_to_memory()

      binary |> PptxHelpers.unzip_pptx_binary() |> PptxHelpers.assert_rels_resolve()
    end
  end
end
