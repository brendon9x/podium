File.mkdir_p!("demos/output")

alias Podium.Chart.ChartData

prs = Podium.new()

# Slide 1: Basic percent positioning via style:
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"CSS Positioning", bold: true, font_size: 36, color: "FFFFFF"}]],
    style: "left: 0%; top: 40%; width: 100%; height: 20%",
    fill: "003366",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box(
    "Using style: strings for familiar CSS absolute positioning",
    style: "left: 10%; top: 65%; width: 80%; height: 10%",
    alignment: :center,
    font_size: 18
  )

# Slide 2: Four quadrants using style: strings
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Four Quadrants via style:", bold: true, font_size: 28, color: "003366"}]],
    style: "left: 5%; top: 2%; width: 90%; height: 10%",
    alignment: :center
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    style: "left: 5%; top: 15%; width: 43%; height: 38%",
    fill: "4472C4",
    text: [[{"Q1: Strategy", bold: true, color: "FFFFFF"}]]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    style: "left: 52%; top: 15%; width: 43%; height: 38%",
    fill: "ED7D31",
    text: [[{"Q2: Execution", bold: true, color: "FFFFFF"}]]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    style: "left: 5%; top: 57%; width: 43%; height: 38%",
    fill: "A5A5A5",
    text: [[{"Q3: Review", bold: true, color: "FFFFFF"}]]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    style: "left: 52%; top: 57%; width: 43%; height: 38%",
    fill: "70AD47",
    text: [[{"Q4: Planning", bold: true, color: "FFFFFF"}]]
  )

# Slide 3: Mixed units — inches + percent via style:
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Mixed Units in style:", bold: true, font_size: 28, color: "003366"}]],
    style: "left: 5%; top: 2%; width: 90%; height: 10%",
    alignment: :center
  )
  |> Podium.add_text_box("1 inch from left, 10% from top",
    style: "left: 1in; top: 10%; width: 4in; height: 1in",
    fill: "E2EFDA",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_text_box("50% from left, 2cm from top",
    style: "left: 50%; top: 2cm; width: 4in; height: 1in",
    fill: "DAEEF3",
    alignment: :center,
    anchor: :middle
  )
  |> Podium.add_table(
    [
      ["Region", "Q1", "Q2"],
      ["North", "120", "145"],
      ["South", "95", "110"]
    ],
    style: "left: 10%; top: 50%; width: 80%; height: 40%"
  )

# Slide 4: Side-by-side comparison — style: vs tuple opts (identical output)
s4 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"style: vs Tuples — Identical Output", bold: true, font_size: 24, color: "003366"}]],
    style: "left: 5%; top: 2%; width: 90%; height: 10%",
    alignment: :center
  )
  # Left side: using style:
  |> Podium.add_text_box(
    [[{"Via style:", bold: true, font_size: 14}]],
    style: "left: 5%; top: 15%; width: 43%; height: 8%",
    alignment: :center,
    fill: "4472C4",
    anchor: :middle
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    style: "left: 5%; top: 25%; width: 43%; height: 70%",
    fill: "D6E4F0",
    text: [[{"Positioned with:", bold: true}], [{"style: \"left: 5%; ...\"", font_size: 12}]]
  )
  # Right side: using tuples
  |> Podium.add_text_box(
    [[{"Via Tuples", bold: true, font_size: 14}]],
    x: {52, :percent},
    y: {15, :percent},
    width: {43, :percent},
    height: {8, :percent},
    alignment: :center,
    fill: "ED7D31",
    anchor: :middle
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {52, :percent},
    y: {25, :percent},
    width: {43, :percent},
    height: {70, :percent},
    fill: "FCE4D6",
    text: [[{"Positioned with:", bold: true}], [{"x: {52, :percent}, ...", font_size: 12}]]
  )

# Slide 5: Chart with style: positioning
chart_data =
  ChartData.new()
  |> ChartData.add_categories(["Jan", "Feb", "Mar", "Apr", "May"])
  |> ChartData.add_series("Sales", [120, 180, 150, 220, 280], color: "4472C4")
  |> ChartData.add_series("Costs", [80, 100, 95, 130, 150], color: "ED7D31")

s5 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [[{"Chart with style: Positioning", bold: true, font_size: 24, color: "003366"}]],
    style: "left: 5%; top: 2%; width: 90%; height: 10%",
    alignment: :center
  )
  |> Podium.add_chart(:column_clustered, chart_data,
    style: "left: 5%; top: 15%; width: 90%; height: 80%",
    title: "Monthly Performance",
    legend: :bottom
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.save("demos/output/css-positioning.pptx")

IO.puts("Generated demos/output/css-positioning.pptx")
