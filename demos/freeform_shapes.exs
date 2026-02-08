# Freeform Shapes Demo
# Demonstrates custom vector paths using the Freeform builder
# 16:9 slide = 13.33" x 7.5"

alias Podium.Freeform

prs = Podium.new(title: "Freeform Shapes Demo", author: "Podium")

# --- Slide 1: Simple closed triangle with fill ---
# Triangle centered horizontally: 6" wide, center at 6.67"
{prs, slide1} = Podium.add_slide(prs, layout: :title_only)
slide1 = Podium.set_placeholder(slide1, :title, "Simple Triangle")

slide1 =
  Freeform.new({3.67, :inches}, {5.5, :inches})
  |> Freeform.line_to({6.67, :inches}, {1.5, :inches})
  |> Freeform.line_to({9.67, :inches}, {5.5, :inches})
  |> Freeform.close()
  |> Podium.add_freeform(slide1, fill: "4472C4")

prs = Podium.put_slide(prs, slide1)

# --- Slide 2: Star shape using line segments ---
# Star centered at 6.67": 7" span from 3.17 to 10.17
{prs, slide2} = Podium.add_slide(prs, layout: :title_only)
slide2 = Podium.set_placeholder(slide2, :title, "Star Shape")

slide2 =
  Freeform.new({6.67, :inches}, {1.5, :inches})
  |> Freeform.add_line_segments(
    [
      {{4.77, :inches}, {5.5, :inches}},
      {{10.17, :inches}, {3, :inches}},
      {{3.17, :inches}, {3, :inches}},
      {{8.57, :inches}, {5.5, :inches}}
    ],
    close: true
  )
  |> Podium.add_freeform(slide2, fill: "FFD700", line: "CC9900")

prs = Podium.put_slide(prs, slide2)

# --- Slide 3: Multiple contours (square with cutout) ---
# Outer rect centered: 6" wide from 3.67 to 9.67
{prs, slide3} = Podium.add_slide(prs, layout: :title_only)
slide3 = Podium.set_placeholder(slide3, :title, "Multiple Contours")

slide3 =
  Freeform.new({3.67, :inches}, {1.5, :inches})
  |> Freeform.add_line_segments([
    {{9.67, :inches}, {1.5, :inches}},
    {{9.67, :inches}, {5.5, :inches}},
    {{3.67, :inches}, {5.5, :inches}}
  ])
  |> Freeform.close()
  |> Freeform.move_to({5.17, :inches}, {2.5, :inches})
  |> Freeform.add_line_segments([
    {{8.17, :inches}, {2.5, :inches}},
    {{8.17, :inches}, {4.5, :inches}},
    {{5.17, :inches}, {4.5, :inches}}
  ])
  |> Freeform.close()
  |> Podium.add_freeform(slide3, fill: "70AD47")

prs = Podium.put_slide(prs, slide3)

# --- Slide 4: Shapes using custom scale + origin ---
# Triangle (3" wide) and diamond (2" wide) spread across 16:9 slide
{prs, slide4} = Podium.add_slide(prs, layout: :title_only)
slide4 = Podium.set_placeholder(slide4, :title, "Custom Scale & Origin")

# Triangle using scale factor (1 unit = 0.01 inches)
slide4 =
  Freeform.new(0, 0, scale: 9144)
  |> Freeform.line_to(300, 0)
  |> Freeform.line_to(150, 260)
  |> Freeform.close()
  |> Podium.add_freeform(slide4, origin_x: {2.5, :inches}, origin_y: {2, :inches}, fill: "ED7D31")

# Diamond using scale factor
slide4 =
  Freeform.new(100, 0, scale: 9144)
  |> Freeform.line_to(200, 100)
  |> Freeform.line_to(100, 200)
  |> Freeform.line_to(0, 100)
  |> Freeform.close()
  |> Podium.add_freeform(slide4, origin_x: {8.5, :inches}, origin_y: {2, :inches}, fill: "5B9BD5")

prs = Podium.put_slide(prs, slide4)

Podium.save(prs, "freeform_shapes.pptx")
IO.puts("Saved freeform_shapes.pptx")
