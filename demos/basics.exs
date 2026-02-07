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
    fill: {:gradient, [{0, "001133"}, {100_000, "004488"}], angle: 5_400_000},
    line: [color: "001133", width: {1.5, :pt}, dash_style: :dash]
  )
  |> Podium.add_text_box(
    [
      [{"Revenue grew ", font_size: 18}, {"35%", bold: true, font_size: 18, color: "228B22"}],
      [
        {"Customer satisfaction at ", font_size: 18},
        {"88%", bold: true, font_size: 18, color: "4472C4"}
      ],
      {[
         {"All metrics trending upward",
          italic: true, font_size: 16, color: "666666", underline: true, font: "Georgia"}
       ], alignment: :right}
    ],
    x: {1, :inches},
    y: {1.5, :inches},
    width: {10, :inches},
    height: {2.5, :inches}
  )

prs = Podium.put_slide(prs, slide2)

# --- Slide 3: Rich text — bullets, spacing, strikethrough, super/subscript ---
{prs, slide3} = Podium.add_slide(prs)

slide3 =
  slide3
  |> Podium.add_text_box(
    [
      {[{"Text Formatting Features", bold: true, font_size: 28, color: "003366"}],
       alignment: :center, space_after: 12}
    ],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    fill: {:pattern, :lt_horz, foreground: "003366", background: "E8EDF2"}
  )
  |> Podium.add_text_box(
    [
      {[
         {"Strikethrough: ", font_size: 16},
         {"old price $99", font_size: 16, strikethrough: true, color: "CC0000"},
         {" → new price $79", font_size: 16, bold: true, color: "228B22"}
       ], space_after: 6},
      {[{"Superscript: E = mc", font_size: 16}, {"2", font_size: 12, superscript: true}],
       space_after: 6},
      {[
         {"Subscript: H", font_size: 16},
         {"2", font_size: 12, subscript: true},
         {"O", font_size: 16}
       ], space_after: 12, line_spacing: 1.5}
    ],
    x: {0.5, :inches},
    y: {1.2, :inches},
    width: {11, :inches},
    height: {2, :inches}
  )
  |> Podium.add_text_box(
    [
      {[{"Bullet Lists", bold: true, font_size: 20}], space_after: 6},
      {["Revenue up 35% year-over-year"], bullet: true},
      {["North America grew fastest"], bullet: true, level: 1},
      {["APAC close behind"], bullet: true, level: 1},
      {["Customer satisfaction at all-time high"], bullet: true},
      {["Custom bullet: hiring plan on track"], bullet: "–"},
      {[{"Numbered Steps", bold: true, font_size: 20}], space_before: 12, space_after: 6},
      {["Review quarterly data"], bullet: :number},
      {["Identify growth opportunities"], bullet: :number},
      {["Present to board"], bullet: :number}
    ],
    x: {0.5, :inches},
    y: {3.2, :inches},
    width: {11, :inches},
    height: {4, :inches}
  )

prs = Podium.put_slide(prs, slide3)

# --- Slide 4: Revenue chart with title, legend, data labels, axis customization ---
{prs, slide4} = Podium.add_slide(prs)

revenue_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_156, 18_167], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")
  |> ChartData.add_series("Net Profit", [2_500, 3_300, 2_656, 5_167], color: "70AD47")

{prs, _slide4} =
  Podium.add_chart(prs, slide4, :column_clustered, revenue_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: [text: "Quarterly Revenue vs Expenses", font_size: 18, bold: true, color: "003366"],
    legend: [position: :bottom, font_size: 10, font: "Arial"],
    data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0"],
    category_axis: [title: "Quarter", label_rotation: -45],
    value_axis: [
      title: "Amount ($)",
      number_format: "$#,##0",
      major_gridlines: true,
      min: 0,
      max: 20000,
      major_unit: 5000
    ]
  )

# --- Slide 5: Pie chart with data labels ---
{prs, slide5} = Podium.add_slide(prs)

market_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia Pacific", "Latin America", "MEA"])
  |> ChartData.add_series("Market Share", [42, 28, 18, 8, 4],
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31", 3 => "FBE5D6", 4 => "A5A5A5"}
  )

{prs, _slide5} =
  Podium.add_chart(prs, slide5, :pie, market_data,
    x: {1.5, :inches},
    y: {0.5, :inches},
    width: {9, :inches},
    height: {6, :inches},
    title: "Market Share by Region",
    legend: :right,
    data_labels: [:category, :percent]
  )

# --- Slide 6: Line chart with series colors ---
{prs, slide6} = Podium.add_slide(prs)

