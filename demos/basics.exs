alias Podium.Chart.ChartData

prs = Podium.new(title: "Acme Corp Annual Review", author: "Podium Demo")

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
    width: {12.33, :inches},
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
    width: {11.33, :inches},
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
    width: {12.33, :inches},
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
    width: {12.33, :inches},
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
    width: {12.33, :inches},
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
    width: {12.33, :inches},
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
    x: {2.17, :inches},
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
    width: {12.33, :inches},
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
    width: {12.33, :inches},
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
    width: {12.33, :inches},
    height: {4.5, :inches}
  )

prs = Podium.put_slide(prs, slide7)

# --- Slide 8: Image ---
{prs, slide8} = Podium.add_slide(prs)

slide8 =
  Podium.add_text_box(slide8, "Image Support Demo",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12.33, :inches},
    height: {0.8, :inches},
    font_size: 28,
    alignment: :center
  )

image_binary = File.read!(Path.join(__DIR__, "acme.jpg"))

{prs, slide8} =
  Podium.add_image(prs, slide8, image_binary,
    x: {3.67, :inches},
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
    width: {12.33, :inches},
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
  |> Podium.set_placeholder(:content, [
    [{"Continue expanding into Asia Pacific market"}],
    [{"Invest in self-service support tools"}],
    [{"Target 95% customer satisfaction by Q4 2026"}]
  ])

prs = Podium.put_slide(prs, slide10)

# --- Slide 11: New features showcase ---
{prs, slide11} = Podium.add_slide(prs, background: "E8EDF2")

slide11 =
  slide11
  |> Podium.add_text_box(
    [
      {[{"New Features Showcase", bold: true, font_size: 28, color: "003366"}],
       alignment: :center}
    ],
    x: {0.5, :inches},
    y: {0.2, :inches},
    width: {12.33, :inches},
    height: {0.6, :inches}
  )
  # Rotated text box with custom margins
  |> Podium.add_text_box("Rotated!",
    x: {0.5, :inches},
    y: {1.2, :inches},
    width: {2, :inches},
    height: {1, :inches},
    rotation: 15,
    fill: "4472C4",
    margin_left: {0.3, :inches},
    margin_right: {0.3, :inches},
    margin_top: {0.15, :inches},
    margin_bottom: {0.15, :inches},
    font_size: 18,
    alignment: :center
  )
  # Underline styles
  |> Podium.add_text_box(
    [
      [
        {"Single", underline: :single, font_size: 14},
        {"  Double", underline: :double, font_size: 14},
        {"  Wavy", underline: :wavy, font_size: 14},
        {"  Heavy", underline: :heavy, font_size: 14},
        {"  Dotted", underline: :dotted, font_size: 14}
      ]
    ],
    x: {3, :inches},
    y: {1.2, :inches},
    width: {9.83, :inches},
    height: {0.6, :inches}
  )
  # Line breaks within a paragraph
  |> Podium.add_text_box(
    [
      [
        {"Line breaks in a single paragraph:", bold: true, font_size: 14},
        :line_break,
        {"First line\nSecond line\nThird line", font_size: 14, color: "4472C4"}
      ]
    ],
    x: {0.5, :inches},
    y: {2.5, :inches},
    width: {5.5, :inches},
    height: {1.8, :inches},
    margin_left: {0.2, :inches},
    margin_top: {0.15, :inches}
  )
  # New pattern preset (sphere)
  |> Podium.add_text_box("Sphere Pattern",
    x: {7, :inches},
    y: {2.5, :inches},
    width: {2.5, :inches},
    height: {1, :inches},
    fill: {:pattern, :sphere, foreground: "4472C4", background: "FFFFFF"},
    font_size: 16,
    alignment: :center
  )
  # New pattern preset (zig_zag)
  |> Podium.add_text_box("ZigZag Pattern",
    x: {10, :inches},
    y: {2.5, :inches},
    width: {2.5, :inches},
    height: {1, :inches},
    fill: {:pattern, :zig_zag, foreground: "ED7D31", background: "FFFFFF"},
    font_size: 16,
    alignment: :center
  )

prs = Podium.put_slide(prs, slide11)

# --- Slide 12: Table with gradient/pattern cell fills and banding flags ---
{prs, slide12} = Podium.add_slide(prs)

slide12 =
  slide12
  |> Podium.add_text_box("Table Cell Fills & Banding",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12.33, :inches},
    height: {0.6, :inches},
    font_size: 24,
    alignment: :center
  )
  |> Podium.add_table(
    [
      [
        {"Gradient Cell",
         fill: {:gradient, [{0, "4472C4"}, {100_000, "002060"}], angle: 5_400_000}},
        {"Pattern Cell",
         fill: {:pattern, :lt_horz, foreground: "ED7D31", background: "FFFFFF"}},
        {"Solid Cell", fill: "70AD47"}
      ],
      ["Plain A", "Plain B", "Plain C"]
    ],
    x: {1, :inches},
    y: {1.2, :inches},
    width: {11.33, :inches},
    height: {2, :inches},
    table_style: [first_row: true, band_row: true, band_col: true]
  )

