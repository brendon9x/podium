defmodule Podium.PresentationTemplateTest do
  use ExUnit.Case, async: true

  import Podium.Test.PptxHelpers

  @fixture "test/fixtures/skeleton_16x9"

  # Minimal valid PNG (1x1 pixel, RGBA)
  @png_binary <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
                0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
                0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
                0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27,
                0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
                0x82>>

  setup_all do
    %{skeleton: zip_dir(@fixture)}
  end

  describe "new/1 (bundled template)" do
    test "still produces a 16:9 presentation with scaled layouts" do
      prs = Podium.new()

      assert prs.template == :bundled
      assert prs.template_width == 9_144_000
      assert prs.slide_width == 12_192_000
      assert prs.slide_height == 6_858_000
      assert prs.notes_master_created == false
      assert map_size(prs.template_info.layouts) == 11

      parts =
        prs
        |> Podium.add_slide(Podium.Slide.new(:title_content))
        |> Podium.save_to_memory()
        |> then(fn {:ok, binary} -> unzip_pptx_binary(binary) end)

      pres_xml = to_string(parts["ppt/presentation.xml"])
      assert pres_xml =~ ~s(<p:sldSz cx="12192000" cy="6858000"/>)
      refute pres_xml =~ "screen4x3"

      # The 4:3 master's title starts at 457200 EMU, scaled by 12192000/9144000
      master = to_string(parts["ppt/slideMasters/slideMaster1.xml"])
      assert master =~ ~s(<a:off x="609600" y="274638"/>)

      assert_rels_resolve(parts)
    end

    test "keeps the same part set as the template plus the slide" do
      {:ok, template_parts} = Podium.OPC.Package.read_default_template()

      {:ok, binary} =
        Podium.new()
        |> Podium.add_slide(Podium.Slide.new(:blank))
        |> Podium.save_to_memory()

      parts = unzip_pptx_binary(binary)

      assert file_list(parts) --
               file_list(template_parts) == [
               "ppt/slides/_rels/slide1.xml.rels",
               "ppt/slides/slide1.xml"
             ]

      assert file_list(template_parts) -- file_list(parts) == []
    end
  end

  describe "from_template/2" do
    test "reads the slide size from the template", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      assert prs.template == :custom
      assert prs.template_width == 12_192_000
      assert prs.slide_width == 12_192_000
      assert prs.slide_height == 6_858_000
    end

    test "inspects the template's own layouts", %{skeleton: skeleton} do
      template = Podium.from_template(skeleton).template_info

      assert Enum.sort(Map.keys(template.layouts)) == [1, 2, 3]
      assert template.layouts[1].name == "Cover"
      assert template.layouts[2].name == "Content"
      assert template.layouts[3].name == "Blank"
    end

    test "detects the template's notes master", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      assert prs.notes_master_created
      assert prs.notes_master_rid == "rId4"
      assert prs.notes_master_partname == "ppt/notesMasters/notesMaster1.xml"
    end

    test "accepts a filesystem path", %{skeleton: skeleton} do
      path =
        Path.join(System.tmp_dir!(), "podium_skeleton_#{System.unique_integer([:positive])}.pptx")

      File.write!(path, skeleton)
      on_exit(fn -> File.rm(path) end)

      assert Podium.from_template(path).slide_width == 12_192_000
    end

    test "sets core properties from options", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton, title: "Quarterly review", author: "Podium")

      assert prs.core_properties.title == "Quarterly review"
      assert prs.core_properties.author == "Podium"
    end

    test "raises when the source cannot be read" do
      assert_raise ArgumentError, ~r/could not read template package/, fn ->
        Podium.from_template("test/fixtures/no_such_file.pptx")
      end
    end

    test "raises when the bytes are not a zip" do
      assert_raise ArgumentError, ~r/could not read template package/, fn ->
        Podium.from_template("PK not really a zip at all")
      end
    end

    test "raises when the package has no presentation part" do
      binary = zip_parts([{"[Content_Types].xml", "<Types/>"}])

      assert_raise ArgumentError, ~r/missing ppt\/presentation\.xml/, fn ->
        Podium.from_template(binary)
      end
    end

    test "raises when the template contains a slide part", %{skeleton: skeleton} do
      binary =
        skeleton
        |> unzip_pptx_binary()
        |> Map.put("ppt/slides/slide1.xml", "<p:sld/>")
        |> Enum.to_list()
        |> zip_parts()

      assert_raise ArgumentError, ~r|ppt/slides/slide1.xml|, fn ->
        Podium.from_template(binary)
      end
    end

    test "raises when the template has no slide master", %{skeleton: skeleton} do
      parts = unzip_pptx_binary(skeleton)

      rels =
        parts["ppt/_rels/presentation.xml.rels"]
        |> to_string()
        |> String.replace(~r|<Relationship Id="rId1"[^>]*/>|, "")

      binary =
        parts |> Map.put("ppt/_rels/presentation.xml.rels", rels) |> Enum.to_list() |> zip_parts()

      assert_raise ArgumentError, ~r/no slide master/, fn ->
        Podium.from_template(binary)
      end
    end

    test "raises when the presentation relates to a slide", %{skeleton: skeleton} do
      parts = unzip_pptx_binary(skeleton)

      rels =
        parts["ppt/_rels/presentation.xml.rels"]
        |> to_string()
        |> String.replace(
          "</Relationships>",
          ~s(<Relationship Id="rId20" Type="#{Podium.OPC.Constants.rt(:slide)}" Target="slides/slide1.xml"/></Relationships>)
        )

      binary =
        parts |> Map.put("ppt/_rels/presentation.xml.rels", rels) |> Enum.to_list() |> zip_parts()

      assert_raise ArgumentError, ~r/slide relationship/, fn ->
        Podium.from_template(binary)
      end
    end
  end

  describe "add_slide/2 with a custom template" do
    test "accepts a layout the template has", %{skeleton: skeleton} do
      prs =
        skeleton
        |> Podium.from_template()
        |> Podium.add_slide(Podium.Slide.new(3))

      assert length(prs.slides) == 1
    end

    test "raises for a layout the template does not have", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      assert_raise ArgumentError, ~r|ppt/slideLayouts/slideLayout9\.xml|, fn ->
        Podium.add_slide(prs, Podium.Slide.new(9))
      end
    end
  end

  describe "add_slide/2 placeholder validation" do
    test "accepts a placeholder the layout defines", %{skeleton: skeleton} do
      slide =
        Podium.Slide.new(2)
        |> Podium.set_placeholder({"title", 0}, "Category performance")
        |> Podium.set_placeholder({"obj", 14}, "Volume grew 4.2%")

      prs = skeleton |> Podium.from_template() |> Podium.add_slide(slide)

      assert length(prs.slides) == 1
    end

    test "raises for an idx the layout does not have", %{skeleton: skeleton} do
      slide = Podium.set_placeholder(Podium.Slide.new(2), {"obj", 1}, "Nope")

      assert_raise ArgumentError, ~r/layout 2 has no placeholder with idx 1/, fn ->
        Podium.add_slide(Podium.from_template(skeleton), slide)
      end
    end

    test "raises when the idx exists but the type differs", %{skeleton: skeleton} do
      slide = Podium.set_picture_placeholder(Podium.Slide.new(2), {"pic", 14}, @png_binary)

      assert_raise ArgumentError, ~r/idx 14 has type "obj", not "pic"/, fn ->
        Podium.add_slide(Podium.from_template(skeleton), slide)
      end
    end

    test "accepts a picture dropped into a content placeholder", %{skeleton: skeleton} do
      slide = Podium.set_picture_placeholder(Podium.Slide.new(2), {"obj", 14}, @png_binary)

      prs = skeleton |> Podium.from_template() |> Podium.add_slide(slide)

      assert length(prs.slides) == 1
    end

    test "a bundled name table placeholder still validates on the bundled template" do
      slide =
        Podium.Slide.new(:title_content)
        |> Podium.set_placeholder(:title, "Title")
        |> Podium.set_placeholder(:content, "Content")

      assert length(Podium.add_slide(Podium.new(), slide).slides) == 1
    end
  end

  describe "{type, idx} charts and tables on a custom template" do
    test "positions a chart at the layout's own box, unscaled", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      data =
        Podium.Chart.ChartData.new()
        |> Podium.Chart.ChartData.add_categories(["a", "b"])
        |> Podium.Chart.ChartData.add_series("S1", [1, 2])

      slide =
        Podium.set_chart_placeholder(
          prs,
          Podium.Slide.new(2),
          {"obj", 14},
          :column_clustered,
          data
        )

      {:ok, binary} = prs |> Podium.add_slide(slide) |> Podium.save_to_memory()
      slide_xml = to_string(unzip_pptx_binary(binary)["ppt/slides/slide1.xml"])

      assert slide_xml =~ ~s(<a:off x="685800" y="1825625"/>)
      assert slide_xml =~ ~s(<a:ext cx="10820400" cy="4351338"/>)
    end

    test "positions a table at the layout's own box", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      slide =
        Podium.set_table_placeholder(prs, Podium.Slide.new(2), {"obj", 14}, [["A", "B"]])

      {:ok, binary} = prs |> Podium.add_slide(slide) |> Podium.save_to_memory()
      slide_xml = to_string(unzip_pptx_binary(binary)["ppt/slides/slide1.xml"])

      assert slide_xml =~ ~s(<a:off x="685800" y="1825625"/>)
    end

    test "raises for a placeholder the layout does not have", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      assert_raise ArgumentError, ~r/layout 2 has no placeholder \{"obj", 3\}/, fn ->
        Podium.set_table_placeholder(prs, Podium.Slide.new(2), {"obj", 3}, [["A"]])
      end
    end

    test "raises for a placeholder that is chrome rather than content",
         %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      assert_raise ArgumentError, ~r/only content placeholders accept charts\/tables/, fn ->
        Podium.set_table_placeholder(prs, Podium.Slide.new(2), {"title", 0}, [["A"]])
      end
    end
  end

  describe "footer chrome follows the layout" do
    test "uses the layout's own idx values", %{skeleton: skeleton} do
      {:ok, binary} =
        skeleton
        |> Podium.from_template()
        |> Podium.set_footer(footer: "Confidential", date: "Jan 2026", slide_number: true)
        |> Podium.add_slide(Podium.Slide.new(2))
        |> Podium.save_to_memory()

      slide_xml = to_string(unzip_pptx_binary(binary)["ppt/slides/slide1.xml"])

      assert slide_xml =~ ~s(<p:ph type="ftr" idx="21"/>)
      assert slide_xml =~ ~s(<p:ph type="dt" idx="20"/>)
      assert slide_xml =~ ~s(<p:ph type="sldNum" idx="22"/>)
    end

    test "emits nothing for chrome the layout does not define", %{skeleton: skeleton} do
      # Strip every placeholder shape from the Blank layout.
      parts = unzip_pptx_binary(skeleton)

      stripped =
        parts["ppt/slideLayouts/slideLayout3.xml"]
        |> to_string()
        |> String.replace(~r|<p:sp>.*</p:sp>|s, "")

      binary =
        parts
        |> Map.put("ppt/slideLayouts/slideLayout3.xml", stripped)
        |> Enum.to_list()
        |> zip_parts()

      {:ok, output} =
        binary
        |> Podium.from_template()
        |> Podium.set_footer(footer: "Confidential", slide_number: true)
        |> Podium.add_slide(Podium.Slide.new(3))
        |> Podium.save_to_memory()

      slide_xml = to_string(unzip_pptx_binary(output)["ppt/slides/slide1.xml"])

      refute slide_xml =~ ~s(type="ftr")
      refute slide_xml =~ ~s(type="sldNum")
      refute slide_xml =~ "Confidential"
    end
  end

  describe "name-based placeholders with a custom template" do
    test "set_chart_placeholder/6 raises", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)
      data = Podium.Chart.ChartData.new() |> Podium.Chart.ChartData.add_categories(["a"])

      assert_raise ArgumentError, ~r/set_chart_placeholder\/6/, fn ->
        Podium.set_chart_placeholder(prs, Podium.Slide.new(2), :content, :column_clustered, data)
      end
    end

    test "set_table_placeholder/5 raises", %{skeleton: skeleton} do
      prs = Podium.from_template(skeleton)

      assert_raise ArgumentError, ~r/set_table_placeholder\/5/, fn ->
        Podium.set_table_placeholder(prs, Podium.Slide.new(2), :content, [["a"]])
      end
    end
  end

  defp zip_parts(parts) do
    entries = Enum.map(parts, fn {name, data} -> {to_charlist(name), data} end)
    {:ok, {_name, binary}} = :zip.create(~c"t.pptx", entries, [:memory])
    binary
  end
end
