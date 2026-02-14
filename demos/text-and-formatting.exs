File.mkdir_p!("demos/output")

prs = Podium.new()

# Slide 1: Mixed formatting -- bold, italic, colors, sizes in one paragraph
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      [{"Q1 Revenue Report", bold: true, font_size: 32, color: "003366"}],
      [{"Prepared by ", font_size: 14}, {"Engineering", bold: true, italic: true}],
      [],
      [
        {"Normal text "},
        {"bold", bold: true},
        {" and ", font_size: 14},
        {"red italic", italic: true, color: "CC0000"}
      ]
    ],
    x: {1, :inches},
    y: {1, :inches},
    width: {10, :inches},
    height: {3, :inches}
  )

# Slide 2: Bullet points with nested levels + numbered list
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Key Results", bold: true, font_size: 24, color: "003366"}], space_after: 8},
      {["Revenue up 35% year-over-year"], bullet: true},
      {["North America grew fastest"], bullet: true, level: 1},
      {["APAC close behind"], bullet: true, level: 1},
      {["Customer satisfaction at all-time high"], bullet: true},
      {[{"Action Items", bold: true, font_size: 24, color: "003366"}],
       space_before: 16, space_after: 8},
      {["Review quarterly data"], bullet: :number},
      {["Identify growth opportunities"], bullet: :number},
      {["Present findings to board"], bullet: :number}
    ],
    x: {1, :inches},
    y: {0.5, :inches},
    width: {10, :inches},
    height: {6, :inches}
  )

# Slide 3: Superscript/subscript + underline styles
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Superscript & Subscript", bold: true, font_size: 24, color: "003366"}],
       space_after: 12},
      [{"E = mc", font_size: 18}, {"2", font_size: 12, superscript: true}],
      [{"H", font_size: 18}, {"2", font_size: 12, subscript: true}, {"O", font_size: 18}]
    ],
    x: {1, :inches},
    y: {0.5, :inches},
    width: {10, :inches},
    height: {2.5, :inches}
  )
  |> Podium.add_text_box(
    [
      {[{"Underline Styles", bold: true, font_size: 24, color: "003366"}], space_after: 12},
      [
        {"Single", underline: :single, font_size: 16},
        {"   "},
        {"Double", underline: :double, font_size: 16},
        {"   "},
        {"Wavy", underline: :wavy, font_size: 16},
        {"   "},
        {"Dotted", underline: :dotted, font_size: 16},
        {"   "},
        {"Dashed", underline: :dash, font_size: 16}
      ]
    ],
    x: {1, :inches},
    y: {3.5, :inches},
    width: {10, :inches},
    height: {2.5, :inches}
  )

# Slide 4: "Putting It All Together" -- gradient header bar + bulleted content
s4 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [
      {[{"Q4 2025 Summary", bold: true, font_size: 28, color: "003366"}],
       alignment: :center, space_after: 12}
    ],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    [
      {[{"Key Results", bold: true, font_size: 20}], space_after: 6},
      {["Revenue grew 35% to $18.2M"], bullet: true},
      {["North America led growth"], bullet: true, level: 1},
      {["APAC expanded 42%"], bullet: true, level: 1},
      {["Operating margin improved to 28%"], bullet: true},
      {[{"Next Steps", bold: true, font_size: 20}], space_before: 12, space_after: 6},
      {["Finalize APAC expansion plan"], bullet: :number},
      {["Launch self-service portal"], bullet: :number},
      {["Target 95% satisfaction by Q2"], bullet: :number}
    ],
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12, :inches},
    height: {5, :inches}
  )

prs =
  prs
  |> Podium.add_slide(s1)
  |> Podium.add_slide(s2)
  |> Podium.add_slide(s3)
  |> Podium.add_slide(s4)
  |> Podium.save("demos/output/text-and-formatting.pptx")

IO.puts("Generated demos/output/text-and-formatting.pptx")
