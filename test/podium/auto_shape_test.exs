defmodule Podium.AutoShapeTest do
  use ExUnit.Case, async: true

  alias Podium.Test.PptxHelpers

  describe "auto shapes" do
    test "XML has no txBox attribute" do
      slide = Podium.Slide.new()

      slide =
        Podium.add_auto_shape(slide, :rounded_rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {1, :inches}
        )

      shape = hd(slide.shapes)
      xml = Podium.Shape.to_xml(shape)

      refute xml =~ ~s(txBox="1")
      assert xml =~ ~s(<p:cNvSpPr/>)
    end

    test "XML has correct prst for several representative shapes" do
      shapes = [
        {:rounded_rectangle, "roundRect"},
        {:oval, "ellipse"},
        {:diamond, "diamond"},
        {:right_arrow, "rightArrow"},
        {:star_5_point, "star5"},
        {:flowchart_process, "flowChartProcess"},
        {:heart, "heart"},
        {:hexagon, "hexagon"}
      ]

      for {preset, expected_prst} <- shapes do
        shape =
          Podium.Shape.auto_shape(2, preset,
            x: {1, :inches},
            y: {1, :inches},
            width: {2, :inches},
            height: {1, :inches}
          )

        xml = Podium.Shape.to_xml(shape)
        assert xml =~ ~s(prst="#{expected_prst}"), "Expected prst=#{expected_prst} for #{preset}"
      end
    end

    test "name follows Basename N pattern" do
      shape =
        Podium.Shape.auto_shape(5, :heart,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {1, :inches}
        )

      assert shape.name == "Heart 4"
      xml = Podium.Shape.to_xml(shape)
      assert xml =~ ~s(name="Heart 4")
    end

    test "with text includes paragraphs" do
      shape =
        Podium.Shape.auto_shape(2, :rounded_rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches},
          text: "Hello Shape"
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "Hello Shape"
      assert xml =~ "<a:p>"
    end

    test "without text includes empty <a:p/>" do
      shape =
        Podium.Shape.auto_shape(2, :oval,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "<a:p/>"
    end

    test "fill works on auto shapes" do
      shape =
        Podium.Shape.auto_shape(2, :rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {1, :inches},
          fill: "FF0000"
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ ~s(<a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>)
    end

    test "nil fill omits fill element for theme style to apply" do
      shape =
        Podium.Shape.auto_shape(2, :rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {1, :inches}
        )

      xml = Podium.Shape.to_xml(shape)
      refute xml =~ "<a:noFill/>"
      refute xml =~ "<a:solidFill>"
    end

    test "line works on auto shapes" do
      shape =
        Podium.Shape.auto_shape(2, :chevron,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {1, :inches},
          line: [color: "000000", width: {2, :pt}]
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ ~s(<a:ln w="25400">)
    end

    test "rotation works on auto shapes" do
      shape =
        Podium.Shape.auto_shape(2, :diamond,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches},
          rotation: 45
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ ~s(rot="2700000")
    end

    test "includes <p:style> element" do
      shape =
        Podium.Shape.auto_shape(2, :oval,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "<p:style>"
      assert xml =~ ~s(<a:fillRef idx="1">)
      assert xml =~ ~s(<a:lnRef idx="2">)
      assert xml =~ "</p:style>"
    end
  end

  describe "auto-size" do
    test ":none generates <a:noAutofit/>" do
      shape =
        Podium.Shape.auto_shape(2, :rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches},
          text: "Test",
          auto_size: :none
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "<a:noAutofit/>"
    end

    test ":text_to_fit_shape generates <a:normAutofit/>" do
      shape =
        Podium.Shape.auto_shape(2, :rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches},
          text: "Test",
          auto_size: :text_to_fit_shape
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "<a:normAutofit/>"
    end

    test ":shape_to_fit_text generates <a:spAutoFit/>" do
      shape =
        Podium.Shape.auto_shape(2, :rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches},
          text: "Test",
          auto_size: :shape_to_fit_text
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "<a:spAutoFit/>"
    end

    test "nil auto_size generates self-closing <a:bodyPr.../>" do
      shape =
        Podium.Shape.auto_shape(2, :rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches},
          text: "Test"
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ ~s(<a:bodyPr wrap="square" rtlCol="0" anchor="ctr"/>)
      refute xml =~ "<a:noAutofit/>"
      refute xml =~ "<a:normAutofit/>"
      refute xml =~ "<a:spAutoFit/>"
    end

    test "auto_size works on text boxes too" do
      shape =
        Podium.Shape.text_box(2, "Fit me",
          x: {1, :inches},
          y: {1, :inches},
          width: {3, :inches},
          height: {1, :inches},
          auto_size: :text_to_fit_shape
        )

      xml = Podium.Shape.to_xml(shape)
      assert xml =~ "<a:normAutofit/>"
      assert xml =~ ~s(txBox="1")
    end
  end

  describe "integration" do
    test "auto shapes produce valid pptx" do
      slide =
        Podium.Slide.new()
        |> Podium.add_auto_shape(:rounded_rectangle,
          x: {1, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {1, :inches},
          text: "Round Rect",
          fill: "4472C4"
        )
        |> Podium.add_auto_shape(:star_5_point,
          x: {4, :inches},
          y: {1, :inches},
          width: {2, :inches},
          height: {2, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)

      parts = PptxHelpers.unzip_pptx_binary(binary)
      slide_xml = parts["ppt/slides/slide1.xml"]

      assert slide_xml =~ ~s(prst="roundRect")
      assert slide_xml =~ ~s(prst="star5")
      assert slide_xml =~ "Round Rect"
      refute slide_xml =~ ~s(txBox="1")
    end
  end
end
