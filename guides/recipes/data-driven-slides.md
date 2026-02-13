# Data-Driven Slides

Generate presentations dynamically from data sources -- databases, APIs, CSV files,
or any Elixir data structure. This guide covers patterns for building slides
programmatically from lists, maps, and query results.

```elixir
departments = [
  %{name: "Engineering", headcount: 230, budget: 4200, satisfaction: 92},
  %{name: "Marketing", headcount: 85, budget: 2100, satisfaction: 87},
  %{name: "Sales", headcount: 120, budget: 3500, satisfaction: 84}
]

prs = Podium.new(title: "Department Review")

{prs, _slides} =
  Enum.reduce(departments, {prs, []}, fn dept, {prs, slides} ->
    {prs, slide} = Podium.add_slide(prs, layout: :title_content)
    slide = Podium.set_placeholder(slide, :title, dept.name)
    slide = Podium.set_placeholder(slide, :content, [
      ["Headcount: #{dept.headcount}"],
      ["Budget: $#{dept.budget}K"],
      ["Satisfaction: #{dept.satisfaction}%"]
    ])
    prs = Podium.put_slide(prs, slide)
    {prs, slides ++ [slide]}
  end)

Podium.save(prs, "departments.pptx")
```

## Generating Chart Data from Query Results

When your data comes from a database, transform the query results into
`ChartData` structs. Here is a pattern using Ecto results.

```elixir
alias Podium.Chart.ChartData

# Imagine these results from an Ecto query:
# Repo.all(from r in Revenue, select: {r.quarter, r.amount, r.expenses})
results = [
  %{quarter: "Q1", revenue: 12_500, expenses: 10_000},
  %{quarter: "Q2", revenue: 14_600, expenses: 11_300},
  %{quarter: "Q3", revenue: 15_200, expenses: 12_500},
  %{quarter: "Q4", revenue: 18_100, expenses: 13_000}
]

categories = Enum.map(results, & &1.quarter)
revenue_values = Enum.map(results, & &1.revenue)
expense_values = Enum.map(results, & &1.expenses)

chart_data =
  ChartData.new()
  |> ChartData.add_categories(categories)
  |> ChartData.add_series("Revenue", revenue_values, color: "4472C4")
  |> ChartData.add_series("Expenses", expense_values, color: "ED7D31")
```

### Extracting a Helper

When you build chart data from query results repeatedly, extract a helper:

```elixir
defmodule ReportHelpers do
  alias Podium.Chart.ChartData

  def chart_data_from_rows(rows, category_key, series_defs) do
    categories = Enum.map(rows, &Map.fetch!(&1, category_key))

    Enum.reduce(series_defs, ChartData.new() |> ChartData.add_categories(categories),
      fn {name, key, opts}, data ->
        values = Enum.map(rows, &Map.fetch!(&1, key))
        ChartData.add_series(data, name, values, opts)
      end)
  end
end
```

Usage:

```elixir
chart_data = ReportHelpers.chart_data_from_rows(results, :quarter, [
  {"Revenue", :revenue, color: "4472C4"},
  {"Expenses", :expenses, color: "ED7D31"}
])
```

## One Slide Per Department

A common pattern: iterate over a collection and create a slide for each item.

```elixir
alias Podium.Chart.ChartData

regions = [
  %{name: "North America", quarters: [12_500, 14_600, 15_200, 18_100]},
  %{name: "Europe", quarters: [8_200, 9_100, 9_800, 10_500]},
  %{name: "Asia Pacific", quarters: [5_100, 6_300, 7_200, 8_800]}
]

prs = Podium.new(title: "Regional Revenue Report")

prs =
  Enum.reduce(regions, prs, fn region, prs ->
    {prs, slide} = Podium.add_slide(prs, layout: :title_only)
    slide = Podium.set_placeholder(slide, :title, region.name)

    chart_data =
      ChartData.new()
      |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
      |> ChartData.add_series("Revenue", region.quarters, color: "4472C4")

    {prs, slide} = Podium.add_chart(prs, slide, :column_clustered, chart_data,
      x: {0.5, :inches}, y: {1.5, :inches},
      width: {12, :inches}, height: {5.5, :inches},
      title: "#{region.name} Revenue",
      value_axis: [number_format: "$#,##0", major_gridlines: true])

    Podium.put_slide(prs, slide)
  end)

Podium.save(prs, "regional_report.pptx")
```

## Dynamic Tables from Lists of Maps

Transform a list of maps into a table with headers derived from the map keys.

```elixir
defmodule TableHelpers do
  def table_from_maps(maps, columns) do
    headers = Enum.map(columns, fn {label, _key} -> label end)
    rows = Enum.map(maps, fn map ->
      Enum.map(columns, fn {_label, key} -> to_string(Map.get(map, key, "")) end)
    end)
    [headers | rows]
  end
end
```

Usage:

