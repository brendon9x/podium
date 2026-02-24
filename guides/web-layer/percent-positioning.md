# Percent Positioning

Position and size elements as percentages of slide dimensions using `{value, :percent}`
tuples. This is useful when you want layout that adapts to different slide sizes
without manually calculating EMU values.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/percent-layout.exs` to generate a presentation with all the examples from this guide.

## Basic Usage

Use `{value, :percent}` anywhere you'd normally pass a position or size dimension:

```elixir
slide =
  Podium.Slide.new()
  |> Podium.add_text_box("Centered",
    x: {25, :percent},
    y: {25, :percent},
    width: {50, :percent},
    height: {50, :percent},
    alignment: :center
  )
```

This places a text box at 25% from the left, 25% from the top, spanning 50% of the
slide in both directions — regardless of whether the slide is 16:9, 4:3, or a custom size.

## How It Works

Percent values are resolved against the slide's dimensions:

- `:x` and `:width` resolve against the slide width (default 12,192,000 EMU for 16:9)
- `:y` and `:height` resolve against the slide height (default 6,858,000 EMU for 16:9)

Resolution happens when you call `add_text_box`, `add_image`, `add_chart`, etc.
By the time the element is stored on the slide, all values are plain EMU integers —
the rest of the pipeline doesn't need to know about percentages.

## Mixing Units

You can freely mix percent with other units in the same call:

```elixir
slide = Podium.add_text_box(slide, "Mixed units",
  x: {10, :percent},        # 10% from the left
  y: {1, :inches},           # 1 inch from the top
  width: {80, :percent},     # 80% of slide width
  height: {2, :inches}       # fixed height
)
```

## All Element Types

Percent positioning works with every element type that accepts position/size options:

```elixir
# Text boxes
slide = Podium.add_text_box(slide, "Text",
  x: {5, :percent}, y: {5, :percent},
  width: {90, :percent}, height: {10, :percent})

# Auto shapes
slide = Podium.add_auto_shape(slide, :rectangle,
  x: {10, :percent}, y: {20, :percent},
  width: {80, :percent}, height: {60, :percent})

# Charts
slide = Podium.add_chart(slide, :column_clustered, chart_data,
  x: {5, :percent}, y: {15, :percent},
  width: {90, :percent}, height: {75, :percent})

# Images
slide = Podium.add_image(slide, image_binary,
  x: {10, :percent}, y: {10, :percent},
  width: {30, :percent}, height: {40, :percent})

# Tables
slide = Podium.add_table(slide, rows,
  x: {5, :percent}, y: {20, :percent},
  width: {90, :percent}, height: {70, :percent})

# Connectors
slide = Podium.add_connector(slide, :straight,
  {10, :percent}, {50, :percent},   # begin point
  {90, :percent}, {50, :percent},   # end point
  line: "000000")

# Videos
slide = Podium.add_movie(slide, video_binary,
  x: {10, :percent}, y: {10, :percent},
  width: {80, :percent}, height: {80, :percent})
```

## Custom Slide Dimensions

When using custom slide dimensions, percent values resolve against those dimensions:

```elixir
# 4:3 presentation
prs = Podium.new(slide_width: {10, :inches}, slide_height: {7.5, :inches})

slide =
  Podium.Slide.new()
  |> Podium.add_text_box("Half-width box",
    x: {25, :percent},
    y: {25, :percent},
    width: {50, :percent},   # 50% of 10 inches = 5 inches
    height: {50, :percent}   # 50% of 7.5 inches = 3.75 inches
  )

prs |> Podium.add_slide(slide) |> Podium.save("output.pptx")
```

When a slide is added to a presentation, the presentation's dimensions are stamped
onto the slide so that subsequent operations (via `put_slide`) use the correct
reference dimensions.

> #### Percent values resolve at `add_*` time {: .warning}
>
> Percent positions are converted to EMU when you call `add_text_box`, `add_image`,
> etc. — not when the slide is added to the presentation. If you're using custom
> dimensions, pass them to `Slide.new/2` so the slide knows the correct reference
> size before you add percent-positioned elements:
>
> ```elixir
> slide =
>   Podium.Slide.new(:blank, slide_width: {10, :inches}, slide_height: {7.5, :inches})
>   |> Podium.add_text_box("Correct", x: {50, :percent}, ...)
> ```

## Limitations

- **Table column widths and row heights** — The `:col_widths` and `:row_heights`
  options on `add_table` do not support percent values, since the semantics are
  ambiguous (percent of slide width? table width?). The table's overall x/y/width/height
  do support percent.

- **Freeform shapes** — `add_freeform` uses its own coordinate system with scale
  factors, so percent positioning does not apply to freeform path coordinates.

---

Percent positioning is part of the Web Layer — it brings the familiar concept of
percentage-based layout from CSS to PowerPoint generation. For more on units, see
the Units section in the [README](../../README.md).
