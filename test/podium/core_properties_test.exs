defmodule Podium.CorePropertiesTest do
  use ExUnit.Case, async: true

  alias Podium.CoreProperties
  alias Podium.Test.PptxHelpers

  describe "to_xml/1" do
    test "generates Dublin Core XML with all fields" do
      props =
        CoreProperties.new(
          title: "Test Presentation",
          author: "Jane Doe",
          subject: "Testing",
          keywords: "elixir, pptx",
          category: "Reports",
          comments: "A test document",
          last_modified_by: "John Smith"
        )

      xml = CoreProperties.to_xml(props)

      assert xml =~ ~s(<?xml version="1.0")
      assert xml =~ "<cp:coreProperties"
      assert xml =~ "<dc:title>Test Presentation</dc:title>"
      assert xml =~ "<dc:creator>Jane Doe</dc:creator>"
      assert xml =~ "<dc:subject>Testing</dc:subject>"
      assert xml =~ "<cp:keywords>elixir, pptx</cp:keywords>"
      assert xml =~ "<cp:category>Reports</cp:category>"
      assert xml =~ "<dc:description>A test document</dc:description>"
      assert xml =~ "<cp:lastModifiedBy>John Smith</cp:lastModifiedBy>"
    end

    test "omits nil fields" do
      props = CoreProperties.new(title: "Only Title")
      xml = CoreProperties.to_xml(props)

      assert xml =~ "<dc:title>Only Title</dc:title>"
      refute xml =~ "<dc:creator>"
      refute xml =~ "<dc:subject>"
      refute xml =~ "<cp:keywords>"
    end

    test "escapes XML special characters" do
      props = CoreProperties.new(title: "R&D <Report> 'Draft'")
      xml = CoreProperties.to_xml(props)

      assert xml =~ "R&amp;D &lt;Report&gt; &apos;Draft&apos;"
    end
  end

  describe "integration with Podium" do
    test "core properties in saved PPTX via new/1 opts" do
      prs = Podium.new(title: "My Deck", author: "Alice")
      {prs, _slide} = Podium.add_slide(prs)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      core_xml = parts["docProps/core.xml"]

      assert core_xml =~ "<dc:title>My Deck</dc:title>"
      assert core_xml =~ "<dc:creator>Alice</dc:creator>"
    end

    test "core properties via set_core_properties/2" do
      prs = Podium.new()
      prs = Podium.set_core_properties(prs, title: "Updated Title", subject: "Science")
      {prs, _slide} = Podium.add_slide(prs)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      core_xml = parts["docProps/core.xml"]

      assert core_xml =~ "<dc:title>Updated Title</dc:title>"
      assert core_xml =~ "<dc:subject>Science</dc:subject>"
    end

    test "default template core.xml when no properties set" do
      prs = Podium.new()
      {prs, _slide} = Podium.add_slide(prs)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Template's core.xml should be preserved as-is
      assert Map.has_key?(parts, "docProps/core.xml")
    end
  end
end
