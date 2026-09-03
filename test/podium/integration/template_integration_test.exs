defmodule Podium.Integration.TemplateIntegrationTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"
  @fixture "test/fixtures/skeleton_16x9"

  describe "rendering into a customer skeleton" do
    setup do
      prs =
        @fixture
        |> PptxHelpers.zip_dir()
        |> Podium.from_template(title: "Skeleton report", author: "Podium")
        |> Podium.set_footer(footer: "Skeleton report", slide_number: true)

      chart_data =
        Podium.Chart.ChartData.new()
        |> Podium.Chart.ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> Podium.Chart.ChartData.add_series("Volume", [4.2, 5.1, 4.8, 6.3])

      cover =
        Podium.Slide.new(1)
        |> Podium.set_placeholder({"ctrTitle", 0}, "Category performance")
        |> Podium.set_placeholder({"subTitle", 7}, "Quarterly review, January 2026")

      slide1 =
        Podium.Slide.new(2)
        |> Podium.set_placeholder({"title", 0}, "Volume grew 4.2%")
        |> Podium.set_notes("Lead with the volume number, then the category context.")

      slide1 =
        Podium.set_chart_placeholder(
          prs,
          slide1,
          {"obj", 14},
          :column_clustered,
          chart_data,
          title: "Volume by quarter"
        )

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
        prs
        |> Podium.add_slide(cover)
        |> Podium.add_slide(slide1)
        |> Podium.add_slide(slide2)

      output_path = Path.join(@output_dir, "skeleton_16x9.pptx")
      assert :ok = Podium.save(prs, output_path)

      %{parts: PptxHelpers.unzip_pptx(output_path)}
    end

    test "fills the layouts' placeholders by type and idx", %{parts: parts} do
      cover = to_string(parts["ppt/slides/slide1.xml"])
      content = to_string(parts["ppt/slides/slide2.xml"])

      assert cover =~ ~s(<p:ph type="ctrTitle"/>)
      assert cover =~ ~s(<p:ph type="subTitle" idx="7"/>)
      assert cover =~ "Category performance"

      assert content =~ ~s(<p:ph type="title"/>)
      assert content =~ "Volume grew 4.2%"
    end

    test "places the chart in the Content layout's own placeholder box", %{parts: parts} do
      content = to_string(parts["ppt/slides/slide2.xml"])

      assert content =~ "<p:graphicFrame"
      assert content =~ ~s(<a:off x="685800" y="1825625"/>)
      assert content =~ ~s(<a:ext cx="10820400" cy="4351338"/>)
    end

    test "emits footer and slide number at the layout's idx values", %{parts: parts} do
      for slide_path <- ["ppt/slides/slide1.xml", "ppt/slides/slide2.xml"] do
        xml = to_string(parts[slide_path])

        assert xml =~ ~s(<p:ph type="ftr" idx="21"/>)
        assert xml =~ ~s(<p:ph type="sldNum" idx="22"/>)
        refute xml =~ ~s(idx="11")
        refute xml =~ ~s(idx="12")
      end
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

    test "lists every slide with relationship ids that exist", %{parts: parts} do
      xml = to_string(parts["ppt/presentation.xml"])
      rels = Podium.OPC.Relationships.parse(to_string(parts["ppt/_rels/presentation.xml.rels"]))
      declared = MapSet.new(rels.rels, &elem(&1, 0))

      entries = Regex.scan(~r/<p:sldId id="(\d+)" r:id="(rId\d+)"\/>/, xml)

      assert [[_, "256", _], [_, "257", _], [_, "258", _]] = entries

      for [_, _, rid] <- entries do
        assert MapSet.member?(declared, rid)
      end
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
