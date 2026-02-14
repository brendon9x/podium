defmodule Podium.Chart.ScatterBubbleTest do
  use ExUnit.Case, async: true

  alias Podium.Chart
  alias Podium.Chart.{BubbleChartData, XmlWriter, XyChartData}

  # -- Scatter charts --

  describe "scatter (markers only)" do
    test "generates scatterChart with lineMarker style" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      chart = %Chart{chart_type: :scatter, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:scatterChart>"
      assert xml =~ ~s(<c:scatterStyle val="lineMarker"/>)
      assert xml =~ ~s(c:varyColors val="0")
    end

    test "has xVal and yVal elements" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      chart = %Chart{chart_type: :scatter, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:xVal>"
      assert xml =~ "<c:yVal>"
      refute xml =~ "<c:cat>"
      refute xml =~ "<c:val>"
    end

    test "has two valAx (no catAx)" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])

      chart = %Chart{chart_type: :scatter, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      val_ax_count = length(Regex.scan(~r/<c:valAx>/, xml))
      assert val_ax_count == 2
      refute xml =~ "<c:catAx>"
    end

    test "scatter (markers only) hides line with noFill" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])

      chart = %Chart{chart_type: :scatter, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<a:noFill/>"
    end

    test "has crossBetween midCat on axes" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])

      chart = %Chart{chart_type: :scatter, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:crossBetween val="midCat"/>)
    end

    test "smooth val=0 for non-smooth scatter" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])

      chart = %Chart{chart_type: :scatter, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:smooth val="0"/>)
    end
  end

  describe "scatter_lines" do
    test "no noFill (lines visible)" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])

      chart = %Chart{chart_type: :scatter_lines, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:scatterChart>"
      refute xml =~ "<a:noFill/>"
    end
  end

  describe "scatter_lines_no_markers" do
    test "hides markers" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2], [10, 20])

      chart = %Chart{chart_type: :scatter_lines_no_markers, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:symbol val="none"/>)
      refute xml =~ "<a:noFill/>"
    end
  end

  describe "scatter_smooth" do
    test "smooth val=1" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      chart = %Chart{chart_type: :scatter_smooth, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:scatterStyle val="smoothMarker"/>)
      assert xml =~ ~s(<c:smooth val="1"/>)
    end
  end

  describe "scatter_smooth_no_markers" do
    test "smooth with hidden markers" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("S1", [1, 2, 3], [10, 20, 30])

      chart = %Chart{chart_type: :scatter_smooth_no_markers, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:smooth val="1"/>)
      assert xml =~ ~s(<c:symbol val="none"/>)
    end
  end

  # -- Bubble charts --

  describe "bubble" do
    test "generates bubbleChart" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2, 3], [10, 20, 30], [5, 10, 15])

      chart = %Chart{chart_type: :bubble, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:bubbleChart>"
      assert xml =~ ~s(c:varyColors val="0")
      assert xml =~ ~s(<c:bubbleScale val="100"/>)
      assert xml =~ ~s(<c:showNegBubbles val="0"/>)
    end

    test "has xVal, yVal, and bubbleSize" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])

      chart = %Chart{chart_type: :bubble, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ "<c:xVal>"
      assert xml =~ "<c:yVal>"
      assert xml =~ "<c:bubbleSize>"
    end

    test "bubble3D is false for standard bubble" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])

      chart = %Chart{chart_type: :bubble, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:bubble3D val="0"/>)
    end

    test "has invertIfNegative on each series" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])

      chart = %Chart{chart_type: :bubble, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:invertIfNegative val="0"/>)
    end

    test "has two valAx (no catAx)" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])

      chart = %Chart{chart_type: :bubble, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      val_ax_count = length(Regex.scan(~r/<c:valAx>/, xml))
      assert val_ax_count == 2
      refute xml =~ "<c:catAx>"
    end
  end

  describe "bubble_3d" do
    test "bubble3D is true" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("S1", [1, 2], [10, 20], [5, 10])

      chart = %Chart{chart_type: :bubble_3d, chart_data: chart_data}
      xml = XmlWriter.to_xml(chart)

      assert xml =~ ~s(<c:bubble3D val="1"/>)
    end
  end

  # -- Integration --

  describe "scatter chart integration" do
    test "full pptx with scatter chart" do
      chart_data =
        XyChartData.new()
        |> XyChartData.add_series("Series 1", [1, 2, 3, 4], [10, 30, 20, 40])

      slide =
        Podium.Slide.new()
        |> Podium.add_chart(:scatter, chart_data,
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = Podium.Test.PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:scatterChart"
      assert chart_xml =~ "c:xVal"
      assert chart_xml =~ "c:yVal"

      # Embedded xlsx exists
      assert Map.has_key?(parts, "ppt/embeddings/Microsoft_Excel_Sheet1.xlsx")
    end
  end

  describe "bubble chart integration" do
    test "full pptx with bubble chart" do
      chart_data =
        BubbleChartData.new()
        |> BubbleChartData.add_series("B1", [1, 2, 3], [10, 20, 30], [5, 15, 10])

      slide =
        Podium.Slide.new()
        |> Podium.add_chart(:bubble, chart_data,
          x: {1, :inches},
          y: {1, :inches},
          width: {6, :inches},
          height: {4, :inches}
        )

      prs =
        Podium.new()
        |> Podium.add_slide(slide)

      {:ok, binary} = Podium.save_to_memory(prs)
      parts = Podium.Test.PptxHelpers.unzip_pptx_binary(binary)

      chart_xml = parts["ppt/charts/chart1.xml"]
      assert chart_xml =~ "c:bubbleChart"
      assert chart_xml =~ "c:bubbleSize"
    end
  end
end