trend_data =
  ChartData.new()
  |> ChartData.add_categories([
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ])
  |> ChartData.add_series("Web", [45, 48, 52, 55, 60, 63, 68, 72, 70, 74, 78, 85],
    color: "4472C4"
  )
  |> ChartData.add_series("Mobile", [30, 35, 38, 42, 50, 55, 62, 68, 71, 75, 80, 92],
    color: "ED7D31"
  )
  |> ChartData.add_series("API", [10, 12, 14, 15, 18, 20, 22, 25, 28, 30, 33, 38],
    color: "70AD47"
  )

{prs, _slide6} =
  Podium.add_chart(prs, slide6, :line_markers, trend_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: "Monthly Active Users — Trend",
    legend: :top,
    value_axis: [title: "Users (thousands)", major_gridlines: true]
  )

# --- Slide 7: Table ---
{prs, slide7} = Podium.add_slide(prs)

slide7 =
  slide7
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
      # Header row: merged title spanning all columns
      [
        {"Department Summary — 2025",
         col_span: 4, fill: "003366", anchor: :middle, padding: [left: {0.1, :inches}]},
        :merge,
        :merge,
        :merge
      ],
      # Column headers with fill and borders
      [
        {"Department", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Headcount", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Budget ($K)", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Satisfaction", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]}
      ],
      # Engineering spans 2 rows vertically with rich text
      [
        {[[{"Engineering", bold: true, color: "003366"}]],
         row_span: 2, anchor: :middle, fill: "D6E4F0", padding: [left: {0.1, :inches}]},
        "230",
        "$4,200",
        {[[{"92%", bold: true, color: "228B22"}]], anchor: :middle}
      ],
      # Merged from Engineering row above
      [:merge, "180", "$3,800", {[[{"94%", bold: true, color: "228B22"}]], anchor: :middle}],
      # Regular rows
      ["Marketing", "85", "$2,100", {"87%", borders: [bottom: "CCCCCC"]}],
      ["Sales", "120", "$3,500", {"84%", borders: [bottom: "CCCCCC"]}]
    ],
    x: {0.5, :inches},
    y: {1.3, :inches},
    width: {11, :inches},
    height: {4.5, :inches}
  )

prs = Podium.put_slide(prs, slide7)

# --- Slide 8: Image ---
{prs, slide8} = Podium.add_slide(prs)

slide8 =
  Podium.add_text_box(slide8, "Image Support Demo",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.8, :inches},
    font_size: 28,
    alignment: :center
  )

image_binary = File.read!(Path.join(__DIR__, "acme.jpg"))

{prs, slide8} =
  Podium.add_image(prs, slide8, image_binary,
    x: {3, :inches},
    y: {1.5, :inches},
    width: {6, :inches},
    height: {4.5, :inches},
    crop: [top: 5000, bottom: 5000]
  )

prs = Podium.put_slide(prs, slide8)

# --- Slide 9: Stacked bar with formatting ---
{prs, slide9} = Podium.add_slide(prs)

tickets_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Email", [250, 230, 210, 200, 185, 170],
    pattern: [type: :dn_diag, foreground: "4472C4", background: "FFFFFF"]
  )
  |> ChartData.add_series("Chat", [180, 200, 220, 250, 280, 310], color: "ED7D31")
  |> ChartData.add_series("Phone", [100, 95, 90, 85, 80, 75], color: "A5A5A5")
  |> ChartData.add_series("Self-Service", [50, 80, 120, 160, 200, 250], color: "70AD47")

{prs, _slide9} =
  Podium.add_chart(prs, slide9, :bar_stacked, tickets_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {11, :inches},
    height: {6, :inches},
    title: "Support Tickets by Channel",
    legend: :right,
    category_axis: [title: "Month"],
    value_axis: [title: "Tickets", major_gridlines: false, label_rotation: -45, crosses: :max]
  )

# --- Slide 10: Title + Content layout with placeholder ---
{prs, slide10} = Podium.add_slide(prs, layout: :title_content)

slide10 =
  slide10
  |> Podium.set_placeholder(:title, "Next Steps")
  |> Podium.set_placeholder(:body, [
    [{"Continue expanding into Asia Pacific market"}],
    [{"Invest in self-service support tools"}],
    [{"Target 95% customer satisfaction by Q4 2026"}]
  ])

prs = Podium.put_slide(prs, slide10)

# --- Slide 11: Closing ---
{prs, slide11} = Podium.add_slide(prs)

slide11 =
  slide11
  |> Podium.add_text_box(
    [
      {[{"Thank You", bold: true, font_size: 44, color: "003366"}], alignment: :center},
      {[{"Questions? strategy@acme.example.com", font_size: 18, color: "666666"}],
       alignment: :center}
    ],
    x: {2, :inches},
    y: {2, :inches},
    width: {8, :inches},
    height: {3, :inches}
  )

prs = Podium.put_slide(prs, slide11)

# --- Save ---
path = Path.join(__DIR__, "basics.pptx")
:ok = Podium.save(prs, path)
IO.puts("Saved to #{path}")
