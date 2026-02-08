# 16:9 slide = 13.33" x 7.5"
# Layout: 0.5" margin on each side = 12.33" usable width
# Two-column: each chart ~5.9" wide with 0.5" gap
# Three-column: each chart ~3.78" wide with 0.5" gap

alias Podium.Chart.{BubbleChartData, ChartData, XyChartData}

# Two charts per row
left = fn y -> [x: {0.5, :inches}, y: {y, :inches}, width: {5.9, :inches}, height: {3, :inches}] end
right = fn y -> [x: {6.9, :inches}, y: {y, :inches}, width: {5.9, :inches}, height: {3, :inches}] end

# Three charts per row
col1 = fn y -> [x: {0.5, :inches}, y: {y, :inches}, width: {3.78, :inches}, height: {3, :inches}] end
col2 = fn y -> [x: {4.78, :inches}, y: {y, :inches}, width: {3.78, :inches}, height: {3, :inches}] end
col3 = fn y -> [x: {9.05, :inches}, y: {y, :inches}, width: {3.78, :inches}, height: {3, :inches}] end

add_title = fn slide, text ->
  Podium.add_text_box(slide, text,
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12.33, :inches},
    height: {0.6, :inches},
    font_size: 24
  )
end

# -- Shared data --

cat_data = fn ->
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Product A", [20, 35, 30, 35], color: "4472C4")
  |> ChartData.add_series("Product B", [25, 25, 35, 25], color: "ED7D31")
  |> ChartData.add_series("Product C", [55, 40, 35, 40], color: "A5A5A5")
end

pie_data =
  ChartData.new()
  |> ChartData.add_categories(["Apples", "Bananas", "Cherries", "Dates"])
  |> ChartData.add_series("Fruit", [35, 25, 20, 20])

radar_data =
  ChartData.new()
  |> ChartData.add_categories(["Speed", "Power", "Range", "Durability", "Precision"])
  |> ChartData.add_series("Model A", [80, 90, 70, 85, 75], color: "4472C4")
  |> ChartData.add_series("Model B", [70, 65, 95, 70, 90], color: "ED7D31")

xy_data = fn ->
  XyChartData.new()
  |> XyChartData.add_series("Series 1", [1, 2, 3, 4, 5], [2.3, 4.1, 3.7, 5.2, 4.8],
    color: "4472C4"
  )
  |> XyChartData.add_series("Series 2", [1, 2, 3, 4, 5], [1.5, 3.2, 2.8, 4.5, 3.9],
    color: "ED7D31"
  )
end

bubble_data =
  BubbleChartData.new()
  |> BubbleChartData.add_series("Region A", [1, 3, 5, 7], [10, 25, 15, 30], [5, 12, 8, 15],
    color: "4472C4"
  )
  |> BubbleChartData.add_series("Region B", [2, 4, 6, 8], [20, 15, 30, 10], [10, 6, 14, 8],
    color: "ED7D31"
  )

prs = Podium.new()

# -- Slide 1: Stacked 100% variants (2x2 grid) --

{prs, s1} = Podium.add_slide(prs)
s1 = add_title.(s1, "Stacked 100% Charts")
{prs, s1} = Podium.add_chart(prs, s1, :column_stacked_100, cat_data.(), left.(1.2))
{prs, s1} = Podium.add_chart(prs, s1, :bar_stacked_100, cat_data.(), right.(1.2))
{prs, s1} = Podium.add_chart(prs, s1, :line_stacked_100, cat_data.(), left.(4.3))
{prs, s1} = Podium.add_chart(prs, s1, :line_markers_stacked_100, cat_data.(), right.(4.3))
prs = Podium.put_slide(prs, s1)

# -- Slide 2: Area charts (3-col top row) --

{prs, s2} = Podium.add_slide(prs)
s2 = add_title.(s2, "Area Charts")
{prs, s2} = Podium.add_chart(prs, s2, :area, cat_data.(), col1.(1.2))
{prs, s2} = Podium.add_chart(prs, s2, :area_stacked, cat_data.(), col2.(1.2))
{prs, s2} = Podium.add_chart(prs, s2, :area_stacked_100, cat_data.(), col3.(1.2))
prs = Podium.put_slide(prs, s2)

# -- Slide 3: Pie exploded + Doughnuts (3-col) --

{prs, s3} = Podium.add_slide(prs)
s3 = add_title.(s3, "Pie Exploded & Doughnut Charts")
{prs, s3} = Podium.add_chart(prs, s3, :pie_exploded, pie_data, col1.(1.2))
{prs, s3} = Podium.add_chart(prs, s3, :doughnut, pie_data, col2.(1.2))
{prs, s3} = Podium.add_chart(prs, s3, :doughnut_exploded, pie_data, col3.(1.2))
prs = Podium.put_slide(prs, s3)

# -- Slide 4: Line stacked + Radar (2-col top, 3-col bottom) --

{prs, s4} = Podium.add_slide(prs)
s4 = add_title.(s4, "Line Stacked & Radar Charts")
{prs, s4} = Podium.add_chart(prs, s4, :line_stacked, cat_data.(), left.(1.2))
{prs, s4} = Podium.add_chart(prs, s4, :line_markers_stacked, cat_data.(), right.(1.2))
{prs, s4} = Podium.add_chart(prs, s4, :radar, radar_data, col1.(4.3))
{prs, s4} = Podium.add_chart(prs, s4, :radar_filled, radar_data, col2.(4.3))
{prs, s4} = Podium.add_chart(prs, s4, :radar_markers, radar_data, col3.(4.3))
prs = Podium.put_slide(prs, s4)

# -- Slide 5: Scatter variants (2x2 + 1 centered) --

{prs, s5} = Podium.add_slide(prs)
s5 = add_title.(s5, "Scatter Charts")
{prs, s5} = Podium.add_chart(prs, s5, :scatter, xy_data.(), left.(1.2))
{prs, s5} = Podium.add_chart(prs, s5, :scatter_lines, xy_data.(), right.(1.2))
{prs, s5} = Podium.add_chart(prs, s5, :scatter_lines_no_markers, xy_data.(), left.(4.3))
{prs, s5} = Podium.add_chart(prs, s5, :scatter_smooth, xy_data.(), right.(4.3))
prs = Podium.put_slide(prs, s5)

# -- Slide 6: Scatter smooth no markers + Bubble (3-col) --

{prs, s6} = Podium.add_slide(prs)
s6 = add_title.(s6, "Scatter Smooth & Bubble Charts")
{prs, s6} = Podium.add_chart(prs, s6, :scatter_smooth_no_markers, xy_data.(), col1.(1.2))
{prs, s6} = Podium.add_chart(prs, s6, :bubble, bubble_data, col2.(1.2))
{prs, s6} = Podium.add_chart(prs, s6, :bubble_3d, bubble_data, col3.(1.2))
prs = Podium.put_slide(prs, s6)

# Save
Podium.save(prs, "chart_types_demo.pptx")
IO.puts("Saved chart_types_demo.pptx with 22 new chart types across 6 slides")