prs = Podium.put_slide(prs, slide12)

# --- Slide 13: Line chart with axis extras and series markers ---
{prs, slide13} = Podium.add_slide(prs)

marker_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Diamonds", [20, 35, 45, 50, 55, 70],
    color: "4472C4",
    marker: [style: :diamond, size: 10, fill: "4472C4", line: "002060"]
  )
  |> ChartData.add_series("Circles", [15, 25, 30, 40, 48, 60],
    color: "ED7D31",
    marker: [style: :circle, size: 8, fill: "ED7D31"]
  )
  |> ChartData.add_series("Squares", [10, 18, 22, 28, 35, 45],
    color: "70AD47",
    marker: [style: :square, size: 6]
  )

{prs, _slide13} =
  Podium.add_chart(prs, slide13, :line_markers, marker_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12.33, :inches},
    height: {6, :inches},
    title: "Series Markers & Axis Extras",
    legend: :bottom,
    category_axis: [
      major_tick_mark: :cross,
      minor_tick_mark: :in
    ],
    value_axis: [
      major_gridlines: true,
      minor_gridlines: true,
      minor_unit: 5,
      major_unit: 20,
      min: 0,
      max: 80
    ]
  )

# --- Slide 14: Line gradient/pattern fill demo ---
{prs, slide14} = Podium.add_slide(prs)

slide14 =
  slide14
  |> Podium.add_text_box("Line Fill Variants",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12.33, :inches},
    height: {0.6, :inches},
    font_size: 24,
    alignment: :center
  )
  |> Podium.add_text_box("Gradient Line",
    x: {1, :inches},
    y: {1.5, :inches},
    width: {5, :inches},
    height: {1.5, :inches},
    font_size: 18,
    alignment: :center,
    line: [
      fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000},
      width: {3, :pt}
    ]
  )
  |> Podium.add_text_box("Pattern Line",
    x: {7.33, :inches},
    y: {1.5, :inches},
    width: {5, :inches},
    height: {1.5, :inches},
    font_size: 18,
    alignment: :center,
    line: [
      fill: {:pattern, :dn_diag, foreground: "003366", background: "FFFFFF"},
      width: {3, :pt}
    ]
  )

prs = Podium.put_slide(prs, slide14)

# --- Slide 15: Image auto-scale demo ---
{prs, slide15} = Podium.add_slide(prs)

slide15 =
  Podium.add_text_box(slide15, "Image Auto-Scale (native size from PNG header)",
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12.33, :inches},
    height: {0.6, :inches},
    font_size: 24,
    alignment: :center
  )

# Re-use the JPEG image with width-only (height auto-calculated)
image_binary = File.read!(Path.join(__DIR__, "acme.jpg"))

{prs, slide15} =
  Podium.add_image(prs, slide15, image_binary,
    x: {2.67, :inches},
    y: {1.5, :inches},
    width: {8, :inches}
  )

