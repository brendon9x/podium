File.mkdir_p!("demos/output")

prs = Podium.new(title: "Presentations and Slides Demo", author: "Podium")

# Slide 1: Title slide with footer, date, slide number
{prs, s1} = Podium.add_slide(prs, layout: :title_slide)

s1 =
  s1
  |> Podium.set_placeholder(:title, "Annual Report 2025")
  |> Podium.set_placeholder(:subtitle, "Finance & Operations Dashboard")

prs = Podium.put_slide(prs, s1)

# Slide 2: Solid dark background with light text
{prs, s2} = Podium.add_slide(prs, background: "1A1A2E")

s2 =
  Podium.add_text_box(s2, "Dark Theme Slide",
    x: {3, :inches},
    y: {3, :inches},
    width: {7, :inches},
    height: {1.5, :inches},
    font_size: 36,
    alignment: :center
  )

prs = Podium.put_slide(prs, s2)

# Slide 3: Gradient background with title
{prs, s3} =
  Podium.add_slide(prs,
    background: {:gradient, [{0, "000428"}, {100_000, "004E92"}], angle: 5_400_000}
  )

s3 =
  Podium.add_text_box(
    s3,
    [{[{"Gradient Background", bold: true, font_size: 36, color: "FFFFFF"}], alignment: :center}],
    x: {2, :inches},
    y: {3, :inches},
    width: {9, :inches},
    height: {1.5, :inches}
  )

prs = Podium.put_slide(prs, s3)

# Slide 4: Pattern background with content
{prs, s4} =
  Podium.add_slide(prs,
    background: {:pattern, :lt_dn_diag, foreground: "CCCCCC", background: "FFFFFF"}
  )

s4 =
  Podium.add_text_box(
    s4,
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

prs = Podium.put_slide(prs, s4)

# Add footer, date, slide numbers
prs =
  Podium.set_footer(prs,
    footer: "Acme Corp Confidential",
    date: "February 2026",
    slide_number: true
  )

:ok = Podium.save(prs, "demos/output/presentations-and-slides.pptx")
IO.puts("Generated demos/output/presentations-and-slides.pptx")
