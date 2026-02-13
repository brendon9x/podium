# Getting Started

Build a complete presentation from scratch in this hands-on tutorial. By the end, you'll know how to create slides, add text, charts, tables, images, and use slide layouts with placeholders.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/getting-started.exs` to generate a presentation with all the examples from this guide.

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)
slide = Podium.add_text_box(slide, "Hello, Podium!",
  x: {1, :inches}, y: {1, :inches},
  width: {8, :inches}, height: {1, :inches})
prs = Podium.put_slide(prs, slide)
Podium.save(prs, "hello.pptx")
```

Each step below builds on the previous one. At the end, you'll find a complete combined script you can copy and run.

## Step 1: Create a Presentation and Add a Slide

Every Podium workflow starts with `Podium.new/1`, which creates a 16:9 presentation by default. Then you add slides with `Podium.add_slide/2`, which returns a `{presentation, slide}` tuple.

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)
```

The slide starts blank. You add content to it, then put the updated slide back into the presentation with `Podium.put_slide/2` before saving.

```elixir
prs = Podium.put_slide(prs, slide)
Podium.save(prs, "output.pptx")
```

This two-step pattern -- get a slide, modify it, put it back -- is the core of how Podium works. Functions that only modify a slide (like `add_text_box/3`) return the updated slide. Functions that also modify the presentation (like `add_chart/5` and `add_image/4`) return a `{presentation, slide}` tuple.

## Step 2: Add a Text Box

Use `Podium.add_text_box/3` to place text on a slide. You provide the text content and position/size options using `{value, unit}` tuples.

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

slide = Podium.add_text_box(slide, "Quarterly Business Review",
  x: {1, :inches}, y: {0.5, :inches},
  width: {10, :inches}, height: {1, :inches},
  font_size: 32, alignment: :center)

prs = Podium.put_slide(prs, slide)
Podium.save(prs, "step2.pptx")
```

Position and size options (`:x`, `:y`, `:width`, `:height`) accept `{number, :inches}`, `{number, :cm}`, `{number, :pt}`, or raw EMU integers. You can also set a background color with `:fill` and a border with `:line`:

```elixir
slide = Podium.add_text_box(slide, "Important Notice",
  x: {1, :inches}, y: {2, :inches},
  width: {10, :inches}, height: {1, :inches},
  font_size: 20, alignment: :center,
  fill: "003366",
  line: [color: "001133", width: {1.5, :pt}])
```

## Step 3: Rich Text with Formatting

For text with mixed formatting -- different fonts, colors, bold/italic on specific words -- pass a list of paragraphs instead of a plain string.

Each paragraph is a list of "runs" (text segments). A run can be a plain string or a `{text, options}` tuple. Paragraph-level options like alignment go in an outer tuple: `{[runs], paragraph_opts}`.

![Rich text with bold title, mixed formatting, and bullets](assets/introduction/getting-started/rich-text-bullets.png)

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

slide = Podium.add_text_box(slide, [
  # Paragraph 1: centered, bold title
  {[{"Engineering Team Update", bold: true, font_size: 28, color: "003366"}],
   alignment: :center},
  # Paragraph 2: mixed formatting
  {[{"Status: ", font_size: 16},
    {"On Track", bold: true, font_size: 16, color: "228B22"}],
   alignment: :left},
  # Paragraph 3: italic note
  {[{"Last updated February 2026", italic: true, font_size: 12, color: "666666"}],
   alignment: :left}
], x: {1, :inches}, y: {0.5, :inches},
   width: {10, :inches}, height: {2, :inches})

prs = Podium.put_slide(prs, slide)
Podium.save(prs, "step3.pptx")
```

Run-level options include: `:bold`, `:italic`, `:underline`, `:strikethrough`, `:superscript`, `:subscript`, `:font_size`, `:color` (hex RGB like `"FF0000"`), and `:font`.

You can also add bullet points and numbered lists using paragraph-level options:

```elixir
slide = Podium.add_text_box(slide, [
  {[{"Key Accomplishments", bold: true, font_size: 20}], space_after: 8},
  {["Shipped v2.0 to production"], bullet: true},
  {["Reduced API latency by 40%"], bullet: true},
  {["Database migration completed"], bullet: true, level: 1},
  {["Cache layer optimized"], bullet: true, level: 1},
  {[{"Action Items", bold: true, font_size: 20}], space_before: 12, space_after: 8},
  {["Finalize Q2 roadmap"], bullet: :number},
  {["Schedule architecture review"], bullet: :number},
  {["Hire two senior engineers"], bullet: :number}
], x: {1, :inches}, y: {3, :inches},
   width: {10, :inches}, height: {3.5, :inches})
```

