# Building a Report

Walk through creating a professional multi-slide report from start to finish. This recipe produces an 8-slide quarterly business review with consistent styling, covering title slides, executive summaries, charts, tables, images, and a conclusion.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/building-a-report.exs` to generate a presentation with all the examples from this guide.

```elixir
alias Podium.Chart.ChartData

prs = Podium.new(title: "Q4 2025 Business Review", author: "Analytics Team")
```

## Setting Up Shared Styles

Before building slides, define colors and helper values you'll reuse throughout the report. This keeps the presentation visually consistent.

```elixir
alias Podium.Chart.ChartData

# Brand colors
primary = "003366"
accent1 = "4472C4"
accent2 = "ED7D31"
accent3 = "70AD47"
light_bg = "E8EDF2"
white = "FFFFFF"

prs = Podium.new(title: "Q4 2025 Business Review", author: "Analytics Team")
```

## Slide 1: Title Slide

Use the `:title_slide` layout for a clean opening with the report name and subtitle.

![Title slide with brand colors](assets/recipes/building-a-report/title-slide.png)

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_slide)

slide =
  slide
  |> Podium.set_placeholder(:title, [
    [{"Q4 2025 Business Review", bold: true, font_size: 40, color: primary}]
  ])
  |> Podium.set_placeholder(:subtitle, "Analytics Team -- Prepared February 2026")

prs = Podium.put_slide(prs, slide)
```

## Slide 2: Executive Summary

A text slide with bullet points summarizing the key findings. The gradient header bar and bulleted list create a clear visual hierarchy.

![Executive summary with gradient header and bullet points](assets/recipes/building-a-report/executive-summary.png)

```elixir
{prs, slide} = Podium.add_slide(prs)

slide =
  slide
  |> Podium.add_text_box(
    [{[{"Executive Summary", bold: true, font_size: 28, color: white}], alignment: :center}],
    x: {0.5, :inches}, y: {0.3, :inches},
    width: {11, :inches}, height: {0.7, :inches},
    fill: {:gradient, [{0, "001133"}, {100_000, accent1}], angle: 5_400_000})
  |> Podium.add_text_box([
    {[{"Revenue grew ", font_size: 16},
      {"28% year-over-year", bold: true, font_size: 16, color: accent3}],
     space_after: 6},
    {["Total revenue reached $60.4M across all regions"], bullet: true},
    {["North America led growth at 35%"], bullet: true, level: 1},
    {["APAC expanded 22%"], bullet: true, level: 1},
    {["Customer satisfaction hit 92%, up from 86%"], bullet: true},
    {["Net Promoter Score improved 15 points to 67"], bullet: true},
    {["Engineering delivered all roadmap milestones on schedule"], bullet: true},
    {[{"Recommendation: ", font_size: 16},
      {"Increase APAC investment by 30% in H1 2026", bold: true, font_size: 16}],
     space_before: 12}
  ], x: {0.5, :inches}, y: {1.3, :inches},
     width: {11, :inches}, height: {5, :inches})

prs = Podium.put_slide(prs, slide)
```

## Slide 3: Revenue Chart

A clustered column chart comparing revenue and expenses across quarters. Data labels and axis formatting make the numbers easy to read.

![Quarterly revenue vs expenses column chart](assets/recipes/building-a-report/revenue-chart.png)

```elixir
{prs, slide} = Podium.add_slide(prs)

revenue_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1 2025", "Q2 2025", "Q3 2025", "Q4 2025"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: accent1)
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: accent2)
  |> ChartData.add_series("Net Profit", [2_500, 3_300, 2_700, 5_100], color: accent3)

{prs, _slide} = Podium.add_chart(prs, slide, :column_clustered, revenue_data,
  x: {0.5, :inches}, y: {0.5, :inches},
  width: {11, :inches}, height: {6, :inches},
  title: [text: "Quarterly Revenue vs Expenses", font_size: 18, bold: true, color: primary],
  legend: [position: :bottom, font_size: 10],
  data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0"],
  category_axis: [title: "Quarter"],
  value_axis: [
    title: "Amount ($)",
    number_format: "$#,##0",
    major_gridlines: true,
    min: 0,
    max: 20_000,
    major_unit: 5_000
  ])
```

## Slide 4: Market Share Pie Chart

A pie chart with per-point colors and category+percent labels breaks down revenue by region.

![Revenue by region pie chart](assets/recipes/building-a-report/market-share-pie.png)

```elixir
{prs, slide} = Podium.add_slide(prs)

market_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia Pacific", "Latin America"])
  |> ChartData.add_series("Revenue", [25_200, 16_800, 12_100, 6_300],
    point_colors: %{0 => accent1, 1 => "BDD7EE", 2 => accent2, 3 => "FBE5D6"})

{prs, _slide} = Podium.add_chart(prs, slide, :pie, market_data,
  x: {1.5, :inches}, y: {0.5, :inches},
  width: {9, :inches}, height: {6, :inches},
  title: [text: "Revenue by Region", font_size: 18, bold: true, color: primary],
  legend: :right,
  data_labels: [:category, :percent])
```

## Slide 5: Department Table

