# Combo/Multi-Plot Charts Demo
# Demonstrates combining multiple chart types in a single plot area
# 16:9 slide = 13.33" x 7.5"

alias Podium.Chart.ChartData

prs = Podium.new(title: "Combo Charts Demo", author: "Podium")

# --- Slide 1: Column + Line combo (revenue bars + margin line) ---
{prs, slide1} = Podium.add_slide(prs, layout: :title_only)
slide1 = Podium.set_placeholder(slide1, :title, "Column + Line Combo")

data1 =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [1500, 4600, 5156, 3167])
  |> ChartData.add_series("Expenses", [1000, 2300, 2500, 3000])
  |> ChartData.add_series("Margin %", [33, 50, 52, 5])

{prs, slide1} =
  Podium.add_combo_chart(prs, slide1, data1,
    [
      {:column_clustered, series: [0, 1]},
      {:line_markers, series: [2]}
    ],
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12.33, :inches},
    height: {5.5, :inches},
    title: "Revenue & Expenses with Margin",
    legend: :bottom
  )

prs = Podium.put_slide(prs, slide1)

# --- Slide 2: Column + Line with secondary axis ---
{prs, slide2} = Podium.add_slide(prs, layout: :title_only)
slide2 = Podium.set_placeholder(slide2, :title, "Secondary Axis Demo")

data2 =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May", "Jun"])
  |> ChartData.add_series("Sales ($K)", [120, 150, 180, 200, 220, 250])
  |> ChartData.add_series("Units", [45, 52, 61, 68, 74, 82])

{prs, slide2} =
  Podium.add_combo_chart(prs, slide2, data2,
    [
      {:column_clustered, series: [0]},
      {:line_markers, series: [1], secondary_axis: true}
    ],
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12.33, :inches},
    height: {5.5, :inches},
    title: "Sales Revenue vs Units Sold",
    legend: :bottom,
    value_axis: [title: "Sales ($K)"],
    secondary_value_axis: [title: "Units Sold"]
  )

prs = Podium.put_slide(prs, slide2)

# --- Slide 3: Area + Line combo ---
{prs, slide3} = Podium.add_slide(prs, layout: :title_only)
slide3 = Podium.set_placeholder(slide3, :title, "Area + Line Combo")

data3 =
  ChartData.new()
  |> ChartData.add_categories(["2020", "2021", "2022", "2023", "2024"])
  |> ChartData.add_series("Total Users", [100, 250, 500, 800, 1200])
  |> ChartData.add_series("Active Users", [80, 200, 400, 700, 1100])
  |> ChartData.add_series("Growth Rate %", [0, 150, 100, 60, 50])

{prs, slide3} =
  Podium.add_combo_chart(prs, slide3, data3,
    [
      {:area, series: [0, 1]},
      {:line_markers, series: [2], secondary_axis: true}
    ],
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12.33, :inches},
    height: {5.5, :inches},
    title: "User Growth Trajectory",
    legend: :bottom,
    secondary_value_axis: [title: "Growth Rate %"]
  )

prs = Podium.put_slide(prs, slide3)

# --- Slide 4: Column Stacked + Line combo ---
{prs, slide4} = Podium.add_slide(prs, layout: :title_only)
slide4 = Podium.set_placeholder(slide4, :title, "Stacked Column + Line")

data4 =
  ChartData.new()
  |> ChartData.add_categories(["North", "South", "East", "West"])
  |> ChartData.add_series("Product A", [300, 400, 350, 280])
  |> ChartData.add_series("Product B", [200, 300, 250, 320])
  |> ChartData.add_series("Target", [550, 600, 500, 500])

{prs, slide4} =
  Podium.add_combo_chart(prs, slide4, data4,
    [
      {:column_stacked, series: [0, 1]},
      {:line_markers, series: [2]}
    ],
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12.33, :inches},
    height: {5.5, :inches},
    title: "Regional Sales vs Target",
    legend: :bottom
  )

prs = Podium.put_slide(prs, slide4)

Podium.save(prs, "combo_charts.pptx")
IO.puts("Saved combo_charts.pptx")
