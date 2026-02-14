# Images

Add images to slides with `Podium.add_image/3`. Podium auto-detects the image format,
can scale from native dimensions, and deduplicates identical images by SHA-1 hash.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/images.exs` to generate a presentation with all the examples from this guide.

```elixir
image_data = File.read!("logo.png")

slide = Podium.add_image(slide, image_data,
  x: {1, :inches}, y: {1, :inches},
  width: {4, :inches})
```

## Adding an Image

`Podium.add_image/3` takes the slide, image binary, and options.
It returns the updated slide:

```elixir
prs = Podium.new()
slide = Podium.Slide.new()

logo = File.read!("company_logo.png")

slide = Podium.add_image(slide, logo,
  x: {4, :inches}, y: {2.5, :inches},
  width: {5, :inches}, height: {3, :inches})

prs = Podium.add_slide(prs, slide)
Podium.save(prs, "with_image.pptx")
```

![Basic image placement with explicit dimensions](assets/core/images/basic-placement.png)

## Supported Formats

Podium auto-detects image format from the binary's magic bytes. No file extension
or content type is needed.

| Format | Auto-Detect | Auto-Scale |
|--------|-------------|------------|
| PNG | yes | yes |
| JPEG | yes | yes |
| BMP | yes | yes |
| GIF | yes | yes |
| TIFF | yes | no |
| EMF | yes | no |
| WMF | yes | no |

> #### Warning {: .warning}
>
> EMF, WMF, and TIFF images require explicit `:width` and `:height` options.
> Auto-scaling from native dimensions is not supported for these formats.

## Sizing Behavior

How Podium resolves image dimensions depends on which size options you provide:

**Both width and height** -- uses the explicit dimensions:

```elixir
slide = Podium.add_image(slide, photo,
  x: {1, :inches}, y: {1, :inches},
  width: {6, :inches}, height: {4, :inches})
```

**Width only** -- height is calculated to preserve the aspect ratio:

```elixir
slide = Podium.add_image(slide, photo,
  x: {1, :inches}, y: {1, :inches},
  width: {6, :inches})
```

**Height only** -- width is calculated to preserve the aspect ratio:

```elixir
slide = Podium.add_image(slide, photo,
  x: {1, :inches}, y: {1, :inches},
  height: {4, :inches})
```

**Neither** -- uses the image's native pixel dimensions and DPI metadata.
Podium reads DPI from PNG pHYs chunks, JPEG JFIF headers, and BMP headers.
When no DPI metadata is present, 72 DPI is assumed.

## Cropping

Crop any side of an image with the `:crop` option. Values are in 1/1000ths
of a percent (0 to 100,000):

```elixir
slide = Podium.add_image(slide, photo,
  x: {1, :inches}, y: {1, :inches},
  width: {6, :inches}, height: {4, :inches},
  crop: [left: 10_000, top: 5_000, right: 10_000, bottom: 5_000])
```

This crops 10% from the left and right, and 5% from the top and bottom.

## Image Masking

By default, images use a rectangular frame. Pass the `:shape` option to
mask the image with a shape preset:

```elixir
# Circular profile photo
slide = Podium.add_image(slide, headshot,
  x: {5, :inches}, y: {2, :inches},
  width: {3, :inches}, height: {3, :inches},
  shape: :ellipse)
```

![Image with ellipse shape mask and cropping](assets/core/images/shape-mask-cropping.png)

Available shape masks: `:ellipse`, `:diamond`, `:round_rect`, `:star5`,
`:star6`, `:star8`, `:heart`, `:triangle`, `:hexagon`, `:octagon`, or any
OOXML preset geometry string.

## Rotation

Rotate an image with the `:rotation` option, specified in degrees clockwise:

```elixir
slide = Podium.add_image(slide, badge,
  x: {4, :inches}, y: {2, :inches},
  width: {3, :inches}, height: {3, :inches},
  rotation: 15)
```

![Image rotated 15 degrees](assets/core/images/image-rotation.png)

## SHA-1 Deduplication

When you add the same image to multiple slides, Podium stores it only once
in the .pptx package. Images are identified by SHA-1 hash of their binary
content. This keeps file sizes small even when a logo or watermark appears
on every slide.

## Image Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:x` | `emu_spec` | required | Horizontal position |
| `:y` | `emu_spec` | required | Vertical position |
| `:width` | `emu_spec` | auto-scaled | Image width |
| `:height` | `emu_spec` | auto-scaled | Image height |
| `:crop` | `keyword` | `nil` | Per-side cropping (`:left`, `:top`, `:right`, `:bottom`) |
| `:rotation` | `number` | `nil` | Rotation in degrees clockwise |
| `:shape` | `atom \| String.t()` | `"rect"` | Image mask shape preset |

---

For using images within slide layouts, see the [Placeholders and Layouts](placeholders.md) guide.
