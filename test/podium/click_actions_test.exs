defmodule Podium.ClickActionsTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "navigation actions" do
    test ":next_slide produces correct action XML" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [[{"Next", hyperlink: :next_slide}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(action="ppaction://hlinkshowjump?jump=nextslide")
      assert xml =~ ~s(r:id="")
    end

    test ":previous_slide produces correct action XML" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [[{"Back", hyperlink: :previous_slide}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(action="ppaction://hlinkshowjump?jump=previousslide")
    end

    test ":first_slide produces correct action XML" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [[{"Start", hyperlink: :first_slide}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(action="ppaction://hlinkshowjump?jump=firstslide")
    end

    test ":last_slide produces correct action XML" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [[{"End", hyperlink: :last_slide}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(action="ppaction://hlinkshowjump?jump=lastslide")
    end

    test ":end_show produces correct action XML" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_text_box(
          slide,
          [[{"Exit", hyperlink: :end_show}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      assert xml =~ ~s(action="ppaction://hlinkshowjump?jump=endshow")
    end

    test "navigation actions create NO external relationships in slide rels" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [[{"Next", hyperlink: :next_slide}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_rels = parts["ppt/slides/_rels/slide1.xml.rels"]

      # Should only have slideLayout rel, no hyperlink rel
      refute slide_rels =~ "hyperlink"
      assert slide_rels =~ "slideLayout"
    end
  end

  describe "slide jump action" do
    test "{:slide, target} produces correct action XML with real r:id" do
      prs = Podium.new()
      {prs, slide1} = Podium.add_slide(prs)
      {prs, slide2} = Podium.add_slide(prs)

      slide2 =
        Podium.add_text_box(
          slide2,
          [[{"Go to intro", hyperlink: {:slide, slide1}}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {0.5, :inches}
        )

      prs = Podium.put_slide(prs, slide2)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide2_xml = parts["ppt/slides/slide2.xml"]

      assert slide2_xml =~ ~s(action="ppaction://hlinksldjump")
      # Should have a real r:id (not empty)
      assert slide2_xml =~ ~r/r:id="rId\d+"/
      refute slide2_xml =~ ~s(r:id="" action="ppaction://hlinksldjump")
    end

    test "slide rels contain RT.SLIDE relationship to target slide" do
      prs = Podium.new()
      {prs, slide1} = Podium.add_slide(prs)
      {prs, slide2} = Podium.add_slide(prs)

      slide2 =
        Podium.add_text_box(
          slide2,
          [[{"Jump", hyperlink: {:slide, slide1}}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      prs = Podium.put_slide(prs, slide2)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide2_rels = parts["ppt/slides/_rels/slide2.xml.rels"]

      # Should reference slide1.xml
      assert slide2_rels =~ "slide1.xml"
    end
  end

  describe "mixed hyperlinks" do
    test "URL hyperlink and action on same slide both work" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_text_box(
          slide,
          [
            [{"Visit site", hyperlink: "https://example.com"}],
            [{"Next slide", hyperlink: :next_slide}]
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

      # URL hyperlink
      assert slide_xml =~ ~s(r:id="rId2")
      # Navigation action
      assert slide_xml =~ ~s(action="ppaction://hlinkshowjump?jump=nextslide")
    end

    test "collect_hyperlink_urls ignores action atoms" do
      paragraphs =
        Podium.Text.normalize([
          [{"Next", hyperlink: :next_slide}],
          [{"Link", hyperlink: "https://example.com"}]
        ])

      urls = Podium.Text.collect_hyperlink_urls(paragraphs)

      assert urls == ["https://example.com"]
    end

    test "collect_hyperlink_urls ignores {:slide, _} tuples" do
      slide_target = %{index: 1}

      paragraphs =
        Podium.Text.normalize([
          [{"Jump", hyperlink: {:slide, slide_target}}],
          [{"Link", hyperlink: "https://example.com"}]
        ])

      urls = Podium.Text.collect_hyperlink_urls(paragraphs)

      assert urls == ["https://example.com"]
    end

    test "collect_slide_jumps returns target indices" do
      slide_target = %{index: 3}

      paragraphs =
        Podium.Text.normalize([
          [{"Jump", hyperlink: {:slide, slide_target}}],
          [{"Link", hyperlink: "https://example.com"}],
          [{"Next", hyperlink: :next_slide}]
        ])

      jumps = Podium.Text.collect_slide_jumps(paragraphs)

      assert jumps == [3]
    end
  end

  describe "end-to-end" do
    test "click actions produce valid pptx" do
      prs = Podium.new()
      {prs, slide1} = Podium.add_slide(prs)
      {prs, slide2} = Podium.add_slide(prs)

      slide1 =
        slide1
        |> Podium.add_text_box(
          [[{"Next →", hyperlink: :next_slide}]],
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )
        |> Podium.add_text_box(
          [[{"End Show", hyperlink: :end_show}]],
          x: {4, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {0.5, :inches}
        )

      slide2 =
        Podium.add_text_box(
          slide2,
          [
            [{"← Back", hyperlink: :previous_slide}],
            [{"Go to Slide 1", hyperlink: {:slide, slide1}}]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches}
        )

      prs = prs |> Podium.put_slide(slide1) |> Podium.put_slide(slide2)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      # Slide 1: navigation actions
      slide1_xml = parts["ppt/slides/slide1.xml"]
      assert slide1_xml =~ "nextslide"
      assert slide1_xml =~ "endshow"

      # Slide 2: previous + slide jump
      slide2_xml = parts["ppt/slides/slide2.xml"]
      assert slide2_xml =~ "previousslide"
      assert slide2_xml =~ "hlinksldjump"

      # Slide 2 rels: has slide1.xml reference
      slide2_rels = parts["ppt/slides/_rels/slide2.xml.rels"]
      assert slide2_rels =~ "slide1.xml"
    end
  end
end
