File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Column + line overlay (Revenue with Trend)
data =
  ChartData.new()
  |> ChartData.add_categories(["Q1", "Q2", "Q3", "Q4"])
  |> ChartData.add_series("Revenue", [1500, 4600, 5200, 3200], color: "4472C4")
  |> ChartData.add_series("Trend", [2000, 3000, 4000, 5000], color: "ED7D31")

s1 =
  Podium.Slide.new()
  |> Podium.add_combo_chart(
    data,
    [
      {:column_clustered, series: [0]},
      {:line_markers, series: [1]}
    ],
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Revenue with Trend Line",
    legend: :bottom
  )

# Slide 2: Stacked column + line
data2 =
  ChartData.new()
  |> ChartData.add_categories(["North", "South", "East", "West"])
  |> ChartData.add_series("Product A", [300, 400, 350, 280], color: "4472C4")
  |> ChartData.add_series("Product B", [200, 300, 250, 320], color: "ED7D31")
  |> ChartData.add_series("Target", [550, 600, 500, 500], color: "70AD47")

s2 =
  Podium.Slide.new()
  |> Podium.add_combo_chart(
    data2,
    [
      {:column_stacked, series: [0, 1]},
      {:line_markers, series: [2]}
    ],
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "Regional Sales vs Target",
    legend: :bottom
  )

# Slide 3: Area + line with secondary Y-axis
data3 =
  ChartData.new()
  |> ChartData.add_categories(["2020", "2021", "2022", "2023", "2024"])
  |> ChartData.add_series("Total Users", [100, 250, 500, 800, 1200], color: "4472C4")
  |> ChartData.add_series("Active Users", [80, 200, 400, 700, 1100], color: "BDD7EE")
  |> ChartData.add_series("Growth Rate %", [0, 150, 100, 60, 50], color: "ED7D31")

s3 =
  Podium.Slide.new()
  |> Podium.add_combo_chart(
    data3,
    [
      {:area, series: [0, 1]},
      {:line_markers, series: [2], secondary_axis: true}
    ],
    x: {0.5, :inches},
    y: {0.5, :inches},
    width: {12, :inches},
    height: {6, :inches},
    title: "User Growth Trajectory",
    legend: :bottom,
    secondary_value_axis: [title: "Growth Rate %"]
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.save("demos/output/combo-charts.pptx")

IO.puts("Generated demos/output/combo-charts.pptx")
