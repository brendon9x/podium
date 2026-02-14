File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title slide layout with styled title/subtitle
s1 =
  Podium.Slide.new(:title_slide)
  |> Podium.set_placeholder(:title, [
    [{"Quarterly Business Review", bold: true, font_size: 40, color: "003366"}]
  ])
  |> Podium.set_placeholder(:subtitle, "Engineering Division -- Q4 2025")

# Slide 2: Rich text with bullets and numbered lists
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Team Highlights", bold: true, font_size: 28, color: "003366"}],
       alignment: :center, space_after: 12},
      {[{"Status: ", font_size: 16}, {"On Track", bold: true, font_size: 16, color: "228B22"}],
       space_after: 8},
      {["Shipped v2.0 to production"], bullet: true},
      {["Reduced API latency by 40%"], bullet: true},
      {["99.9% uptime maintained"], bullet: true},
      {[{"Next Steps", bold: true, font_size: 20}], space_before: 16, space_after: 8},
      {["Finalize Q1 2026 roadmap"], bullet: :number},
      {["Hire two senior engineers"], bullet: :number}
    ],
    x: {1, :inches},
    y: {0.5, :inches},
    width: {10, :inches},
    height: {6, :inches}
  )

# Slide 3: Clustered column chart (Revenue vs Expenses)
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")

s3 =
  Podium.Slide.new()
  |> Podium.add_chart(:column_clustered, chart_data,
    x: {1, :inches},
    y: {0.5, :inches},
    width: {10, :inches},
    height: {6, :inches},
    title: "Revenue vs Expenses",
    legend: :bottom,
    data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0", font_size: 9],
    category_axis: [title: "Quarter"],
    value_axis: [title: "Amount ($)", number_format: "$#,##0", major_gridlines: true]
  )

# Slide 4: Formatted table with header fills
s4 =
  Podium.Slide.new()
  |> Podium.add_text_box("Department Summary",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {10, :inches},
    height: {0.8, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_table(
    [
      [
        {[[{"Department", color: "FFFFFF"}]], fill: "003366"},
        {[[{"Headcount", color: "FFFFFF"}]], fill: "003366"},
        {[[{"Budget", color: "FFFFFF"}]], fill: "003366"},
        {[[{"Score", color: "FFFFFF"}]], fill: "003366"}
      ],
      ["Engineering", "230", "$4,200K", "92%"],
      ["Marketing", "85", "$2,100K", "87%"],
      ["Sales", "120", "$3,500K", "84%"],
      ["Operations", "65", "$1,800K", "91%"]
    ],
    x: {1, :inches},
    y: {1.5, :inches},
    width: {10, :inches},
    height: {4, :inches}
  )

# Slide 5: Title+Content layout with placeholder content
s5 =
  Podium.Slide.new(:title_content)
  |> Podium.set_placeholder(:title, "Looking Ahead")
  |> Podium.set_placeholder(:content, [
    [{"Expand into APAC market by Q2 2026"}],
    [{"Launch self-service analytics platform"}],
    [{"Target 95% customer satisfaction"}]
  ])

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.save("demos/output/getting-started.pptx")

IO.puts("Generated demos/output/getting-started.pptx")
