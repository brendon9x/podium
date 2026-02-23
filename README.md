# Podium

Podium is a comprehensive Powerpoint Generation Library for Elixir, ported from Python's python-pptx (with huge thanks).

Podium's Powerpoint support is feature complete beyond most common use-cases, including:

- **Rich text** — bold, italic, underline, strikethrough, superscript, subscript, color, font, alignment, bullets, paragraph spacing
- **Charts** — column (clustered/stacked), bar (clustered/stacked), line, line with markers, pie, XY, Radar — all fully editable
- **Chart formatting** — titles, legends, data labels, axis customization (min/max, gridlines, number format), per-series colors
- **Images** — PNG and JPEG with automatic format detection, masking, rotations
- **Tables** — rows and columns with rich text cells, cell merging, styling, full border control, etc
- **Placeholders** — title, subtitle, and body on standard slide layouts
- **Shape styling** — solid, gradient, pattern fills and lines with configurable width
- **Slide dimensions** — 16:9 default, fully configurable
- **Extras** – Speaker's notes, footers, document metadata

## Quick start

```elixir
alias Podium.Chart.ChartData

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167], color: "4472C4")
  |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000], color: "ED7D31")

slide =
  Podium.Slide.new()
  |> Podium.add_text_box([
    {[{"Quarterly Report", bold: true, font_size: 36, color: "003366"}], alignment: :center}
  ], x: {1, :inches}, y: {0.5, :inches}, width: {10, :inches}, height: {1, :inches})
  |> Podium.add_chart(:column_clustered, chart_data,
    x: {1, :inches}, y: {2, :inches}, width: {10, :inches}, height: {4.5, :inches},
    title: "Revenue vs Expenses",
    legend: :bottom,
    data_labels: [:value]
  )

Podium.new()
|> Podium.add_slide(slide)
|> Podium.save("report.pptx")
```

## Installation

Add `podium` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:podium, "~> 0.2"}
  ]
end
```

## Usage

### Presentations and slides

```elixir
# 16:9 (default)
prs = Podium.new()

# Custom dimensions
prs = Podium.new(slide_width: {10, :inches}, slide_height: {7.5, :inches})

# Create slides with different layouts
blank = Podium.Slide.new()                    # blank
title = Podium.Slide.new(:title_slide)        # title + subtitle
content = Podium.Slide.new(:title_content)    # title + body

# Add slides to a presentation
prs
|> Podium.add_slide(blank)
|> Podium.add_slide(title)
|> Podium.add_slide(content)
```

### Rich text

Plain strings work for simple cases. For formatting, pass a list of paragraphs:

```elixir
# Simple
slide = Podium.add_text_box(slide, "Hello", x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {1, :inches}, font_size: 24)

# Rich — multiple paragraphs with per-run formatting
slide = Podium.add_text_box(slide, [
  [{"Title", bold: true, font_size: 28, color: "003366"}],
  [{"By ", font_size: 14}, {"Engineering", bold: true, italic: true}]
], x: {1, :inches}, y: {1, :inches}, width: {8, :inches}, height: {2, :inches},
   alignment: :center)

# Per-paragraph alignment
slide = Podium.add_text_box(slide, [
  {[{"Heading", bold: true}], alignment: :center},
  {[{"Body text here"}], alignment: :left}
], x: {1, :inches}, y: {1, :inches}, width: {8, :inches}, height: {2, :inches})
```

Run options: `bold`, `italic`, `underline`, `strikethrough`, `superscript`, `subscript`, `font_size`, `color` (hex RGB), `font`.

### HTML text

Pass HTML strings anywhere text is accepted. Podium auto-detects HTML tags and parses them into the same internal format:

```elixir
# HTML — compact, familiar syntax
slide = Podium.add_text_box(slide,
  ~s(<p>Revenue grew <span style="color: #228B22"><b>35%</b></span></p>),
  x: {1, :inches}, y: {1, :inches}, width: {10, :inches}, height: {1, :inches})

