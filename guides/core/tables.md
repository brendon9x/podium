# Tables

Build data tables with `Podium.add_table/3`. Tables support plain strings, rich
text, cell merging, borders, padding, fills, and custom column widths.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/tables.exs` to generate a presentation with all the examples from this guide.

```elixir
slide = Podium.add_table(slide, [
  ["Region", "Q1", "Q2"],
  ["North America", "$12.5M", "$14.1M"],
  ["Europe", "$8.2M", "$9.0M"]
], x: {1, :inches}, y: {1.5, :inches},
   width: {11, :inches}, height: {3, :inches})
```

## Basic Tables

Pass a list of rows to `Podium.add_table/3`. Each row is a list of cell values.
In the simplest case, every cell is a plain string.

![Basic table with header fills and borders](assets/core/tables/basic-table.png)

```elixir
prs = Podium.new()
slide = Podium.Slide.new()

slide = Podium.add_table(slide, [
  ["Department", "Headcount", "Budget"],
  ["Engineering", "230", "$4,200K"],
  ["Marketing", "85", "$2,100K"],
  ["Sales", "120", "$3,500K"]
], x: {1, :inches}, y: {1, :inches},
   width: {11, :inches}, height: {3, :inches})

prs = Podium.add_slide(prs, slide)
Podium.save(prs, "table_demo.pptx")
```

Column widths are distributed evenly across the total width by default. Row heights
are distributed evenly across the total height.

## Rich Text in Cells

Cells accept the same rich text format as `Podium.add_text_box/3`. Wrap the rich
text list in an outer list to form a cell value:

```elixir
slide = Podium.add_table(slide, [
  [[[{"Department", bold: true, color: "FFFFFF"}]], [[{"Score", bold: true, color: "FFFFFF"}]]],
  ["Engineering", [[{"92%", bold: true, color: "228B22"}]]],
  ["Marketing", "87%"]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {2.5, :inches})
```

The header row uses bold white text via rich text formatting, while the Engineering
score cell uses bold green text.

## Cell Formatting

To apply formatting to a cell, use a `{text, options}` tuple. The text can be a
plain string or a rich text list.

```elixir
{"Header", fill: "4472C4", borders: [bottom: "003366"]}
```

### Cell Fill

Set a background color on individual cells with the `:fill` option:

![Cell formatting with gradient, pattern fills, and vertical alignment](assets/core/tables/cell-formatting.png)

```elixir
slide = Podium.add_table(slide, [
  [{"Department", fill: "4472C4"}, {"Budget", fill: "4472C4"}],
  ["Engineering", "$4,200K"],
  ["Marketing", "$2,100K"]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {2, :inches})
```

Cell fills support the same formats as shape fills -- solid colors, gradients,
and patterns:

```elixir
# Solid fill
{"Revenue", fill: "4472C4"}

# Gradient fill
{"Gradient", fill: {:gradient, [{0, "4472C4"}, {100_000, "002060"}], angle: 5_400_000}}

# Pattern fill
{"Pattern", fill: {:pattern, :lt_horz, foreground: "ED7D31", background: "FFFFFF"}}
```

### Cell Borders

Set borders per side with the `:borders` option. Each side accepts a color string
for a simple border or a keyword list for full control:

```elixir
slide = Podium.add_table(slide, [
  [{"Cell", borders: [
    bottom: "000000",
    top: [color: "FF0000", width: {2, :pt}]
  ]}]
], x: {1, :inches}, y: {1, :inches},
   width: {4, :inches}, height: {1, :inches})
```

Available sides: `:left`, `:right`, `:top`, `:bottom`.

### Cell Padding

Control the internal margin on each side of a cell:

```elixir
{"Padded text", padding: [left: {0.1, :inches}, top: {0.05, :inches}]}
```

Available sides: `:left`, `:right`, `:top`, `:bottom`.

### Vertical Alignment

Anchor text to the top, middle, or bottom of a cell:

```elixir
{"Centered vertically", anchor: :middle}
```

| Value | Description |
|-------|-------------|
| `:top` | Align to top (default) |
| `:middle` | Center vertically |
| `:bottom` | Align to bottom |

### Cell Options Reference

| Option | Type | Description |
|--------|------|-------------|
| `:fill` | `fill_spec` | Cell background (solid, gradient, or pattern) |
| `:borders` | `keyword` | Per-side borders |
| `:padding` | `keyword` | Per-side internal padding |
| `:anchor` | `:top \| :middle \| :bottom` | Vertical text alignment |
| `:col_span` | `integer` | Number of columns to merge across |
| `:row_span` | `integer` | Number of rows to merge down |

## Cell Merging

Merge cells horizontally with `:col_span`, vertically with `:row_span`, or both.
Fill the spanned positions with the `:merge` placeholder atom.

### Horizontal Merge

![Cell merging with horizontal span and vertical span](assets/core/tables/cell-merging.png)

```elixir
slide = Podium.add_table(slide, [
  [{"Q4 2025 Results", col_span: 3, fill: "003366"}, :merge, :merge],
  ["Region", "Revenue", "Growth"],
  ["North America", "$12.5M", "+18%"],
  ["Europe", "$8.2M", "+12%"]
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {3, :inches})
```

The first row spans all three columns. The two `:merge` atoms mark the cells
consumed by the span.

### Vertical Merge

```elixir
slide = Podium.add_table(slide, [
  [{"Engineering", row_span: 2, fill: "D6E4F0", anchor: :middle}, "Frontend", "42"],
  [:merge, "Backend", "58"],
  ["Marketing", "Digital", "85"]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {2.5, :inches})
```

The "Engineering" cell spans two rows. The `:merge` in the second row marks the
consumed position.

### Combined Merge

You can combine `:col_span` and `:row_span` on the same cell. Place `:merge`
atoms in every consumed position:

```elixir
[{"Big Cell", col_span: 2, row_span: 2}, :merge],
[:merge, :merge]
```

## Table Style Banding

Control which banding flags PowerPoint applies to the table. These flags affect
how the built-in table style renders alternating row/column shading.

```elixir
slide = Podium.add_table(slide, rows,
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {3, :inches},
  table_style: [
    first_row: true,
    band_row: true,
    band_col: false,
    last_row: false,
    first_col: false,
    last_col: false
  ])
```

| Flag | Default | Description |
|------|---------|-------------|
| `:first_row` | `true` | Highlight the first row as a header |
| `:last_row` | `false` | Highlight the last row |
| `:first_col` | `false` | Highlight the first column |
| `:last_col` | `false` | Highlight the last column |
| `:band_row` | `true` | Alternate row shading |
| `:band_col` | `false` | Alternate column shading |

## Custom Column Widths and Row Heights

Override the even distribution with explicit dimensions:

```elixir
slide = Podium.add_table(slide, [
  ["Rank", "Description", "Score"],
  ["1", "Revenue growth exceeded target", "95%"],
  ["2", "Customer retention improved", "88%"]
], x: {1, :inches}, y: {1, :inches},
   width: {11, :inches}, height: {2, :inches},
   col_widths: [{1.5, :inches}, {6, :inches}, {3.5, :inches}],
   row_heights: [{0.5, :inches}, {0.75, :inches}, {0.75, :inches}])
```

Column widths and row heights accept the same unit formats as position values:
`{value, :inches}`, `{value, :cm}`, `{value, :pt}`, or raw EMU integers.

## Table Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:x` | `emu_spec` | required | Horizontal position |
| `:y` | `emu_spec` | required | Vertical position |
| `:width` | `emu_spec` | required | Total table width |
| `:height` | `emu_spec` | required | Total table height |
| `:col_widths` | `[emu_spec]` | even distribution | Per-column widths |
| `:row_heights` | `[emu_spec]` | even distribution | Per-row heights |
| `:table_style` | `keyword` | see banding defaults | Banding flags |

## Complete Example

Here is a professional report table that combines header merging, cell fills,
borders, rich text, vertical merging, and padding:

![Professional report table with merging, fills, borders, and rich text](assets/core/tables/complete-example.png)

```elixir
prs = Podium.new()
slide = Podium.Slide.new()

slide = Podium.add_table(slide, [
  # Merged title row
  [{"Department Summary -- 2025", col_span: 4, fill: "003366",
    anchor: :middle, padding: [left: {0.1, :inches}]},
   :merge, :merge, :merge],

  # Column headers with fill and bottom border
  [{"Department", fill: "4472C4",
    borders: [bottom: [color: "003366", width: {2, :pt}]]},
   {"Headcount", fill: "4472C4",
    borders: [bottom: [color: "003366", width: {2, :pt}]]},
   {"Budget ($K)", fill: "4472C4",
    borders: [bottom: [color: "003366", width: {2, :pt}]]},
   {"Satisfaction", fill: "4472C4",
    borders: [bottom: [color: "003366", width: {2, :pt}]]}],

  # Engineering spans 2 rows with rich text
  [{[[{"Engineering", bold: true, color: "003366"}]],
    row_span: 2, anchor: :middle, fill: "D6E4F0",
    padding: [left: {0.1, :inches}]},
   "230", "$4,200",
   {[[{"92%", bold: true, color: "228B22"}]], anchor: :middle}],

  [:merge, "180", "$3,800",
   {[[{"94%", bold: true, color: "228B22"}]], anchor: :middle}],

  ["Marketing", "85", "$2,100",
   {"87%", borders: [bottom: "CCCCCC"]}],

  ["Sales", "120", "$3,500",
   {"84%", borders: [bottom: "CCCCCC"]}]
], x: {0.5, :inches}, y: {1, :inches},
   width: {12, :inches}, height: {4.5, :inches})

prs = Podium.add_slide(prs, slide)
Podium.save(prs, "report_table.pptx")
```

---

Tables present structured data on slides. For data visualization, see
[Charts](charts.md) to create column, bar, line, pie, and other chart types.