## Step 4: Add a Chart

Charts are Podium's flagship feature. You build chart data with `Podium.Chart.ChartData`, then add it to a slide with `Podium.add_chart/5`. Because charts embed an Excel workbook, `add_chart/5` returns a `{presentation, slide}` tuple.

![Column clustered chart with axis config and data labels](assets/introduction/getting-started/column-chart.png)

```elixir
alias Podium.Chart.ChartData

prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")

{prs, slide} = Podium.add_chart(prs, slide, :column_clustered, chart_data,
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {5.5, :inches},
  title: "Revenue vs Expenses",
  legend: :bottom,
  data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0"],
  category_axis: [title: "Quarter"],
  value_axis: [title: "Amount ($)", number_format: "$#,##0", major_gridlines: true])

prs = Podium.put_slide(prs, slide)
Podium.save(prs, "step4.pptx")
```

Podium supports 29 chart types including `:column_clustered`, `:bar_stacked`, `:line_markers`, `:pie`, `:area`, `:doughnut`, `:radar`, `:scatter`, and `:bubble`. The chart title, legend, data labels, and axis options are all configurable.

> #### Tip {: .tip}
>
> Recipients can double-click any chart in PowerPoint to edit the underlying
> Excel data. The workbook is fully embedded in the `.pptx` file.

## Step 5: Add a Table

Use `Podium.add_table/3` to create data tables. Pass a list of rows, where each row is a list of cell values.

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

