# Shapes and Connectors Demo
# Demonstrates auto shapes, connectors, and text auto-size features.

prs = Podium.new()

# ── Slide 1: Auto Shapes Gallery ──────────────────────────────────────────────

{prs, slide} = Podium.add_slide(prs, layout: :title_only)
slide = Podium.set_placeholder(slide, :title, "Auto Shapes Gallery")

# Row 1
slide =
  slide
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {0.5, :inches},
    y: {1.8, :inches},
    width: {2, :inches},
    height: {1, :inches},
    text: "Rounded Rect",
    fill: "4472C4"
  )
  |> Podium.add_auto_shape(:oval,
    x: {3, :inches},
    y: {1.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    text: "Oval",
    fill: "ED7D31"
  )
  |> Podium.add_auto_shape(:diamond,
    x: {5, :inches},
    y: {1.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    text: "Diamond",
    fill: "A5A5A5"
  )
  |> Podium.add_auto_shape(:right_arrow,
    x: {7, :inches},
    y: {1.8, :inches},
    width: {2.5, :inches},
    height: {1, :inches},
    text: "Arrow",
    fill: "FFC000"
  )
  |> Podium.add_auto_shape(:star_5_point,
    x: {10, :inches},
    y: {1.5, :inches},
    width: {1.8, :inches},
    height: {1.8, :inches},
    fill: "5B9BD5"
  )

# Row 2
slide =
  slide
  |> Podium.add_auto_shape(:flowchart_process,
    x: {0.5, :inches},
    y: {3.8, :inches},
    width: {2, :inches},
    height: {1, :inches},
    text: "Process",
    fill: "70AD47"
  )
  |> Podium.add_auto_shape(:flowchart_decision,
    x: {3, :inches},
    y: {3.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    text: "Decision",
    fill: "FF6384"
  )
  |> Podium.add_auto_shape(:heart,
    x: {5, :inches},
    y: {3.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    fill: "FF0000"
  )
  |> Podium.add_auto_shape(:chevron,
    x: {7, :inches},
    y: {3.8, :inches},
    width: {2, :inches},
    height: {1, :inches},
    text: "Chevron",
    fill: "9B59B6"
  )
  |> Podium.add_auto_shape(:hexagon,
    x: {10, :inches},
    y: {3.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    text: "Hex",
    fill: "1ABC9C",
    line: [color: "117864", width: {2, :pt}]
  )

# Row 3 — shapes without fill (theme-styled)
slide =
  slide
  |> Podium.add_auto_shape(:isosceles_triangle,
    x: {0.5, :inches},
    y: {5.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches}
  )
  |> Podium.add_auto_shape(:lightning_bolt,
    x: {2.5, :inches},
    y: {5.8, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches}
  )
  |> Podium.add_auto_shape(:cloud,
    x: {4.5, :inches},
    y: {5.8, :inches},
    width: {2, :inches},
    height: {1.2, :inches}
  )
  |> Podium.add_auto_shape(:can,
    x: {7, :inches},
    y: {5.8, :inches},
    width: {1.2, :inches},
    height: {1.5, :inches}
  )
  |> Podium.add_auto_shape(:cross,
    x: {9, :inches},
    y: {5.8, :inches},
    width: {1.2, :inches},
    height: {1.2, :inches},
    rotation: 45
  )

prs = Podium.put_slide(prs, slide)

# ── Slide 2: Connectors ──────────────────────────────────────────────────────

{prs, slide} = Podium.add_slide(prs, layout: :title_only)
slide = Podium.set_placeholder(slide, :title, "Connectors")

# Pair 1: straight connector
slide =
  slide
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {0.5, :inches},
    y: {2, :inches},
    width: {1.5, :inches},
    height: {0.8, :inches},
    text: "Start",
    fill: "4472C4"
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {4, :inches},
    y: {2, :inches},
    width: {1.5, :inches},
    height: {0.8, :inches},
    text: "End",
    fill: "4472C4"
  )
  |> Podium.add_connector(:straight, {2, :inches}, {2.4, :inches}, {4, :inches}, {2.4, :inches},
    line: [color: "000000", width: {1.5, :pt}]
  )

# Pair 2: elbow connector
slide =
  slide
  |> Podium.add_auto_shape(:oval,
    x: {0.5, :inches},
    y: {3.8, :inches},
    width: {1.5, :inches},
    height: {1, :inches},
    text: "A",
    fill: "ED7D31"
  )
  |> Podium.add_auto_shape(:oval,
    x: {4, :inches},
    y: {4.8, :inches},
    width: {1.5, :inches},
    height: {1, :inches},
    text: "B",
    fill: "ED7D31"
  )
  |> Podium.add_connector(:elbow, {2, :inches}, {4.3, :inches}, {4, :inches}, {5.3, :inches},
    line: [color: "FF0000", width: {2, :pt}, dash_style: :dash]
  )

# Pair 3: curved connector
slide =
  slide
  |> Podium.add_auto_shape(:diamond,
    x: {7, :inches},
    y: {2, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    text: "X",
    fill: "70AD47"
  )
  |> Podium.add_auto_shape(:diamond,
    x: {10, :inches},
    y: {4, :inches},
    width: {1.5, :inches},
    height: {1.5, :inches},
    text: "Y",
    fill: "70AD47"
  )
  |> Podium.add_connector(:curved, {8.5, :inches}, {2.75, :inches}, {10, :inches}, {4.75, :inches},
    line: [color: "5B9BD5", width: {2.5, :pt}]
  )

prs = Podium.put_slide(prs, slide)

# ── Slide 3: Text Auto-Size ──────────────────────────────────────────────────

{prs, slide} = Podium.add_slide(prs, layout: :title_only)
slide = Podium.set_placeholder(slide, :title, "Text Auto-Size")

# No auto-size (fixed)
slide =
  slide
  |> Podium.add_text_box(
    [
      [{"auto_size: :none", bold: true, font_size: 14}],
      [{"Text stays the same size regardless of box dimensions. Overflow is clipped."}]
    ],
    x: {0.5, :inches},
    y: {2, :inches},
    width: {3.5, :inches},
    height: {1.5, :inches},
    fill: "F2F2F2",
    line: "D9D9D9",
    auto_size: :none
  )

# Text to fit shape (shrink text)
slide =
  slide
  |> Podium.add_text_box(
    [
      [{"auto_size: :text_to_fit_shape", bold: true, font_size: 14}],
      [
        {"Text shrinks automatically to fit within the shape boundaries. Useful for variable-length content."}
      ]
    ],
    x: {4.5, :inches},
    y: {2, :inches},
    width: {3.5, :inches},
    height: {1.5, :inches},
    fill: "E2EFDA",
    line: "A9D18E",
    auto_size: :text_to_fit_shape
  )

# Shape to fit text (grow shape)
slide =
  slide
  |> Podium.add_text_box(
    [
      [{"auto_size: :shape_to_fit_text", bold: true, font_size: 14}],
      [
        {"The shape grows or shrinks to fit the text content. The box height adjusts automatically."}
      ]
    ],
    x: {8.5, :inches},
    y: {2, :inches},
    width: {3.5, :inches},
    height: {1.5, :inches},
    fill: "DAEEF3",
    line: "9DC3E6",
    auto_size: :shape_to_fit_text
  )

# Auto shape with auto-size
slide =
  slide
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {2, :inches},
    y: {4.5, :inches},
    width: {8, :inches},
    height: {1.5, :inches},
    text: "Auto shape with :text_to_fit_shape — text shrinks to fit the rounded rectangle",
    fill: "4472C4",
    font_size: 20,
    auto_size: :text_to_fit_shape
  )

prs = Podium.put_slide(prs, slide)

# ── Save ──────────────────────────────────────────────────────────────────────

Podium.save(prs, "demos/shapes_and_connectors.pptx")
IO.puts("Generated demos/shapes_and_connectors.pptx")
