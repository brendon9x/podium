defmodule Podium.OPC.PresentationXmlTest do
  use ExUnit.Case, async: true

  alias Podium.OPC.PresentationXml

  @master_list ~s(<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>)
  @notes_list ~s(<p:notesMasterIdLst><p:notesMasterId r:id="rId7"/></p:notesMasterIdLst>)
  @handout_list ~s(<p:handoutMasterIdLst><p:handoutMasterId r:id="rId8"/></p:handoutMasterIdLst>)

  defp presentation(body) do
    ~s(<?xml version="1.0"?><p:presentation xmlns:p="p" xmlns:r="r">) <>
      body <> ~s(</p:presentation>)
  end

  describe "slide_size/1" do
    test "reads cx and cy" do
      xml = presentation(~s(<p:sldSz cx="12192000" cy="6858000"/>))

      assert PresentationXml.slide_size(xml) == {12_192_000, 6_858_000}
    end

    test "ignores other attributes and their order" do
      xml = presentation(~s(<p:sldSz type="screen4x3" cy="6858000" cx="9144000"/>))

      assert PresentationXml.slide_size(xml) == {9_144_000, 6_858_000}
    end

    test "returns nil when there is no slide size" do
      assert PresentationXml.slide_size(presentation(@master_list)) == nil
    end
  end

  describe "put_slide_size/3" do
    test "replaces the element and drops the type attribute" do
      xml =
        presentation(~s(<p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>))
        |> PresentationXml.put_slide_size(12_192_000, 6_858_000)

      assert xml =~ ~s(<p:sldSz cx="12192000" cy="6858000"/>)
      refute xml =~ "screen4x3"
      assert PresentationXml.slide_size(xml) == {12_192_000, 6_858_000}
    end
  end

  describe "put_slide_id_list/2" do
    test "inserts the list after the slide master list" do
      xml =
        presentation(@master_list <> ~s(<p:sldSz cx="1" cy="2"/>))
        |> PresentationXml.put_slide_id_list([{256, "rId7"}, {257, "rId8"}])

      assert xml =~
               @master_list <>
                 ~s(<p:sldIdLst><p:sldId id="256" r:id="rId7"/><p:sldId id="257" r:id="rId8"/></p:sldIdLst><p:sldSz)
    end

    test "inserts after the notes master list when there is one" do
      xml =
        presentation(@master_list <> @notes_list)
        |> PresentationXml.put_slide_id_list([{256, "rId2"}])

      assert xml =~ @notes_list <> ~s(<p:sldIdLst>)
    end

    test "inserts after the handout master list when there is one" do
      xml =
        presentation(@master_list <> @notes_list <> @handout_list)
        |> PresentationXml.put_slide_id_list([{256, "rId2"}])

      assert xml =~ @handout_list <> ~s(<p:sldIdLst>)
    end

    test "replaces an existing list" do
      existing = ~s(<p:sldIdLst><p:sldId id="300" r:id="rId9"/></p:sldIdLst>)

      xml =
        presentation(@master_list <> existing)
        |> PresentationXml.put_slide_id_list([{256, "rId2"}])

      refute xml =~ ~s(id="300")
      assert xml =~ ~s(<p:sldIdLst><p:sldId id="256" r:id="rId2"/></p:sldIdLst>)
    end

    test "replaces a self-closing empty list" do
      xml =
        presentation(@master_list <> ~s(<p:sldIdLst/>))
        |> PresentationXml.put_slide_id_list([{256, "rId2"}])

      refute xml =~ ~s(<p:sldIdLst/>)
      assert xml =~ ~s(<p:sldIdLst><p:sldId id="256" r:id="rId2"/></p:sldIdLst>)
    end

    test "writes no list at all when there are no slides" do
      xml =
        presentation(@master_list <> ~s(<p:sldIdLst><p:sldId id="300" r:id="rId9"/></p:sldIdLst>))
        |> PresentationXml.put_slide_id_list([])

      refute xml =~ "sldIdLst"
      assert xml =~ @master_list
    end
  end

  describe "put_notes_master_id/2" do
    test "inserts the list after the slide master list" do
      xml =
        presentation(@master_list <> ~s(<p:sldSz cx="1" cy="2"/>))
        |> PresentationXml.put_notes_master_id("rId7")

      assert xml =~ @master_list <> @notes_list
    end

    test "leaves an existing list alone" do
      xml = presentation(@master_list <> @notes_list)

      assert PresentationXml.put_notes_master_id(xml, "rId99") == xml
    end

    test "is idempotent" do
      once =
        presentation(@master_list)
        |> PresentationXml.put_notes_master_id("rId7")

      assert PresentationXml.put_notes_master_id(once, "rId7") == once
    end
  end

  describe "strip_section_list/1" do
    test "removes the section extension and the emptied extLst" do
      ext_list =
        ~s(<p:extLst><p:ext uri="{521415D9-36F7-43E2-AB2F-B90AF26B5E84}">) <>
          ~s(<p14:sectionLst xmlns:p14="p14"><p14:section name="Intro" id="{A}">) <>
          ~s(<p14:sldIdLst><p14:sldId id="999"/></p14:sldIdLst></p14:section>) <>
          ~s(</p14:sectionLst></p:ext></p:extLst>)

      xml = presentation(@master_list <> ext_list) |> PresentationXml.strip_section_list()

      refute xml =~ "sectionLst"
      refute xml =~ "extLst"
      assert xml =~ @master_list
    end

    test "keeps other extensions and their extLst" do
      other = ~s(<p:ext uri="{OTHER}"><p14:other xmlns:p14="p14" val="1"/></p:ext>)

      section =
        ~s(<p:ext uri="{521415D9-36F7-43E2-AB2F-B90AF26B5E84}"><p14:sectionLst xmlns:p14="p14"/></p:ext>)

      xml =
        presentation(@master_list <> "<p:extLst>" <> other <> section <> "</p:extLst>")
        |> PresentationXml.strip_section_list()

      refute xml =~ "sectionLst"
      assert xml =~ "<p:extLst>" <> other <> "</p:extLst>"
    end

    test "leaves XML without a section list unchanged" do
      xml = presentation(@master_list)

      assert PresentationXml.strip_section_list(xml) == xml
    end
  end
end
