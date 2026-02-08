defmodule Podium.HyperlinkTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "hyperlinks in text boxes" do
    test "hyperlink on text run produces hlinkClick and external relationship" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, [[{"Click here", hyperlink: "https://example.com"}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(<a:hlinkClick r:id=")
      assert slide_xml =~ ~s(xmlns:r=")

      rels_xml = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert rels_xml =~ ~s(Target="https://example.com")
      assert rels_xml =~ ~s(TargetMode="External")
    end

    test "hyperlink with tooltip" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"Visit site", hyperlink: [url: "https://example.com", tooltip: "Visit Example"]}
            ]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ ~s(tooltip="Visit Example")
    end

    test "multiple runs with same URL share one relationship" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"Link A", hyperlink: "https://example.com"},
              {"Link B", hyperlink: "https://example.com"}
            ]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      rels_xml = parts["ppt/slides/_rels/slide1.xml.rels"]
      # Only one relationship for the same URL
      count =
        rels_xml
        |> String.split("https://example.com")
        |> length()

      # split produces N+1 segments for N occurrences
      assert count == 2
    end

    test "no hyperlink produces no hlinkClick" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, "No link here",
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      refute slide_xml =~ "hlinkClick"
    end

    test "mailto URL works" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(slide, [[{"Email us", hyperlink: "mailto:test@example.com"}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      rels_xml = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert rels_xml =~ ~s(Target="mailto:test@example.com")
      assert rels_xml =~ ~s(TargetMode="External")
    end

    test "hyperlink in placeholder text" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, layout: :title_content)

      slide =
        Podium.set_placeholder(slide, :content, [
          [{"Click me", hyperlink: "https://example.com"}]
        ])

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "hlinkClick"

      rels_xml = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert rels_xml =~ "https://example.com"
      assert rels_xml =~ ~s(TargetMode="External")
    end

    test "multiple different URLs produce separate relationships" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [
              {"One", hyperlink: "https://one.example.com"},
              {"Two", hyperlink: "https://two.example.com"}
            ]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)

      rels_xml = parts["ppt/slides/_rels/slide1.xml.rels"]
      assert rels_xml =~ "https://one.example.com"
      assert rels_xml =~ "https://two.example.com"
    end
  end
end
