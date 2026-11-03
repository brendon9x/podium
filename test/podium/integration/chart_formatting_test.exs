defmodule Podium.Integration.ChartFormattingTest do
  # Each test writes a deck to test/podium/integration/output for visual review.
  # Every slide carries an "Expect:" caption saying what should be visible.
  use ExUnit.Case, async: true

  alias Podium.Chart.ChartData
  alias Podium.Test.PptxHelpers

  @output_dir "test/podium/integration/output"

  setup_all do
    File.mkdir_p!(@output_dir)
    :ok
  end

  defp regional_data do
    ChartData.new()
    |> ChartData.add_categories(["North", "South", "East", "West"])
    |> ChartData.add_series("2025", [48, 61, 37, 55], color: "4472C4")
    |> ChartData.add_series("2026", [52, 58, 44, 63], color: "ED7D31")
  end

  # A slide with a caption above a chart area of 12 x 5.6 inches.
  defp slide_with(caption, add_chart) do
    Podium.Slide.new()
    |> Podium.add_text_box("Expect: " <> caption,
      x: {0.5, :inches},
      y: {0.2, :inches},
      width: {12.33, :inches},
      height: {1, :inches},
      font_size: 14
    )
    |> add_chart.(
      x: {0.5, :inches},
      y: {1.4, :inches},
      width: {12, :inches},
      height: {5.6, :inches}
    )
  end

  defp save_deck(slides, name) do
    prs = Enum.reduce(slides, Podium.new(), &Podium.add_slide(&2, &1))
    path = Path.join(@output_dir, name)
    assert :ok = Podium.save(prs, path)
    {:ok, binary} = Podium.save_to_memory(prs)
    PptxHelpers.unzip_pptx_binary(binary)
  end

  describe "chart fonts" do
    test "chart-wide text, element overrides and tick label fonts" do
      data =
        regional_data()
        |> then(fn data ->
          ChartData.add_series(data, "Target", [50, 60, 45, 60],
            color: "A5A5A5",
            data_labels: %{3 => [show: [:value], bold: true, underline: true, color: "C00000"]}
          )
        end)

      slides = [
        slide_with(
          "all chart text Georgia 12pt dark grey; title 20pt bold; legend italic; " <>
            "category labels 11pt bold; value labels 9pt mid-grey; " <>
            "Target's West label bold, underlined, red",
          &Podium.add_chart(
            &1,
            :column_clustered,
            data,
            &2 ++
              [
                text: [font_size: 12, font: "Georgia", color: "404040"],
                title: [text: "Chart Fonts", font_size: 20, bold: true],
                legend: [position: :bottom, italic: true],
                category_axis: [font_size: 11, bold: true, title: [text: "Region", italic: true]],
                value_axis: [font_size: 9, color: "808080"]
              ]
          )
        ),
        slide_with(
          "chart text bold everywhere except the legend, which is regular (bold: false)",
          &Podium.add_chart(
            &1,
            :line_markers,
            regional_data(),
            &2 ++
              [
                text: [bold: true],
                title: "Bold by default",
                legend: [position: :right, bold: false]
              ]
          )
        ),
        slide_with(
          "data labels on every point, 10pt white italic, inside the bar ends",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [
                data_labels: [
                  position: :inside_end,
                  font_size: 10,
                  color: "FFFFFF",
                  italic: true
                ]
              ]
          )
        ),
        slide_with(
          "category labels rotated -45 degrees, struck through, in Courier New",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [
                category_axis: [
                  label_rotation: -45,
                  strikethrough: true,
                  font: "Courier New"
                ]
              ]
          )
        )
      ]

      parts = save_deck(slides, "chart_fonts.pptx")
      chart1 = parts["ppt/charts/chart1.xml"]

      assert chart1 =~ ~s(<a:defRPr sz="1200"><a:solidFill><a:srgbClr val="404040"/>)
      assert chart1 =~ ~s(u="sng")
      assert parts["ppt/charts/chart2.xml"] =~ ~s(<a:defRPr b="0"/>)
      assert parts["ppt/charts/chart3.xml"] =~ ~s(<c:showVal val="1"/>)
      assert parts["ppt/charts/chart4.xml"] =~ ~s(strike="sngStrike")
    end
  end

  describe "rich-text titles" do
    test "chart and axis titles with several runs and paragraphs" do
      slides = [
        slide_with(
          "title line 1 'Revenue' bold + 'by Region' italic, 20pt; line 2 smaller grey, " <>
            "right-aligned; value axis title 'Revenue ($M)' with '($M)' italic grey",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [
                title: [
                  text: [
                    [{"Revenue ", bold: true}, {"by Region", italic: true}],
                    {[{"FY2025 vs FY2026", font_size: 12, color: "808080"}], alignment: :right}
                  ],
                  font_size: 20
                ],
                value_axis: [title: [["Revenue ", {"($M)", italic: true, color: "808080"}]]]
              ]
          )
        ),
        slide_with(
          "title on two lines from a line break: 'Quarterly' / 'Results'",
          &Podium.add_chart(
            &1,
            :line_markers,
            regional_data(),
            &2 ++ [title: "Quarterly\nResults"]
          )
        )
      ]

      parts = save_deck(slides, "chart_rich_titles.pptx")
      assert parts["ppt/charts/chart1.xml"] =~ ~s(<a:pPr algn="r"/>)
      assert parts["ppt/charts/chart2.xml"] =~ "<a:br/>"
    end
  end

  describe "fill and line" do
    test "chart area, plot area, title, legend, axes, gridlines and labels" do
      backdrop = fn slide ->
        Podium.add_auto_shape(slide, :rectangle,
          x: {0.5, :inches},
          y: {1.4, :inches},
          width: {12, :inches},
          height: {5.6, :inches},
          fill: {:gradient, [{0, "FCE4D6"}, {100_000, "DDEBF7"}], angle: 0},
          line: :none
        )
      end

      slides = [
        slide_with(
          "the orange-to-blue backdrop shows through the chart (background :none, " <>
            "no chart border); plot area pale grey with a thin grey border",
          fn slide, pos ->
            slide
            |> backdrop.()
            |> Podium.add_chart(
              :column_clustered,
              regional_data(),
              pos ++ [background: :none, plot_area: [fill: "F2F2F2", line: "A6A6A6"]]
            )
          end
        ),
        slide_with(
          "title white on navy; legend boxed in grey at the top; value axis line hidden; " <>
            "dashed light grey major gridlines; category axis line thick dark grey",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [
                title: [text: "Fill and Line", fill: "1F3864", color: "FFFFFF"],
                legend: [position: :top, line: [color: "808080", width: {1, :pt}]],
                value_axis: [
                  line: :none,
                  major_gridlines: [line: [color: "BFBFBF", dash_style: :dash]]
                ],
                category_axis: [line: [color: "404040", width: {2.5, :pt}]]
              ]
          )
        ),
        slide_with(
          "category gridlines (vertical, light blue) and minor value gridlines (dotted)",
          &Podium.add_chart(
            &1,
            :line_markers,
            regional_data(),
            &2 ++
              [
                category_axis: [major_gridlines: [line: "BDD7EE"]],
                value_axis: [minor_gridlines: [line: [color: "D9D9D9", dash_style: :sys_dot]]]
              ]
          )
        ),
        slide_with(
          "every data label in a white box with a blue border; the South 2026 label yellow",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data()
            |> ChartData.add_series("Target", [50, 60, 45, 60],
              color: "A5A5A5",
              data_labels: %{1 => [show: [:value], fill: "FFFF00"]}
            ),
            &2 ++
              [
                data_labels: [
                  show: [:value],
                  position: :outside_end,
                  fill: "FFFFFF",
                  line: "4472C4",
                  font_size: 9
                ]
              ]
          )
        ),
        slide_with(
          "axis titles boxed: 'Region' with a red outline, 'Sales' on a grey fill",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [
                category_axis: [title: [text: "Region", line: "C00000"]],
                value_axis: [title: [text: "Sales", fill: "D9D9D9"]]
              ]
          )
        )
      ]

      parts = save_deck(slides, "chart_fill_and_line.pptx")
      assert parts["ppt/charts/chart1.xml"] =~ "<a:noFill/><a:ln><a:noFill/></a:ln>"
      assert parts["ppt/charts/chart3.xml"] =~ "<c:catAx>"
      assert parts["ppt/charts/chart4.xml"] =~ ~s(<a:srgbClr val="FFFF00"/>)
    end
  end

  describe "series fill and line" do
    test "outlines, markers-only lines, gradients and inverted negatives" do
      score_data =
        ChartData.new()
        |> ChartData.add_categories(["Ad A", "Ad B", "Ad C", "Ad D"])
        |> ChartData.add_series("Score", [72, 58, 64, 81], color: "4472C4")
        |> ChartData.add_series("Target", [70, 70, 70, 70],
          color: :none,
          line: [color: "404040", width: {1.5, :pt}, dash_style: :dash]
        )
        |> ChartData.add_series("Norm", [62, 60, 61, 63],
          line: :none,
          marker: [style: :dash, size: 20, fill: "ED7D31", line: "ED7D31"]
        )

      change_data =
        ChartData.new()
        |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
        |> ChartData.add_series("Inverted", [12, -8, 5, -15],
          color: "4472C4",
          invert_if_negative: true
        )
        |> ChartData.add_series("Gradient", [9, -4, 11, 6],
          fill: {:gradient, [{0, "BDD7EE"}, {100_000, "1F4E79"}], angle: 5_400_000},
          line: "1F4E79"
        )

      xy_data =
        Podium.Chart.XyChartData.new()
        |> Podium.Chart.XyChartData.add_series("Coloured markers", [1, 2, 3, 4], [3, 5, 4, 6],
          color: "C00000",
          point_colors: %{3 => "70AD47"}
        )

      bubble_data =
        Podium.Chart.BubbleChartData.new()
        |> Podium.Chart.BubbleChartData.add_series("Regions", [1, 2, 3], [4, 6, 5], [10, 20, 15],
          fill: "BDD7EE",
          line: [color: "1F4E79", width: {2, :pt}],
          point_colors: %{1 => "F4B183"}
        )

      slides = [
        slide_with(
          "blue Score bars; Target drawn as dashed dark grey outlined boxes with no fill; " <>
            "Norm as orange dashes only, with no connecting line",
          &Podium.add_combo_chart(
            &1,
            score_data,
            [{:column_clustered, series: [0, 1]}, {:line_markers, series: [2]}],
            &2 ++ [legend: :bottom]
          )
        ),
        slide_with(
          "Inverted: negative Q2 and Q4 bars drawn inverted (white or light); " <>
            "Gradient: bars shading light to dark blue with a dark blue outline",
          &Podium.add_chart(&1, :column_clustered, change_data, &2 ++ [legend: :bottom])
        ),
        slide_with(
          "red markers with no connecting line; the fourth point green",
          &Podium.add_chart(&1, :scatter, xy_data, &2)
        ),
        slide_with(
          "blue line with blue markers; South's marker green; West's marker a large " <>
            "white diamond with a red outline",
          &Podium.add_chart(
            &1,
            :line_markers,
            ChartData.new()
            |> ChartData.add_categories(["North", "South", "East", "West"])
            |> ChartData.add_series("2026", [52, 58, 44, 63],
              color: "4472C4",
              marker: [style: :circle, size: 8, fill: "4472C4", line: "4472C4"],
              point_colors: %{1 => "70AD47"},
              point_formats: %{
                3 => [fill: "FFFFFF", line: "C00000", marker: [style: :diamond, size: 14]]
              }
            ),
            &2
          )
        ),
        slide_with(
          "pale blue bubbles with a thick dark blue outline; the middle bubble orange",
          &Podium.add_chart(&1, :bubble, bubble_data, &2)
        )
      ]

      parts = save_deck(slides, "chart_series_fill_and_line.pptx")
      assert parts["ppt/charts/chart1.xml"] =~ "<a:ln><a:noFill/></a:ln>"
      assert parts["ppt/charts/chart2.xml"] =~ ~s(<c:invertIfNegative val="1"/>)
      assert parts["ppt/charts/chart3.xml"] =~ "<c:dPt><c:idx val=\"3\"/><c:marker>"
      assert parts["ppt/charts/chart4.xml"] =~ ~s(<c:symbol val="diamond"/><c:size val="14"/>)
      assert parts["ppt/charts/chart5.xml"] =~ "<c:dPt>"
    end
  end

  describe "manual layout" do
    test "plot area, legend and titles placed by hand" do
      slides = [
        slide_with(
          "title in the top-left corner; plot area (shaded) on the left two-thirds; " <>
            "legend boxed in the right third, upper half",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [
                title: [text: "Manual Layout", x: 0.02, y: 0.02],
                legend: [x: 0.72, y: 0.15, w: 0.25, h: 0.35, line: "808080"],
                plot_area: [x: 0.06, y: 0.15, w: 0.62, h: 0.75, fill: "F2F2F2"]
              ]
          )
        ),
        slide_with(
          "legend floats over the top-right of the plot area (overlay), plot area full width",
          &Podium.add_chart(
            &1,
            :line_markers,
            regional_data(),
            &2 ++ [legend: [position: :right, x: 0.8, y: 0.05, overlay: true, fill: "FFFFFF"]]
          )
        ),
        slide_with(
          "plot area with :outer target: the tick labels sit inside the shaded box",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++
              [plot_area: [x: 0.1, y: 0.1, w: 0.8, h: 0.8, target: :outer, fill: "FFF2CC"]]
          )
        ),
        slide_with(
          "value axis title 'Sales' at the far left, half-way up",
          &Podium.add_chart(
            &1,
            :column_clustered,
            regional_data(),
            &2 ++ [value_axis: [title: [text: "Sales", x: 0.0, y: 0.45]]]
          )
        )
      ]

      parts = save_deck(slides, "chart_manual_layout.pptx")
      assert parts["ppt/charts/chart1.xml"] =~ "<c:manualLayout>"
      assert parts["ppt/charts/chart2.xml"] =~ ~s(<c:overlay val="1"/>)
      assert parts["ppt/charts/chart3.xml"] =~ ~s(<c:layoutTarget val="outer"/>)
    end
  end
end
