defmodule Podium.OPC.ContentTypesTest do
  use ExUnit.Case, async: true

  alias Podium.OPC.ContentTypes
  alias Podium.OPC.Constants

  defp bundled_xml do
    {:ok, parts} = Podium.OPC.Package.read_default_template()
    to_string(parts["[Content_Types].xml"])
  end

  describe "parse/1" do
    test "reads the bundled template's defaults and overrides" do
      ct = ContentTypes.parse(bundled_xml())

      assert ct.defaults["xml"] == Constants.ct(:xml)
      assert ct.defaults["rels"] == Constants.ct(:rels)
      assert ct.defaults["jpeg"] == Constants.ct(:jpeg)
      assert ct.defaults["bin"] == Constants.ct(:printer_settings)

      assert ct.overrides["/ppt/presentation.xml"] == Constants.ct(:presentation)
      assert ct.overrides["/ppt/slideMasters/slideMaster1.xml"] == Constants.ct(:slide_master)
      assert ct.overrides["/ppt/theme/theme1.xml"] == Constants.ct(:theme)
      assert ct.overrides["/docProps/core.xml"] == Constants.ct(:core_properties)
      assert map_size(ct.overrides) == 19
    end

    test "does not depend on attribute order" do
      xml = """
      <?xml version="1.0"?>
      <Types xmlns="#{Constants.ns(:ct)}">
      <Default ContentType="#{Constants.ct(:xml)}" Extension="xml"/>
      <Override ContentType="#{Constants.ct(:theme)}" PartName="/ppt/theme/theme1.xml"/>
      </Types>
      """

      ct = ContentTypes.parse(xml)

      assert ct.defaults == %{"xml" => Constants.ct(:xml)}
      assert ct.overrides == %{"/ppt/theme/theme1.xml" => Constants.ct(:theme)}
    end

    test "downcases extensions so they match what Podium adds" do
      xml = ~s(<Types><Default Extension="PNG" ContentType="#{Constants.ct(:png)}"/></Types>)

      ct =
        xml
        |> ContentTypes.parse()
        |> ContentTypes.add_default("png", Constants.ct(:png))

      assert ct.defaults == %{"png" => Constants.ct(:png)}
    end

    test "round-trips through to_xml/1" do
      ct = ContentTypes.parse(bundled_xml())
      reparsed = ct |> ContentTypes.to_xml() |> ContentTypes.parse()

      assert reparsed == ct
    end

    test "ignores elements missing a required attribute" do
      xml = ~s(<Types><Default Extension="xml"/><Override PartName="/a.xml"/></Types>)

      assert ContentTypes.parse(xml) == %ContentTypes{}
    end
  end

  describe "add_override/3" do
    test "adds a new override entry" do
      ct =
        ContentTypes.parse(bundled_xml())
        |> ContentTypes.add_override("/ppt/slides/slide1.xml", Constants.ct(:slide))

      assert ct.overrides["/ppt/slides/slide1.xml"] == Constants.ct(:slide)
    end
  end

  describe "add_default/3" do
    test "downcases the extension" do
      ct = ContentTypes.add_default(%ContentTypes{}, "JPEG", Constants.ct(:jpeg))

      assert ct.defaults == %{"jpeg" => Constants.ct(:jpeg)}
    end
  end

  describe "to_xml/1" do
    test "generates valid content types XML" do
      xml = ContentTypes.parse(bundled_xml()) |> ContentTypes.to_xml()

      assert String.starts_with?(xml, ~s(<?xml version="1.0"))
      assert xml =~ ~s(xmlns="http://schemas.openxmlformats.org/package/2006/content-types")
      assert xml =~ ~s(Extension="xml")
      assert xml =~ ~s(PartName="/ppt/presentation.xml")
    end
  end
end
