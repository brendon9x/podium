File.mkdir_p!("demos/output")

prs = Podium.new()

# Slide 1: Solid dark background with light text
{prs, s1} = Podium.add_slide(prs, background: "1A1A2E")

s1 =
  Podium.add_text_box(
    s1,
    [
      {[{"Solid Background", bold: true, font_size: 36, color: "FFFFFF"}], alignment: :center},
      {[{"Dark theme with light text", font_size: 18, color: "CCCCCC"}], alignment: :center}
    ],
    x: {3, :inches},
    y: {2.5, :inches},
    width: {7, :inches},
    height: {2.5, :inches}
  )

s1 =
  Podium.set_notes(s1, "This slide demonstrates a solid dark background with white text overlay.")

prs = Podium.put_slide(prs, s1)

# Slide 2: Gradient background
{prs, s2} =
  Podium.add_slide(prs,
    background: {:gradient, [{0, "000428"}, {100_000, "004E92"}], angle: 5_400_000}
  )

s2 =
  Podium.add_text_box(
    s2,
    [
      {[{"Gradient Background", bold: true, font_size: 36, color: "FFFFFF"}], alignment: :center},
      {[{"Deep blue top-to-bottom gradient", font_size: 18, color: "BDD7EE"}], alignment: :center}
    ],
    x: {3, :inches},
    y: {2.5, :inches},
    width: {7, :inches},
    height: {2.5, :inches}
  )

s2 =
  Podium.set_notes(
    s2,
    "Key talking points:\n- Gradient backgrounds add visual depth\n- Use angle: 5_400_000 for top-to-bottom"
  )

prs = Podium.put_slide(prs, s2)

# Slide 3: Pattern background
{prs, s3} =
  Podium.add_slide(prs,
    background: {:pattern, :lt_dn_diag, foreground: "CCCCCC", background: "FFFFFF"}
  )

s3 =
  Podium.add_text_box(
    s3,
    [
      {[{"Pattern Background", bold: true, font_size: 36, color: "003366"}], alignment: :center},
      {[{"Light diagonal pattern fill", font_size: 18, color: "666666"}], alignment: :center}
    ],
    x: {3, :inches},
    y: {2.5, :inches},
    width: {7, :inches},
    height: {2.5, :inches}
  )

s3 = Podium.set_notes(s3, "All 54 OOXML pattern presets are available via Podium.Pattern.")

prs = Podium.put_slide(prs, s3)

# Slide 4: Picture background with overlay text
bg_image = File.read!("test/fixtures/acme.jpg")

{prs, s4} = Podium.add_slide(prs, background: {:picture, bg_image})

s4 =
  Podium.add_text_box(
    s4,
    [
      {[{"Annual Conference 2026", bold: true, font_size: 44, color: "FFFFFF"}],
       alignment: :center}
    ],
    x: {1, :inches},
    y: {2.5, :inches},
    width: {11, :inches},
    height: {2, :inches}
  )

s4 =
  Podium.set_notes(
    s4,
    "Picture backgrounds use {:picture, binary} tuple.\nThe image is stretched to fill the entire slide."
  )

prs = Podium.put_slide(prs, s4)

:ok = Podium.save(prs, "demos/output/slide-backgrounds-and-notes.pptx")
IO.puts("Generated demos/output/slide-backgrounds-and-notes.pptx")
