File.mkdir_p!("demos/output")

prs = Podium.new()

# Create all slides upfront so we can reference them for slide jumps
s1 = Podium.Slide.new()
s2 = Podium.Slide.new()
s3 = Podium.Slide.new()

# Slide 1: URL hyperlinks and email links with styled text
s1 =
  s1
  |> Podium.add_text_box(
    [{[{"Hyperlinks", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_text_box(
    [
      [
        {"Read the full report: ", font_size: 16},
        {"Q4 Analysis",
         font_size: 16,
         color: "0563C1",
         underline: true,
         hyperlink: "https://reports.example.com/q4-2025"}
      ],
      [],
      [
        {"Contact us: ", font_size: 16},
        {"support@acme.example.com",
         font_size: 16,
         color: "0563C1",
         underline: true,
         hyperlink: "mailto:support@acme.example.com"}
      ],
      [],
      [
        {"With tooltip: ", font_size: 16},
        {"example.com",
         font_size: 16,
         color: "0563C1",
         underline: true,
         hyperlink: [url: "https://example.com", tooltip: "Visit Example.com"]}
      ]
    ],
    x: {1, :inches},
    y: {1.5, :inches},
    width: {10, :inches},
    height: {4, :inches}
  )

# Slide 2: Navigation buttons -- Next/Previous/End Show shapes
s2 =
  s2
  |> Podium.add_text_box(
    [{[{"Navigation Actions", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {1, :inches},
    y: {2.5, :inches},
    width: {3, :inches},
    height: {0.8, :inches},
    fill: "4472C4",
    text: [
      {[{"<-- Previous", bold: true, color: "FFFFFF", hyperlink: :previous_slide}],
       alignment: :center}
    ]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {5, :inches},
    y: {2.5, :inches},
    width: {3, :inches},
    height: {0.8, :inches},
    fill: "70AD47",
    text: [
      {[{"Next -->", bold: true, color: "FFFFFF", hyperlink: :next_slide}], alignment: :center}
    ]
  )
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {9, :inches},
    y: {2.5, :inches},
    width: {3, :inches},
    height: {0.8, :inches},
    fill: "CC0000",
    text: [
      {[{"End Show", bold: true, color: "FFFFFF", hyperlink: :end_show}], alignment: :center}
    ]
  )
  |> Podium.add_text_box(
    [
      [
        {"First Slide", font_size: 14, color: "0563C1", underline: true, hyperlink: :first_slide},
        {"   |   "},
        {"Last Slide", font_size: 14, color: "0563C1", underline: true, hyperlink: :last_slide}
      ]
    ],
    x: {4, :inches},
    y: {4.5, :inches},
    width: {5, :inches},
    height: {0.6, :inches},
    alignment: :center
  )

# Slide 3: Table of contents with slide jump links
s3 =
  s3
  |> Podium.add_text_box(
    [{[{"Table of Contents", bold: true, font_size: 28}], alignment: :center}],
    x: {2, :inches},
    y: {0.5, :inches},
    width: {9, :inches},
    height: {0.8, :inches}
  )
  |> Podium.add_text_box(
    [
      [
        {"1. Hyperlinks & Email Links",
         font_size: 18, color: "0563C1", underline: true, hyperlink: {:slide, s1}}
      ],
      [
        {"2. Navigation Actions",
         font_size: 18, color: "0563C1", underline: true, hyperlink: {:slide, s2}}
      ],
      [
        {"3. This Page (Table of Contents)",
         font_size: 18, color: "0563C1", underline: true, hyperlink: {:slide, s3}}
      ]
    ],
    x: {2, :inches},
    y: {1.8, :inches},
    width: {9, :inches},
    height: {3, :inches}
  )

prs =
  prs
  |> Podium.add_slide(s1)
  |> Podium.add_slide(s2)
  |> Podium.add_slide(s3)
  |> Podium.save("demos/output/hyperlinks-and-actions.pptx")

IO.puts("Generated demos/output/hyperlinks-and-actions.pptx")
