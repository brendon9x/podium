defmodule Podium.OPC.RelationshipsTest do
  use ExUnit.Case, async: true

  alias Podium.OPC.{Relationships, Constants}

  describe "new/0" do
    test "creates empty relationships" do
      rels = Relationships.new()
      assert rels.rels == []
      assert rels.next_id == 1
    end
  end

  describe "from_list/1" do
    test "creates from existing rels with correct next_id" do
      rels =
        Relationships.from_list([
          {"rId1", Constants.rt(:slide_master), "slideMasters/slideMaster1.xml"},
          {"rId3", Constants.rt(:theme), "theme/theme1.xml"}
        ])

      assert length(rels.rels) == 2
      assert rels.next_id == 4
    end

    test "ignores ids that are not of the form rIdN" do
      rels =
        Relationships.from_list([
          {"docRId", Constants.rt(:theme), "theme/theme1.xml"},
          {"rId2", Constants.rt(:slide_master), "slideMasters/slideMaster1.xml"}
        ])

      assert length(rels.rels) == 2
      assert rels.next_id == 3
    end
  end

  describe "parse/1" do
    test "reads internal and external relationships" do
      xml = """
      <?xml version="1.0"?>
      <Relationships xmlns="#{Constants.ns(:pr)}">
      <Relationship Id="rId1" Type="#{Constants.rt(:slide_master)}" Target="slideMasters/slideMaster1.xml"/>
      <Relationship Id="rId2" Type="#{Constants.rt(:hyperlink)}" Target="https://example.com/" TargetMode="External"/>
      </Relationships>
      """

      rels = Relationships.parse(xml)

      assert rels.rels == [
               {"rId1", Constants.rt(:slide_master), "slideMasters/slideMaster1.xml"},
               {"rId2", Constants.rt(:hyperlink), "https://example.com/", true}
             ]
    end

    test "does not depend on attribute order" do
      xml =
        ~s(<Relationships><Relationship Target="theme/theme1.xml" Type="#{Constants.rt(:theme)}" Id="rId9"/></Relationships>)

      assert Relationships.parse(xml).rels == [
               {"rId9", Constants.rt(:theme), "theme/theme1.xml"}
             ]
    end

    test "sets next_id past the highest rIdN even when ids are non-contiguous" do
      xml = """
      <Relationships>
      <Relationship Id="rId1" Type="#{Constants.rt(:slide_master)}" Target="a.xml"/>
      <Relationship Id="rId7" Type="#{Constants.rt(:theme)}" Target="b.xml"/>
      <Relationship Id="rId5" Type="#{Constants.rt(:view_props)}" Target="c.xml"/>
      </Relationships>
      """

      assert Relationships.parse(xml).next_id == 8
    end

    test "tolerates a foreign id" do
      xml = """
      <Relationships>
      <Relationship Id="R7f3" Type="#{Constants.rt(:theme)}" Target="a.xml"/>
      <Relationship Id="rId2" Type="#{Constants.rt(:view_props)}" Target="b.xml"/>
      </Relationships>
      """

      rels = Relationships.parse(xml)

      assert rels.next_id == 3
      assert {rels, "rId3"} = Relationships.add(rels, Constants.rt(:slide), "slides/slide1.xml")
      assert length(rels.rels) == 3
    end

    test "round-trips through to_xml/1" do
      xml = """
      <Relationships>
      <Relationship Id="rId1" Type="#{Constants.rt(:slide_master)}" Target="a.xml"/>
      <Relationship Id="rId2" Type="#{Constants.rt(:hyperlink)}" Target="https://example.com/" TargetMode="External"/>
      </Relationships>
      """

      rels = Relationships.parse(xml)

      assert rels |> Relationships.to_xml() |> Relationships.parse() == rels
    end
  end

  describe "find_by_type/2" do
    test "returns the rId and target of the first matching relationship" do
      rels =
        Relationships.from_list([
          {"rId1", Constants.rt(:slide_master), "slideMasters/slideMaster1.xml"},
          {"rId4", Constants.rt(:notes_master), "notesMasters/notesMaster1.xml"}
        ])

      assert Relationships.find_by_type(rels, Constants.rt(:notes_master)) ==
               {"rId4", "notesMasters/notesMaster1.xml"}
    end

    test "returns nil when no relationship has the type" do
      rels = Relationships.from_list([{"rId1", Constants.rt(:theme), "theme/theme1.xml"}])

      assert Relationships.find_by_type(rels, Constants.rt(:notes_master)) == nil
    end
  end

  describe "add/3" do
    test "adds a relationship and returns the rId" do
      {rels, rid} =
        Relationships.new() |> Relationships.add(Constants.rt(:slide), "slides/slide1.xml")

      assert rid == "rId1"
      assert length(rels.rels) == 1
      assert rels.next_id == 2
    end

    test "increments rId for each addition" do
      {rels, rid1} =
        Relationships.new()
        |> Relationships.add(Constants.rt(:slide), "slides/slide1.xml")

      {_rels, rid2} = Relationships.add(rels, Constants.rt(:slide), "slides/slide2.xml")

      assert rid1 == "rId1"
      assert rid2 == "rId2"
    end
  end

  describe "to_xml/1" do
    test "generates valid relationships XML" do
      {rels, _} =
        Relationships.new()
        |> Relationships.add(Constants.rt(:slide), "slides/slide1.xml")

      xml = Relationships.to_xml(rels)

      assert String.starts_with?(xml, ~s(<?xml version="1.0"))
      assert xml =~ ~s(xmlns="http://schemas.openxmlformats.org/package/2006/relationships")
      assert xml =~ ~s(Id="rId1")
      assert xml =~ ~s(Target="slides/slide1.xml")
    end
  end
end
