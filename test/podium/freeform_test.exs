defmodule Podium.FreeformTest do
  use ExUnit.Case, async: true

  alias Podium.{Freeform, Shape}
  alias Podium.Test.PptxHelpers

  describe "Freeform.new/3" do
    test "with EMU coordinates" do
      fb = Freeform.new(914_400, 914_400)
      assert fb.start_x == 914_400
      assert fb.start_y == 914_400
      assert fb.x_scale == 1.0
      assert fb.y_scale == 1.0
    end

    test "with unit tuples" do
      fb = Freeform.new({1, :inches}, {2, :inches})
      assert fb.start_x == 914_400
      assert fb.start_y == 1_828_800
    end

    test "with custom scale" do
      fb = Freeform.new(0, 0, scale: 9144)
      assert fb.x_scale == 9144.0
      assert fb.y_scale == 9144.0
    end
  end

  describe "operations" do
    test "line_to appends operation" do
      fb = Freeform.new(0, 0) |> Freeform.line_to(100, 0)
      assert fb.operations == [{:line_to, 100, 0}]
    end

    test "move_to appends operation" do
      fb = Freeform.new(0, 0) |> Freeform.move_to(50, 50)
      assert fb.operations == [{:move_to, 50, 50}]
    end

    test "close appends operation" do
      fb = Freeform.new(0, 0) |> Freeform.close()
      assert fb.operations == [:close]
    end

    test "add_line_segments appends multiple line_to" do
      fb =
        Freeform.new(0, 0)
        |> Freeform.add_line_segments([{100, 0}, {50, 87}])

      assert fb.operations == [{:line_to, 100, 0}, {:line_to, 50, 87}]
    end

    test "add_line_segments with close: true" do
      fb =
        Freeform.new(0, 0)
        |> Freeform.add_line_segments([{100, 0}, {50, 87}], close: true)

      assert fb.operations == [{:line_to, 100, 0}, {:line_to, 50, 87}, :close]
    end
  end

  describe "bounding_box/1" do
    test "basic triangle" do
      fb =
        Freeform.new(0, 0)
        |> Freeform.line_to(100, 0)
        |> Freeform.line_to(50, 87)

      {min_x, min_y, dx, dy} = Freeform.bounding_box(fb)
      assert min_x == 0
      assert min_y == 0
      assert dx == 100
      assert dy == 87
    end

    test "start point included in bounding box" do
      fb =
        Freeform.new(50, 50)
        |> Freeform.line_to(100, 100)

      {min_x, min_y, dx, dy} = Freeform.bounding_box(fb)
      assert min_x == 50
      assert min_y == 50
      assert dx == 50
      assert dy == 50
    end

    test "handles negative coordinates" do
      fb =
        Freeform.new(-10, -20)
        |> Freeform.line_to(30, 40)

      {min_x, min_y, dx, dy} = Freeform.bounding_box(fb)
      assert min_x == -10
      assert min_y == -20
      assert dx == 40
      assert dy == 60
    end
  end

  describe "shape_operations/1" do
    test "coordinates offset by min" do
      fb =
        Freeform.new(10, 20)
        |> Freeform.line_to(30, 40)
        |> Freeform.line_to(10, 40)

      ops = Freeform.shape_operations(fb)

      assert ops == [
               {:move_to, 0, 0},
               {:line_to, 20, 20},
               {:line_to, 0, 20}
             ]
    end
  end

  describe "Shape.freeform/3" do
    test "creates shape with correct position and size" do
      fb =
        Freeform.new(0, 0, scale: 9144)
        |> Freeform.line_to(100, 0)
        |> Freeform.line_to(50, 87)
        |> Freeform.close()

      shape = Shape.freeform(2, fb, origin_x: {1, :inches}, origin_y: {1, :inches})

      assert shape.type == :freeform
      assert shape.name == "Freeform 1"
      assert shape.x == 914_400
      assert shape.y == 914_400
      assert shape.width == round(100 * 9144)
      assert shape.height == round(87 * 9144)
      assert shape.path_data
    end

    test "fill and line are passed through" do
      fb = Freeform.new(0, 0) |> Freeform.line_to(100, 0)
      shape = Shape.freeform(2, fb, fill: "FF0000", line: "000000")

      assert shape.fill == "FF0000"
      assert shape.line == "000000"
    end
  end

  describe "XML generation" do
    test "generates custGeom instead of prstGeom" do
      fb =
        Freeform.new(0, 0)
        |> Freeform.line_to(100, 0)
        |> Freeform.line_to(50, 87)
        |> Freeform.close()

      shape = Shape.freeform(2, fb, [])
      xml = Shape.to_xml(shape)

      assert xml =~ "a:custGeom"
      refute xml =~ "a:prstGeom"
      assert xml =~ "a:pathLst"
      assert xml =~ "a:moveTo"
      assert xml =~ "a:lnTo"
      assert xml =~ "a:close"
    end

    test "has correct path w and h" do
      fb =
        Freeform.new(0, 0)
        |> Freeform.line_to(200, 0)
        |> Freeform.line_to(100, 150)

      shape = Shape.freeform(2, fb, [])
      xml = Shape.to_xml(shape)

      assert xml =~ ~s(a:path w="200" h="150")
    end

    test "freeform-specific style indices" do
      fb = Freeform.new(0, 0) |> Freeform.line_to(100, 100)
      shape = Shape.freeform(2, fb, [])
      xml = Shape.to_xml(shape)

      assert xml =~ ~s(a:lnRef idx="1")
      assert xml =~ ~s(a:fillRef idx="3")
      assert xml =~ ~s(a:effectRef idx="2")
    end

    test "no txBox attribute" do
      fb = Freeform.new(0, 0) |> Freeform.line_to(100, 100)
      shape = Shape.freeform(2, fb, [])
      xml = Shape.to_xml(shape)

      refute xml =~ "txBox"
    end

    test "fill applied when provided" do
      fb = Freeform.new(0, 0) |> Freeform.line_to(100, 100)
      shape = Shape.freeform(2, fb, fill: "4472C4")
      xml = Shape.to_xml(shape)

      assert xml =~ ~s(a:solidFill)
      assert xml =~ ~s(srgbClr val="4472C4")
    end

    test "rotation applied" do
      fb = Freeform.new(0, 0) |> Freeform.line_to(100, 100)
      shape = Shape.freeform(2, fb, rotation: 45)
      xml = Shape.to_xml(shape)

      assert xml =~ ~s(rot="2700000")
    end

    test "multiple contours with move_to" do
      fb =
        Freeform.new(0, 0)
        |> Freeform.add_line_segments([{100, 0}, {100, 100}, {0, 100}])
        |> Freeform.move_to(25, 25)
        |> Freeform.add_line_segments([{75, 25}, {75, 75}, {25, 75}])

      shape = Shape.freeform(2, fb, [])
      xml = Shape.to_xml(shape)

      # Should have 2 moveTo elements (initial + the explicit move_to)
      move_count = length(String.split(xml, "a:moveTo>")) - 1
      assert move_count >= 2
    end
  end

  describe "Podium.add_freeform/3" do
    test "adds freeform to slide" do
      prs = Podium.new()
      {_prs, slide} = Podium.add_slide(prs)

      slide =
        Freeform.new({1, :inches}, {1, :inches})
        |> Freeform.line_to({3, :inches}, {1, :inches})
        |> Freeform.line_to({2, :inches}, {2.5, :inches})
        |> Freeform.close()
        |> Podium.add_freeform(slide, fill: "4472C4")

      assert length(slide.shapes) == 1
      assert hd(slide.shapes).type == :freeform
    end
  end

  describe "integration" do
    test "save and unzip produces valid pptx" do
      prs = Podium.new()
      {prs, slide} = Podium.add_slide(prs)

      slide =
        Freeform.new({1, :inches}, {1, :inches})
        |> Freeform.line_to({3, :inches}, {1, :inches})
        |> Freeform.line_to({2, :inches}, {2.5, :inches})
        |> Freeform.close()
        |> Podium.add_freeform(slide, fill: "4472C4")

      prs = Podium.put_slide(prs, slide)
      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)

      slide_xml = parts["ppt/slides/slide1.xml"]
      assert slide_xml =~ "a:custGeom"
      assert slide_xml =~ "a:pathLst"
      assert slide_xml =~ "Freeform"
    end

    test "scale factor applied correctly" do
      fb =
        Freeform.new(0, 0, scale: 9144)
        |> Freeform.line_to(100, 0)
        |> Freeform.line_to(50, 87)
        |> Freeform.close()

      shape = Shape.freeform(2, fb, origin_x: {2, :inches}, origin_y: {1, :inches})

      # Width should be 100 * 9144 = 914400 EMU = 1 inch
      assert shape.width == round(100 * 9144)
      assert shape.height == round(87 * 9144)
      # Origin + (min * scale) where min is 0
      assert shape.x == round(2 * 914_400)
      assert shape.y == round(1 * 914_400)
    end
  end
end
