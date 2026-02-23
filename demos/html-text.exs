File.mkdir_p!("demos/output")

prs = Podium.new()

# Slide 1: Basic HTML formatting -- bold, italic, underline, colors, fonts
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    {:html,
     ~s(<p style="text-align: center"><span style="font-size: 28pt; color: #003366"><b>HTML Text Input</b></span></p>)},
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    {:html, """
    <p><b>Bold text</b>, <i>italic text</i>, <u>underlined text</u></p>
    <p><s>Strikethrough</s>, E=mc<sup>2</sup>, H<sub>2</sub>O</p>
    <p><span style="color: #FF0000">Red</span>, <span style="color: #00AA00">Green</span>, <span style="color: #0000FF">Blue</span></p>
    <p><span style="font-family: Courier New; font-size: 14pt">Courier New at 14pt</span></p>
    """},
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12, :inches},
    height: {5, :inches}
  )

# Slide 2: Bullet lists and numbered lists
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    {:html,
     ~s(<p style="text-align: center"><span style="font-size: 28pt; color: #003366"><b>Lists</b></span></p>)},
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    {:html, """
    <ul>
      <li>Unordered list item one</li>
      <li>Unordered list item two</li>
      <ul>
        <li>Nested bullet point</li>
        <li>Another nested point</li>
      </ul>
      <li>Back to top level</li>
    </ul>
    """},
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {5.5, :inches},
    height: {4.5, :inches}
  )
  |> Podium.add_text_box(
    {:html, """
    <ol>
      <li>First step</li>
      <li>Second step</li>
      <li>Third step</li>
    </ol>
    """},
    x: {6.5, :inches},
    y: {1.5, :inches},
    width: {5.5, :inches},
    height: {4.5, :inches}
  )

# Slide 3: Nested formatting and styled spans
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    {:html,
     ~s(<p style="text-align: center"><span style="font-size: 28pt; color: #003366"><b>Nested Formatting</b></span></p>)},
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    {:html, """
    <p><b><i>Bold and italic combined</i></b></p>
    <p><b><u>Bold and underlined</u></b></p>
    <p><b><i><span style="color: #CC0000">Bold italic red</span></i></b></p>
    <p><span style="font-size: 24pt; font-family: Georgia; color: #003366">Large Georgia blue</span></p>
    """},
    x: {0.5, :inches},
    y: {1.5, :inches},
    width: {12, :inches},
    height: {5, :inches}
  )

# Slide 4: Side-by-side comparison -- rich text API vs HTML
s4 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    {:html,
     ~s(<p style="text-align: center"><span style="font-size: 28pt; color: #003366"><b>Same Output, Two APIs</b></span></p>)},
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000}
  )
  # Left side: using HTML
  |> Podium.add_text_box(
    {:html, ~s(<p style="text-align: center"><b>Via HTML</b></p>)},
    x: {0.5, :inches},
    y: {1.3, :inches},
    width: {5.5, :inches},
    height: {0.5, :inches}
  )
  |> Podium.add_text_box(
    {:html, """
    <p><b>Q4 Summary</b></p>
    <ul>
      <li>Revenue grew <span style="color: #228B22"><b>35%</b></span></li>
      <li>Customer sat at <span style="color: #4472C4"><b>88%</b></span></li>
    </ul>
    """},
    x: {0.5, :inches},
    y: {1.8, :inches},
    width: {5.5, :inches},
    height: {4, :inches},
    fill: "F5F5F5",
    line: "CCCCCC"
  )
  # Right side: using rich text API (same output)
  |> Podium.add_text_box(
    {:html, ~s(<p style="text-align: center"><b>Via Rich Text API</b></p>)},
    x: {6.5, :inches},
    y: {1.3, :inches},
    width: {5.5, :inches},
    height: {0.5, :inches}
  )
  |> Podium.add_text_box(
    [
      [{"Q4 Summary", bold: true}],
      {[{"Revenue grew "}, {"35%", bold: true, color: "228B22"}], bullet: true},
      {[{"Customer sat at "}, {"88%", bold: true, color: "4472C4"}], bullet: true}
    ],
    x: {6.5, :inches},
    y: {1.8, :inches},
    width: {5.5, :inches},
    height: {4, :inches},
    fill: "F5F5F5",
    line: "CCCCCC"
  )

# Slide 5: HTML in tables and placeholders
s5 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    {:html,
     ~s(<p style="text-align: center"><span style="font-size: 28pt; color: #003366"><b>HTML in Tables</b></span></p>)},
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000}
  )
  |> Podium.add_table(
    [
      [{:html, "<b>Name</b>"}, {:html, "<b>Status</b>"}, {:html, "<b>Notes</b>"}],
      [
        "Alice",
        {:html, ~s(<span style="color: #228B22"><b>Active</b></span>)},
        "Top performer"
      ],
      [
        "Bob",
        {:html, ~s(<span style="color: #CC0000"><b>On Leave</b></span>)},
        {:html, "<i>Returns March</i>"}
      ]
    ],
    x: {1, :inches},
    y: {1.5, :inches},
    width: {10, :inches},
    height: {3, :inches}
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.add_slide(s5)
|> Podium.save("demos/output/html-text.pptx")

IO.puts("Generated demos/output/html-text.pptx")
