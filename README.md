# Podium

Generate PowerPoint (`.pptx`) files from Elixir — with editable charts.

Podium creates well-formed OOXML presentations from scratch. Charts embed real Excel workbooks so recipients can double-click to edit the data directly in PowerPoint. No templates to manage, no COM interop, no external services.

## Features

- **Rich text** — bold, italic, underline, strikethrough, superscript, subscript, color, font, alignment, bullets, paragraph spacing
- **Charts** — column (clustered/stacked), bar (clustered/stacked), line, line with markers, pie — all fully editable
- **Chart formatting** — titles, legends, data labels, axis customization (min/max, gridlines, number format), per-series colors
- **Images** — PNG and JPEG with automatic format detection
- **Tables** — rows and columns with rich text cells
- **Placeholders** — title, subtitle, and body on standard slide layouts
- **Shape styling** — solid fills and lines with configurable width
- **Slide dimensions** — 16:9 default, fully configurable

## Quick start

```elixir
alias Podium.Chart.ChartData

prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

# Add a styled text box
slide = Podium.add_text_box(slide, [
  {[{"Quarterly Report", bold: true, font_size: 36, color: "003366"}], alignment: :center}
], x: {1, :inches}, y: {0.5, :inches}, width: {10, :inches}, height: {1, :inches})

# Add an editable chart
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167], color: "4472C4")
  |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000], color: "ED7D31")

{prs, slide} = Podium.add_chart(prs, slide, :column_clustered, chart_data,
  x: {1, :inches}, y: {2, :inches}, width: {10, :inches}, height: {4.5, :inches},
  title: "Revenue vs Expenses",
  legend: :bottom,
  data_labels: [:value]
)

prs = Podium.put_slide(prs, slide)
Podium.save(prs, "report.pptx")
```

## Installation

Add `podium` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:podium, "~> 0.1.0"}
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

# Add slides with different layouts
{prs, slide} = Podium.add_slide(prs)                          # blank
{prs, slide} = Podium.add_slide(prs, layout: :title_slide)    # title + subtitle
{prs, slide} = Podium.add_slide(prs, layout: :title_content)  # title + body
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

Seven chart types: `:column_clustered`, `:column_stacked`, `:bar_clustered`, `:bar_stacked`, `:line`, `:line_markers`, `:pie`.

```elixir
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia"])
  |> ChartData.add_series("2024", [42, 28, 18], color: "4472C4")
  |> ChartData.add_series("2025", [48, 32, 25], color: "ED7D31")

{prs, slide} = Podium.add_chart(prs, slide, :pie, chart_data,
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
{prs, slide} = Podium.add_image(prs, slide, File.read!("logo.png"),
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
{prs, slide} = Podium.add_slide(prs, layout: :title_slide)

slide =
  slide
  |> Podium.set_placeholder(:title, "Annual Report 2025")
  |> Podium.set_placeholder(:subtitle, "Engineering Division")
```

Available layouts and their placeholders:

| Layout | Placeholders |
|--------|-------------|
| `:title_slide` | `:title`, `:subtitle` |
| `:title_content` | `:title`, `:body` |
| `:blank` | (none) |

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

## Demo

See [`demos/basics.exs`](demos/basics.exs) for a complete 11-slide presentation exercising every feature.

```bash
mix run demos/basics.exs
open demos/basics.pptx
```

## License

MIT — see [LICENSE](LICENSE).
