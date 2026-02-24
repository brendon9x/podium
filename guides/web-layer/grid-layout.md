# Grid Layout

A Bootstrap-style 12-column grid system that computes positions for you. Instead of
calculating that a right column starts at 52% of the slide width, use `"col-8"` and `"col-4"`.

This module is infrastructure for the upcoming DSL (Phase 5), which will wrap it in
`row do / col "col-N" do` macro blocks. The direct API documented here is also usable
standalone for dynamic or programmatic layouts.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/grid-layout.exs` to generate a presentation with all the examples from this guide.

## Basic Usage

Create a grid from a slide, claim rows, then compute column positions:

```elixir
alias Podium.Layout

slide = Podium.Slide.new()
grid = Layout.grid(slide)

# Title row at top, content row fills the rest
{title_row, grid} = Layout.row(grid, height: {20, :percent})
[header] = Layout.cols(title_row, ["col-12"])

{content_row, _grid} = Layout.row(grid)
[left, right] = Layout.cols(content_row, ["col-8", "col-4"])

slide
|> Podium.add_text_box("Title", header ++ [fill: "003366", alignment: :center])
|> Podium.add_chart(:column_clustered, chart_data, left ++ [title: "Sales"])
|> Podium.add_text_box(html, right ++ [fill: "E2EFDA"])
```

Each `cols/2` call returns a list of `[x:, y:, width:, height:]` keyword lists — the same
format that `add_text_box/3`, `add_chart/4`, and all other `add_*` functions expect. Merge
additional opts with `++`.

![Two-column layout with chart and text](assets/web-layer/grid-layout/two-column.png)

## How It Works

The grid divides the slide into a content area (after margins), then:

1. **`grid/2`** computes the content area bounds and column unit width
2. **`row/2`** claims vertical space, advancing a cursor
3. **`cols/2`** places columns left-to-right within a row

```
┌─────────────────────────────────────────┐
│  margin                                 │
│  ┌─────────────────────────────────┐    │
│  │ row 1 (title)                   │    │
│  │ [  col-12                     ] │    │
│  ├─────────────────────────────────┤    │
│  │ row 2 (content)                 │    │
│  │ [ col-8         ][ col-4      ] │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

## Configuration

### Grid options

| Option | Default | Description |
|--------|---------|-------------|
| `:margin` | `{5, :percent}` | Slide edge margin — uniform or asymmetric keyword list |
| `:gutter` | `{2, :percent}` | Gap between columns and rows (like Bootstrap's `g-*`) |
| `:column_gutter` | same as `:gutter` | Override horizontal gutter only (like `gx-*`) |
| `:row_gutter` | same as `:gutter` | Override vertical gutter only (like `gy-*`) |
| `:columns` | `12` | Number of grid columns |

```elixir
# Defaults
grid = Layout.grid(slide)

# Custom — 6-column grid with larger margins
grid = Layout.grid(slide, columns: 6, margin: {8, :percent}, gutter: {3, :percent})

# Asymmetric margins
grid = Layout.grid(slide,
  margin: [left: {3, :percent}, top: {5, :percent}, right: {3, :percent}, bottom: {5, :percent}]
)
```

All dimension values use the standard Podium dimension system: `{value, :percent}`,
`{value, :inches}`, `{value, :cm}`, `{value, :pt}`, or raw EMU integers.

![Custom 6-column grid configuration](assets/web-layer/grid-layout/custom-config.png)

### Row heights

Rows stack vertically. The last row automatically fills remaining space:

```elixir
{title_row, grid} = Layout.row(grid, height: {15, :percent})  # 15% of content height
{body_row, grid} = Layout.row(grid, height: {2, :inches})      # absolute height
{footer_row, _grid} = Layout.row(grid)                          # fills remaining space
```

## Column Specs

Column specs use Bootstrap vocabulary:

| Spec | Meaning |
|------|---------|
| `"col-12"` | Full width |
| `"col-6"` | Half width |
| `"col-4"` | One-third width |
| `"col-8 offset-2"` | 8 columns wide, shifted 2 columns from the left |

### Three equal columns

```elixir
{row, _grid} = Layout.row(grid)
[c1, c2, c3] = Layout.cols(row, ["col-4", "col-4", "col-4"])
```

![Three equal columns](assets/web-layer/grid-layout/three-columns.png)

### Offset centering

Center content on the slide using offsets:

```elixir
{row, _grid} = Layout.row(grid)
[centered] = Layout.cols(row, ["col-6 offset-3"])

slide = Podium.add_text_box(slide, "Centered content", centered)
```

![Centered column with offset-3](assets/web-layer/grid-layout/offset-centering.png)

### Column math

Given a 12-column grid with content width `W` and gutter `G`:

- Unit width: `(W - 11 * G) / 12`
- `col-N` width: `N * unit_width + (N - 1) * G`
- Columns are placed left-to-right with one gutter between each

## Worked Example

A report slide with title, chart, and key takeaways:

```elixir
alias Podium.Layout
alias Podium.Chart.ChartData

slide = Podium.Slide.new()
grid = Layout.grid(slide)

# Title row
{title_row, grid} = Layout.row(grid, height: {15, :percent})
[title] = Layout.cols(title_row, ["col-12"])

# Content row — chart on the left, text on the right
{content_row, _grid} = Layout.row(grid)
[chart_area, text_area] = Layout.cols(content_row, ["col-8", "col-4"])

data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [120, 180, 150, 220], color: "4472C4")

slide
|> Podium.add_text_box(
  [[{"Quarterly Report", bold: true, font_size: 28}]],
  title ++ [alignment: :center, anchor: :middle]
)
|> Podium.add_chart(:column_clustered, data,
  chart_area ++ [title: "Revenue by Quarter", legend: :bottom]
)
|> Podium.add_text_box(
  {:html, "<p><b>Highlights</b></p><ul><li>Revenue up 83%</li><li>Strong Q4 finish</li></ul>"},
  text_area ++ [fill: "E2EFDA", font_size: 14]
)
```

![Title row with content area below](assets/web-layer/grid-layout/title-content.png)

---

Grid layout is part of the Web Layer — it brings Bootstrap's familiar column system
to PowerPoint generation. See also [CSS Styling](css-styling.md) for `style:` strings
and [HTML Text](html-text.md) for HTML formatting.
