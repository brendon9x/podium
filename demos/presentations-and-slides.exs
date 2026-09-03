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
  |> Podium.add_text_box(
    [{[{"Dark Theme Slide", font_size: 36, color: "FFFFFF"}], alignment: :center}],
    x: {3, :inches},
    y: {3, :inches},
    width: {7, :inches},
    height: {1.5, :inches}
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

# --- Building on your own template ---
#
# Podium.from_template/2 takes a path or the bytes of a slide-less pptx and
# renders into it, keeping its masters, layouts, theme, media and slide size.
# The test fixture here stands in for a customer's branded skeleton; in real use
# you would pass the path to the file itself.

skeleton_dir = "test/fixtures/skeleton_16x9"

entries =
  skeleton_dir
  |> Path.join("**")
  |> Path.wildcard(match_dot: true)
  |> Enum.reject(&File.dir?/1)
  |> Enum.map(&{&1 |> Path.relative_to(skeleton_dir) |> to_charlist(), File.read!(&1)})

{:ok, {_name, skeleton}} = :zip.create(~c"skeleton.pptx", entries, [:memory])

# Layouts are addressed by their index in the template: 2 is its "Content"
# layout, 3 its "Blank". Charts and tables need explicit positions, because the
# name-based placeholder helpers only know the bundled template.
t1 =
  Podium.Slide.new(2)
  |> Podium.add_text_box(
    [[{"Rendered into a customer template", bold: true, font_size: 36}]],
    x: {0.75, :inches},
    y: {0.5, :inches},
    width: {10, :inches},
    height: {1, :inches}
  )
  |> Podium.add_text_box(
    "The accent bar and logo come from the template's own master and theme.",
    x: {0.75, :inches},
    y: {2, :inches},
    width: {10, :inches},
    height: {1, :inches},
    font_size: 20
  )
  |> Podium.set_notes("Speaker notes reuse the template's notes master.")

t2 =
  Podium.Slide.new(3)
  |> Podium.add_text_box(
    [{[{"Thank you", font_size: 44}], alignment: :center}],
    x: {1, :inches},
    y: {2.8, :inches},
    width: {11.3, :inches},
    height: {1.5, :inches}
  )

skeleton
|> Podium.from_template(title: "Skeleton Report", author: "Podium")
|> Podium.add_slide(t1)
|> Podium.add_slide(t2)
|> Podium.save("demos/output/presentation-from-template.pptx")

IO.puts("Generated demos/output/presentation-from-template.pptx")
