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
