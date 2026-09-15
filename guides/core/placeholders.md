# Placeholders and Layouts

Use slide layouts and their placeholders to create structured slides with
predefined regions for titles, content, pictures, and captions. Placeholders
inherit their position and size from the slide master template.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/placeholders.exs` to generate a presentation with all the examples from this guide.

```elixir
slide = Podium.Slide.new(:title_slide)

slide =
  slide
  |> Podium.set_placeholder(:title, "Annual Report 2025")
  |> Podium.set_placeholder(:subtitle, "Engineering Division")
```

![Title slide layout with styled title and subtitle](assets/core/placeholders/title-slide-layout.png)

## What Placeholders Are

Every slide layout in a PowerPoint template defines named regions called
placeholders. When you create a slide with a specific layout, Podium makes those
placeholders available for you to fill with content. The position and size of each
placeholder come from the template -- you don't need to specify coordinates.

This is different from `Podium.add_text_box/3` or `Podium.add_chart/4`, where you
provide explicit `x`, `y`, `width`, and `height` values. Placeholders give you
template-driven positioning for a consistent look across slides.

## Available Layouts

Podium includes 11 slide layouts. Specify a layout when creating a slide with
`Podium.Slide.new/1`:

```elixir
slide = Podium.Slide.new(:title_content)
# or equivalently:
slide = Podium.Slide.new(2)
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

The `:blank` layout (index 7) is the default when you call `Podium.Slide.new/0`
without a layout argument. It has no placeholders -- use it when you want full
control over positioning with `add_text_box/3`, `add_chart/4`, and other functions.

## Text Placeholders

Set text content in a placeholder with `Podium.set_placeholder/3`. This works for
all text-based placeholders: `:title`, `:subtitle`, `:content`, `:body`,
`:caption`, `:left_content`, `:right_content`, `:left_heading`, and
`:right_heading`.

```elixir
slide = Podium.Slide.new(:title_content)

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
slide = Podium.Slide.new(:section_header)

slide =
  slide
  |> Podium.set_placeholder(:title, "Financial Results")
  |> Podium.set_placeholder(:body, "Detailed breakdown of Q4 performance")
```

**Comparison** -- five placeholders for side-by-side comparison:

```elixir
slide = Podium.Slide.new(:comparison)

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

![Comparison layout with before/after content](assets/core/placeholders/comparison-layout.png)

**Content with caption** -- a content area paired with a caption:

```elixir
slide = Podium.Slide.new(:content_caption)

slide =
  slide
  |> Podium.set_placeholder(:title, "Dashboard Overview")
  |> Podium.set_placeholder(:content, "Main visualization area")
  |> Podium.set_placeholder(:caption, "Source: Internal analytics, Jan 2026")
```

![Content with caption layout](assets/core/placeholders/content-caption-layout.png)

## Picture Placeholders

The `:picture_caption` layout has a `:picture` placeholder that accepts image
data. Use `Podium.set_picture_placeholder/3` instead of `set_placeholder/3`:

```elixir
slide = Podium.Slide.new(:picture_caption)

slide =
  slide
  |> Podium.set_placeholder(:title, "Product Showcase")
  |> Podium.set_placeholder(:caption, "The Acme Widget 3000")

image_binary = File.read!("product_photo.png")
slide = Podium.set_picture_placeholder(slide, :picture, image_binary)
```

> #### Warning {: .warning}
>
> Using `set_placeholder/3` on a `:picture` placeholder raises an
> `ArgumentError`. Use `set_picture_placeholder/3` for picture placeholders.

## Charts in Content Placeholders

Content placeholders (`:content`, `:left_content`, `:right_content`) can hold
charts. Use `Podium.set_chart_placeholder/6` to place a chart with position and
size inherited from the template layout:

```elixir
alias Podium.Chart.ChartData

slide = Podium.Slide.new(:title_content)
slide = Podium.set_placeholder(slide, :title, "Revenue by Quarter")

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4")

slide = Podium.set_chart_placeholder(prs, slide, :content,
  :column_clustered, chart_data,
  title: "Quarterly Revenue", legend: :bottom)
```

![Column chart inside a content placeholder](assets/core/placeholders/chart-placeholder.png)

Any `:x`, `:y`, `:width`, or `:height` values in the options are silently dropped.
The chart inherits its position from the template. Other chart options like
`:title`, `:legend`, and `:data_labels` pass through normally.

## Tables in Content Placeholders

Content placeholders also accept tables via `Podium.set_table_placeholder/5`:

```elixir
slide = Podium.Slide.new(:title_content)
slide = Podium.set_placeholder(slide, :title, "Regional Summary")

slide = Podium.set_table_placeholder(prs, slide, :content, [
  ["Region", "Revenue", "Growth"],
  ["North America", "$12.5M", "+18%"],
  ["Europe", "$8.2M", "+12%"],
  ["Asia Pacific", "$5.1M", "+42%"]
], table_style: [first_row: true])
```

## Side-by-Side Content

The `:two_content` layout is useful for placing a table and chart next to each
other:

```elixir
alias Podium.Chart.ChartData