# Equivalent rich text API
slide = Podium.add_text_box(slide, [
  [{"Revenue grew "}, {"35%", bold: true, color: "228B22"}]
], x: {1, :inches}, y: {1, :inches}, width: {10, :inches}, height: {1, :inches})
```

Supported: `<b>`, `<i>`, `<u>`, `<s>`, `<sup>`, `<sub>`, `<p>`, `<br>`, `<ul>`, `<ol>`, `<li>`, `<span style="...">`. Style properties: `color`, `font-size`, `font-family`, `text-align`.

### Paragraph spacing and bullets

Paragraph-level options go in the tuple form `{runs, opts}`:

```elixir
slide = Podium.add_text_box(slide, [
  {[{"Spaced heading", bold: true}], line_spacing: 1.5, space_after: 12},
  {["Bullet item one"], bullet: true},
  {["Sub-item"], bullet: true, level: 1},
  {["Custom bullet"], bullet: "–"},
  {["Step one"], bullet: :number},
  {[{"E=mc", font_size: 16}, {"2", font_size: 12, superscript: true}], space_before: 6}
], x: {1, :inches}, y: {1, :inches}, width: {8, :inches}, height: {4, :inches})
```

Paragraph options: `alignment`, `line_spacing` (multiplier, e.g. `1.5`), `space_before` / `space_after` (points), `bullet` (`true`, a custom character, or `:number`), `level` (0-based indent).

### Shape fills and lines

```elixir
slide = Podium.add_text_box(slide, "Alert!", x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {1, :inches},
  fill: "FF0000",
  line: [color: "000000", width: {2, :pt}])
```

### Charts

29 chart types across 10 families: column, bar, line, pie, area, doughnut, radar, scatter, bubble, and combo.

```elixir
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia"])
  |> ChartData.add_series("2024", [42, 28, 18], color: "4472C4")
  |> ChartData.add_series("2025", [48, 32, 25], color: "ED7D31")

slide =
  Podium.Slide.new()
  |> Podium.add_chart(:pie, chart_data,
    x: {1, :inches}, y: {1, :inches}, width: {8, :inches}, height: {5, :inches},
    title: "Market Share",
    legend: :right,                              # :left | :right | :top | :bottom | false
    data_labels: [:category, :percent],          # :value | :category | :series | :percent
    category_axis: [title: "Region"],
    value_axis: [
      title: "Share (%)",
      number_format: "0%",
      min: 0, max: 100, major_unit: 25,
      major_gridlines: true                      # default true, set false to hide
    ]
  )
```

### Images

```elixir
slide = Podium.add_image(slide, File.read!("logo.png"),
  x: {1, :inches}, y: {1, :inches}, width: {3, :inches}, height: {2, :inches})
```

Format is auto-detected from file magic bytes (PNG and JPEG supported).

### Tables

```elixir
slide = Podium.add_table(slide, [
  ["Name",  "Q1",  "Q2",  "Q3" ],
  ["Alice", "100", "200", "300"],
  ["Bob",   "150", "250", "350"]
], x: {1, :inches}, y: {2, :inches}, width: {8, :inches}, height: {3, :inches})
```

Cells accept the same text formats as `add_text_box` — plain strings or rich text lists.

### Placeholders

```elixir
slide =
  Podium.Slide.new(:title_slide)
  |> Podium.set_placeholder(:title, "Annual Report 2025")
  |> Podium.set_placeholder(:subtitle, "Engineering Division")
```

Available layouts and their placeholders:

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

### Saving

```elixir
# To file
:ok = Podium.save(prs, "output.pptx")

# To memory (for streaming, uploads, etc.)
{:ok, binary} = Podium.save_to_memory(prs)
```

### Units

All position and size values accept `{number, unit}` tuples or raw EMU integers:

```elixir
{1, :inches}   # 914,400 EMU
{2.54, :cm}    # 914,400 EMU
{72, :pt}      # 914,400 EMU
914_400         # raw EMU
```

## Demos

The `demos/` directory has scripts covering every feature. Run any of them to generate a `.pptx` file in `demos/output/`:

    mix run demos/getting-started.exs

Integration tests also produce viewable `.pptx` files in `test/podium/integration/output/` when you run `mix test`.

## Acknowledgments

Podium's design and feature set are ported from [python-pptx](https://github.com/scanny/python-pptx) by Steve Canny. Without python-pptx as a reference, this library would not exist.

## License

MIT — see [LICENSE](LICENSE).
