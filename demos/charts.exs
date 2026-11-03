File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData
alias Podium.Chart.XyChartData
alias Podium.Chart.BubbleChartData

prs = Podium.new()

# Slide 1: Column clustered with axis config, data labels, titles
col_data =
  ChartData.new()
  |> ChartData.add_categories(["Engineering", "Marketing", "Sales", "Support"])
  |> ChartData.add_series("Headcount", [230, 85, 120, 65], color: "4472C4")
  |> ChartData.add_series("Budget ($K)", [4200, 2100, 3500, 1800], color: "ED7D31")

s1 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, col_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: [text: "Department Overview", font_size: 18, bold: true, color: "003366"],
    legend: [position: :bottom, font_size: 10],
    data_labels: [show: [:value], position: :outside_end],
    category_axis: [title: "Department"],
    value_axis: [title: "Count / Amount", major_gridlines: true]
  )

# Slide 2: Stacked bar chart
channel_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Email", [250, 230, 210, 200, 185, 170], color: "4472C4")
  |> ChartData.add_series("Chat", [180, 200, 220, 250, 280, 310], color: "ED7D31")
  |> ChartData.add_series("Phone", [100, 95, 90, 85, 80, 75], color: "A5A5A5")

s2 =
  Podium.Slide.new()
  |> Podium.add_chart(:bar_stacked, channel_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Support Tickets by Channel",
    legend: :right
  )

# Slide 3: Line chart with markers
trend_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Web", [45, 48, 52, 55, 60, 63], color: "4472C4")
  |> ChartData.add_series("Mobile", [30, 35, 38, 42, 50, 55], color: "ED7D31")

s3 =
  Podium.Slide.new()
  |> Podium.add_chart(:line_markers, trend_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Monthly Active Users",
    legend: :top,
    value_axis: [title: "Users (thousands)", major_gridlines: true]
  )

# Slide 4: Pie chart with per-point colors and category+percent labels
market_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia Pacific", "Latin America"])
  |> ChartData.add_series("Revenue", [42, 28, 18, 12],
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31", 3 => "FBE5D6"}
  )

s4 =
  Podium.Slide.new()
  |> Podium.add_chart(:pie, market_data,
    x: {2, :inches},
    y: {0.5, :inches},
    width: {9, :inches},
    height: {6, :inches},
    title: "Revenue by Region",
    legend: :right,
    data_labels: [:category, :percent]
  )

# Slide 5: Radar filled chart
skill_data =
  ChartData.new()
  |> ChartData.add_categories(["Speed", "Power", "Range", "Durability", "Precision"])
  |> ChartData.add_series("Model A", [80, 90, 70, 85, 75], color: "4472C4")
  |> ChartData.add_series("Model B", [70, 65, 95, 70, 90], color: "ED7D31")

s5 =
  Podium.Slide.new()
  |> Podium.add_chart(:radar_filled, skill_data,
    x: {2, :inches},
    y: {0.5, :inches},
    width: {9, :inches},
    height: {6, :inches},
    title: "Product Comparison",
    legend: :bottom
  )

# Slide 6: Scatter chart (XyChartData, non-monotonic X values)
xy_data =
  XyChartData.new()
  |> XyChartData.add_series("Series A", [1, 2, 3, 4, 5], [2.3, 4.1, 3.7, 5.2, 4.8],
    color: "4472C4"
  )
  |> XyChartData.add_series("Series B", [1, 2, 3, 4, 5], [1.5, 3.2, 2.8, 4.5, 3.9],
    color: "ED7D31"
  )

s6 =
  Podium.Slide.new()
  |> Podium.add_chart(:scatter, xy_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Scatter Analysis",
    legend: :bottom
  )

# Slide 7: Bubble chart (BubbleChartData)
bubble_data =
  BubbleChartData.new()
  |> BubbleChartData.add_series("Region A", [1, 3, 5, 7], [10, 25, 15, 30], [5, 12, 8, 15],
    color: "4472C4"
  )
  |> BubbleChartData.add_series("Region B", [2, 4, 6, 8], [20, 15, 30, 10], [10, 6, 14, 8],
    color: "ED7D31"
  )

s7 =
  Podium.Slide.new()
  |> Podium.add_chart(:bubble, bubble_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Market Opportunity Analysis",
    legend: :bottom
  )

# Slide 8: Chart with pattern fills + per-point formatting
pattern_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Email", [250, 230, 210, 200],
    fill: {:pattern, :dn_diag, foreground: "4472C4", background: "FFFFFF"}
  )
  |> ChartData.add_series("Revenue", [42, 28, 18, 35],
    color: "ED7D31",
    point_formats: %{
      0 => [fill: "2E75B6", line: [color: "001133", width: {2, :pt}]],
      3 => [fill: "ED7D31", line: [color: "7F3300", width: {2, :pt}]]
    }
  )

s8 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, pattern_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Pattern Fills & Per-Point Formatting",
    legend: :bottom
  )

# Slide 9: Chart fonts - chart-wide text, per-element overrides, tick label fonts
font_data =
  ChartData.new()
  |> ChartData.add_categories(["North", "South", "East", "West"])
  |> ChartData.add_series("2025", [48, 61, 37, 55], color: "4472C4")
  |> ChartData.add_series("2026", [52, 58, 44, 63], color: "ED7D31")

