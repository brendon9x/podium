# CSS Styling

Use CSS-style strings to position, size, and style elements on a slide, as an alternative to
Elixir keyword opts. This brings familiar CSS syntax to PowerPoint generation.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/css-styling.exs` to generate a presentation with all the examples from this guide.

## Basic Usage

Pass a `style:` string anywhere you'd normally pass position/size options:

```elixir
slide =
  Podium.Slide.new()
  |> Podium.add_text_box("Centered content",
    style: "left: 10%; top: 5%; width: 80%; height: 15%; text-align: center; vertical-align: middle"
  )
```

This is equivalent to:

```elixir
slide =
  Podium.Slide.new()
  |> Podium.add_text_box("Centered content",
    x: {10, :percent},
    y: {5, :percent},
    width: {80, :percent},
    height: {15, :percent},
    alignment: :center,
    anchor: :middle
  )
```

![Basic percent positioning with style:](assets/web-layer/css-styling/basic-percent.png)

## Property Mapping

### Position and Size

| CSS Property | Podium Option | Description |
|-------------|---------------|-------------|
| `left`      | `:x`          | Horizontal position from left edge |
| `top`       | `:y`          | Vertical position from top edge |
| `width`     | `:width`      | Element width |
| `height`    | `:height`     | Element height |

### Text and Alignment

| CSS Property      | Podium Option | Values |
|------------------|---------------|--------|
| `text-align`     | `:alignment`  | `left`, `center`, `right`, `justify` |
| `vertical-align` | `:anchor`     | `top`, `middle`, `bottom` |

### Background

| CSS Property  | Podium Option | Values |
|--------------|---------------|--------|
| `background` | `:fill`       | Hex color: `#FF0000` or `FF0000` |

### Padding (Text Margins)

| CSS Property     | Podium Option    | Notes |
|-----------------|------------------|-------|
| `padding`       | all `:margin_*`  | Single value only — sets all four sides |
| `padding-left`  | `:margin_left`   | |
| `padding-right` | `:margin_right`  | |
| `padding-top`   | `:margin_top`    | |
| `padding-bottom`| `:margin_bottom` | |

## Supported Units

All Podium units are available in `style:` strings:

| CSS Syntax | Podium Equivalent | Example |
|-----------|-------------------|---------|
| `10%`     | `{10, :percent}`  | `"left: 10%"` |
| `2in`     | `{2, :inches}`    | `"width: 2in"` |
| `5cm`     | `{5, :cm}`        | `"height: 5cm"` |
| `72pt`    | `{72, :pt}`       | `"top: 72pt"` |
| `914400`  | `914400` (EMU)    | `"left: 914400"` |

You can mix units within a single style string:

```elixir
slide = Podium.add_text_box(slide, "Mixed units",
  style: "left: 1in; top: 10%; width: 80%; height: 2in"
)
```

![Mixed units in a style: string](assets/web-layer/css-styling/mixed-units.png)

## Non-Positional Properties

The `style:` string can include alignment, background, and padding alongside positioning:

```elixir
# All-in-one style string
slide = Podium.add_text_box(slide, "Styled content",
  style: "left: 10%; top: 5%; width: 80%; height: 15%; text-align: center; vertical-align: middle; background: #003366; padding: 12pt"
)

# Equivalent keyword opts
slide = Podium.add_text_box(slide, "Styled content",
  x: {10, :percent}, y: {5, :percent}, width: {80, :percent}, height: {15, :percent},
  alignment: :center, anchor: :middle, fill: "003366",
  margin_left: {12, :pt}, margin_right: {12, :pt}, margin_top: {12, :pt}, margin_bottom: {12, :pt}
)
```

![Non-positional CSS properties — alignment, background, padding](assets/web-layer/css-styling/non-positional-properties.png)

## Mixing `style:` with Explicit Options

When both `style:` and explicit opts are provided, explicit opts take precedence.
This lets you use `style:` for defaults and override specific values:

```elixir
# style: provides positioning + alignment, but alignment is overridden
slide = Podium.add_text_box(slide, "Override example",
  style: "left: 10%; top: 5%; width: 80%; height: 15%; text-align: center",
  x: {50, :percent},     # overrides left: 10%
  alignment: :right       # overrides text-align: center
)
```

## All Element Types

The `style:` option works with every element that accepts position/size options:

```elixir
# Text boxes
slide = Podium.add_text_box(slide, "Text",
  style: "left: 5%; top: 5%; width: 90%; height: 10%")

# Auto shapes
slide = Podium.add_auto_shape(slide, :rectangle,
  style: "left: 10%; top: 20%; width: 80%; height: 60%")

# Charts
slide = Podium.add_chart(slide, :column_clustered, chart_data,
  style: "left: 5%; top: 15%; width: 90%; height: 75%")

# Images
slide = Podium.add_image(slide, image_binary,
  style: "left: 10%; top: 10%; width: 30%; height: 40%")

# Tables
slide = Podium.add_table(slide, rows,
  style: "left: 5%; top: 20%; width: 90%; height: 70%")

# Videos
slide = Podium.add_movie(slide, video_binary,
  style: "left: 10%; top: 10%; width: 80%; height: 80%")
```

Connectors are not supported — CSS box model doesn't map to begin/end points.
Continue using `{value, :percent}` tuples with connectors directly.

## Comparison with Tuple Approach

Both approaches produce identical output. Choose whichever reads better for your use case:

```elixir
# CSS style — compact, familiar to web developers
Podium.add_text_box(slide, text,
  style: "left: 10%; top: 5%; width: 80%; height: 15%; text-align: center")

# Tuple opts — explicit, mixable with other units
Podium.add_text_box(slide, text,
  x: {10, :percent}, y: {5, :percent},
  width: {80, :percent}, height: {15, :percent},
  alignment: :center)
```

The `style:` option is parsed by `Podium.CSS.parse_style/1` and merged into
the opts before resolution — the rest of the pipeline is identical.

---

CSS styling is part of the Web Layer — it brings familiar web conventions to
PowerPoint generation. See also [Percent Positioning](percent-positioning.md) for the
underlying `{value, :percent}` system and [HTML Text](html-text.md) for HTML formatting.
