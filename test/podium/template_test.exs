defmodule Podium.TemplateTest do
  use ExUnit.Case, async: true

  alias Podium.Template
  alias Podium.Test.PptxHelpers

  @fixture "test/fixtures/skeleton_16x9"

  setup_all do
    %{skeleton: PptxHelpers.zip_dir(@fixture)}
  end

  defp placeholder(template, layout_index, ref) do
    Template.placeholder(template, layout_index, ref)
  end

  describe "inspect/1 on the bundled template" do
    setup do
      {:ok, parts} = Podium.OPC.Package.read_default_template()
      %{template: Template.inspect(parts)}
    end

    test "reports the slide size and the single master", %{template: template} do
      assert template.slide_size == {9_144_000, 6_858_000}
      assert Map.keys(template.masters) == [1]
    end

    test "reports all 11 layouts with their names and types", %{template: template} do
      assert map_size(template.layouts) == 11

      assert template.layouts[1].name == "Title Slide"
      assert template.layouts[1].type == "title"
      assert template.layouts[2].name == "Title and Content"
      assert template.layouts[2].type == "obj"
      assert template.layouts[7].name == "Blank"
      assert template.layouts[7].type == "blank"
    end

    test "every layout resolves to master 1", %{template: template} do
      for {_index, layout} <- template.layouts do
        assert layout.master_index == 1
      end
    end

    test "layout 1's ctrTitle has idx 0 and its own box", %{template: template} do
      ph = placeholder(template, 1, {"ctrTitle", 0})

      assert ph.name == "Title 1"
      assert ph.box == %{x: 685_800, y: 2_130_425, w: 7_772_400, h: 1_470_025}
    end

    test "layout 2's title inherits the master title box", %{template: template} do
      master_title = Enum.find(template.masters[1].placeholders, &(&1.type == "title"))
      ph = placeholder(template, 2, {"title", 0})

      assert ph.box == master_title.box
      assert ph.box == %{x: 457_200, y: 274_638, w: 8_229_600, h: 1_143_000}
    end

    test "layout 2's content placeholder is {obj, 1} and inherits the master body box",
         %{template: template} do
      ph = placeholder(template, 2, {"obj", 1})

      assert ph.type == "obj"
      assert ph.box == %{x: 457_200, y: 1_600_200, w: 8_229_600, h: 4_525_963}
    end

    test "chrome inherits from the master placeholder of the same type", %{template: template} do
      # The layouts carry dt/ftr/sldNum at 10/11/12; the master at 2/3/4.
      assert placeholder(template, 7, {"dt", 10}).box ==
               %{x: 457_200, y: 6_356_350, w: 2_133_600, h: 365_125}

      assert placeholder(template, 7, {"ftr", 11}).box ==
               %{x: 3_124_200, y: 6_356_350, w: 2_895_600, h: 365_125}

      assert placeholder(template, 7, {"sldNum", 12}).box ==
               %{x: 6_553_200, y: 6_356_350, w: 2_133_600, h: 365_125}
    end
  end

  describe "inspect/1 on a template of its own" do
    setup %{skeleton: skeleton} do
      %{template: Template.inspect(skeleton)}
    end

    test "reports the 16:9 slide size", %{template: template} do
      assert template.slide_size == {12_192_000, 6_858_000}
    end

    test "reports the three named layouts", %{template: template} do
      assert Enum.sort(Map.keys(template.layouts)) == [1, 2, 3]
      assert template.layouts[1].name == "Cover"
      assert template.layouts[2].name == "Content"
      assert template.layouts[3].name == "Blank"
      assert template.layouts[3].type == "blank"
    end

    test "the Content layout's {obj, 14} carries its own box", %{template: template} do
      ph = placeholder(template, 2, {"obj", 14})

      assert ph.name == "Content Placeholder 2"
      assert ph.box == %{x: 685_800, y: 1_825_625, w: 10_820_400, h: 4_351_338}
    end

    test "the Cover layout's subTitle idx 7 inherits the master body box",
         %{template: template} do
      master_body = Enum.find(template.masters[1].placeholders, &(&1.type == "body"))

      assert placeholder(template, 1, {"subTitle", 7}).box ==
               %{x: 914_400, y: 3_886_200, w: 8_382_000, h: 1_143_000}

      # The Content layout's title has no box of its own, so it does inherit.
      assert placeholder(template, 2, {"title", 0}).box ==
               Enum.find(template.masters[1].placeholders, &(&1.type == "title")).box

      refute master_body.box == nil
    end

    test "every layout lists dt, ftr and sldNum at 20, 21 and 22 inheriting the master box",
         %{template: template} do
      for layout_index <- 1..3, {type, idx} <- [{"dt", 20}, {"ftr", 21}, {"sldNum", 22}] do
        ph = placeholder(template, layout_index, {type, idx})
        master_ph = Enum.find(template.masters[1].placeholders, &(&1.type == type))

        assert ph != nil, "layout #{layout_index} has no #{type} placeholder"
        assert ph.box == master_ph.box
      end
    end

    test "skips shapes that are not placeholders", %{template: template} do
      # The master carries an accent bar and a logo picture, neither a placeholder.
      types = Enum.map(template.masters[1].placeholders, & &1.type)
      assert types == ["title", "body", "dt", "ftr", "sldNum"]
    end
  end

  describe "inspect/1 sources" do
    test "reads from a filesystem path", %{skeleton: skeleton} do
      path =
        Path.join(System.tmp_dir!(), "podium_inspect_#{System.unique_integer([:positive])}.pptx")

      File.write!(path, skeleton)
      on_exit(fn -> File.rm(path) end)

      assert Template.inspect(path).slide_size == {12_192_000, 6_858_000}
    end

    test "reads from pptx bytes", %{skeleton: skeleton} do
      assert Template.inspect(skeleton).slide_size == {12_192_000, 6_858_000}
    end

    test "raises when the source cannot be read" do
      assert_raise ArgumentError, ~r/could not read template package/, fn ->
        Template.inspect("test/fixtures/no_such_template.pptx")
      end
    end
  end

  describe "bundled/0" do
    test "returns the same inspection every time" do
      assert Template.bundled() == Template.bundled()
      assert map_size(Template.bundled().layouts) == 11
    end
  end

  describe "placeholder/3" do
    setup %{skeleton: skeleton} do
      %{template: Template.inspect(skeleton)}
    end

    test "finds a placeholder by type and idx", %{template: template} do
      assert placeholder(template, 2, {"obj", 14}).idx == 14
    end

    test "normalises a nil type to obj and a nil idx to 0", %{template: template} do
      assert placeholder(template, 2, {nil, 14}).type == "obj"
      assert placeholder(template, 2, %{type: "title", idx: nil}).type == "title"
    end

    test "returns nil when the layout has no placeholder with that idx",
         %{template: template} do
      assert placeholder(template, 2, {"obj", 99}) == nil
    end

    test "returns nil when the idx exists but the type differs", %{template: template} do
      assert placeholder(template, 2, {"pic", 14}) == nil
      assert Template.placeholder_by_idx(template, 2, 14).type == "obj"
    end

    test "returns nil for a layout the template does not have", %{template: template} do
      assert placeholder(template, 9, {"title", 0}) == nil
    end
  end

  describe "master inheritance edge cases" do
    @master_head ~s(<?xml version="1.0"?><p:sldMaster><p:cSld><p:spTree>)
    @master_tail ~s(</p:spTree></p:cSld></p:sldMaster>)

    defp master_sp(name, ph_attrs, box) do
      xfrm =
        case box do
          nil ->
            "<p:spPr/>"

          {x, y, w, h} ->
            ~s(<p:spPr><a:xfrm><a:off x="#{x}" y="#{y}"/><a:ext cx="#{w}" cy="#{h}"/>) <>
              ~s(</a:xfrm></p:spPr>)
        end

      ~s(<p:sp><p:nvSpPr><p:cNvPr id="2" name="#{name}"/><p:cNvSpPr/>) <>
        ~s(<p:nvPr><p:ph #{ph_attrs}/></p:nvPr></p:nvSpPr>#{xfrm}<p:txBody/></p:sp>)
    end

    defp parts_with(master_shapes, layout_shapes) do
      %{
        "ppt/presentation.xml" => ~s(<p:sldSz cx="9144000" cy="6858000"/>),
        "ppt/slideMasters/slideMaster1.xml" => @master_head <> master_shapes <> @master_tail,
        "ppt/slideLayouts/slideLayout1.xml" =>
          ~s(<p:sldLayout><p:cSld name="L1"><p:spTree>) <>
            layout_shapes <> ~s(</p:spTree></p:cSld></p:sldLayout>)
      }
    end

    test "a master with two body placeholders inherits from the first" do
      master =
        master_sp("Body A", ~s(type="body" idx="1"), {1, 2, 3, 4}) <>
          master_sp("Body B", ~s(type="body" idx="5"), {10, 20, 30, 40})

      template = Template.inspect(parts_with(master, master_sp("Content", ~s(idx="7"), nil)))

      assert placeholder(template, 1, {"obj", 7}).box == %{x: 1, y: 2, w: 3, h: 4}
    end

    test "a master body with a non-1 idx is still inherited from" do
      master = master_sp("Body", ~s(type="body" idx="9"), {5, 6, 7, 8})

      template = Template.inspect(parts_with(master, master_sp("Content", ~s(idx="2"), nil)))

      assert placeholder(template, 1, {"obj", 2}).box == %{x: 5, y: 6, w: 7, h: 8}
    end

    test "a layout placeholder with no matching master placeholder has a nil box" do
      master = master_sp("Title", ~s(type="title"), {1, 1, 1, 1})

      template = Template.inspect(parts_with(master, master_sp("Content", ~s(idx="2"), nil)))

      assert placeholder(template, 1, {"obj", 2}).box == nil
    end

    test "falls back to the only master when the layout has no relationships" do
      master = master_sp("Title", ~s(type="title"), {1, 1, 1, 1})

      template = Template.inspect(parts_with(master, master_sp("Title", ~s(type="title"), nil)))

      assert template.layouts[1].master_index == 1
    end
  end
end
