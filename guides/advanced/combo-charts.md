# Combo Charts

Combine multiple chart types in a single plot area with `Podium.add_combo_chart/4`.
A combo chart can show revenue as columns and a trend line overlaid on the same axes,
each using different series from the same data set.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/combo-charts.exs` to generate a presentation with all the examples from this guide.

```elixir
alias Podium.Chart.ChartData

data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [1500, 4600, 5200, 3200], color: "4472C4")
  |> ChartData.add_series("Trend", [2000, 3000, 4000, 5000], color: "ED7D31")

slide =
  Podium.add_combo_chart(slide, data, [
    {:column_clustered, series: [0]},
    {:line_markers, series: [1]}
  ], x: {0.5, :inches}, y: {1, :inches},
     width: {12, :inches}, height: {5.5, :inches},
     title: "Revenue with Trend Line",
     legend: :bottom)
```

![Column and line overlay combo chart](assets/advanced/combo-charts/column-line-overlay.png)

## The add_combo_chart API

```elixir
Podium.add_combo_chart(slide, chart_data, plots, opts)
```

- `chart_data` -- a `%ChartData{}` struct with shared categories and all series
- `plots` -- a list of plot spec tuples (at least 2)
- `opts` -- position, size, and chart-level options (same as `add_chart/4`, plus `:secondary_value_axis`)

Returns `slide`.

## Plot Specifications

Each plot spec is a tuple of `{chart_type, options}`:

```elixir
{:column_clustered, series: [0, 1]}
{:line_markers, series: [2], secondary_axis: true}
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:series` | `[integer]` | required | Zero-based indices into the chart data series list |
| `:secondary_axis` | `boolean` | `false` | Plot this group against a secondary value axis |

## Allowed Chart Types

These chart types can be used in combo charts:

| Family | Types |
|--------|-------|
| Column | `:column_clustered`, `:column_stacked`, `:column_stacked_100` |
| Bar | `:bar_clustered`, `:bar_stacked`, `:bar_stacked_100` |
| Line | `:line`, `:line_markers`, `:line_stacked`, `:line_markers_stacked`, `:line_stacked_100`, `:line_markers_stacked_100` |
| Area | `:area`, `:area_stacked`, `:area_stacked_100` |

Pie, doughnut, radar, scatter, and bubble chart types cannot be used in combo charts.

## Secondary Value Axis

When a plot spec sets `secondary_axis: true`, those series are plotted against a
secondary Y-axis on the right side of the chart. Configure it with
`:secondary_value_axis`.

```elixir
alias Podium.Chart.ChartData

data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Sales ($K)", [120, 150, 180, 200, 220, 250])
  |> ChartData.add_series("Units", [45, 52, 61, 68, 74, 82])

slide =
  Podium.add_combo_chart(slide, data, [
    {:column_clustered, series: [0]},
    {:line_markers, series: [1], secondary_axis: true}
  ], x: {0.5, :inches}, y: {1, :inches},
     width: {12, :inches}, height: {5.5, :inches},
     title: "Sales Revenue vs Units Sold",
     legend: :bottom,
     value_axis: [title: "Sales ($K)"],
     secondary_value_axis: [title: "Units Sold"])
```

The `:secondary_value_axis` option accepts the same configuration as `:value_axis`
(`:title`, `:number_format`, `:min`, `:max`, `:major_unit`, `:major_gridlines`, etc.).

## More Examples

### Stacked Column + Line

```elixir
data =
  ChartData.new()
  |> ChartData.add_categories(["North", "South", "East", "West"])
  |> ChartData.add_series("Product A", [300, 400, 350, 280])
  |> ChartData.add_series("Product B", [200, 300, 250, 320])
  |> ChartData.add_series("Target", [550, 600, 500, 500])

slide =
  Podium.add_combo_chart(slide, data, [
    {:column_stacked, series: [0, 1]},
    {:line_markers, series: [2]}
  ], x: {0.5, :inches}, y: {1, :inches},
     width: {12, :inches}, height: {5.5, :inches},
     title: "Regional Sales vs Target",
     legend: :bottom)
```

![Stacked column with line overlay](assets/advanced/combo-charts/stacked-column-line.png)

### Area + Line with Secondary Axis

```elixir
data =
  ChartData.new()
  |> ChartData.add_categories(["2020", "2021", "2022", "2023", "2024"])
  |> ChartData.add_series("Total Users", [100, 250, 500, 800, 1200])
  |> ChartData.add_series("Active Users", [80, 200, 400, 700, 1100])
  |> ChartData.add_series("Growth Rate %", [0, 150, 100, 60, 50])

slide =
  Podium.add_combo_chart(slide, data, [
    {:area, series: [0, 1]},
    {:line_markers, series: [2], secondary_axis: true}
  ], x: {0.5, :inches}, y: {1, :inches},
     width: {12, :inches}, height: {5.5, :inches},
     title: "User Growth Trajectory",
     legend: :bottom,
     secondary_value_axis: [title: "Growth Rate %"])
```

![Area chart with line on secondary axis](assets/advanced/combo-charts/area-line-secondary-axis.png)

## Constraints

Podium validates combo chart configurations and raises `ArgumentError` for
invalid setups:

- **Minimum 2 plots** -- a combo chart must have at least 2 plot specs.
- **No overlapping series** -- each series index can appear in only one plot.
- **No mixing bar and column** -- you cannot combine horizontal bar types with
  vertical column types in the same combo chart.
- **Series indices must be valid** -- indices must be within the range of series
  defined in the chart data.

All chart-level options from `Podium.add_chart/4` work with combo charts: `:title`,
`:legend`, `:data_labels`, `:category_axis`, and `:value_axis`. See the
[Charts](charts.md) guide for full details on those options.
