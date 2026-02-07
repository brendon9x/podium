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

    test "cell with solid fill" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_table(
          slide,
          [
            [{"Header", fill: "4472C4"}, "Plain"],
            ["Data 1", "Data 2"]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {2, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(<a:solidFill><a:srgbClr val="4472C4"/></a:solidFill>)
      assert xml =~ "Header"
    end

    test "cell with borders" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_table(
          slide,
          [
            [{"Cell", borders: [bottom: "000000", top: [color: "FF0000", width: {2, :pt}]]}]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ "<a:lnB>"
      assert xml =~ ~s(val="000000")
      assert xml =~ ~s(<a:lnT w="25400">)
      assert xml =~ ~s(val="FF0000")
    end

    test "cell with padding" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_table(
          slide,
          [
            [{"Padded", padding: [left: {0.1, :inches}, top: {0.05, :inches}]}]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      # 0.1 inches = 91440 EMU
      assert xml =~ ~s(marL="91440")
      # 0.05 inches = 45720 EMU
      assert xml =~ ~s(marT="45720")
    end

    test "horizontal cell merge" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_table(
          slide,
          [
            [{"Merged Header", col_span: 2}, :merge],
            ["A", "B"]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {2, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(gridSpan="2")
      assert xml =~ ~s(hMerge="1")
    end

    test "vertical cell merge" do
      {_prs, slide} = Podium.new() |> Podium.add_slide()

      slide =
        Podium.add_table(
          slide,
          [
            [{"Tall", row_span: 2}, "Top"],
            [:merge, "Bottom"]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {2, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(rowSpan="2")
      assert xml =~ ~s(vMerge="1")
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