```elixir
employees = [
  %{name: "Alice Chen", department: "Engineering", tenure: 5},
  %{name: "Bob Martinez", department: "Marketing", tenure: 3},
  %{name: "Carol Park", department: "Sales", tenure: 7}
]

columns = [{"Name", :name}, {"Department", :department}, {"Tenure (yrs)", :tenure}]
rows = TableHelpers.table_from_maps(employees, columns)

slide = Podium.add_table(slide, rows,
  x: {1, :inches}, y: {1.5, :inches},
  width: {11, :inches}, height: {3, :inches},
  table_style: [first_row: true])
```

## Streaming Downloads from Phoenix

Use `Podium.save_to_memory/1` to generate the .pptx binary and send it
directly from a Phoenix controller.

```elixir
defmodule MyAppWeb.ReportController do
  use MyAppWeb, :controller

  alias Podium.Chart.ChartData

  def download(conn, %{"id" => report_id}) do
    data = MyApp.Reports.get_data(report_id)
    prs = build_presentation(data)
    {:ok, binary} = Podium.save_to_memory(prs)

    conn
    |> put_resp_content_type("application/vnd.openxmlformats-officedocument.presentationml.presentation")
    |> put_resp_header("content-disposition", ~s(attachment; filename="report_#{report_id}.pptx"))
    |> send_resp(200, binary)
  end

  defp build_presentation(data) do
    prs = Podium.new(title: data.title, author: data.author)

    # Title slide
    {prs, slide} = Podium.add_slide(prs, layout: :title_slide)
    slide = Podium.set_placeholder(slide, :title, data.title)
    slide = Podium.set_placeholder(slide, :subtitle, data.subtitle)
    prs = Podium.put_slide(prs, slide)

    # Data slides
    Enum.reduce(data.sections, prs, fn section, prs ->
      add_section_slide(prs, section)
    end)
  end

  defp add_section_slide(prs, section) do
    {prs, slide} = Podium.add_slide(prs, layout: :title_only)
    slide = Podium.set_placeholder(slide, :title, section.heading)

    chart_data =
      ChartData.new()
      |> ChartData.add_categories(section.categories)
      |> ChartData.add_series(section.series_name, section.values, color: "4472C4")

    {prs, slide} = Podium.add_chart(prs, slide, :column_clustered, chart_data,
      x: {0.5, :inches}, y: {1.5, :inches},
      width: {12, :inches}, height: {5.5, :inches},
      title: section.chart_title,
      legend: :bottom)

    Podium.put_slide(prs, slide)
  end
end
```

## Consistent Slide Creation with Helpers

When generating many slides with the same structure, extract the pattern into
a helper function.

```elixir
defmodule SlideBuilder do
  alias Podium.Chart.ChartData

  def add_chart_slide(prs, title, categories, series_list, opts \\ []) do
    chart_type = Keyword.get(opts, :chart_type, :column_clustered)

    {prs, slide} = Podium.add_slide(prs, layout: :title_only)
    slide = Podium.set_placeholder(slide, :title, title)

    chart_data =
      Enum.reduce(series_list, ChartData.new() |> ChartData.add_categories(categories),
        fn {name, values, series_opts}, data ->
          ChartData.add_series(data, name, values, series_opts)
        end)

    {prs, slide} = Podium.add_chart(prs, slide, chart_type, chart_data,
      x: {0.5, :inches}, y: {1.5, :inches},
      width: {12, :inches}, height: {5.5, :inches},
      title: title,
      legend: :bottom,
      value_axis: Keyword.get(opts, :value_axis, [major_gridlines: true]))

    Podium.put_slide(prs, slide)
  end

  def add_table_slide(prs, title, rows, opts \\ []) do
    {prs, slide} = Podium.add_slide(prs, layout: :title_only)
    slide = Podium.set_placeholder(slide, :title, title)

    slide = Podium.add_table(slide, rows,
      x: {0.5, :inches}, y: {1.5, :inches},
      width: {12, :inches}, height: Keyword.get(opts, :height, {5, :inches}),
      table_style: Keyword.get(opts, :table_style, [first_row: true]))

    Podium.put_slide(prs, slide)
  end
end
```

Usage:

```elixir
prs = Podium.new(title: "Monthly Report")

prs = SlideBuilder.add_chart_slide(prs, "Revenue by Quarter",
  ["Q1", "Q2", "Q3", "Q4"],
  [{"Revenue", [12_500, 14_600, 15_200, 18_100], color: "4472C4"},
   {"Expenses", [10_000, 11_300, 12_500, 13_000], color: "ED7D31"}],
  value_axis: [number_format: "$#,##0", major_gridlines: true])

prs = SlideBuilder.add_table_slide(prs, "Team Summary",
  [["Name", "Role", "Status"],
   ["Alice", "Lead", "Active"],
   ["Bob", "Developer", "Active"]])

Podium.save(prs, "monthly_report.pptx")
```

For more patterns on building complete multi-slide reports, see
[Building a Report](building-a-report.md). For consistent visual styling across
data-driven presentations, see [Styling Patterns](styling-patterns.md).