A formatted table with header styling, borders, and a merged title row for a professional look.

![Department performance table with merged title row](assets/recipes/building-a-report/department-table.png)

```elixir
{prs, slide} = Podium.add_slide(prs)

slide =
  slide
  |> Podium.add_text_box(
    [{[{"Department Performance", bold: true, font_size: 24, color: primary}], alignment: :center}],
    x: {0.5, :inches}, y: {0.3, :inches},
    width: {11, :inches}, height: {0.7, :inches})
  |> Podium.add_table([
    [{"Department Performance -- Q4 2025", col_span: 5, fill: primary},
     :merge, :merge, :merge, :merge],
    [{"Department", fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
     {"Headcount", fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
     {"Budget", fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
     {"Revenue", fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]},
     {"Satisfaction", fill: accent1, borders: [bottom: [color: primary, width: {2, :pt}]]}],
    ["Engineering", "230", "$4,200K", "$18,100K",
     {[[{"92%", bold: true, color: accent3}]], anchor: :middle}],
    ["Marketing", "85", "$2,100K", "$15,200K", "87%"],
    ["Sales", "120", "$3,500K", "$21,800K", "84%"],
    ["Operations", "65", "$1,800K", "$5,300K", "91%"]
  ], x: {0.5, :inches}, y: {1.2, :inches},
     width: {11, :inches}, height: {4.5, :inches})

prs = Podium.put_slide(prs, slide)
```

## Slide 6: Trend Chart

A line chart with markers showing monthly user growth across channels.

![Monthly active users trend line chart](assets/recipes/building-a-report/trend-line-chart.png)

```elixir
{prs, slide} = Podium.add_slide(prs)

trend_data =
  ChartData.new()
  |> ChartData.add_categories(["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"])
  |> ChartData.add_series("Web", [68, 72, 70, 74, 78, 85],
    color: accent1, marker: [style: :circle, size: 6, fill: accent1])
  |> ChartData.add_series("Mobile", [62, 68, 71, 75, 80, 92],
    color: accent2, marker: [style: :diamond, size: 6, fill: accent2])
  |> ChartData.add_series("API", [22, 25, 28, 30, 33, 38],
    color: accent3, marker: [style: :square, size: 6, fill: accent3])

{prs, _slide} = Podium.add_chart(prs, slide, :line_markers, trend_data,
  x: {0.5, :inches}, y: {0.5, :inches},
  width: {11, :inches}, height: {6, :inches},
  title: [text: "Monthly Active Users (H2 2025)", font_size: 18, bold: true, color: primary],
  legend: :bottom,
  value_axis: [title: "Users (thousands)", major_gridlines: true])
```

## Slide 7: Image Slide

Add a product screenshot or photo. Replace the file path with your own image.

```elixir
{prs, slide} = Podium.add_slide(prs)

slide = Podium.add_text_box(slide,
  [{[{"Product Dashboard", bold: true, font_size: 24, color: primary}], alignment: :center}],
  x: {0.5, :inches}, y: {0.3, :inches},
  width: {11, :inches}, height: {0.7, :inches})

# Replace with your actual image path
image_binary = File.read!("path/to/dashboard_screenshot.png")

{prs, slide} = Podium.add_image(prs, slide, image_binary,
  x: {1, :inches}, y: {1.3, :inches},
  width: {10, :inches})

prs = Podium.put_slide(prs, slide)
```

## Slide 8: Conclusion

Close with key takeaways using the `:title_content` layout and speaker notes for the presenter.

![Key takeaways and next steps conclusion slide](assets/recipes/building-a-report/conclusion.png)

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_content)

slide =
  slide
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

prs = Podium.put_slide(prs, slide)
```

## Add Footer and Save

Apply a consistent footer with the company name, date, and slide numbers across all slides.

```elixir
prs = Podium.set_footer(prs,
  footer: "Acme Corp -- Confidential",
  date: "February 2026",
  slide_number: true)

:ok = Podium.save(prs, "q4_business_review.pptx")
IO.puts("Saved q4_business_review.pptx")
```

## Running the Complete Report

To run this as a single script, concatenate all the code blocks above into one file. Start with the "Setting Up Shared Styles" section, then add each slide section in order, and finish with the "Add Footer and Save" section. Save as `report.exs` and run:

```bash
mix run report.exs
```

The resulting `q4_business_review.pptx` contains 8 slides: title, executive summary, revenue chart, market share pie chart, department table, trend line chart, conclusion with speaker notes, and a closing slide.

## Tips for Professional Reports

- **Consistent colors**: Define your palette once and reference variables throughout. This makes rebranding trivial.
- **Header bars**: A gradient-filled text box at the top of each content slide creates visual structure without relying on slide masters.
- **Speaker notes**: Add presenter talking points with `Podium.set_notes/2`. They appear in Presenter View but not on the projected slides.
- **Footer and slide numbers**: `Podium.set_footer/2` applies to every slide, so you set it once at the end.

For dynamic data-driven reports, see the [Data-Driven Slides](data-driven-slides.md) recipe. For reusable styling patterns, see [Styling Patterns](styling-patterns.md).
