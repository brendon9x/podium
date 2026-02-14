File.mkdir_p!("demos/output")

prs = Podium.new()

# Slide 1: Basic table with header fills and borders
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Basic Table", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_table(
    [
      [
        {"Department", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Headcount", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Budget", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]}
      ],
      ["Engineering", "230", "$4,200K"],
      ["Marketing", "85", "$2,100K"],
      ["Sales", "120", "$3,500K"]
    ],
    x: {1, :inches},
    y: {1.5, :inches},
    width: {11, :inches},
    height: {3, :inches}
  )

# Slide 2: Cell merging -- horizontal merge title row + vertical merge column
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Cell Merging", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_table(
    [
      [{"Q4 2025 Results", col_span: 3, fill: "003366"}, :merge, :merge],
      ["Region", "Revenue", "Growth"],
      ["North America", "$12.5M", "+18%"],
      ["Europe", "$8.2M", "+12%"]
    ],
    x: {0.5, :inches},
    y: {1.3, :inches},
    width: {5.5, :inches},
    height: {3, :inches}
  )
  |> Podium.add_table(
    [
      [
        {"Engineering", row_span: 2, fill: "D6E4F0", anchor: :middle},
        "Frontend",
        "42"
      ],
      [:merge, "Backend", "58"],
      ["Marketing", "Digital", "85"]
    ],
    x: {6.5, :inches},
    y: {1.3, :inches},
    width: {5.5, :inches},
    height: {2.5, :inches}
  )

# Slide 3: Cell formatting -- gradient fill, pattern fill, padding, vertical alignment
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box(
    [{[{"Cell Formatting", bold: true, font_size: 28, color: "003366"}], alignment: :center}],
    x: {0.5, :inches},
    y: {0.3, :inches},
    width: {12, :inches},
    height: {0.7, :inches}
  )
  |> Podium.add_table(
    [
      [
        {"Solid Fill", fill: "4472C4"},
        {"Gradient Fill",
         fill: {:gradient, [{0, "4472C4"}, {100_000, "002060"}], angle: 5_400_000}},
        {"Pattern Fill", fill: {:pattern, :lt_horz, foreground: "ED7D31", background: "FFFFFF"}}
      ],
      [
        {"Top aligned", anchor: :top, padding: [top: {0.1, :inches}]},
        {"Middle aligned", anchor: :middle},
        {"Bottom aligned", anchor: :bottom, padding: [bottom: {0.1, :inches}]}
      ],
      [
        {"Padded Cell", padding: [left: {0.2, :inches}, top: {0.1, :inches}]},
        {"Border Bottom", borders: [bottom: [color: "FF0000", width: {2, :pt}]]},
        {[[{"Rich ", font_size: 14}, {"Text", bold: true, color: "4472C4", font_size: 14}]],
         anchor: :middle}
      ]
    ],
    x: {0.5, :inches},
    y: {1.3, :inches},
    width: {12, :inches},
    height: {4, :inches}
  )

# Slide 4: "Complete Example" professional report table
s4 =
  Podium.Slide.new()
  |> Podium.add_table(
    [
      # Merged title row
      [
        {"Department Summary -- 2025",
         col_span: 4, fill: "003366", anchor: :middle, padding: [left: {0.1, :inches}]},
        :merge,
        :merge,
        :merge
      ],
      # Column headers with fill and bottom border
      [
        {"Department", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Headcount", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Budget ($K)", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]},
        {"Satisfaction", fill: "4472C4", borders: [bottom: [color: "003366", width: {2, :pt}]]}
      ],
      # Engineering spans 2 rows with rich text
      [
        {[[{"Engineering", bold: true, color: "003366"}]],
         row_span: 2, anchor: :middle, fill: "D6E4F0", padding: [left: {0.1, :inches}]},
        "230",
        "$4,200",
        {[[{"92%", bold: true, color: "228B22"}]], anchor: :middle}
      ],
      [
        :merge,
        "180",
        "$3,800",
        {[[{"94%", bold: true, color: "228B22"}]], anchor: :middle}
      ],
      [
        "Marketing",
        "85",
        "$2,100",
        {"87%", borders: [bottom: "CCCCCC"]}
      ],
      [
        "Sales",
        "120",
        "$3,500",
        {"84%", borders: [bottom: "CCCCCC"]}
      ]
    ],
    x: {0.5, :inches},
    y: {1, :inches},
    width: {12, :inches},
    height: {4.5, :inches}
  )

prs =
  prs
  |> Podium.add_slide(s1)
  |> Podium.add_slide(s2)
  |> Podium.add_slide(s3)
  |> Podium.add_slide(s4)
  |> Podium.save("demos/output/tables.pptx")

IO.puts("Generated demos/output/tables.pptx")
