defmodule Podium.OPC.ContentTypesTest do
  use ExUnit.Case, async: true

  alias Podium.OPC.ContentTypes
  alias Podium.OPC.Constants

  describe "from_template/0" do
    test "includes standard defaults" do
      ct = ContentTypes.from_template()

      assert ct.defaults["xml"] == Constants.ct(:xml)
      assert ct.defaults["rels"] == Constants.ct(:rels)
      assert ct.defaults["jpeg"] == Constants.ct(:jpeg)
    end

    test "includes standard overrides" do
      ct = ContentTypes.from_template()

      assert ct.overrides["/ppt/presentation.xml"] == Constants.ct(:presentation)
      assert ct.overrides["/ppt/slideMasters/slideMaster1.xml"] == Constants.ct(:slide_master)
      assert ct.overrides["/ppt/theme/theme1.xml"] == Constants.ct(:theme)
    end
  end

  describe "add_override/3" do
    test "adds a new override entry" do
      ct =
        ContentTypes.from_template()
        |> ContentTypes.add_override("/ppt/slides/slide1.xml", Constants.ct(:slide))

      assert ct.overrides["/ppt/slides/slide1.xml"] == Constants.ct(:slide)
    end
  end

  describe "to_xml/1" do
    test "generates valid content types XML" do
      xml = ContentTypes.from_template() |> ContentTypes.to_xml()

      assert String.starts_with?(xml, ~s(<?xml version="1.0"))
      assert xml =~ ~s(xmlns="http://schemas.openxmlformats.org/package/2006/content-types")
      assert xml =~ ~s(Extension="xml")
      assert xml =~ ~s(PartName="/ppt/presentation.xml")
    end
  end
end
