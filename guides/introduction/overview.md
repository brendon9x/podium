# Overview

Podium is an Elixir library for generating PowerPoint (.pptx) files from code, with fully editable charts backed by embedded Excel workbooks.

```elixir
prs = Podium.new()

slide =
  Podium.Slide.new()
  |> Podium.add_text_box("Hello from Podium!",
    x: {1, :inches}, y: {1, :inches},
    width: {8, :inches}, height: {1, :inches},
    font_size: 24)

prs
|> Podium.add_slide(slide)
|> Podium.save("hello.pptx")
```

## What Podium Does

Podium creates well-formed OOXML presentations from scratch. You build slides programmatically -- adding text, charts, tables, images, and shapes -- then save to a `.pptx` file or an in-memory binary for streaming.

Charts embed real Excel workbooks, so recipients can double-click any chart in PowerPoint to edit the underlying data. No templates to manage, no COM interop, no external services.

## Key Differentiators

- **Editable charts** -- 29 chart types with embedded Excel data that recipients can modify directly in PowerPoint
- **Functional API with pipes** -- chain operations naturally with Elixir's pipe operator
- **Create-only design** -- focused on generating presentations, not reading or modifying existing files
- **Combo chart creation** -- build multi-plot charts programmatically, including multi-plot combo charts with secondary axes
- **Rich table formatting** -- per-cell borders, padding, merging, and gradient/pattern fills

## Who It's For

Podium is built for backend teams generating reports, dashboards, and slide decks programmatically. Common use cases include:

- Automated weekly/monthly business reports
- Data pipeline outputs delivered as presentations
- Phoenix applications that stream `.pptx` downloads to users
- Replacing manual slide creation with code-driven generation

## A Taste of What You Can Build

```elixir
alias Podium.Chart.ChartData

prs = Podium.new()

# Add a styled text box
slide =
  Podium.Slide.new()
  |> Podium.add_text_box([
    {[{"Quarterly Report", bold: true, font_size: 36, color: "003366"}], alignment: :center}
  ], x: {1, :inches}, y: {0.5, :inches}, width: {10, :inches}, height: {1, :inches})

# Add an editable chart
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167], color: "4472C4")
  |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000], color: "ED7D31")

slide = Podium.add_chart(slide, :column_clustered, chart_data,
  x: {1, :inches}, y: {2, :inches}, width: {10, :inches}, height: {4.5, :inches},
  title: "Revenue vs Expenses",
  legend: :bottom,
  data_labels: [:value])

prs
|> Podium.add_slide(slide)
|> Podium.save("report.pptx")
```

## Where to Go from Here

- **[Getting Started](getting-started.md)** -- hands-on tutorial building a complete presentation step by step
- **API Reference** -- `Podium` module documentation with all public functions

Ready to get started? Head to [Installation](installation.md).
