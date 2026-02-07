defmodule Podium.SlideTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "slide background" do
    test "solid background fill" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs, background: "003366")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ "<p:bgPr>"
      assert slide_xml =~ ~s(<a:solidFill><a:srgbClr val="003366"/></a:solidFill>)
      assert slide_xml =~ "<a:effectLst/>"
    end

    test "gradient background fill" do
      prs = Podium.new()

      {prs, slide} =
        Podium.add_slide(prs,
          background: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000}
        )

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ "<p:bg>"
      assert slide_xml =~ ~s(<a:gradFill rotWithShape="1">)
    end

    test "no background when nil" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)
      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      refute slide_xml =~ "<p:bg>"
    end
  end
end
