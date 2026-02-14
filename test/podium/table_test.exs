defmodule Podium.TableTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "add_table/3" do
    test "adds a basic table to a slide" do
      slide =
        Podium.Slide.new()
        |> Podium.add_table(
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

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

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
      slide = Podium.Slide.new()

      # Rich text cells: each cell is a Text.normalize-compatible value.
      # A cell with formatting uses the list-of-paragraphs form:
      #   [[{"Header", bold: true}]]  -- one paragraph with one bold run
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
      slide = Podium.Slide.new()

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
      slide = Podium.Slide.new()

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
      slide = Podium.Slide.new()

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
      slide = Podium.Slide.new()

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
      slide = Podium.Slide.new()

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

    test "cell with gradient fill" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [
            [
              {"Gradient",
               fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000}},
              "Plain"
            ]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {2, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(<a:gradFill rotWithShape="1">)
      assert xml =~ ~s(<a:gs pos="0"><a:srgbClr val="FF0000"/></a:gs>)
      assert xml =~ ~s(<a:gs pos="100000"><a:srgbClr val="0000FF"/></a:gs>)
    end

    test "cell with pattern fill" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [
            [
              {"Pattern", fill: {:pattern, :dn_diag, foreground: "FF0000", background: "FFFFFF"}},
              "Plain"
            ]
          ],
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {2, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(<a:pattFill prst="dnDiag">)
      assert xml =~ ~s(<a:fgClr><a:srgbClr val="FF0000"/></a:fgClr>)
    end

    test "default banding flags" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["A", "B"]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches}
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(<a:tblPr firstRow="1" bandRow="1"/>)
    end

    test "custom banding flags" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["A", "B"]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {1, :inches},
          table_style: [first_row: false, band_row: false, band_col: true, last_row: true]
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      refute xml =~ ~s(firstRow="1")
      refute xml =~ ~s(bandRow="1")
      assert xml =~ ~s(bandCol="1")
      assert xml =~ ~s(lastRow="1")
    end

    test "distributes column widths evenly" do
      slide = Podium.Slide.new()

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

    test "explicit col_widths produces correct gridCol elements" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["Rank", "Description", "Score"]],
          x: {1, :inches},
          y: {1, :inches},
          width: {11, :inches},
          height: {1, :inches},
          col_widths: [{1.5, :inches}, {6, :inches}, {3.5, :inches}]
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      # 1.5 inches = 1371600 EMU
      assert xml =~ ~s(gridCol w="1371600")
      # 6 inches = 5486400 EMU
      assert xml =~ ~s(gridCol w="5486400")
      # 3.5 inches = 3200400 EMU
      assert xml =~ ~s(gridCol w="3200400")
    end

    test "explicit row_heights produces correct tr h attributes" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["Header"], ["Data"]],
          x: {1, :inches},
          y: {1, :inches},
          width: {4, :inches},
          height: {2, :inches},
          row_heights: [{0.5, :inches}, {1.5, :inches}]
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      # 0.5 inches = 457200 EMU
      assert xml =~ ~s(h="457200")
      # 1.5 inches = 1371600 EMU
      assert xml =~ ~s(h="1371600")
    end

    test "even distribution rounding: last column absorbs remainder" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["A", "B", "C"]],
          x: {1, :inches},
          y: {1, :inches},
          width: 3_000_001,
          height: 1_000_000
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      # 3_000_001 / 3 = 1_000_000 base, last col gets 1_000_001
      assert xml =~ ~s(gridCol w="1000001")
    end

    test "only col_widths provided, rows still even" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["A", "B"], ["C", "D"]],
          x: {1, :inches},
          y: {1, :inches},
          width: {8, :inches},
          height: 2_000_000,
          col_widths: [{3, :inches}, {5, :inches}]
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      # Custom col widths
      assert xml =~ ~s(gridCol w="2743200")
      assert xml =~ ~s(gridCol w="4572000")
      # Even row heights: 2_000_000 / 2 = 1_000_000
      assert xml =~ ~s(h="1000000")
    end

    test "raw EMU integers in col_widths work" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_table(
          slide,
          [["A", "B"]],
          x: {1, :inches},
          y: {1, :inches},
          width: 5_000_000,
          height: 1_000_000,
          col_widths: [2_000_000, 3_000_000]
        )

      table = hd(slide.tables)
      xml = Podium.Table.to_xml(table)

      assert xml =~ ~s(gridCol w="2000000")
      assert xml =~ ~s(gridCol w="3000000")
    end
  end
end
