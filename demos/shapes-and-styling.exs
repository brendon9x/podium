File.mkdir_p!("demos/output")

prs = Podium.new()

# Slide 1: Shape gallery -- rectangle, oval, diamond, arrows, stars
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Shape Gallery", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_auto_shape(:rectangle,
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {2, :inches},
    height: {1.5, :inches},
    fill: "4472C4",
    text: "Rectangle"
  )
  |> Podium.add_auto_shape(:oval,
    x: {3, :inches},
    y: {1.5, :inches},
    width: {2, :inches},
    height: {1.5, :inches},
    fill: "ED7D31",
    text: "Oval"
  )
  |> Podium.add_auto_shape(:diamond,
    x: {5.5, :inches},
    y: {1.5, :inches},
    width: {2, :inches},
    height: {1.5, :inches},
    fill: "70AD47",
    text: "Diamond"
  )
  |> Podium.add_auto_shape(:right_arrow,
    x: {8, :inches},
    y: {1.5, :inches},
    width: {2.5, :inches},
    height: {1.5, :inches},
    fill: "FFC000",
    text: "Arrow"
  )
  |> Podium.add_auto_shape(:star_5_point,
    x: {11, :inches},
    y: {1.5, :inches},
    width: {1.8, :inches},
    height: {1.8, :inches},
    fill: "FF6347"
  )
  |> Podium.add_auto_shape(:hexagon,
    x: {0.5, :inches},
    y: {4, :inches},
    width: {2, :inches},
    height: {2, :inches},
    fill: "5B9BD5"
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {3, :inches},
    y: {4, :inches},
    width: {2.5, :inches},
    height: {1.5, :inches},
    fill: "9B59B6",
    text: "Rounded"
  )
  |> Podium.add_auto_shape(:chevron,
    x: {6, :inches},
    y: {4, :inches},
    width: {2.5, :inches},
    height: {1.5, :inches},
    fill: "E74C3C"
  )
  |> Podium.add_auto_shape(:flowchart_decision,
    x: {9, :inches},
    y: {4, :inches},
    width: {2, :inches},
    height: {2, :inches},
    fill: "1ABC9C",
    text: "Decision"
  )

