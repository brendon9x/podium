# Charts

Add data visualizations to slides with `Podium.add_chart/4`. Podium supports 29 chart
types with editable data backed by embedded Excel workbooks -- your audience can
double-click any chart in PowerPoint and modify the underlying data.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/charts.exs` to generate a presentation with all the examples from this guide.

```elixir
alias Podium.Chart.ChartData

chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [12_500, 14_600, 15_200, 18_100])

slide = Podium.add_chart(slide, :column_clustered, chart_data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {9, :inches}, height: {5, :inches})
```

## The Chart Data Model

Every chart starts with a data structure that defines the categories and series.
Podium provides three data modules, each for a different family of chart types:

| Module | Used For | Categories |
|--------|----------|------------|
| `Podium.Chart.ChartData` | Column, bar, line, pie, area, doughnut, radar | Named categories (strings) |
| `Podium.Chart.XyChartData` | Scatter charts | Numeric X values per series |
| `Podium.Chart.BubbleChartData` | Bubble charts | Numeric X values + bubble sizes |

### ChartData

`Podium.Chart.ChartData` is the most common. You build it by adding categories
(shared across all series) and then adding one or more named series with numeric values.

```elixir
alias Podium.Chart.ChartData

data =
  ChartData.new()
  |> ChartData.add_categories(["Engineering", "Marketing", "Sales", "Support"])
  |> ChartData.add_series("Headcount", [230, 85, 120, 65], color: "4472C4")
  |> ChartData.add_series("Budget ($K)", [4200, 2100, 3500, 1800], color: "ED7D31")
