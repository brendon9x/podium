defmodule Podium.TableTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "add_table/3" do
    test "adds a basic table to a slide" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Podium.add_table(
          slide,
          [
            ["Name", "Q1", "Q2"],
            ["Alice", "100", "200"],
            ["Bob", "150", "250"]
          ],
          x: {1, :inches},
          y: {2, :inches},
          width: {8, :inches},
          height: {3, :inches}
        )

      assert length(slide.tables) == 1

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      # Table is in a graphicFrame
      assert slide_xml =~ "p:graphicFrame"
      assert slide_xml =~ "a:tbl"
      assert slide_xml =~ "a:tr"
      assert slide_xml =~ "a:tc"

      # Cell content
      assert slide_xml =~ "Alice"
      assert slide_xml =~ "Bob"
      assert slide_xml =~ "Q1"
      assert slide_xml =~ "200"
    end

    test "table with rich text cells" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      # Rich text cells: each cell is a Text.normalize-compatible value.
      # A cell with formatting uses the list-of-paragraphs form:
      #   [[{"Header", bold: true}]]  — one paragraph with one bold run
      slide =
        Podium.add_table(
          slide,
          [
            [[[{"Header", bold: true}]], "Plain"],
            ["Data 1", "Data 2"]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {2, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(b="1")
      assert xml =~ "Header"
      assert xml =~ "Plain"
    end

    test "distributes column widths evenly" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_table(
          slide,
          [["A", "B", "C"]],
          x: {1, :inches},
          y: {1, :inches},
          width: 3_000_000,
          height: 1_000_000
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      # 3_000_000 / 3 cols = 1_000_000 per col
      assert xml =~ ~s(gridCol w="1000000")
    end
  end
end
