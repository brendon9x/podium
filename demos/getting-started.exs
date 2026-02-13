File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title slide layout with styled title/subtitle
{prs, s1} = Podium.add_slide(prs, layout: :title_slide)

s1 =
  s1
  |> Podium.set_placeholder(:title, [
    [{"Quarterly Business Review", bold: true, font_size: 40, color: "003366"}]
  ])
  |> Podium.set_placeholder(:subtitle, "Engineering Division -- Q4 2025")

prs = Podium.put_slide(prs, s1)

# Slide 2: Rich text with bullets and numbered lists
{prs, s2} = Podium.add_slide(prs)

s2 =
  Podium.add_text_box(
    s2,
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

prs = Podium.put_slide(prs, s2)

# Slide 3: Clustered column chart (Revenue vs Expenses)
{prs, s3} = Podium.add_slide(prs)

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")

{prs, s3} =
  Podium.add_chart(prs, s3, :column_clustered, chart_data,
    x: {1, :inches},
    y: {0.5, :inches},
    width: {10, :inches},
    height: {6, :inches},
    title: "Revenue vs Expenses",
    legend: :bottom,
    data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0"],
    category_axis: [title: "Quarter"],
    value_axis: [title: "Amount ($)", number_format: "$#,##0", major_gridlines: true]
  )

prs = Podium.put_slide(prs, s3)

# Slide 4: Formatted table with header fills
{prs, s4} = Podium.add_slide(prs)

s4 =
  Podium.add_text_box(s4, "Department Summary",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {10, :inches},
    height: {0.8, :inches},
    font_size: 28,
    alignment: :center
  )

s4 =
  Podium.add_table(
    s4,
    [
      [
        {"Department", fill: "003366"},
        {"Headcount", fill: "003366"},
        {"Budget", fill: "003366"},
        {"Score", fill: "003366"}
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

prs = Podium.put_slide(prs, s4)

# Slide 5: Title+Content layout with placeholder content
{prs, s5} = Podium.add_slide(prs, layout: :title_content)

s5 =
  s5
  |> Podium.set_placeholder(:title, "Looking Ahead")
  |> Podium.set_placeholder(:content, [
    [{"Expand into APAC market by Q2 2026"}],
    [{"Launch self-service analytics platform"}],
    [{"Target 95% customer satisfaction"}]
  ])

prs = Podium.put_slide(prs, s5)

:ok = Podium.save(prs, "demos/output/getting-started.pptx")
IO.puts("Generated demos/output/getting-started.pptx")
