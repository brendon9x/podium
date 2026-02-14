File.mkdir_p!("demos/output")

image_binary = File.read!("test/fixtures/acme.jpg")

prs = Podium.new()

# Slide 1: Basic image placement with explicit dimensions
s1 =
  Podium.Slide.new()
  |> Podium.add_text_box("Basic Image Placement",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_image(image_binary,
    x: {3, :inches},
    y: {1.5, :inches},
    width: {6, :inches},
    height: {4, :inches}
  )

# Slide 2: Image with shape mask (ellipse) + image with cropping
s2 =
  Podium.Slide.new()
  |> Podium.add_text_box("Shape Mask & Cropping",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_image(image_binary,
    x: {1, :inches},
    y: {1.5, :inches},
    width: {4, :inches},
    height: {4, :inches},
    shape: :ellipse
  )
  |> Podium.add_image(image_binary,
    x: {7, :inches},
    y: {1.5, :inches},
    width: {5, :inches},
    height: {4, :inches},
    crop: [left: 10_000, top: 5_000, right: 10_000, bottom: 5_000]
  )

# Slide 3: Image with rotation
s3 =
  Podium.Slide.new()
  |> Podium.add_text_box("Image Rotation",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )
  |> Podium.add_image(image_binary,
    x: {4, :inches},
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