slide = Podium.add_table(slide, [
  ["Department", "Headcount", "Budget", "Satisfaction"],
  ["Engineering", "230", "$4,200K", "92%"],
  ["Marketing", "85", "$2,100K", "87%"],
  ["Sales", "120", "$3,500K", "84%"],
  ["Operations", "65", "$1,800K", "91%"]
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {4, :inches})

prs = Podium.put_slide(prs, slide)
Podium.save(prs, "step5.pptx")
```

For formatted cells, use a `{text, options}` tuple. You can set fill colors, borders, and vertical alignment per cell:

![Table with header fills and formatted cells](assets/introduction/getting-started/formatted-table.png)

```elixir
slide = Podium.add_table(slide, [
  [{"Department", fill: "003366"}, {"Headcount", fill: "003366"},
   {"Budget", fill: "003366"}, {"Score", fill: "003366"}],
  ["Engineering", "230", "$4,200K",
   {[[{"92%", bold: true, color: "228B22"}]], anchor: :middle}],
  ["Marketing", "85", "$2,100K", "87%"]
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {3, :inches})
```

Cells also accept rich text in the same format as `add_text_box/3`, and you can merge cells with `:col_span`, `:row_span`, and the `:merge` placeholder.

## Step 6: Add an Image

Use `Podium.add_image/4` to place images on a slide. Pass the image as a binary (from `File.read!/1`) and Podium auto-detects the format from magic bytes.

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

image_binary = File.read!("path/to/logo.png")

{prs, slide} = Podium.add_image(prs, slide, image_binary,
  x: {3, :inches}, y: {1.5, :inches},
  width: {6, :inches}, height: {4, :inches})

prs = Podium.put_slide(prs, slide)
Podium.save(prs, "step6.pptx")
```

If you provide only `:width`, Podium auto-calculates the height to preserve the aspect ratio (and vice versa). If you omit both, Podium uses the native image dimensions read from the file headers.

Supported formats: PNG, JPEG, BMP, GIF, TIFF, EMF, WMF.

> #### Warning {: .warning}
>
> EMF, WMF, and TIFF images require explicit `:width` and `:height` options.
> Auto-scaling from native dimensions is not supported for these formats.

## Step 7: Use a Layout with Placeholders

Instead of manually positioning every element, you can use slide layouts with predefined placeholders. Create a slide with a `:layout` option, then fill its placeholders with `Podium.set_placeholder/3`.

![Title slide with styled title and subtitle](assets/introduction/getting-started/title-slide.png)

```elixir
prs = Podium.new()

# Title slide layout has :title and :subtitle placeholders
{prs, slide} = Podium.add_slide(prs, layout: :title_slide)

slide =
  slide
  |> Podium.set_placeholder(:title, "Annual Report 2026")
  |> Podium.set_placeholder(:subtitle, "Engineering Division")

prs = Podium.put_slide(prs, slide)
```

Placeholders accept plain strings or rich text, just like `add_text_box/3`:

![Title and content layout with placeholder text](assets/introduction/getting-started/title-content-layout.png)

```elixir
slide = Podium.set_placeholder(slide, :title, [
  [{"Annual Report", bold: true, font_size: 44, color: "003366"}]
])
```

Podium supports all 11 standard slide layouts:

| Layout | Placeholders |
|--------|-------------|
| `:title_slide` | `:title`, `:subtitle` |
| `:title_content` | `:title`, `:content` |
| `:section_header` | `:title`, `:body` |
| `:two_content` | `:title`, `:left_content`, `:right_content` |
| `:comparison` | `:title`, `:left_heading`, `:left_content`, `:right_heading`, `:right_content` |
| `:title_only` | `:title` |
| `:blank` | (none) |
| `:content_caption` | `:title`, `:content`, `:caption` |
| `:picture_caption` | `:title`, `:picture`, `:caption` |
| `:title_vertical_text` | `:title`, `:body` |
| `:vertical_title_text` | `:title`, `:body` |

Content placeholders (`:content`, `:left_content`, `:right_content`) can also hold charts and tables via `Podium.set_chart_placeholder/6` and `Podium.set_table_placeholder/5`. The position and size are inherited from the template layout.

## Step 8: Save and Open

You already know `Podium.save/2` for saving to a file. For web applications, use `Podium.save_to_memory/1` to get a binary you can stream to the client:

```elixir
# Save to file
:ok = Podium.save(prs, "report.pptx")

# Save to memory (for Phoenix, uploads, etc.)
{:ok, binary} = Podium.save_to_memory(prs)
```

## Complete Script

Here is everything combined into a single runnable script. Save as `tutorial.exs` and run with `mix run tutorial.exs`:

```elixir
alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Title slide
{prs, s1} = Podium.add_slide(prs, layout: :title_slide)
s1 = s1
  |> Podium.set_placeholder(:title, [
    [{"Quarterly Business Review", bold: true, font_size: 40, color: "003366"}]])
  |> Podium.set_placeholder(:subtitle, "Engineering Division -- Q4 2025")
prs = Podium.put_slide(prs, s1)

# Slide 2: Rich text with bullets
{prs, s2} = Podium.add_slide(prs)
s2 = Podium.add_text_box(s2, [
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
], x: {1, :inches}, y: {0.5, :inches}, width: {10, :inches}, height: {6, :inches})
prs = Podium.put_slide(prs, s2)

# Slide 3: Column chart
{prs, s3} = Podium.add_slide(prs)
chart_data = ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")
  |> ChartData.add_series("Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31")
{prs, s3} = Podium.add_chart(prs, s3, :column_clustered, chart_data,
  x: {1, :inches}, y: {0.5, :inches}, width: {10, :inches}, height: {6, :inches},
  title: "Revenue vs Expenses", legend: :bottom,
  data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0"],
  category_axis: [title: "Quarter"],
  value_axis: [title: "Amount ($)", number_format: "$#,##0", major_gridlines: true])
prs = Podium.put_slide(prs, s3)

# Slide 4: Data table
{prs, s4} = Podium.add_slide(prs)
s4 = Podium.add_text_box(s4, "Department Summary",
  x: {1, :inches}, y: {0.3, :inches}, width: {10, :inches}, height: {0.8, :inches},
  font_size: 28, alignment: :center)
s4 = Podium.add_table(s4, [
  [{"Department", fill: "003366"}, {"Headcount", fill: "003366"},
   {"Budget", fill: "003366"}, {"Score", fill: "003366"}],
  ["Engineering", "230", "$4,200K", "92%"],
  ["Marketing", "85", "$2,100K", "87%"],
  ["Sales", "120", "$3,500K", "84%"],
  ["Operations", "65", "$1,800K", "91%"]
], x: {1, :inches}, y: {1.5, :inches}, width: {10, :inches}, height: {4, :inches})
prs = Podium.put_slide(prs, s4)

# Slide 5: Layout with placeholders
{prs, s5} = Podium.add_slide(prs, layout: :title_content)
s5 = s5
  |> Podium.set_placeholder(:title, "Looking Ahead")
  |> Podium.set_placeholder(:content, [
    [{"Expand into APAC market by Q2 2026"}],
    [{"Launch self-service analytics platform"}],
    [{"Target 95% customer satisfaction"}]])
prs = Podium.put_slide(prs, s5)

:ok = Podium.save(prs, "tutorial.pptx")
IO.puts("Saved tutorial.pptx")
```

## What's Next

You've seen the basics of creating presentations with Podium. The Core Features guides cover each area in depth, starting with [Presentations and Slides](presentations-and-slides.md). You can also explore the full `Podium` API reference for every available option.