# Slide 2: Fill showcase -- solid, gradient, pattern fills side-by-side
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Fill Types", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {3.5, :inches},
    height: {2.5, :inches},
    fill: "4472C4",
    text: [{[{"Solid Fill", bold: true, color: "FFFFFF", font_size: 18}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {4.5, :inches},
    y: {1.5, :inches},
    width: {3.5, :inches},
    height: {2.5, :inches},
    fill: {:gradient, [{0, "003366"}, {100_000, "66CCFF"}], angle: 5_400_000},
    text: [{[{"Gradient Fill", bold: true, color: "FFFFFF", font_size: 18}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {8.5, :inches},
    y: {1.5, :inches},
    width: {3.5, :inches},
    height: {2.5, :inches},
    fill: {:pattern, :dn_diag, foreground: "4472C4", background: "FFFFFF"},
    text: [{[{"Pattern Fill", bold: true, color: "003366", font_size: 18}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:rectangle,
    x: {0.5, :inches},
    y: {4.5, :inches},
    width: {3.5, :inches},
    height: {2, :inches},
    fill: "FF6347",
    text: [{[{"Tomato Solid", color: "FFFFFF", font_size: 14}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:rectangle,
    x: {4.5, :inches},
    y: {4.5, :inches},
    width: {3.5, :inches},
    height: {2, :inches},
    fill: {:gradient, [{0, "FFD700"}, {50_000, "FF6347"}, {100_000, "8B0000"}], angle: 0},
    text: [
      {[{"Multi-Stop Gradient", bold: true, color: "FFFFFF", font_size: 14}], alignment: :center}
    ]
  )
  |> Podium.add_auto_shape(:rectangle,
    x: {8.5, :inches},
    y: {4.5, :inches},
    width: {3.5, :inches},
    height: {2, :inches},
    fill: {:pattern, :lt_horz, foreground: "ED7D31", background: "FFFFFF"},
    text: [
      {[{"Horizontal Lines", bold: true, color: "003366", font_size: 14}], alignment: :center}
    ]
  )

# Slide 3: Line styles -- solid, dashed, gradient line on different shapes
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Line Styles", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_auto_shape(:rectangle,
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {3.5, :inches},
    height: {2, :inches},
    line: [color: "003366", width: {2, :pt}],
    text: [{[{"Solid Line", font_size: 14}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:oval,
    x: {4.5, :inches},
    y: {1.5, :inches},
    width: {3.5, :inches},
    height: {2, :inches},
    line: [color: "FF0000", width: {2, :pt}, dash_style: :dash],
    text: [{[{"Dashed Line", font_size: 14}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {8.5, :inches},
    y: {1.5, :inches},
    width: {3.5, :inches},
    height: {2, :inches},
    line: [
      fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000},
      width: {3, :pt}
    ],
    text: [{[{"Gradient Line", font_size: 14}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:diamond,
    x: {0.5, :inches},
    y: {4.2, :inches},
    width: {3.5, :inches},
    height: {2.5, :inches},
    line: [color: "70AD47", width: {1.5, :pt}, dash_style: :dot],
    text: [{[{"Dotted Line", font_size: 14}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:hexagon,
    x: {4.5, :inches},
    y: {4.2, :inches},
    width: {3.5, :inches},
    height: {2.5, :inches},
    line: [color: "9B59B6", width: {3, :pt}, dash_style: :long_dash],
    text: [{[{"Long Dash", font_size: 14}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:star_5_point,
    x: {9, :inches},
    y: {4.2, :inches},
    width: {2.5, :inches},
    height: {2.5, :inches},
    fill: "FFC000",
    line: [color: "CC9900", width: {2, :pt}, dash_style: :dash_dot]
  )

# Slide 4: Shape with rich text inside + rotation
s4 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Text in Shapes & Rotation", bold: true, font_size: 28, color: "003366"}],
       alignment: :center}
    ],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {1, :inches},
    y: {1.5, :inches},
    width: {4, :inches},
    height: {2, :inches},
    fill: "003366",
    text: [
      {[
         {"Revenue: ", color: "FFFFFF"},
         {"$4.2M", bold: true, color: "00FF00"}
       ], alignment: :center}
    ]
  )
  |> Podium.add_auto_shape(:cross,
    x: {7, :inches},
    y: {1.5, :inches},
    width: {2.5, :inches},
    height: {2.5, :inches},
    fill: "ED7D31",
    rotation: 45
  )
  |> Podium.add_auto_shape(:rectangle,
    x: {10, :inches},
    y: {1.5, :inches},
    width: {2, :inches},
    height: {2, :inches},
    fill: "70AD47",
    rotation: 15,
    text: [{[{"Tilted", bold: true, color: "FFFFFF"}], alignment: :center}]
  )
  |> Podium.add_auto_shape(:oval,
    x: {1, :inches},
    y: {4.5, :inches},
    width: {5, :inches},
    height: {2.5, :inches},
    fill: {:gradient, [{0, "4472C4"}, {100_000, "002060"}], angle: 5_400_000},
    text: [
      {[{"Oval with Gradient", bold: true, font_size: 20, color: "FFFFFF"}], alignment: :center},
      {[{"Multiple lines of rich text", italic: true, color: "BDD7EE"}], alignment: :center}
    ]
  )
  |> Podium.add_auto_shape(:star_5_point,
    x: {8, :inches},
    y: {4, :inches},
    width: {3, :inches},
    height: {3, :inches},
    fill: "FFD700",
    rotation: 20,
    line: [color: "CC9900", width: {2, :pt}]
  )

prs =
  prs
  |> Podium.add_slide(s1)
  |> Podium.add_slide(s2)
  |> Podium.add_slide(s3)
  |> Podium.add_slide(s4)
  |> Podium.save("demos/output/shapes-and-styling.pptx")

IO.puts("Generated demos/output/shapes-and-styling.pptx")
