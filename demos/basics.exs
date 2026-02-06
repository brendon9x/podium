alias Podium.Chart.ChartData

prs = Podium.new()

# --- Slide 1: Title slide using placeholder layout ---
{prs, slide1} = Podium.add_slide(prs, layout: :title_slide)

slide1 =
  slide1
  |> Podium.set_placeholder(:title, [
    [{"Acme Corp", bold: true, font_size: 44, color: "003366"}]
  ])
  |> Podium.set_placeholder(:subtitle, "2025 Annual Review — Finance & Operations Dashboard")

prs = Podium.put_slide(prs, slide1)

# --- Slide 2: Rich text with fill/line ---
{prs, slide2} = Podium.add_slide(prs)

slide2 =
  slide2
  |> Podium.add_text_box(
    [
      {[{"Key Highlights", bold: true, font_size: 32, color: "FFFFFF"}], alignment: :center}
    ],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.8, :inches},
    fill: "003366",
    line: "001133"
  )
  |> Podium.add_text_box(
    [
      [{"Revenue grew ", font_size: 18}, {"35%", bold: true, font_size: 18, color: "228B22"}],
      [{"Customer satisfaction at ", font_size: 18}, {"88%", bold: true, font_size: 18, color: "4472C4"}],
      {[{"All metrics trending upward", italic: true, font_size: 16, color: "666666"}], alignment: :right}
    ],
    x: {1, :inches},
    y: {1.5, :inches},
    width: {10, :inches},
    height: {2.5, :inches}
  )

prs = Podium.put_slide(prs, slide2)

# --- Slide 3: Revenue chart with title, legend, data labels, axis customization ---
{prs, slide3} = Podium.add_slide(prs)

revenue_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_156, 18_167], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")
  |> ChartData.add_series("Net Profit", [2_500, 3_300, 2_656, 5_167], color: "70AD47")

{prs, _slide3} =
  Podium.add_chart(prs, slide3, :column_clustered, revenue_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: "Quarterly Revenue vs Expenses",
    legend: :bottom,
    data_labels: [:value],
    category_axis: [title: "Quarter"],
    value_axis: [
      title: "Amount ($)",
      number_format: "$#,##0",
      major_gridlines: true,
      min: 0,
      max: 20000,
      major_unit: 5000
    ]
  )

# --- Slide 4: Pie chart with data labels ---
{prs, slide4} = Podium.add_slide(prs)

market_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia Pacific", "Latin America", "MEA"])
  |> ChartData.add_series("Market Share", [42, 28, 18, 8, 4])

{prs, _slide4} =
  Podium.add_chart(prs, slide4, :pie, market_data,
    x: {1.5, :inches},
    y: {0.5, :inches},
    width: {9, :inches},
    height: {6, :inches},
    title: "Market Share by Region",
    legend: :right,
    data_labels: [:category, :percent]
  )

# --- Slide 5: Line chart with series colors ---
{prs, slide5} = Podium.add_slide(prs)

trend_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
  |> ChartData.add_series("Web", [45, 48, 52, 55, 60, 63, 68, 72, 70, 74, 78, 85], color: "4472C4")
  |> ChartData.add_series("Mobile", [30, 35, 38, 42, 50, 55, 62, 68, 71, 75, 80, 92], color: "ED7D31")
  |> ChartData.add_series("API", [10, 12, 14, 15, 18, 20, 22, 25, 28, 30, 33, 38], color: "70AD47")

{prs, _slide5} =
  Podium.add_chart(prs, slide5, :line_markers, trend_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: "Monthly Active Users — Trend",
    legend: :top,
    value_axis: [title: "Users (thousands)", major_gridlines: true]
  )

# --- Slide 6: Table ---
{prs, slide6} = Podium.add_slide(prs)

slide6 =
  slide6
  |> Podium.add_text_box("Department Summary",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.8, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_table(
    [
      ["Department", "Headcount", "Budget ($K)", "Satisfaction"],
      ["Engineering", "230", "$4,200", "92%"],
      ["Marketing", "85", "$2,100", "87%"],
      ["Sales", "120", "$3,500", "84%"],
      ["Operations", "65", "$1,800", "89%"],
      ["HR", "40", "$900", "91%"]
    ],
    x: {0.5, :inches},
    y: {1.3, :inches},
    width: {11, :inches},
    height: {4.5, :inches}
  )

prs = Podium.put_slide(prs, slide6)

# --- Slide 7: Image (create a minimal PNG programmatically) ---
{prs, slide7} = Podium.add_slide(prs)

slide7 =
  Podium.add_text_box(slide7, "Image Support Demo",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.8, :inches},
    font_size: 28,
    alignment: :center
  )

image_binary = File.read!(Path.join(__DIR__, "acme.jpg"))

{prs, slide7} =
  Podium.add_image(prs, slide7, image_binary,
    x: {3, :inches},
    y: {1.5, :inches},
    width: {6, :inches},
    height: {4.5, :inches}
  )

prs = Podium.put_slide(prs, slide7)

# --- Slide 8: Stacked bar with formatting ---
{prs, slide8} = Podium.add_slide(prs)

tickets_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Email", [250, 230, 210, 200, 185, 170], color: "4472C4")
  |> ChartData.add_series("Chat", [180, 200, 220, 250, 280, 310], color: "ED7D31")
  |> ChartData.add_series("Phone", [100, 95, 90, 85, 80, 75], color: "A5A5A5")
  |> ChartData.add_series("Self-Service", [50, 80, 120, 160, 200, 250], color: "70AD47")

{prs, _slide8} =
  Podium.add_chart(prs, slide8, :bar_stacked, tickets_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: "Support Tickets by Channel",
    legend: :right,
    category_axis: [title: "Month"],
    value_axis: [title: "Tickets", major_gridlines: false]
  )

# --- Slide 9: Title + Content layout with placeholder ---
{prs, slide9} = Podium.add_slide(prs, layout: :title_content)

slide9 =
  slide9
  |> Podium.set_placeholder(:title, "Next Steps")
  |> Podium.set_placeholder(:body, [
    [{"Continue expanding into Asia Pacific market"}],
    [{"Invest in self-service support tools"}],
    [{"Target 95% customer satisfaction by Q4 2026"}]
  ])

prs = Podium.put_slide(prs, slide9)

# --- Slide 10: 4:3 presentation note + closing ---
{prs, slide10} = Podium.add_slide(prs)

slide10 =
  slide10
  |> Podium.add_text_box(
    [
      {[{"Thank You", bold: true, font_size: 44, color: "003366"}], alignment: :center},
      {[{"Questions? strategy@acme.example.com", font_size: 18, color: "666666"}], alignment: :center}
    ],
    x: {2, :inches},
    y: {2, :inches},
    width: {8, :inches},
    height: {3, :inches}
  )

prs = Podium.put_slide(prs, slide10)

# --- Save ---
path = Path.join(__DIR__, "basics.pptx")
:ok = Podium.save(prs, path)
IO.puts("Saved to #{path}")