prs = Podium.put_slide(prs, slide15)

# --- Slide 16: New Tier 1 features ---
{prs, slide16} = Podium.add_slide(prs)

slide16 =
  Podium.add_text_box(slide16, "Tier 1 Feature Showcase",
    x: {0.5, :inches},
    y: {0.2, :inches},
    width: {12.33, :inches},
    height: {0.6, :inches},
    font_size: 28,
    alignment: :center
  )

# Image masking — ellipse shape
{prs, slide16} =
  Podium.add_image(prs, slide16, image_binary,
    x: {0.67, :inches},
    y: {1, :inches},
    width: {3, :inches},
    height: {3, :inches},
    shape: :ellipse
  )

# Image masking — diamond shape
{prs, slide16} =
  Podium.add_image(prs, slide16, image_binary,
    x: {5.17, :inches},
    y: {1, :inches},
    width: {3, :inches},
    height: {3, :inches},
    shape: :diamond
  )

# Image masking — rounded rectangle
{prs, slide16} =
  Podium.add_image(prs, slide16, image_binary,
    x: {9.67, :inches},
    y: {1, :inches},
    width: {3, :inches},
    height: {3, :inches},
    shape: :round_rect
  )

# Picture fill text box
{prs, slide16} =
  Podium.add_picture_fill_text_box(
    prs,
    slide16,
    [[{"Picture Fill!", bold: true, font_size: 24, color: "FFFFFF"}]],
    image_binary,
    x: {0.5, :inches},
    y: {4.5, :inches},
    width: {5, :inches},
    height: {2, :inches},
    alignment: :center,
    fill_mode: :stretch
  )

prs = Podium.put_slide(prs, slide16)

# --- Slide 17: Per-point line + per-point data labels ---
{prs, slide17} = Podium.add_slide(prs)

highlight_data =
  ChartData.new()
  |> ChartData.add_categories(["Acme", "BetaCo", "Gamma", "Delta", "Echo"])
  |> ChartData.add_series("Revenue ($K)", [42, 28, 18, 35, 22],
    point_colors: %{0 => "2E75B6", 3 => "ED7D31"},
    point_formats: %{
      0 => [line: [color: "001133", width: {2, :pt}]],
      3 => [line: [color: "7F3300", width: {2, :pt}]]
    },
    data_labels: %{
      0 => [show: [:value], position: :outside_end, number_format: "$#,##0K"],
      3 => [show: [:value], position: :outside_end, number_format: "$#,##0K"]
    }
  )

{prs, _slide17} =
  Podium.add_chart(prs, slide17, :column_clustered, highlight_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12.33, :inches},
    height: {6, :inches},
    title: "Per-Point Lines & Data Label Overrides",
    value_axis: [title: "Revenue ($K)", major_gridlines: true]
  )

# --- Slide 18: Date axis demo ---
{prs, slide18} = Podium.add_slide(prs)

date_data =
  ChartData.new()
  |> ChartData.add_categories(["2025-01", "2025-04", "2025-07", "2025-10", "2026-01"])
  |> ChartData.add_series("Sales", [120, 145, 190, 210, 250], color: "4472C4")

{prs, _slide18} =
  Podium.add_chart(prs, slide18, :line_markers, date_data,
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12.33, :inches},
    height: {6, :inches},
    title: "Quarterly Sales (Date Axis)",
    legend: :bottom,
    category_axis: [
      type: :date,
      title: "Date",
      base_time_unit: :months,
      major_time_unit: :months,
      major_unit: 3
    ],
    value_axis: [title: "Sales ($K)", major_gridlines: true]
  )

# --- Slide 19: Chart placeholder on title_content layout ---
{prs, slide19} = Podium.add_slide(prs, layout: :title_content)

slide19 = Podium.set_placeholder(slide19, :title, "Chart Placeholder Demo")

placeholder_chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_156, 18_167], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")

