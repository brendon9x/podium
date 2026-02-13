# Placeholders and Layouts

Use slide layouts and their placeholders to create structured slides with
predefined regions for titles, content, pictures, and captions. Placeholders
inherit their position and size from the slide master template.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/placeholders.exs` to generate a presentation with all the examples from this guide.

![Title slide layout with styled title and subtitle](assets/core/placeholders/title-slide-layout.png)

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_slide)

slide =
  slide
  |> Podium.set_placeholder(:title, "Annual Report 2025")
  |> Podium.set_placeholder(:subtitle, "Engineering Division")
```

## What Placeholders Are

Every slide layout in a PowerPoint template defines named regions called
placeholders. When you add a slide with a specific layout, Podium makes those
placeholders available for you to fill with content. The position and size of each
placeholder come from the template -- you don't need to specify coordinates.

This is different from `Podium.add_text_box/3` or `Podium.add_chart/5`, where you
provide explicit `x`, `y`, `width`, and `height` values. Placeholders give you
template-driven positioning for a consistent look across slides.

## Available Layouts

Podium includes 11 slide layouts. Specify a layout by atom or integer index when
adding a slide with `Podium.add_slide/2`:

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_content)
# or equivalently:
{prs, slide} = Podium.add_slide(prs, layout: 2)
```

| Layout | Index | Placeholders |
|--------|-------|-------------|
| `:title_slide` | 1 | `:title`, `:subtitle` |
| `:title_content` | 2 | `:title`, `:content` |
| `:section_header` | 3 | `:title`, `:body` |
| `:two_content` | 4 | `:title`, `:left_content`, `:right_content` |
| `:comparison` | 5 | `:title`, `:left_heading`, `:left_content`, `:right_heading`, `:right_content` |
| `:title_only` | 6 | `:title` |
| `:blank` | 7 | (none) |
| `:content_caption` | 8 | `:title`, `:content`, `:caption` |
| `:picture_caption` | 9 | `:title`, `:picture`, `:caption` |
| `:title_vertical_text` | 10 | `:title`, `:body` |
| `:vertical_title_text` | 11 | `:title`, `:body` |

The `:blank` layout (index 7) is the default when you call `Podium.add_slide/2`
without a `:layout` option. It has no placeholders -- use it when you want full
control over positioning with `add_text_box/3`, `add_chart/5`, and other functions.

## Text Placeholders

Set text content in a placeholder with `Podium.set_placeholder/3`. This works for
all text-based placeholders: `:title`, `:subtitle`, `:content`, `:body`,
`:caption`, `:left_content`, `:right_content`, `:left_heading`, and
`:right_heading`.

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_content)

slide =
  slide
  |> Podium.set_placeholder(:title, "Quarterly Review")
  |> Podium.set_placeholder(:content, "Revenue exceeded target by 12%.")
```

### Rich Text in Placeholders

Placeholders accept the same rich text format as `Podium.add_text_box/3`:

```elixir
slide = Podium.set_placeholder(slide, :title, [
  [{"Q4 Results", bold: true, font_size: 44, color: "003366"}]
])

slide = Podium.set_placeholder(slide, :content, [
  [{"Revenue grew 35% year-over-year"}],
  [{"Customer satisfaction at 92%"}],
  [{"Operating margin improved to 28%"}]
])
```

### Layout-Specific Examples

**Section header** -- use for dividing a presentation into sections:

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :section_header)

slide =
  slide
  |> Podium.set_placeholder(:title, "Financial Results")
  |> Podium.set_placeholder(:body, "Detailed breakdown of Q4 performance")
```

**Comparison** -- five placeholders for side-by-side comparison:

![Comparison layout with before/after content](assets/core/placeholders/comparison-layout.png)

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :comparison)

slide =
  slide
  |> Podium.set_placeholder(:title, "Before vs After")
  |> Podium.set_placeholder(:left_heading, "Before (Q1)")
  |> Podium.set_placeholder(:left_content, [
    [{"Manual processes"}],
    [{"3-day turnaround"}]
  ])
  |> Podium.set_placeholder(:right_heading, "After (Q4)")
  |> Podium.set_placeholder(:right_content, [
    [{"Fully automated"}],
    [{"Same-day delivery"}]
  ])
```

**Content with caption** -- a content area paired with a caption:

![Content with caption layout](assets/core/placeholders/content-caption-layout.png)

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :content_caption)

slide =
  slide
  |> Podium.set_placeholder(:title, "Dashboard Overview")
  |> Podium.set_placeholder(:content, "Main visualization area")
  |> Podium.set_placeholder(:caption, "Source: Internal analytics, Jan 2026")
