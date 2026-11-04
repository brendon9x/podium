File.mkdir_p!("demos/output")

image_binary = File.read!("test/fixtures/acme.jpg")

prs = Podium.new()

# Offsets from the left edge of a centred row
alias Podium.Units

# Slide 1: Basic image placement with explicit dimensions
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box("Basic Image Placement",
    x: Podium.center_x(prs, {11, :inches}),
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_image(image_binary,
    x: Podium.center_x(prs, {6, :inches}),
    y: {1.5, :inches},
    width: {6, :inches},
    height: {4, :inches}
  )

# Slide 2: Image with shape mask (ellipse) + image with cropping
# A 4in and a 5in image, 2in apart, centred as an 11in row
images_left = Podium.center_x(prs, {11, :inches})

s2 =
  Podium.Slide.new()
  |> Podium.add_text_box("Shape Mask & Cropping",
    x: Podium.center_x(prs, {11, :inches}),
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_image(image_binary,
    x: images_left,
    y: {1.5, :inches},
    width: {4, :inches},
    height: {4, :inches},
    shape: :ellipse
  )
  |> Podium.add_image(image_binary,
    x: images_left + Units.to_emu({6, :inches}),
    y: {1.5, :inches},
    width: {5, :inches},
    height: {4, :inches},
    crop: [left: 10_000, top: 5_000, right: 10_000, bottom: 5_000]
  )

# Slide 3: Image with rotation
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box("Image Rotation",
    x: Podium.center_x(prs, {11, :inches}),
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_image(image_binary,
    x: Podium.center_x(prs, {5, :inches}),
    y: {1.5, :inches},
    width: {5, :inches},
    height: {4, :inches},
    rotation: 15
  )

prs
|> Podium.add_slide(s1)
|> Podium.add_slide(s2)
|> Podium.add_slide(s3)
|> Podium.save("demos/output/images.pptx")

IO.puts("Generated demos/output/images.pptx")
