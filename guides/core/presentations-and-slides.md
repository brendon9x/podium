# Presentations and Slides

Create and configure presentations with `Podium.new/1`, create slides with
`Podium.Slide.new/1`, and add them to the presentation with `Podium.add_slide/2`.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/presentations-and-slides.exs` to generate a presentation with all the examples from this guide.

```elixir
prs = Podium.new()
slide = Podium.Slide.new()
slide = Podium.add_text_box(slide, "Hello, World!",
  x: {1, :inches}, y: {1, :inches},
  width: {8, :inches}, height: {1, :inches})
prs = Podium.add_slide(prs, slide)
Podium.save(prs, "hello.pptx")
```

## Creating a Presentation

Call `Podium.new/1` to create a blank presentation. The default slide dimensions
are 16:9 widescreen (13.33" x 7.5").

```elixir
# Default 16:9 widescreen
prs = Podium.new()

# Standard 4:3
prs = Podium.new(slide_width: {10, :inches}, slide_height: {7.5, :inches})

# Custom dimensions
prs = Podium.new(slide_width: {14, :inches}, slide_height: {8, :inches})
```

## Slide Dimensions and Units

Podium uses English Metric Units (EMU) internally. You can pass dimensions as raw
EMU integers or as `{value, unit}` tuples with one of three supported units.

| Unit | Tuple Form | EMU per Unit |
|------|------------|--------------|
| Inches | `{1, :inches}` | 914,400 |
| Centimeters | `{2.54, :cm}` | 360,000 |
| Points | `{72, :pt}` | 12,700 |
| Raw EMU | `914_400` | 1 |

All position and size options throughout Podium accept these unit formats --
`:x`, `:y`, `:width`, `:height`, `:margin_left`, column widths, and so on.

### Common Slide Sizes

| Aspect Ratio | Width | Height |
|-------------|-------|--------|
| 16:9 (default) | `{13.333, :inches}` | `{7.5, :inches}` |
| 4:3 | `{10, :inches}` | `{7.5, :inches}` |
| 16:10 | `{13.333, :inches}` | `{8.333, :inches}` |

## Creating Slides

Create slides with `Podium.Slide.new/1`. By default it uses the `:blank` layout.

```elixir
slide = Podium.Slide.new()
```

### Slide Layouts

Specify a layout by passing a layout atom or index:

| Layout | Atom | Placeholders |
|--------|------|-------------|
| Title Slide | `:title_slide` | `:title`, `:subtitle` |
| Title + Content | `:title_content` | `:title`, `:content` |
| Section Header | `:section_header` | `:title`, `:body` |
| Two Content | `:two_content` | `:title`, `:left_content`, `:right_content` |
| Comparison | `:comparison` | `:title`, `:left_heading`, `:left_content`, `:right_heading`, `:right_content` |
| Title Only | `:title_only` | `:title` |
| Blank | `:blank` | (none) |
| Content + Caption | `:content_caption` | `:title`, `:content`, `:caption` |
| Picture + Caption | `:picture_caption` | `:title`, `:picture`, `:caption` |
| Title + Vertical Text | `:title_vertical_text` | `:title`, `:body` |
| Vertical Title + Text | `:vertical_title_text` | `:title`, `:body` |

```elixir
slide = Podium.Slide.new(:title_slide)
slide = Podium.set_placeholder(slide, :title, "Annual Report 2025")
slide = Podium.set_placeholder(slide, :subtitle, "Finance & Operations Dashboard")
prs = Podium.add_slide(prs, slide)
```

### Slide Backgrounds

Set a background color, gradient, pattern, or picture when creating a slide.

Slide backgrounds accept solid colors, gradients, patterns, and pictures. On dark backgrounds, use rich text with a light color for readability:

```elixir
# Solid color
slide = Podium.Slide.new(:blank, background: "E8EDF2")
```

```elixir
# Gradient
slide = Podium.Slide.new(:blank,
  background: {:gradient, [{0, "001133"}, {100_000, "004488"}], angle: 5_400_000})
```

```elixir
# Pattern
slide = Podium.Slide.new(:blank,
  background: {:pattern, :lt_horz, foreground: "003366", background: "E8EDF2"})

# Picture
image_binary = File.read!("background.jpg")
slide = Podium.Slide.new(:blank, background: {:picture, image_binary})
```

![Solid dark background with light text](assets/core/presentations-and-slides/solid-background.png)

![Gradient background with centered title](assets/core/presentations-and-slides/gradient-background.png)

![Pattern background with diagonal lines](assets/core/presentations-and-slides/pattern-background.png)

When no background is set, the slide inherits the background from the slide master.

## The Slide Builder Pattern

All content functions take a slide as first argument and return the updated slide.
This makes it natural to build slides with the pipe operator.

After building a slide, call `Podium.add_slide/2` to add it to the presentation.

```elixir
prs = Podium.new()

# Build a slide with pipes
slide =
  Podium.Slide.new()
  |> Podium.add_text_box("Hello",
    x: {1, :inches}, y: {1, :inches}, width: {4, :inches}, height: {1, :inches})
  |> Podium.add_chart(:pie, chart_data,
    x: {1, :inches}, y: {2, :inches}, width: {6, :inches}, height: {4, :inches})

# Add the slide to the presentation
prs = Podium.add_slide(prs, slide)
```

## Saving

### Save to File

```elixir
:ok = Podium.save(prs, "report.pptx")
```

### Save to Memory

Use `Podium.save_to_memory/1` to get the .pptx as an in-memory binary. This is
useful for streaming downloads from a Phoenix controller or uploading to cloud storage.

```elixir
{:ok, binary} = Podium.save_to_memory(prs)
```

## Core Properties

Set document metadata with `Podium.new/1` options or `Podium.set_core_properties/2`.

```elixir
prs = Podium.new(
  title: "Q4 Report",
  author: "Analytics Team",
  subject: "Quarterly Review",
  created: ~U[2025-01-15 10:00:00Z],
  modified: DateTime.utc_now(),
  revision: 1
)
```

All core property options: `:title`, `:author`, `:subject`, `:keywords`, `:category`,
`:comments`, `:last_modified_by`, `:created`, `:modified`, `:last_printed`, `:revision`,
`:content_status`, `:language`, `:version`.

You can also set properties after creation:

```elixir
prs = Podium.set_core_properties(prs, title: "Updated Title", revision: 2)
```

## Footer, Date, and Slide Numbers

`Podium.set_footer/2` adds footer text, a date string, and slide numbers to
every slide in the presentation.

```elixir
prs = Podium.set_footer(prs,
  footer: "Acme Corp Confidential",
  date: "February 2026",
  slide_number: true)
```

![Title slide with footer, date, and slide number](assets/core/presentations-and-slides/title-slide-footer.png)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:footer` | `String.t()` | `nil` | Footer text |
| `:date` | `String.t()` | `nil` | Date text |
| `:slide_number` | `boolean` | `false` | Show slide numbers |

## Speaker Notes

Add presenter notes to any slide with `Podium.set_notes/2`. Notes appear in
Presenter View but not on the projected slides.

```elixir
slide = Podium.set_notes(slide, "Talking points: Revenue grew 35% YoY. Key driver was APAC expansion.")
```

The next guide covers adding text and rich formatting to your slides. See
[Text and Formatting](text-and-formatting.md).