{prs, _slide19} =
  Podium.set_chart_placeholder(prs, slide19, :content, :column_clustered, placeholder_chart_data,
    title: "Revenue vs Expenses",
    legend: :bottom
  )

# --- Slide 20: Table + chart in two_content layout placeholders ---
{prs, slide20} = Podium.add_slide(prs, layout: :two_content)

slide20 = Podium.set_placeholder(slide20, :title, "Table & Chart Placeholders")

{prs, slide20} =
  Podium.set_table_placeholder(prs, slide20, :left_content,
    [
      ["Region", "Revenue"],
      ["North America", "$12.5M"],
      ["Europe", "$8.2M"],
      ["Asia Pacific", "$5.1M"]
    ],
    table_style: [first_row: true]
  )

two_content_chart_data =
  ChartData.new()
  |> ChartData.add_categories(["NA", "EU", "APAC"])
  |> ChartData.add_series("Revenue", [12.5, 8.2, 5.1],
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31"}
  )

{prs, _slide20} =
  Podium.set_chart_placeholder(prs, slide20, :right_content, :pie, two_content_chart_data,
    title: "Revenue Split",
    legend: :bottom,
    data_labels: [:category, :percent]
  )

# --- Slide 21: Closing ---
{prs, slide21} = Podium.add_slide(prs)

slide21 =
  slide21
  |> Podium.add_text_box(
    [
      {[{"Thank You", bold: true, font_size: 44, color: "003366"}], alignment: :center},
      {[{"Questions? strategy@acme.example.com", font_size: 18, color: "666666"}],
       alignment: :center}
    ],
    x: {2.67, :inches},
    y: {2, :inches},
    width: {8, :inches},
    height: {3, :inches}
  )

prs = Podium.put_slide(prs, slide21)

# --- Slide 22: Two Content layout ---
{prs, slide22} = Podium.add_slide(prs, layout: :two_content)

slide22 =
  slide22
  |> Podium.set_placeholder(:title, "Two Column Layout")
  |> Podium.set_placeholder(:left_content, [
    [{"Left Column Highlights"}],
    [{"Revenue growth: 35%"}],
    [{"Market expansion ongoing"}]
  ])
  |> Podium.set_placeholder(:right_content, [
    [{"Right Column Details"}],
    [{"Customer satisfaction: 92%"}],
    [{"NPS score improved by 15 points"}]
  ])

prs = Podium.put_slide(prs, slide22)

# --- Slide 23: Comparison layout ---
{prs, slide23} = Podium.add_slide(prs, layout: :comparison)

slide23 =
  slide23
  |> Podium.set_placeholder(:title, "Before vs After")
  |> Podium.set_placeholder(:left_heading, "Before (Q1)")
  |> Podium.set_placeholder(:left_content, [
    [{"Manual processes"}],
    [{"3-day turnaround"}],
    [{"High error rate"}]
  ])
  |> Podium.set_placeholder(:right_heading, "After (Q4)")
  |> Podium.set_placeholder(:right_content, [
    [{"Fully automated"}],
    [{"Same-day delivery"}],
    [{"99.9% accuracy"}]
  ])

prs = Podium.put_slide(prs, slide23)

# --- Slide 24: Picture + Caption layout ---
{prs, slide24} = Podium.add_slide(prs, layout: :picture_caption)

slide24 =
  slide24
  |> Podium.set_placeholder(:title, "Product Showcase")
  |> Podium.set_placeholder(:caption, "Our flagship product — the Acme Widget 3000")

{prs, _slide24} = Podium.set_picture_placeholder(prs, slide24, :picture, image_binary)

# --- Slide 25: Footer, date, and slide number demo ---
# Enable footer on the presentation
prs =
  Podium.set_footer(prs,
    footer: "Acme Corp Confidential",
    date: "February 2026",
    slide_number: true
  )

# --- Save ---
path = Path.join(__DIR__, "basics.pptx")
:ok = Podium.save(prs, path)
IO.puts("Saved to #{path}")
