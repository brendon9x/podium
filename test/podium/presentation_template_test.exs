defmodule Podium.PresentationTemplateTest do
  use ExUnit.Case, async: true

  import Podium.Test.PptxHelpers

  @fixture "test/fixtures/skeleton_16x9"

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
      assert map_size(prs.placeholder_positions) > 0

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

    test "ignores the name-based placeholder tables", %{skeleton: skeleton} do
      assert Podium.from_template(skeleton).placeholder_positions == %{}
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
