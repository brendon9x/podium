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
    pattern: [type: :dn_diag, foreground: "4472C4", background: "FFFFFF"]
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

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.add_slide(s6)
|> Podium.add_slide(s7)
|> Podium.add_slide(s8)
|> Podium.save("demos/output/charts.pptx")

IO.puts("Generated demos/output/charts.pptx")
