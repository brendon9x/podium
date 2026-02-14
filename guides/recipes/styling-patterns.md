# Styling Patterns

Build reusable patterns for consistent, professional presentations. This guide
covers color palettes, helper functions, chart styling, table formatting, and
theme variations.

```elixir
defmodule Acme.Slides do
  @brand_navy "003366"
  @brand_blue "4472C4"
  @brand_green "228B22"

  def title_box(slide, text) do
    Podium.add_text_box(slide,
      [{[{text, bold: true, font_size: 28, color: @brand_navy}], alignment: :center}],
      x: {0.5, :inches}, y: {0.3, :inches},
      width: {12, :inches}, height: {0.8, :inches})
  end
end
```

## Color Palette as Module Attributes

Define your brand colors once and reference them everywhere. Module attributes are
compile-time constants, so there is no runtime cost.

```elixir
defmodule Acme.Style do
  # Primary palette
  @navy "003366"
  @blue "4472C4"
  @light_blue "BDD7EE"
  @orange "ED7D31"
  @green "70AD47"
  @dark_green "228B22"
  @gray "A5A5A5"
  @light_gray "E8EDF2"

  # Text colors
  @text_dark "333333"
  @text_light "FFFFFF"
  @text_muted "666666"

  # Expose for other modules
  def navy, do: @navy
  def blue, do: @blue
  def light_blue, do: @light_blue
  def orange, do: @orange
  def green, do: @green
  def gray, do: @gray
  def text_dark, do: @text_dark
  def text_light, do: @text_light
end
```

Reference these in your slide-building code to keep colors consistent across
every text box, chart, and table.

## Helper Functions for Branded Text Boxes

Wrap common text box patterns in functions so every slide looks the same without
duplicating options:

```elixir
defmodule Acme.Slides do
  alias Acme.Style

  def slide_title(slide, text) do
    Podium.add_text_box(slide,
      [{[{text, bold: true, font_size: 28, color: Style.navy()}], alignment: :center}],
      x: {0.5, :inches}, y: {0.3, :inches},
      width: {12, :inches}, height: {0.8, :inches})
  end

  def section_header(slide, title, subtitle) do
    Podium.add_text_box(slide,
      [
        {[{title, bold: true, font_size: 32, color: Style.text_light()}], alignment: :center},
        {[{subtitle, font_size: 16, color: Style.light_blue()}], alignment: :center}
      ],
      x: {0.5, :inches}, y: {0.3, :inches},
      width: {12, :inches}, height: {1, :inches},
      fill: {:gradient, [{0, Style.navy()}, {100_000, Style.blue()}], angle: 5_400_000})
  end

  def body_text(slide, paragraphs, opts \\ []) do
    y = Keyword.get(opts, :y, {1.5, :inches})

    Podium.add_text_box(slide, paragraphs,
      x: {0.5, :inches}, y: y,
      width: {12, :inches}, height: {5, :inches})
  end

  def footnote(slide, text) do
    Podium.add_text_box(slide, text,
      x: {0.5, :inches}, y: {6.5, :inches},
      width: {12, :inches}, height: {0.3, :inches},
      font_size: 10, alignment: :right)
  end
end
```

Usage becomes concise and consistent:

```elixir
slide =
  Podium.Slide.new()
  |> Acme.Slides.slide_title("Q4 2025 Performance")
  |> Acme.Slides.body_text([
    {["Revenue grew 35% year-over-year"], bullet: true},
    {["Operating margin improved to 28%"], bullet: true},
    {["Customer satisfaction reached 92%"], bullet: true}
  ])
  |> Acme.Slides.footnote("Source: Internal analytics, Jan 2026")

prs = Podium.add_slide(prs, slide)
```

## Consistent Chart Styling

Wrap chart creation in a function that applies your standard options:

```elixir
defmodule Acme.Charts do
  alias Acme.Style
  alias Podium.Chart.ChartData

  @default_chart_opts [
    x: {0.5, :inches},
    y: {1.2, :inches},
    width: {12, :inches},
    height: {5.5, :inches}
  ]

  def add_chart(slide, chart_type, chart_data, opts \\ []) do
    merged_opts =
      @default_chart_opts
      |> Keyword.merge(
        title: Keyword.get(opts, :title),
        legend: Keyword.get(opts, :legend, [position: :bottom, font_size: 10]),
        value_axis: Keyword.get(opts, :value_axis, [major_gridlines: true]),
        category_axis: Keyword.get(opts, :category_axis, [])
      )
      |> Keyword.merge(opts)

    Podium.add_chart(slide, chart_type, chart_data, merged_opts)
  end

  def revenue_chart_data(categories, values) do
    ChartData.new()
    |> ChartData.add_categories(categories)
    |> ChartData.add_series("Revenue", values, color: Style.blue())
  end
end
```

Every chart created through `Acme.Charts.add_chart/4` gets the same position,
legend style, and gridline settings:

```elixir
chart_data = Acme.Charts.revenue_chart_data(
  ["Q1", "Q2", "Q3", "Q4"],
  [12_500, 14_600, 15_200, 18_100])

slide =
  Acme.Charts.add_chart(slide, :column_clustered, chart_data,
    title: "Quarterly Revenue")
```

## Professional Table Styling

Create a helper that applies consistent header formatting, borders, and banding:

```elixir
defmodule Acme.Tables do
  alias Acme.Style

  def add_report_table(slide, headers, data_rows, opts \\ []) do
    header_row =
      Enum.map(headers, fn text ->
        {text, fill: Style.blue(),
         borders: [bottom: [color: Style.navy(), width: {2, :pt}]]}
      end)

    all_rows = [header_row | data_rows]

    Podium.add_table(slide, all_rows,
      x: Keyword.get(opts, :x, {0.5, :inches}),
      y: Keyword.get(opts, :y, {1.2, :inches}),
      width: Keyword.get(opts, :width, {12, :inches}),
      height: Keyword.get(opts, :height, {4, :inches}),
      table_style: [first_row: true, band_row: true])
  end
end
```

Usage:

```elixir
slide = Acme.Tables.add_report_table(slide,
  ["Department", "Headcount", "Budget", "Score"],
  [
    ["Engineering", "230", "$4,200K", "92%"],
    ["Marketing", "85", "$2,100K", "87%"],
    ["Sales", "120", "$3,500K", "84%"]
  ])
```

## Building a Style System

Combine the palette, text helpers, chart helpers, and table helpers into a
coherent module structure:

```
lib/
  acme/
    style.ex          # Color palette and constants
    slides.ex         # Text box helpers (title, body, footnote)
    charts.ex         # Chart wrappers with default options
    tables.ex         # Table wrappers with header styling
    report_builder.ex # High-level functions for full slide types
```

The report builder ties everything together:

```elixir
defmodule Acme.ReportBuilder do
  alias Acme.{Charts, Slides, Tables}

  def title_slide(prs, title, subtitle) do
    slide =
      Podium.Slide.new(:title_slide)
      |> Podium.set_placeholder(:title, [
        [{title, bold: true, font_size: 44, color: Acme.Style.navy()}]
      ])
      |> Podium.set_placeholder(:subtitle, subtitle)

    Podium.add_slide(prs, slide)
  end

  def data_slide(prs, title, chart_type, chart_data, table_headers, table_rows) do
    slide =
      Podium.Slide.new(:two_content)
      |> Podium.set_placeholder(:title, title)
      |> Podium.set_table_placeholder(prs, :left_content,
        [table_headers | table_rows],
        table_style: [first_row: true])
      |> Podium.set_chart_placeholder(prs, :right_content,
        chart_type, chart_data,
        legend: :bottom, data_labels: [:percent])

    Podium.add_slide(prs, slide)
  end
end
```

## Gradient and Pattern Fill Recipes

### Gradient Header Bar

A horizontal gradient makes a professional header background:

```elixir
slide = Podium.add_text_box(slide,
  [{[{"Section Title", bold: true, font_size: 24, color: "FFFFFF"}], alignment: :center}],
  x: {0.5, :inches}, y: {0.3, :inches},
  width: {12, :inches}, height: {0.7, :inches},
  fill: {:gradient, [{0, "001133"}, {100_000, "004488"}], angle: 5_400_000})
```

The `angle` is in 60,000ths of a degree. Common values:

| Angle | Direction |
|-------|-----------|
| `0` | Left to right |
| `5_400_000` | Top to bottom |
| `2_700_000` | Diagonal (top-left to bottom-right) |
| `10_800_000` | Bottom to top |

### Pattern Fill Accent

Use pattern fills for texture accents on supporting elements:

```elixir
slide = Podium.add_text_box(slide, "Key Insight",
  x: {1, :inches}, y: {5, :inches},
  width: {4, :inches}, height: {0.8, :inches},
  fill: {:pattern, :lt_horz, foreground: "003366", background: "E8EDF2"},
  font_size: 14, alignment: :center)
```

Common pattern presets for professional use: `:lt_horz` (light horizontal),
`:lt_vert` (light vertical), `:dn_diag` (downward diagonal), `:sm_grid`
(small grid), `:pct_5` through `:pct_20` (percentage fills for subtle textures).

## Dark Theme Example

A dark theme inverts the typical color scheme. Use dark backgrounds with light
text:

```elixir
defmodule Acme.DarkTheme do
  @bg_dark "1A1A2E"
  @bg_card "16213E"
  @accent "0F3460"
  @highlight "E94560"
  @text_primary "EAEAEA"
  @text_secondary "A0A0A0"

  def dark_slide() do
    Podium.Slide.new(background: @bg_dark)
  end

  def dark_title(slide, text) do
    Podium.add_text_box(slide,
      [{[{text, bold: true, font_size: 28, color: @text_primary}], alignment: :center}],
      x: {0.5, :inches}, y: {0.3, :inches},
      width: {12, :inches}, height: {0.8, :inches})
  end

  def dark_card(slide, title, body, opts \\ []) do
    x = Keyword.get(opts, :x, {1, :inches})
    y = Keyword.get(opts, :y, {1.5, :inches})
    width = Keyword.get(opts, :width, {5, :inches})

    Podium.add_text_box(slide, [
      {[{title, bold: true, font_size: 18, color: @highlight}], space_after: 6},
      {[{body, font_size: 14, color: @text_secondary}], line_spacing: 1.3}
    ], x: x, y: y, width: width, height: {2, :inches},
       fill: @bg_card,
       line: [color: @accent, width: {1, :pt}],
       margin_left: {0.2, :inches}, margin_top: {0.15, :inches})
  end
end
```

Usage:

```elixir
slide =
  Acme.DarkTheme.dark_slide()
  |> Acme.DarkTheme.dark_title("Performance Dashboard")
  |> Acme.DarkTheme.dark_card("Revenue", "$18.2M (+35%)",
    x: {0.5, :inches}, y: {1.5, :inches}, width: {5.5, :inches})
  |> Acme.DarkTheme.dark_card("Customers", "1,247 active accounts",
    x: {6.5, :inches}, y: {1.5, :inches}, width: {5.5, :inches})

prs = Podium.add_slide(prs, slide)
```

## Light Theme Example

A light theme uses white backgrounds with colored accents:

```elixir
defmodule Acme.LightTheme do
  @bg_white "FFFFFF"
  @accent_bar "4472C4"
  @text_heading "1F2937"
  @text_body "4B5563"
  @border_light "E5E7EB"

  def light_slide() do
    Podium.Slide.new(background: @bg_white)
  end

  def light_title(slide, text) do
    slide
    |> Podium.add_text_box(
      [{[{text, bold: true, font_size: 28, color: @text_heading}], alignment: :left}],
      x: {0.5, :inches}, y: {0.4, :inches},
      width: {12, :inches}, height: {0.7, :inches})
    |> Podium.add_text_box("",
      x: {0.5, :inches}, y: {1.1, :inches},
      width: {2, :inches}, height: {0.05, :inches},
      fill: @accent_bar)
  end
end
```

The accent bar -- a thin colored text box -- creates a clean visual separator
below the heading.

## Key Takeaways

- Define colors as module attributes to avoid magic strings scattered through code
- Wrap repeated patterns in helper functions with sensible defaults
- Use `Keyword.merge/2` to let callers override defaults when needed
- Keep your style module separate from your slide-building logic
- Test both light and dark themes to verify text remains readable

---

These patterns help you build maintainable, consistently-styled presentations.
For a complete end-to-end example that uses these patterns, see
[Building a Report](building-a-report.md).