slide = Podium.Slide.new(:two_content)
slide = Podium.set_placeholder(slide, :title, "Revenue Overview")

# Table on the left
slide = Podium.set_table_placeholder(prs, slide, :left_content, [
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

slide = Podium.set_chart_placeholder(prs, slide, :right_content,
  :pie, chart_data,
  title: "Revenue Split", legend: :bottom,
  data_labels: [:category, :percent])
```

![Two-content layout with table and pie chart side by side](assets/core/placeholders/two-content-layout.png)

## Inspecting a Template

The placeholder names above belong to the template Podium bundles. A template of
your own, loaded with `Podium.from_template/2`, has its own layouts with their
own placeholders. See
[Building on Your Own Template](presentations-and-slides.md#building-on-your-own-template)
for what a template has to contain and how slide size is handled.

`Podium.Template.inspect/1` reports what is actually in a package: its slide
size, its masters, and for every layout its name, its type, the master it sits
on, and each placeholder with the box it resolves to.

```elixir
template = Podium.Template.inspect("priv/brand/skeleton.pptx")

for {index, layout} <- Enum.sort(template.layouts) do
  IO.puts("#{index}: #{layout.name}")

  for ph <- layout.placeholders do
    IO.puts("   {#{ph.type}, #{ph.idx}}  #{ph.name}")
  end
end
```

```
1: Cover
   {ctrTitle, 0}  Title 1
   {subTitle, 7}  Subtitle 2
   {dt, 20}  Date Placeholder 3
   {ftr, 21}  Footer Placeholder 4
   {sldNum, 22}  Slide Number Placeholder 5
2: Content
   {title, 0}  Title 1
   {obj, 14}  Content Placeholder 2
   ...
```

A `<p:ph/>` element without a `type` attribute means `"obj"` and one without an
`idx` attribute means `0`, so inspection always reports a string type and an
integer idx. A placeholder's box is its own `<a:xfrm>` when it has one, and
otherwise the box inherited from the master placeholder of the matching type.

`inspect/1` accepts a path, the bytes of a `.pptx`/`.potx`, or an already-read
parts map. Reading a whole package is not free, so inspect a template once and
keep the result rather than calling it per slide.

## Addressing Placeholders by Type and Idx

Every placeholder function takes the `{type, idx}` pair that inspection reports,
in place of a bundled-template name. This is the way to fill placeholders on a
template of your own:

```elixir
alias Podium.Chart.ChartData

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3"])
  |> ChartData.add_series("Volume", [1500, 4600, 5156])

prs = Podium.from_template("priv/brand/skeleton.pptx")

cover =
  Podium.Slide.new(1)
  |> Podium.set_placeholder({"ctrTitle", 0}, "Category performance")
  |> Podium.set_placeholder({"subTitle", 7}, "Quarterly review, January 2026")

slide = Podium.set_placeholder(Podium.Slide.new(2), {"title", 0}, "Volume grew 4.2%")

slide =
  Podium.set_chart_placeholder(prs, slide, {"obj", 14}, :column_clustered, chart_data,
    title: "Volume by quarter"
  )

prs = prs |> Podium.add_slide(cover) |> Podium.add_slide(slide)
```

The type is always the layout placeholder's own. PowerPoint leaves a content
placeholder's `p:ph` alone when a picture goes into it, so a picture in a content
placeholder is `{"obj", 14}`, not `{"pic", 14}`:

```elixir
slide = Podium.set_picture_placeholder(slide, {"obj", 14}, File.read!("chart.png"))
```

`Podium.add_slide/2` checks every placeholder on the slide against the layout and
raises when the layout has no placeholder at that idx, or has one of a different
type. That turns a placeholder that PowerPoint would have silently dropped into
an error at build time.

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

The chrome follows the layout. PowerPoint only shows a footer, date or slide
number on a slide that carries the placeholder itself, so Podium emits each one
at the idx its layout uses, and emits nothing for a layout that has no such
placeholder. On the bundled template that is idx 11 for the footer, 10 for the
date and 12 for the slide number; on a template of your own, whatever
`Podium.Template.inspect/1` reports.

## Content Type Rules

Not all placeholders accept all content types. Here is what each placeholder
function works with:

| Function | Valid Placeholders |
|----------|-------------------|
| `set_placeholder/3` | All text placeholders (`:title`, `:subtitle`, `:content`, `:body`, `:caption`, etc.) |
| `set_picture_placeholder/3` | Picture placeholders only (`:picture`) |
| `set_chart_placeholder/6` | Content placeholders only -- `:content`, `:left_content`, `:right_content` |
| `set_table_placeholder/5` | Content placeholders only -- `:content`, `:left_content`, `:right_content` |

Using the wrong function for a placeholder type raises an `ArgumentError` with a
descriptive message.

Addressed by `{type, idx}`, the rules loosen a little: `set_placeholder/3` and
`set_picture_placeholder/3` take any placeholder, and charts and tables take any
placeholder that is not a title, subtitle, date, footer or slide number.

---

Placeholders give you template-driven positioning for consistent, professional
slides. For interactive features like hyperlinks and navigation buttons, continue
to [Hyperlinks and Click Actions](hyperlinks-and-actions.md).
