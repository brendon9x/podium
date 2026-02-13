File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title slide layout
{prs, s1} = Podium.add_slide(prs, layout: :title_slide)

s1 =
  s1
  |> Podium.set_placeholder(:title, [
    [{"Annual Report 2025", bold: true, font_size: 44, color: "003366"}]
  ])
  |> Podium.set_placeholder(:subtitle, "Engineering Division")

prs = Podium.put_slide(prs, s1)

# Slide 2: Comparison layout with all placeholders filled
{prs, s2} = Podium.add_slide(prs, layout: :comparison)

s2 =
  s2
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

prs = Podium.put_slide(prs, s2)

# Slide 3: Content+Caption layout
{prs, s3} = Podium.add_slide(prs, layout: :content_caption)

s3 =
  s3
  |> Podium.set_placeholder(:title, "Dashboard Overview")
  |> Podium.set_placeholder(:content, "Main visualization area")
  |> Podium.set_placeholder(:caption, "Source: Internal analytics, Jan 2026")

prs = Podium.put_slide(prs, s3)

# Slide 4: Two-content layout -- table left, pie chart right
{prs, s4} = Podium.add_slide(prs, layout: :two_content)

s4 = Podium.set_placeholder(s4, :title, "Revenue Overview")

# Table on the left
{prs, s4} =
  Podium.set_table_placeholder(
    prs,
    s4,
    :left_content,
    [
      ["Region", "Revenue"],
      ["North America", "$12.5M"],
      ["Europe", "$8.2M"],
      ["Asia Pacific", "$5.1M"]
    ], table_style: [first_row: true])

# Chart on the right
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["NA", "EU", "APAC"])
  |> ChartData.add_series("Revenue", [12.5, 8.2, 5.1],
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31"}
  )

{prs, s4} =
  Podium.set_chart_placeholder(prs, s4, :right_content, :pie, chart_data,
    title: "Revenue Split",
    legend: :bottom,
    data_labels: [:category, :percent]
  )

prs = Podium.put_slide(prs, s4)

# Slide 5: Chart in content placeholder
{prs, s5} = Podium.add_slide(prs, layout: :title_content)

s5 = Podium.set_placeholder(s5, :title, "Revenue by Quarter")

revenue_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")

{prs, s5} =
  Podium.set_chart_placeholder(prs, s5, :content, :column_clustered, revenue_data,
    title: "Quarterly Revenue",
    legend: :bottom
  )

prs = Podium.put_slide(prs, s5)

:ok = Podium.save(prs, "demos/output/placeholders.pptx")
IO.puts("Generated demos/output/placeholders.pptx")
