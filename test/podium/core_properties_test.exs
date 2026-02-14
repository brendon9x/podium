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

    test "created and modified dates with xsi:type attribute" do
      props =
        CoreProperties.new(
          title: "Dated Doc",
          created: ~U[2025-01-15 10:00:00Z],
          modified: ~U[2025-02-07 10:30:00Z]
        )

      xml = CoreProperties.to_xml(props)

      assert xml =~ ~s(xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance")

      assert xml =~
               ~s(<dcterms:created xsi:type="dcterms:W3CDTF">2025-01-15T10:00:00Z</dcterms:created>)

      assert xml =~
               ~s(<dcterms:modified xsi:type="dcterms:W3CDTF">2025-02-07T10:30:00Z</dcterms:modified>)
    end

    test "revision as integer element" do
      props = CoreProperties.new(revision: 5)
      xml = CoreProperties.to_xml(props)

      assert xml =~ "<cp:revision>5</cp:revision>"
    end

    test "content_status as string element" do
      props = CoreProperties.new(content_status: "Draft")
      xml = CoreProperties.to_xml(props)

      assert xml =~ "<cp:contentStatus>Draft</cp:contentStatus>"
    end

    test "language field" do
      props = CoreProperties.new(language: "en-US")
      xml = CoreProperties.to_xml(props)

      assert xml =~ "<dc:language>en-US</dc:language>"
    end

    test "version field" do
      props = CoreProperties.new(version: "1.0")
      xml = CoreProperties.to_xml(props)

      assert xml =~ "<cp:version>1.0</cp:version>"
    end

    test "no xsi namespace when no datetime fields" do
      props = CoreProperties.new(title: "No Dates")
      xml = CoreProperties.to_xml(props)

      refute xml =~ "xmlns:xsi"
    end
  end

  describe "integration with Podium" do
    test "core properties in saved PPTX via new/1 opts" do
      prs =
        Podium.new(title: "My Deck", author: "Alice")
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      core_xml = parts["docProps/core.xml"]

      assert core_xml =~ "<dc:title>My Deck</dc:title>"
      assert core_xml =~ "<dc:creator>Alice</dc:creator>"
    end

    test "core properties via set_core_properties/2" do
      prs =
        Podium.new()
        |> Podium.set_core_properties(title: "Updated Title", subject: "Science")
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      core_xml = parts["docProps/core.xml"]

      assert core_xml =~ "<dc:title>Updated Title</dc:title>"
      assert core_xml =~ "<dc:subject>Science</dc:subject>"
    end

    test "default template core.xml when no properties set" do
      prs =
        Podium.new()
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Template's core.xml should be preserved as-is
      assert Map.has_key?(parts, "docProps/core.xml")
    end

    test "date and revision fields via new/1 opts" do
      prs =
        Podium.new(
          title: "Full Props",
          created: ~U[2025-01-15 10:00:00Z],
          modified: ~U[2025-02-07 10:30:00Z],
          revision: 5,
          content_status: "Draft",
          language: "en-US"
        )
        |> Podium.add_slide(Podium.Slide.new())

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      core_xml = parts["docProps/core.xml"]

      assert core_xml =~ "<dc:title>Full Props</dc:title>"
      assert core_xml =~ "2025-01-15T10:00:00Z"
      assert core_xml =~ "2025-02-07T10:30:00Z"
      assert core_xml =~ "<cp:revision>5</cp:revision>"
      assert core_xml =~ "<cp:contentStatus>Draft</cp:contentStatus>"
      assert core_xml =~ "<dc:language>en-US</dc:language>"
      assert core_xml =~ ~s(xsi:type="dcterms:W3CDTF")
    end
  end
end
