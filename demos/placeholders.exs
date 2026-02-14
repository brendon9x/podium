File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title slide layout
s1 =
  Podium.Slide.new(:title_slide)
  |> Podium.set_placeholder(:title, [
    [{"Annual Report 2025", bold: true, font_size: 44, color: "003366"}]
  ])
  |> Podium.set_placeholder(:subtitle, "Engineering Division")

# Slide 2: Comparison layout with all placeholders filled
s2 =
  Podium.Slide.new(:comparison)
  |> Podium.set_placeholder(:title, "Before vs After")
  |> Podium.set_placeholder(:left_heading, "Before (Q1)")
  |> Podium.set_placeholder(:left_content, [
    [{"Manual processes"}],
    [{"3-day turnaround"}],
    [{"Error rate: 12%"}]
  ])
  |> Podium.set_placeholder(:right_heading, "After (Q4)")
  |> Podium.set_placeholder(:right_content, [
    [{"Fully automated"}],
    [{"Same-day delivery"}],
    [{"Error rate: 0.5%"}]
  ])

# Slide 3: Content+Caption layout
s3 =
  Podium.Slide.new(:content_caption)
  |> Podium.set_placeholder(:title, "Dashboard Overview")
  |> Podium.set_placeholder(:content, "Main visualization area")
  |> Podium.set_placeholder(:caption, "Source: Internal analytics, Jan 2026")

# Slide 4: Two-content layout -- table left, pie chart right
s4 = Podium.Slide.new(:two_content)
s4 = Podium.set_placeholder(s4, :title, "Revenue Overview")

# Table on the left
s4 =
  Podium.set_table_placeholder(
    prs,
    s4,
    :left_content,
    [
      ["Region", "Revenue"],
      ["North America", "$12.5M"],
      ["Europe", "$8.2M"],
      ["Asia Pacific", "$5.1M"]
    ],
    table_style: [first_row: true]
  )

# Chart on the right
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["NA", "EU", "APAC"])
  |> ChartData.add_series("Revenue", [12.5, 8.2, 5.1],
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31"}
  )

s4 =
  Podium.set_chart_placeholder(prs, s4, :right_content, :pie, chart_data,
    title: "Revenue Split",
    legend: :bottom,
    data_labels: [:category, :percent]
  )

# Slide 5: Chart in content placeholder
s5 = Podium.Slide.new(:title_content)
s5 = Podium.set_placeholder(s5, :title, "Revenue by Quarter")

revenue_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")

s5 =
  Podium.set_chart_placeholder(prs, s5, :content, :column_clustered, revenue_data,
    title: "Quarterly Revenue",
    legend: :bottom
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.save("demos/output/placeholders.pptx")

IO.puts("Generated demos/output/placeholders.pptx")
