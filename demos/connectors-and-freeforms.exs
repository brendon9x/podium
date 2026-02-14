File.mkdir_p!("demos/output")

alias Podium.Freeform

prs = Podium.new()

# Slide 1: Flowchart -- 3 shapes with straight, elbow, curved connectors
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Connectors", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {1, :inches},
    y: {2, :inches},
    width: {2, :inches},
    height: {1, :inches},
    text: "Planning",
    fill: "4472C4"
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {5.5, :inches},
    y: {2, :inches},
    width: {2, :inches},
    height: {1, :inches},
    text: "Execution",
    fill: "70AD47"
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {10, :inches},
    y: {2, :inches},
    width: {2, :inches},
    height: {1, :inches},
    text: "Review",
    fill: "ED7D31"
  )
  # Straight connector: Planning -> Execution
  |> Podium.add_connector(:straight, {3, :inches}, {2.5, :inches}, {5.5, :inches}, {2.5, :inches},
    line: [color: "000000", width: {1.5, :pt}]
  )
  # Elbow connector: Execution -> Review (going down then across)
  |> Podium.add_connector(:elbow, {7.5, :inches}, {2.5, :inches}, {10, :inches}, {2.5, :inches},
    line: [color: "FF0000", width: {2, :pt}, dash_style: :dash]
  )
  # Curved connector: Review back to Planning (feedback loop below)
  |> Podium.add_connector(:curved, {11, :inches}, {3, :inches}, {2, :inches}, {5, :inches},
    line: [color: "5B9BD5", width: {2, :pt}]
  )

# Slide 2: Freeform triangle + star
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Freeform Shapes", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )

# Triangle
triangle =
  Freeform.new({2, :inches}, {5, :inches})
  |> Freeform.line_to({4, :inches}, {1.5, :inches})
  |> Freeform.line_to({6, :inches}, {5, :inches})
  |> Freeform.close()

s2 = Podium.add_freeform(s2, triangle, fill: "4472C4", line: "002060")

# Star (5-pointed)
star =
  Freeform.new({9.67, :inches}, {1.5, :inches})
  |> Freeform.add_line_segments(
    [
      {{8.49, :inches}, {5.12, :inches}},
      {{11.57, :inches}, {2.88, :inches}},
      {{7.77, :inches}, {2.88, :inches}},
      {{10.85, :inches}, {5.12, :inches}}
    ],
    close: true
  )

s2 = Podium.add_freeform(s2, star, fill: "FFD700", line: "CC9900")

# Slide 3: Multi-contour freeform (square with cutout)
# Square with square cutout
cutout =
  Freeform.new({4.67, :inches}, {1.5, :inches})
  |> Freeform.add_line_segments([
    {{8.67, :inches}, {1.5, :inches}},
    {{8.67, :inches}, {5.5, :inches}},
    {{4.67, :inches}, {5.5, :inches}}
  ])
  |> Freeform.close()
  |> Freeform.move_to({5.67, :inches}, {2.5, :inches})
  |> Freeform.add_line_segments([
    {{7.67, :inches}, {2.5, :inches}},
    {{7.67, :inches}, {4.5, :inches}},
    {{5.67, :inches}, {4.5, :inches}}
  ])
  |> Freeform.close()

s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Multi-Contour Freeform", bold: true, font_size: 28, color: "003366"}],
       alignment: :center}
    ],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_freeform(cutout, fill: "70AD47")

prs =
  prs
  |> Podium.add_slide(s1)
  |> Podium.add_slide(s2)
  |> Podium.add_slide(s3)
  |> Podium.save("demos/output/connectors-and-freeforms.pptx")

IO.puts("Generated demos/output/connectors-and-freeforms.pptx")