```

## Picture Placeholders

The `:picture_caption` layout has a `:picture` placeholder that accepts image
data. Use `Podium.set_picture_placeholder/4` instead of `set_placeholder/3`:

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :picture_caption)

slide =
  slide
  |> Podium.set_placeholder(:title, "Product Showcase")
  |> Podium.set_placeholder(:caption, "The Acme Widget 3000")

image_binary = File.read!("product_photo.png")
{prs, slide} = Podium.set_picture_placeholder(prs, slide, :picture, image_binary)
```

> #### Warning {: .warning}
>
> Using `set_placeholder/3` on a `:picture` placeholder raises an
> `ArgumentError`. Use `set_picture_placeholder/4` for picture placeholders.

## Charts in Content Placeholders

Content placeholders (`:content`, `:left_content`, `:right_content`) can hold
charts. Use `Podium.set_chart_placeholder/6` to place a chart with position and
size inherited from the template layout:

![Column chart inside a content placeholder](assets/core/placeholders/chart-placeholder.png)

```elixir
alias Podium.Chart.ChartData

{prs, slide} = Podium.add_slide(prs, layout: :title_content)
slide = Podium.set_placeholder(slide, :title, "Revenue by Quarter")

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")

{prs, slide} = Podium.set_chart_placeholder(prs, slide, :content,
  :column_clustered, chart_data,
  title: "Quarterly Revenue", legend: :bottom)
```

Any `:x`, `:y`, `:width`, or `:height` values in the options are silently dropped.
The chart inherits its position from the template. Other chart options like
`:title`, `:legend`, and `:data_labels` pass through normally.

## Tables in Content Placeholders

Content placeholders also accept tables via `Podium.set_table_placeholder/5`:

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_content)
slide = Podium.set_placeholder(slide, :title, "Regional Summary")

{prs, slide} = Podium.set_table_placeholder(prs, slide, :content, [
  ["Region", "Revenue", "Growth"],
  ["North America", "$12.5M", "+18%"],
  ["Europe", "$8.2M", "+12%"],
  ["Asia Pacific", "$5.1M", "+42%"]
], table_style: [first_row: true])
```

## Side-by-Side Content

The `:two_content` layout is useful for placing a table and chart next to each
other:

![Two-content layout with table and pie chart side by side](assets/core/placeholders/two-content-layout.png)

```elixir
alias Podium.Chart.ChartData

{prs, slide} = Podium.add_slide(prs, layout: :two_content)
slide = Podium.set_placeholder(slide, :title, "Revenue Overview")

# Table on the left
{prs, slide} = Podium.set_table_placeholder(prs, slide, :left_content, [
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
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31"})

{prs, slide} = Podium.set_chart_placeholder(prs, slide, :right_content,
  :pie, chart_data,
  title: "Revenue Split", legend: :bottom,
  data_labels: [:category, :percent])
```

## Footer, Date, and Slide Numbers

Set presentation-wide footer text, a date string, and slide numbers with
`Podium.set_footer/2`. These are injected into every slide at save time.

```elixir
prs = Podium.set_footer(prs,
  footer: "Acme Corp Confidential",
  date: "February 2026",
  slide_number: true)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:footer` | `String.t()` | `nil` | Footer text displayed at bottom of each slide |
| `:date` | `String.t()` | `nil` | Date text displayed at bottom of each slide |
| `:slide_number` | `boolean` | `false` | Show auto-incrementing slide numbers |

Footer settings apply to the entire presentation. Call `set_footer/2` before or
after adding slides -- the values are applied when you save.

## Content Type Rules

Not all placeholders accept all content types. Here is what each placeholder
function works with:

| Function | Valid Placeholders |
|----------|-------------------|
| `set_placeholder/3` | All text placeholders (`:title`, `:subtitle`, `:content`, `:body`, `:caption`, etc.) |
| `set_picture_placeholder/4` | Picture placeholders only (`:picture`) |
| `set_chart_placeholder/6` | Content placeholders only (type: nil) -- `:content`, `:left_content`, `:right_content` |
| `set_table_placeholder/5` | Content placeholders only (type: nil) -- `:content`, `:left_content`, `:right_content` |

Using the wrong function for a placeholder type raises an `ArgumentError` with a
descriptive message.

---

Placeholders give you template-driven positioning for consistent, professional
slides. For interactive features like hyperlinks and navigation buttons, continue
to [Hyperlinks and Click Actions](hyperlinks-and-actions.md).
