File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

# Brand colors
primary = "003366"
accent1 = "4472C4"
accent2 = "ED7D31"
accent3 = "70AD47"
white = "FFFFFF"

prs = Podium.new(title: "Q4 2025 Business Review", author: "Analytics Team")

# Slide 1: Title slide with brand colors
s1 =
  Podium.Slide.new(:title_slide)
  |> Podium.set_placeholder(:title, [
    [{"Q4 2025 Business Review", bold: true, font_size: 40, color: primary}]
  ])
  |> Podium.set_placeholder(:subtitle, "Analytics Team -- Prepared February 2026")

# Slide 2: Executive summary -- gradient header bar + bullets
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Executive Summary", bold: true, font_size: 28, color: white}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    fill: {:gradient, [{0, "001133"}, {100_000, accent1}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    [
      {[
         {"Revenue grew ", font_size: 16},
         {"28% year-over-year", bold: true, font_size: 16, color: accent3}
       ], space_after: 6},
      {["Total revenue reached $60.4M across all regions"], bullet: true},
      {["North America led growth at 35%"], bullet: true, level: 1},
      {["APAC expanded 22%"], bullet: true, level: 1},
      {["Customer satisfaction hit 92%, up from 86%"], bullet: true},
      {["Net Promoter Score improved 15 points to 67"], bullet: true},
      {["Engineering delivered all roadmap milestones on schedule"], bullet: true},
      {[
         {"Recommendation: ", font_size: 16},
         {"Increase APAC investment by 30% in H1 2026", bold: true, font_size: 16}
       ], space_before: 12}
    ],
    x: {0.5, :inches},
    y: {1.3, :inches},
    width: {11, :inches},
    height: {5, :inches}
  )

# Slide 3: Revenue clustered column chart
revenue_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: accent1)
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: accent2)
  |> ChartData.add_series("Net Profit", [2_500, 3_300, 2_700, 5_100], color: accent3)

s3 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, revenue_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: [text: "Quarterly Revenue vs Expenses", font_size: 18, bold: true, color: primary],
    legend: [position: :bottom, font_size: 10],
    data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0", font_size: 9],
    category_axis: [title: "Quarter"],
    value_axis: [
      title: "Amount ($)",
      number_format: "$#,##0",
      major_gridlines: true,
      min: 0,
      max: 20_000,
      major_unit: 5_000
    ]
  )

# Slide 4: Market share pie chart
market_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia Pacific", "Latin America"])
  |> ChartData.add_series("Revenue", [25_200, 16_800, 12_100, 6_300],
    point_colors: %{0 => accent1, 1 => "BDD7EE", 2 => accent2, 3 => "FBE5D6"}
  )

s4 =
  Podium.Slide.new()
  |> Podium.add_chart(:pie, market_data,
    x: {1.5, :inches},
    y: {0.5, :inches},
    width: {9, :inches},
    height: {6, :inches},
    title: [text: "Revenue by Region", font_size: 18, bold: true, color: primary],
    legend: :right,
    data_labels: [:category, :percent]
  )

# Slide 5: Department table with merged title row
s5 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Department Performance", bold: true, font_size: 24, color: primary}],
       alignment: :center}
    ],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_table(
    [
      [
        {[[{"Department Performance -- Q4 2025", color: white}]], col_span: 5, fill: primary},
        :merge,
        :merge,
        :merge,
        :merge
      ],
      [
        {[[{"Department", color: white}]],
         fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
        {[[{"Headcount", color: white}]],
         fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
        {[[{"Budget", color: white}]],
         fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
        {[[{"Revenue", color: white}]],
         fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
        {[[{"Satisfaction", color: white}]],
         fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]}
      ],
      [
        "Engineering",
        "230",
        "$4,200K",
        "$18,100K",
        {[[{"92%", bold: true, color: accent3}]], anchor: :middle}
      ],
      ["Marketing", "85", "$2,100K", "$15,200K", "87%"],
      ["Sales", "120", "$3,500K", "$21,800K", "84%"],
      ["Operations", "65", "$1,800K", "$5,300K", "91%"]
    ],
    x: {0.5, :inches},
    y: {1.2, :inches},
    width: {11, :inches},
    height: {4.5, :inches}
  )

# Slide 6: Trend line chart with markers
trend_data =
  ChartData.new()
  |> ChartData.add_categories(["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
  |> ChartData.add_series("Web", [68, 72, 70, 74, 78, 85],
    color: accent1,
    marker: [style: :circle, size: 6, fill: accent1]
  )
  |> ChartData.add_series("Mobile", [62, 68, 71, 75, 80, 92],
    color: accent2,
    marker: [style: :diamond, size: 6, fill: accent2]
  )
  |> ChartData.add_series("API", [22, 25, 28, 30, 33, 38],
    color: accent3,
    marker: [style: :square, size: 6, fill: accent3]
  )

s6 =
  Podium.Slide.new()
  |> Podium.add_chart(:line_markers, trend_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: [
      text: "Monthly Active Users (H2 2025)",
      font_size: 18,
      bold: true,
      color: primary
    ],
    legend: :bottom,
    value_axis: [title: "Users (thousands)", major_gridlines: true]
  )

# Slide 7: Conclusion with title+content layout
s7 =
  Podium.Slide.new(:title_content)
  |> Podium.set_placeholder(:title, "Key Takeaways & Next Steps")
  |> Podium.set_placeholder(:content, [
    [{"Revenue up 28% YoY, driven by North America and APAC"}],
    [{"Customer satisfaction at all-time high of 92%"}],
    [{"Engineering delivered 100% of roadmap milestones"}],
    [{"Increase APAC investment by 30% in H1 2026"}],
    [{"Launch self-service analytics platform by Q2"}],
    [{"Target 95% customer satisfaction by year-end"}]
  ])
  |> Podium.set_notes(
    "Talking points: Emphasize the APAC growth opportunity. " <>
      "Mention the board approved the additional investment. " <>
      "Remind the audience about the customer advisory board meeting in March."
  )

# Add footer and save
prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.add_slide(s6)
|> Podium.add_slide(s7)
|> Podium.set_footer(
  footer: "Acme Corp -- Confidential",
  date: "February 2026",
  slide_number: true
)
|> Podium.save("demos/output/building-a-report.pptx")

IO.puts("Generated demos/output/building-a-report.pptx")
