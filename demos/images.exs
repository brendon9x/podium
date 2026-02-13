File.mkdir_p!("demos/output")

image_binary = File.read!("test/fixtures/acme.jpg")

prs = Podium.new()

# Slide 1: Basic image placement with explicit dimensions
{prs, s1} = Podium.add_slide(prs)

s1 =
  Podium.add_text_box(s1, "Basic Image Placement",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )

{prs, s1} =
  Podium.add_image(prs, s1, image_binary,
    x: {3, :inches},
    y: {1.5, :inches},
    width: {6, :inches},
    height: {4, :inches}
  )

prs = Podium.put_slide(prs, s1)

# Slide 2: Image with shape mask (ellipse) + image with cropping
{prs, s2} = Podium.add_slide(prs)

s2 =
  Podium.add_text_box(s2, "Shape Mask & Cropping",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )

# Ellipse mask
{prs, s2} =
  Podium.add_image(prs, s2, image_binary,
    x: {1, :inches},
    y: {1.5, :inches},
    width: {4, :inches},
    height: {4, :inches},
    shape: :ellipse
  )

# Cropped image
{prs, s2} =
  Podium.add_image(prs, s2, image_binary,
    x: {7, :inches},
    y: {1.5, :inches},
    width: {5, :inches},
    height: {4, :inches},
    crop: [left: 10_000, top: 5_000, right: 10_000, bottom: 5_000]
  )

prs = Podium.put_slide(prs, s2)

# Slide 3: Image with rotation
{prs, s3} = Podium.add_slide(prs)

s3 =
  Podium.add_text_box(s3, "Image Rotation",
    x: {1, :inches},
    y: {0.3, :inches},
    width: {11, :inches},
    height: {0.7, :inches},
    font_size: 28,
    alignment: :center
  )

{prs, s3} =
  Podium.add_image(prs, s3, image_binary,
    x: {4, :inches},
    y: {1.5, :inches},
    width: {5, :inches},
    height: {4, :inches},
    rotation: 15
  )

prs = Podium.put_slide(prs, s3)

:ok = Podium.save(prs, "demos/output/images.pptx")
IO.puts("Generated demos/output/images.pptx")
