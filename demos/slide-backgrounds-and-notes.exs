File.mkdir_p!("demos/output")

prs = Podium.new()

# Slide 1: Solid dark background with light text
s1 =
  Podium.Slide.new(:blank, background: "1A1A2E")
  |> Podium.add_text_box(
    [
      {[{"Solid Background", bold: true, font_size: 36, color: "FFFFFF"}], alignment: :center},
      {[{"Dark theme with light text", font_size: 18, color: "CCCCCC"}], alignment: :center}
    ],
    x: {3, :inches},
    y: {2.5, :inches},
    width: {7, :inches},
    height: {2.5, :inches}
  )
  |> Podium.set_notes("This slide demonstrates a solid dark background with white text overlay.")

# Slide 2: Gradient background
s2 =
  Podium.Slide.new(:blank,
    background: {:gradient, [{0, "000428"}, {100_000, "004E92"}], angle: 5_400_000}
  )
  |> Podium.add_text_box(
    [
      {[{"Gradient Background", bold: true, font_size: 36, color: "FFFFFF"}], alignment: :center},
      {[{"Deep blue top-to-bottom gradient", font_size: 18, color: "BDD7EE"}], alignment: :center}
    ],
    x: {3, :inches},
    y: {2.5, :inches},
    width: {7, :inches},
    height: {2.5, :inches}
  )
  |> Podium.set_notes(
    "Key talking points:\n- Gradient backgrounds add visual depth\n- Use angle: 5_400_000 for top-to-bottom"
  )

# Slide 3: Pattern background
s3 =
  Podium.Slide.new(:blank,
    background: {:pattern, :lt_dn_diag, foreground: "CCCCCC", background: "FFFFFF"}
  )
  |> Podium.add_text_box(
    [
      {[{"Pattern Background", bold: true, font_size: 36, color: "003366"}], alignment: :center},
      {[{"Light diagonal pattern fill", font_size: 18, color: "666666"}], alignment: :center}
    ],
    x: {3, :inches},
    y: {2.5, :inches},
    width: {7, :inches},
    height: {2.5, :inches}
  )
  |> Podium.set_notes("All 54 OOXML pattern presets are available via Podium.Pattern.")

# Slide 4: Picture background with overlay text
bg_image = File.read!("test/fixtures/acme.jpg")

s4 =
  Podium.Slide.new(:blank, background: {:picture, bg_image})
  |> Podium.add_text_box(
    [
      {[{"Annual Conference 2026", bold: true, font_size: 44, color: "FFFFFF"}],
       alignment: :center}
    ],
    x: {1, :inches},
    y: {2.5, :inches},
    width: {11, :inches},
    height: {2, :inches}
  )
  |> Podium.set_notes(
    "Picture backgrounds use {:picture, binary} tuple.\nThe image is stretched to fill the entire slide."
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.add_slide(s4)
|> Podium.save("demos/output/slide-backgrounds-and-notes.pptx")

IO.puts("Generated demos/output/slide-backgrounds-and-notes.pptx")
