File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Full-width title bar with centered text
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Percent-Based Layout", bold: true, font_size: 36, color: "FFFFFF"}]],
    x: {0, :percent},
    y: {40, :percent},
    width: {100, :percent},
    height: {20, :percent},
    fill: "003366",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box("Positioning elements as percentages of slide dimensions",
    x: {10, :percent},
    y: {65, :percent},
    width: {80, :percent},
    height: {10, :percent},
    alignment: :center,
    font_size: 18
  )

# Slide 2: Four quadrants using percent positioning
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Four Quadrants", bold: true, font_size: 28, color: "003366"}]],
    x: {5, :percent},
    y: {2, :percent},
    width: {90, :percent},
    height: {10, :percent},
    alignment: :center
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {5, :percent},
    y: {15, :percent},
    width: {43, :percent},
    height: {38, :percent},
    fill: "4472C4",
    text: [[{"Q1: Strategy", bold: true, color: "FFFFFF"}]]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {52, :percent},
    y: {15, :percent},
    width: {43, :percent},
    height: {38, :percent},
    fill: "ED7D31",
    text: [[{"Q2: Execution", bold: true, color: "FFFFFF"}]]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {5, :percent},
    y: {57, :percent},
    width: {43, :percent},
    height: {38, :percent},
    fill: "A5A5A5",
    text: [[{"Q3: Review", bold: true, color: "FFFFFF"}]]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {52, :percent},
    y: {57, :percent},
    width: {43, :percent},
    height: {38, :percent},
    fill: "70AD47",
    text: [[{"Q4: Planning", bold: true, color: "FFFFFF"}]]
  )

# Slide 3: Chart with percent layout — fills most of the slide
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May"])
  |> ChartData.add_series("Sales", [120, 180, 150, 220, 280], color: "4472C4")
  |> ChartData.add_series("Costs", [80, 100, 95, 130, 150], color: "ED7D31")

s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Monthly Performance", bold: true, font_size: 24, color: "003366"}]],
    x: {5, :percent},
    y: {2, :percent},
    width: {90, :percent},
    height: {10, :percent},
    alignment: :center
  )
  |> Podium.add_chart(:column_clustered, chart_data,
    x: {5, :percent},
    y: {15, :percent},
    width: {90, :percent},
    height: {80, :percent},
    title: "Sales vs Costs",
    legend: :bottom
  )

# Slide 4: Mixed units — percent for position, inches for size
s4 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Mixed Units", bold: true, font_size: 28, color: "003366"}]],
    x: {5, :percent},
    y: {2, :percent},
    width: {90, :percent},
    height: {10, :percent},
    alignment: :center
  )
  |> Podium.add_text_box("Percent X, fixed size",
    x: {10, :percent},
    y: {1.5, :inches},
    width: {3, :inches},
    height: {1, :inches},
    fill: "E2EFDA",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box("Starts at 50%",
    x: {50, :percent},
    y: {1.5, :inches},
    width: {3, :inches},
    height: {1, :inches},
    fill: "DAEEF3",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_connector(:straight,
    {10, :percent},
    {60, :percent},
    {90, :percent},
    {60, :percent},
    line: [color: "FF0000", width: {2, :pt}]
  )
  |> Podium.add_text_box("Connector above spans 10%–90% of slide width",
    x: {10, :percent},
    y: {62, :percent},
    width: {80, :percent},
    height: {8, :percent},
    alignment: :center,
    font_size: 14
  )
  |> Podium.add_table(
    [
      ["Region", "Q1", "Q2"],
      ["North", "120", "145"],
      ["South", "95", "110"]
    ],
    x: {10, :percent},
    y: {75, :percent},
    width: {80, :percent},
    height: {20, :percent}
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.save("demos/output/percent-layout.pptx")

IO.puts("Generated demos/output/percent-layout.pptx")
