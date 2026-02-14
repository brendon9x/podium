File.mkdir_p!("demos/output")

prs = Podium.new(title: "Presentations and Slides Demo", author: "Podium")

# Slide 1: Title slide with footer, date, slide number
s1 =
  Podium.Slide.new(:title_slide)
  |> Podium.set_placeholder(:title, "Annual Report 2025")
  |> Podium.set_placeholder(:subtitle, "Finance & Operations Dashboard")

# Slide 2: Solid dark background with light text
s2 =
  Podium.Slide.new(:blank, background: "1A1A2E")
  |> Podium.add_text_box("Dark Theme Slide",
    x: {3, :inches},
    y: {3, :inches},
    width: {7, :inches},
    height: {1.5, :inches},
    font_size: 36,
    alignment: :center
  )

# Slide 3: Gradient background with title
s3 =
  Podium.Slide.new(:blank,
    background: {:gradient, [{0, "000428"}, {100_000, "004E92"}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    [{[{"Gradient Background", bold: true, font_size: 36, color: "FFFFFF"}], alignment: :center}],
    x: {2, :inches},
    y: {3, :inches},
    width: {9, :inches},
    height: {1.5, :inches}
  )

# Slide 4: Pattern background with content
s4 =
  Podium.Slide.new(:blank,
    background: {:pattern, :lt_dn_diag, foreground: "CCCCCC", background: "FFFFFF"}
  )
  |> Podium.add_text_box(
    [
      {[{"Pattern Background", bold: true, font_size: 28, color: "003366"}],
       alignment: :center, space_after: 12},
      {[{"This slide uses a diagonal pattern fill as its background."}], alignment: :center}
    ],
    x: {2, :inches},
    y: {2.5, :inches},
    width: {9, :inches},
    height: {2.5, :inches}
  )

# Add footer, date, slide numbers
prs =
  prs
  |> Podium.add_slide(s1)
  |> Podium.add_slide(s2)
  |> Podium.add_slide(s3)
  |> Podium.add_slide(s4)
  |> Podium.set_footer(
    footer: "Acme Corp Confidential",
    date: "February 2026",
    slide_number: true
  )
  |> Podium.save("demos/output/presentations-and-slides.pptx")

IO.puts("Generated demos/output/presentations-and-slides.pptx")