```

Each series accepts these options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:color` | `String.t()` | `nil` | Hex RGB color for the series |
| `:pattern` | `keyword` | `nil` | Pattern fill (see [Series Formatting](#series-formatting)) |
| `:marker` | `keyword` | `nil` | Marker options for line/scatter charts |
| `:point_colors` | `map` | `%{}` | Per-point color overrides by index |
| `:point_formats` | `map` | `%{}` | Per-point fill/line overrides by index |
| `:data_labels` | `map` | `nil` | Per-point data label overrides by index |

A `ChartData` struct supports up to 25 series. All values must be numbers.

## Adding a Chart

Use `Podium.add_chart/4` to place a chart on a slide. The function takes the
slide, chart type atom, chart data, and a keyword list of options.
It returns the updated slide.

```elixir
slide = Podium.add_chart(slide, :bar_clustered, data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {12, :inches}, height: {5.5, :inches},
  title: "Department Overview",
  legend: :bottom)
```

![Column clustered chart with axis config and data labels](assets/core/charts/column-clustered.png)

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:x` | `emu_spec` | required | Horizontal position |
| `:y` | `emu_spec` | required | Vertical position |
| `:width` | `emu_spec` | required | Chart width |
| `:height` | `emu_spec` | required | Chart height |
| `:title` | `String.t()` or `keyword` | `nil` | Chart title |
| `:legend` | `atom` or `keyword` or `false` | `nil` | Legend configuration |
| `:data_labels` | `list` or `keyword` | `[]` | Data label configuration |
| `:category_axis` | `keyword` | `[]` | Category axis options |
| `:value_axis` | `keyword` | `[]` | Value axis options |

## Category Charts

Category charts use `ChartData` with string categories on one axis and numeric
values on the other. Here are the available types grouped by family.

### Column and Bar Charts

Column charts display vertical bars; bar charts display horizontal bars.

| Type | Description |
|------|-------------|
| `:column_clustered` | Side-by-side vertical bars |
| `:column_stacked` | Stacked vertical bars |
| `:column_stacked_100` | Stacked vertical bars normalized to 100% |
| `:bar_clustered` | Side-by-side horizontal bars |
| `:bar_stacked` | Stacked horizontal bars |
| `:bar_stacked_100` | Stacked horizontal bars normalized to 100% |

```elixir
# Stacked bar chart showing channel breakdown
channel_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Email", [250, 230, 210, 200, 185, 170], color: "4472C4")
  |> ChartData.add_series("Chat", [180, 200, 220, 250, 280, 310], color: "ED7D31")
  |> ChartData.add_series("Phone", [100, 95, 90, 85, 80, 75], color: "A5A5A5")

slide = Podium.add_chart(slide, :bar_stacked, channel_data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {12, :inches}, height: {5.5, :inches},
  title: "Support Tickets by Channel",
  legend: :right)
```

![Stacked bar chart showing channel breakdown](assets/core/charts/bar-stacked.png)

### Line Charts

| Type | Description |
|------|-------------|
| `:line` | Lines without markers |
| `:line_markers` | Lines with data point markers |
| `:line_stacked` | Stacked lines |
| `:line_markers_stacked` | Stacked lines with markers |
| `:line_stacked_100` | Stacked lines normalized to 100% |
| `:line_markers_stacked_100` | Stacked lines with markers, normalized to 100% |

```elixir
trend_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Web", [45, 48, 52, 55, 60, 63], color: "4472C4")
  |> ChartData.add_series("Mobile", [30, 35, 38, 42, 50, 55], color: "ED7D31")

slide = Podium.add_chart(slide, :line_markers, trend_data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {12, :inches}, height: {5.5, :inches},
  title: "Monthly Active Users",
  legend: :top,
  value_axis: [title: "Users (thousands)", major_gridlines: true])
```

![Line chart with markers showing monthly active users](assets/core/charts/line-markers.png)

### Pie and Doughnut Charts

Pie and doughnut charts show proportions. They do not have axes.

| Type | Description |
|------|-------------|
| `:pie` | Standard pie chart |
| `:pie_exploded` | Pie with slices pulled out (25% explosion) |
| `:doughnut` | Ring chart with 50% hole |
| `:doughnut_exploded` | Ring chart with slices pulled out |

```elixir
market_data =
  ChartData.new()
  |> ChartData.add_categories(["North America", "Europe", "Asia Pacific", "Latin America"])
  |> ChartData.add_series("Revenue", [42, 28, 18, 12],
    point_colors: %{0 => "2E75B6", 1 => "BDD7EE", 2 => "ED7D31", 3 => "FBE5D6"})

slide = Podium.add_chart(slide, :pie, market_data,
  x: {2, :inches}, y: {1, :inches},
  width: {9, :inches}, height: {5.5, :inches},
  title: "Revenue by Region",
  legend: :right,
  data_labels: [:category, :percent])
```

![Pie chart with per-point colors and category labels](assets/core/charts/pie-chart.png)

### Area Charts

| Type | Description |
|------|-------------|
| `:area` | Standard area chart |
| `:area_stacked` | Stacked area |
| `:area_stacked_100` | Stacked area normalized to 100% |

### Radar Charts

| Type | Description |
|------|-------------|
| `:radar` | Radar without markers |
| `:radar_markers` | Radar with data point markers |
| `:radar_filled` | Filled radar (spider chart) |

```elixir
skill_data =
  ChartData.new()
  |> ChartData.add_categories(["Speed", "Power", "Range", "Durability", "Precision"])
  |> ChartData.add_series("Model A", [80, 90, 70, 85, 75], color: "4472C4")
  |> ChartData.add_series("Model B", [70, 65, 95, 70, 90], color: "ED7D31")

slide = Podium.add_chart(slide, :radar_filled, skill_data,
  x: {2, :inches}, y: {1, :inches},
  width: {9, :inches}, height: {5.5, :inches},
  title: "Product Comparison",
  legend: :bottom)
```

![Filled radar chart comparing two models](assets/core/charts/radar-filled.png)

## Chart Titles

Pass a string for a plain title, or a keyword list for formatted titles.
Pass `nil` (the default) for no title.

```elixir
# Plain title
Podium.add_chart(slide, :column_clustered, data,
  x: {0.5, :inches}, y: {1, :inches}, width: {12, :inches}, height: {5, :inches},
  title: "Quarterly Revenue")

# Formatted title
Podium.add_chart(slide, :column_clustered, data,
  x: {0.5, :inches}, y: {1, :inches}, width: {12, :inches}, height: {5, :inches},
  title: [text: "Quarterly Revenue", font_size: 18, bold: true, color: "003366", font: "Arial"])
```

Title formatting options: `:text`, `:font_size`, `:bold`, `:italic`, `:color`, `:font`.

## Legends

Control legend visibility and position. Pass `false` or `nil` for no legend, an atom
for position only, or a keyword list for full formatting.

```elixir
# Position only
legend: :bottom

# Formatted legend
legend: [position: :bottom, font_size: 10, bold: true, font: "Arial", color: "333333"]
```

Legend positions: `:left`, `:right`, `:top`, `:bottom`.

## Data Labels

Data labels display values directly on chart elements. Pass a list of atoms to
control what information appears, or a keyword list for full configuration.

```elixir
# Show category names and percentages (common for pie charts)
data_labels: [:category, :percent]

# Show values with positioning and number format
data_labels: [show: [:value], position: :outside_end, number_format: "$#,##0"]
```

Available label content: `:value`, `:category`, `:series`, `:percent`.

| Position | Description |
|----------|-------------|
| `:center` | Centered on the data point |
| `:inside_end` | Inside the bar, near the end |
| `:inside_base` | Inside the bar, near the base |
| `:outside_end` | Outside the bar end |
| `:top` | Above the point |
| `:bottom` | Below the point |
| `:left` | Left of the point |
| `:right` | Right of the point |
| `:best_fit` | PowerPoint chooses the position |

## Category Axis

Customize the category (horizontal) axis with the `:category_axis` option.

```elixir
slide = Podium.add_chart(slide, :column_clustered, data,
  x: {0.5, :inches}, y: {1, :inches}, width: {12, :inches}, height: {5, :inches},
  category_axis: [
    title: "Quarter",
    label_rotation: -45,
    major_tick_mark: :cross,
    minor_tick_mark: :in
  ])
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:title` | `String.t()` or `keyword` | `nil` | Axis title (plain string or formatted) |
| `:label_rotation` | `number` | `nil` | Label rotation in degrees |
| `:reverse` | `boolean` | `false` | Reverse axis direction |
| `:visible` | `boolean` | `true` | Show or hide the axis |
| `:major_tick_mark` | `atom` | `nil` | `:out`, `:in`, `:cross`, or `:none` |
| `:minor_tick_mark` | `atom` | `nil` | `:out`, `:in`, `:cross`, or `:none` |
| `:crosses` | `atom` or `number` | `nil` | Where the value axis crosses: `:auto_zero`, `:min`, `:max`, or a number |
| `:type` | `:date` | `nil` | Set to `:date` for date axis mode |

Axis titles support the same formatting options as chart titles: `:text`, `:font_size`,
`:bold`, `:italic`, `:color`, `:font`.

```elixir
category_axis: [title: [text: "Quarter", font_size: 12, bold: true, color: "333333"]]
```

## Value Axis

Customize the value (numeric) axis with the `:value_axis` option.

```elixir
slide = Podium.add_chart(slide, :column_clustered, data,
  x: {0.5, :inches}, y: {1, :inches}, width: {12, :inches}, height: {5, :inches},
  value_axis: [
    title: "Amount ($)",
    number_format: "$#,##0",
    major_gridlines: true,
    min: 0,
    max: 20_000,
    major_unit: 5000
  ])
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:title` | `String.t()` or `keyword` | `nil` | Axis title |
| `:number_format` | `String.t()` | `nil` | Excel-style number format (e.g. `"$#,##0"`) |
| `:major_gridlines` | `boolean` | `true` | Show major gridlines |
| `:minor_gridlines` | `boolean` | `false` | Show minor gridlines |
| `:min` | `number` | `nil` | Minimum axis value |
| `:max` | `number` | `nil` | Maximum axis value |
| `:major_unit` | `number` | `nil` | Major unit step |
| `:minor_unit` | `number` | `nil` | Minor unit step |
| `:crosses` | `atom` or `number` | `nil` | Where the category axis crosses |
| `:label_rotation` | `number` | `nil` | Label rotation in degrees |
| `:reverse` | `boolean` | `false` | Reverse axis direction |
| `:visible` | `boolean` | `true` | Show or hide the axis |
| `:major_tick_mark` | `atom` | `nil` | `:out`, `:in`, `:cross`, or `:none` |
| `:minor_tick_mark` | `atom` | `nil` | `:out`, `:in`, `:cross`, or `:none` |

## Series Formatting

### Colors

Set a series color with the `:color` option on `ChartData.add_series/4`:

```elixir
ChartData.add_series(data, "Revenue", [100, 200, 300], color: "4472C4")
```

### Pattern Fills

Use pattern fills instead of solid colors:

```elixir
ChartData.add_series(data, "Email", [250, 230, 210],
  pattern: [type: :dn_diag, foreground: "4472C4", background: "FFFFFF"])
```

![Pattern fills and per-point formatting on columns](assets/core/charts/pattern-fills-per-point.png)

The `:type` must be one of the 54 pattern presets from `Podium.Pattern` (e.g.
`:dn_diag`, `:lt_horz`, `:dk_vert`, `:sm_grid`, `:cross`).

### Markers

For line and scatter charts, customize data point markers:

```elixir
ChartData.add_series(data, "Trend", [20, 35, 45, 50, 55, 70],
  color: "4472C4",
  marker: [style: :diamond, size: 10, fill: "4472C4", line: "002060"])
```

Marker styles: `:circle`, `:square`, `:diamond`, `:triangle`, `:star`, `:x`,
`:plus`, `:dash`, `:dot`, `:none`.

## Per-Point Formatting

Override the appearance of individual data points within a series.

### Point Colors

Color specific points by index:

```elixir
ChartData.add_series(data, "Revenue", [42, 28, 18, 35, 22],
  point_colors: %{0 => "2E75B6", 3 => "ED7D31"})
```

### Point Formats

Apply fill and line formatting to specific points:

```elixir
ChartData.add_series(data, "Revenue", [42, 28, 18, 35, 22],
  point_formats: %{
    0 => [fill: "2E75B6", line: [color: "001133", width: {2, :pt}]],
    3 => [fill: "ED7D31", line: [color: "7F3300", width: {2, :pt}]]
  })
```

### Per-Point Data Labels

Show data labels on specific points only:

```elixir
ChartData.add_series(data, "Revenue ($K)", [42, 28, 18, 35, 22],
  data_labels: %{
    0 => [show: [:value], position: :outside_end, number_format: "$#,##0K"],
    3 => [show: [:value, :category], position: :outside_end]
  })
```

## XY (Scatter) Charts

Scatter charts plot data as X/Y coordinate pairs. Use `Podium.Chart.XyChartData`
instead of `ChartData` -- there are no shared categories, each series provides its
own X and Y value lists.

```elixir
alias Podium.Chart.XyChartData

xy_data =
  XyChartData.new()
  |> XyChartData.add_series("Series A", [1, 2, 3, 4, 5], [2.3, 4.1, 3.7, 5.2, 4.8],
    color: "4472C4")
  |> XyChartData.add_series("Series B", [1, 2, 3, 4, 5], [1.5, 3.2, 2.8, 4.5, 3.9],
    color: "ED7D31")

slide = Podium.add_chart(slide, :scatter, xy_data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {12, :inches}, height: {5.5, :inches},
  title: "Scatter Analysis")
```

![Scatter chart with two series](assets/core/charts/scatter-chart.png)

| Type | Description |
|------|-------------|
| `:scatter` | Points only (no connecting lines) |
| `:scatter_lines` | Points connected with straight lines |
| `:scatter_lines_no_markers` | Straight lines, no point markers |
| `:scatter_smooth` | Points connected with smooth curves |
| `:scatter_smooth_no_markers` | Smooth curves, no point markers |

`XyChartData.add_series/5` takes the series name, X values list, Y values list, and
optional formatting options. The X and Y lists must have the same length, and all values
must be numbers.

## Bubble Charts

Bubble charts extend scatter charts with a third dimension: bubble size. Use
`Podium.Chart.BubbleChartData`.

```elixir
alias Podium.Chart.BubbleChartData

bubble_data =
  BubbleChartData.new()
  |> BubbleChartData.add_series("Region A",
    [1, 3, 5, 7], [10, 25, 15, 30], [5, 12, 8, 15],
    color: "4472C4")
  |> BubbleChartData.add_series("Region B",
    [2, 4, 6, 8], [20, 15, 30, 10], [10, 6, 14, 8],
    color: "ED7D31")

slide = Podium.add_chart(slide, :bubble, bubble_data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {12, :inches}, height: {5.5, :inches},
  title: "Market Opportunity Analysis")
```

![Bubble chart with sized data points](assets/core/charts/bubble-chart.png)

| Type | Description |
|------|-------------|
| `:bubble` | Standard bubble chart |
| `:bubble_3d` | Bubble chart with 3D effect |

`BubbleChartData.add_series/6` takes the series name, X values, Y values, bubble sizes,
and optional formatting options. All three lists must have the same length.

## Date Axes

When your categories represent dates, set the category axis type to `:date` to get
proper date-based spacing and formatting.

```elixir
date_data =
  ChartData.new()
  |> ChartData.add_categories(["2025-01", "2025-04", "2025-07", "2025-10", "2026-01"])
  |> ChartData.add_series("Sales", [120, 145, 190, 210, 250], color: "4472C4")

slide = Podium.add_chart(slide, :line_markers, date_data,
  x: {0.5, :inches}, y: {1, :inches},
  width: {12, :inches}, height: {5.5, :inches},
  title: "Quarterly Sales",
  category_axis: [
    type: :date,
    title: "Date",
    base_time_unit: :months,
    major_time_unit: :months,
    major_unit: 3
  ],
  value_axis: [title: "Sales ($K)", major_gridlines: true])
```

Date axis options:

| Option | Type | Description |
|--------|------|-------------|
| `:base_time_unit` | `:days`, `:months`, or `:years` | Base time unit for date axis |
| `:major_time_unit` | `:days`, `:months`, or `:years` | Major tick time unit |
| `:minor_time_unit` | `:days`, `:months`, or `:years` | Minor tick time unit |
| `:major_unit` | `number` | Number of time units between major ticks |
| `:minor_unit` | `number` | Number of time units between minor ticks |

## Chart Type Reference

All 29 chart types supported by Podium:

| Category | Type Atom | Data Module |
|----------|-----------|-------------|
| Column | `:column_clustered` | `ChartData` |
| Column | `:column_stacked` | `ChartData` |
| Column | `:column_stacked_100` | `ChartData` |
| Bar | `:bar_clustered` | `ChartData` |
| Bar | `:bar_stacked` | `ChartData` |
| Bar | `:bar_stacked_100` | `ChartData` |
| Line | `:line` | `ChartData` |
| Line | `:line_markers` | `ChartData` |
| Line | `:line_stacked` | `ChartData` |
| Line | `:line_markers_stacked` | `ChartData` |
| Line | `:line_stacked_100` | `ChartData` |
| Line | `:line_markers_stacked_100` | `ChartData` |
| Pie | `:pie` | `ChartData` |
| Pie | `:pie_exploded` | `ChartData` |
| Area | `:area` | `ChartData` |
| Area | `:area_stacked` | `ChartData` |
| Area | `:area_stacked_100` | `ChartData` |
| Doughnut | `:doughnut` | `ChartData` |
| Doughnut | `:doughnut_exploded` | `ChartData` |
| Radar | `:radar` | `ChartData` |
| Radar | `:radar_markers` | `ChartData` |
| Radar | `:radar_filled` | `ChartData` |
| Scatter | `:scatter` | `XyChartData` |
| Scatter | `:scatter_lines` | `XyChartData` |
| Scatter | `:scatter_lines_no_markers` | `XyChartData` |
| Scatter | `:scatter_smooth` | `XyChartData` |
| Scatter | `:scatter_smooth_no_markers` | `XyChartData` |
| Bubble | `:bubble` | `BubbleChartData` |
| Bubble | `:bubble_3d` | `BubbleChartData` |

For even more charting power, see [Combo Charts](combo-charts.md) to combine
multiple chart types in a single plot area.