# The same figures with a target series, its West label styled on its own
font_override_data =
  ChartData.add_series(font_data, "Target", [50, 60, 45, 60],
    color: "A5A5A5",
    data_labels: %{3 => [show: [:value], bold: true, underline: true, color: "C00000"]}
  )

s9 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, font_override_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    text: [font_size: 12, font: "Georgia", color: "404040"],
    title: [text: "Chart Fonts", font_size: 20, bold: true],
    legend: [position: :bottom, italic: true],
    data_labels: [position: :outside_end, font_size: 10],
    category_axis: [font_size: 11, bold: true, title: [text: "Region", italic: true]],
    value_axis: [font_size: 9, color: "808080"]
  )

# Slide 10: Rich-text chart and axis titles
s10 =
  Podium.Slide.new()
  |> Podium.add_chart(:line_markers, font_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: [
      text: [
        [{"Revenue ", bold: true}, {"by Region", italic: true}],
        [{"FY2025 vs FY2026, in $M", font_size: 12, color: "808080"}]
      ],
      font_size: 20
    ],
    legend: :bottom,
    value_axis: [title: [["Revenue ", {"($M)", italic: true, color: "808080"}]]]
  )

# Slide 11: Fill and line on chart elements
s11 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, col_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: [text: "Fill and Line", fill: "1F3864", line: :none, color: "FFFFFF", bold: true],
    background: :none,
    plot_area: [fill: "F7F9FC", line: [color: "D9D9D9", width: {0.75, :pt}]],
    legend: [position: :top, line: "BFBFBF"],
    value_axis: [line: :none, major_gridlines: [line: [color: "D9D9D9", dash_style: :dash]]],
    category_axis: [line: [color: "404040", width: {1.5, :pt}]],
    data_labels: [show: [:value], position: :inside_end, fill: "FFFFFF", line: "4472C4", font_size: 9]
  )

# Slide 12: Series lines - outlined bars and a markers-only norm line
score_data =
  ChartData.new()
  |> ChartData.add_categories(["Ad A", "Ad B", "Ad C", "Ad D", "Ad E"])
  |> ChartData.add_series("Score", [72, 58, 64, 81, 49],
    color: "4472C4",
    point_colors: %{3 => "70AD47", 4 => "C00000"}
  )
  |> ChartData.add_series("Target", [70, 70, 70, 70, 70],
    color: :none,
    line: [color: "404040", width: {1.5, :pt}, dash_style: :dash]
  )
  |> ChartData.add_series("Norm", [62, 60, 61, 63, 59],
    line: :none,
    marker: [style: :dash, size: 20, fill: "ED7D31", line: "ED7D31"]
  )

s12 =
  Podium.Slide.new()
  |> Podium.add_combo_chart(
    score_data,
    [{:column_clustered, series: [0, 1]}, {:line_markers, series: [2]}],
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Series Lines",
    legend: :bottom
  )

# Slide 13: Manual layout of the title, legend and plot area
s13 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, font_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: [text: "Manual Layout", x: 0.02, y: 0.02],
    legend: [x: 0.82, y: 0.15, w: 0.16, h: 0.3, line: "BFBFBF"],
    plot_area: [x: 0.06, y: 0.15, w: 0.72, h: 0.72, fill: "F7F9FC"]
  )

# Slide 14: Plot options - bar width and colour by category
s14 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, font_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {6, :inches},
    height: {6, :inches},
    title: "gap_width: 40, overlap: 0",
    legend: :bottom,
    gap_width: 40,
    overlap: 0
  )
  |> Podium.add_chart(
    :column_clustered,
    ChartData.new()
    |> ChartData.add_categories(["North", "South", "East", "West"])
    |> ChartData.add_series("2026", [52, 58, 44, 63]),
    x: {6.75, :inches},
    y: {0.5, :inches},
    width: {6, :inches},
    height: {6, :inches},
    title: "vary_by_categories: true",
    vary_by_categories: true,
    gap_width: 80
  )

# Slide 15: Series data labels with a point override and an unlabelled series
label_data =
  ChartData.new()
  |> ChartData.add_categories(["Ad A", "Ad B", "Ad C", "Ad D"])
  |> ChartData.add_series("Score", [72, 58, 64, 81],
    color: "4472C4",
    data_labels: [
      show: [:value],
      position: :inside_end,
      color: "FFFFFF",
      points: %{3 => [show: [:value, :category], separator: "\n", bold: true]}
    ]
  )
  |> ChartData.add_series("Target", [70, 70, 70, 70], color: "D9D9D9", data_labels: [show: []])

s15 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, label_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Series Data Labels",
    legend: :bottom,
    data_labels: [show: [:value], position: :outside_end]
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.add_slide(s6)
|> Podium.add_slide(s7)
|> Podium.add_slide(s8)
|> Podium.add_slide(s9)
|> Podium.add_slide(s10)
|> Podium.add_slide(s11)
|> Podium.add_slide(s12)
|> Podium.add_slide(s13)
|> Podium.add_slide(s14)
|> Podium.add_slide(s15)
|> Podium.save("demos/output/charts.pptx")

IO.puts("Generated demos/output/charts.pptx")
