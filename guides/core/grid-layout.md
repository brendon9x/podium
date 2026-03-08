# Grid Layout

A Tailwind CSS Grid system that computes positions for you. Instead of calculating
that a right column starts at 52% of the slide width, declare `row-2 col-span-8` and
`row-2 col-span-4` on your elements.

Grid config goes on the slide, placement goes inline on elements. No intermediate
variables, no state threading.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/grid-layout.exs` to generate a presentation with all the examples from this guide.

## Basic Usage

Declare the grid on the slide with Tailwind classes, then place elements inline:

```elixir
slide = Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
|> Podium.add_text_box("Title",
    style: "row-1 col-span-12", fill: "003366", alignment: :center)
|> Podium.add_chart(:column_clustered, chart_data,
    style: "row-2 col-span-8", title: "Sales")
|> Podium.add_text_box(html,
    style: "row-2 col-span-4", fill: "E2EFDA")
```

Elements are placed immediately when `add_*` is called. Each row tracks a column
cursor that advances automatically.

![Two-column layout with chart and text](assets/web-layer/grid-layout/two-column.png)

## How It Works

The grid divides the slide into a content area (after padding), then:

1. **`Slide.new`** parses the grid config and pre-computes row positions/heights
2. **Each `add_*` call** resolves the element's grid placement to x/y/width/height

```
┌─────────────────────────────────────────┐
│  padding                                │
│  ┌─────────────────────────────────┐    │
│  │ row 1 (title)                   │    │
│  │ [  col-span-12               ] │    │
│  ├─────────────────────────────────┤    │
│  │ row 2 (content)                 │    │
│  │ [ col-span-8     ][ col-span-4] │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

## Slide-Level Classes

| Class | Description |
|-------|-------------|
| `grid` | Enables grid mode (required) |
| `grid-cols-N` | Number of columns (default 12) |
| `grid-rows-[H1_H2_...]` | Row heights template — `%` for explicit, `auto` for equal fill |
| `p-[N%]` | Uniform padding from slide edges |
| `px-[N%]` | Horizontal padding only |
| `py-[N%]` | Vertical padding only |
| `gap-[N%]` | Uniform gap between cells |
| `gap-x-[N%]` | Horizontal gap only |
| `gap-y-[N%]` | Vertical gap only |

### Row height examples

```elixir
# Two rows: 15% title, auto-fill content
style: "grid grid-rows-[15%_auto] ..."

# Three equal rows
style: "grid grid-rows-[auto_auto_auto] ..."

# Mixed: 10% header, 70% body, 20% footer
style: "grid grid-rows-[10%_70%_20%] ..."
```

`auto` rows split the remaining space equally after explicit heights and gaps are subtracted.

## Element-Level Classes

| Class | Description |
|-------|-------------|
| `row-N` | Place in row N (1-indexed, required for grid elements) |
| `col-span-N` | Span N columns (default 1) |
| `col-start-N` | Start at column N (1-indexed, for centering/offsets) |

### Three equal columns

```elixir
slide = Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
|> Podium.add_text_box("Phase 1", style: "row-2 col-span-4", fill: "4472C4")
|> Podium.add_text_box("Phase 2", style: "row-2 col-span-4", fill: "ED7D31")
|> Podium.add_text_box("Phase 3", style: "row-2 col-span-4", fill: "70AD47")
```

![Three equal columns](assets/web-layer/grid-layout/three-columns.png)

### Centering with col-start

Center content on the slide using `col-start`:

```elixir
|> Podium.add_text_box("Centered",
    style: "row-2 col-span-6 col-start-4", fill: "DAEEF3")
```

![Centered column with col-start-4](assets/web-layer/grid-layout/offset-centering.png)

### Column math

Given a 12-column grid with content width `W` and gap `G`:

- Unit width: `(W - 11 * G) / 12`
- `col-span-N` width: `N * unit_width + (N - 1) * G`
- Columns are placed left-to-right with one gap between each

## Custom Configuration

```elixir
# 6-column grid with larger padding
slide = Podium.Slide.new(style: "grid grid-cols-6 grid-rows-[20%_auto] p-[8%] gap-[3%]")

# Separate horizontal/vertical padding and gap
slide = Podium.Slide.new(style: "grid px-[3%] py-[7%] gap-x-[1%] gap-y-[3%] grid-rows-[auto]")
```

![Custom 6-column grid configuration](assets/web-layer/grid-layout/custom-config.png)

## Mixing Grid and Non-Grid Elements

Elements without grid classes (`row-N`, `col-span-N`) on a grid slide fall through to
normal absolute positioning via `style:` CSS properties or keyword opts:

```elixir
slide = Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[auto] p-[5%]")
|> Podium.add_text_box("Grid element", style: "row-1 col-span-12")
|> Podium.add_text_box("Absolute element", style: "left: 5%; top: 90%; width: 90%; height: 8%")
```

Non-grid slides continue to work exactly as before.

## Worked Example

A report slide with title, chart, and key takeaways:

```elixir
alias Podium.Chart.ChartData

data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [120, 180, 150, 220], color: "4472C4")

slide = Podium.Slide.new(style: "grid grid-cols-12 grid-rows-[15%_auto] p-[5%] gap-[2%]")
|> Podium.add_text_box(
  [[{"Quarterly Report", bold: true, font_size: 28}]],
  style: "row-1 col-span-12", alignment: :center, anchor: :middle
)
|> Podium.add_chart(:column_clustered, data,
  style: "row-2 col-span-8", title: "Revenue by Quarter", legend: :bottom
)
|> Podium.add_text_box(
  {:html, "<p><b>Highlights</b></p><ul><li>Revenue up 83%</li><li>Strong Q4 finish</li></ul>"},
  style: "row-2 col-span-4", fill: "E2EFDA", font_size: 14
)
```

![Title row with content area below](assets/web-layer/grid-layout/title-content.png)

---

Grid layout is part of the Web Layer — it brings Tailwind's familiar grid system
to PowerPoint generation. See also [CSS Styling](css-styling.md) for `style:` strings
and [HTML Text](html-text.md) for HTML formatting.
