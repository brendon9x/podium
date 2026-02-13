# Connectors and Freeform Shapes

Draw lines between elements with `Podium.add_connector/7` and build custom
vector shapes with the `Podium.Freeform` builder.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/connectors-and-freeforms.exs` to generate a presentation with all the examples from this guide.

```elixir
slide = Podium.add_connector(slide, :straight,
  {2, :inches}, {3, :inches}, {6, :inches}, {3, :inches},
  line: [color: "003366", width: {1.5, :pt}])
```

## Connectors

Connectors are lines that run between two coordinate points. Podium supports
three types: `:straight` (direct line), `:elbow` (right-angle routed), and
`:curved` (S-curve).

### Adding Connectors

`Podium.add_connector/7` takes the slide, connector type, start coordinates,
end coordinates, and optional line formatting:

![Flowchart with straight, elbow, and curved connectors](assets/advanced/connectors-and-freeforms/flowchart-connectors.png)

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

slide =
  slide
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {1, :inches}, y: {2, :inches},
    width: {2, :inches}, height: {1, :inches},
    text: "Planning", fill: "4472C4")
  |> Podium.add_auto_shape(:rounded_rectangle,
    x: {6, :inches}, y: {2, :inches},
    width: {2, :inches}, height: {1, :inches},
    text: "Execution", fill: "70AD47")
  |> Podium.add_connector(:straight,
    {3, :inches}, {2.5, :inches}, {6, :inches}, {2.5, :inches},
    line: [color: "000000", width: {1.5, :pt}])
```

Podium automatically calculates flip attributes when the end point is to the
left of or above the start point.

### Elbow and Curved Connectors

```elixir
# Elbow connector with dashed line
slide = Podium.add_connector(slide, :elbow,
  {2, :inches}, {4, :inches}, {7, :inches}, {6, :inches},
  line: [color: "FF0000", width: {2, :pt}, dash_style: :dash])

# Curved connector
slide = Podium.add_connector(slide, :curved,
  {8, :inches}, {2, :inches}, {11, :inches}, {5, :inches},
  line: [color: "5B9BD5", width: {2, :pt}])
```

### Connector Line Formatting

Connector lines accept the same options as shape lines: `:color`, `:width`,
`:dash_style`, and `:fill` (for gradient or pattern lines). When no `:line`
option is provided, connectors use the theme's default styling.

## Freeform Shapes

Freeform shapes let you draw custom vector paths. The `Podium.Freeform` module
uses a builder pattern: create a builder, chain path operations, then add it
to a slide with `Podium.add_freeform/3`.

### Drawing a Triangle

![Freeform triangle and five-pointed star](assets/advanced/connectors-and-freeforms/freeform-triangle-star.png)

```elixir
alias Podium.Freeform

slide =
  Freeform.new({2, :inches}, {4, :inches})
  |> Freeform.line_to({5, :inches}, {1, :inches})
  |> Freeform.line_to({8, :inches}, {4, :inches})
  |> Freeform.close()
  |> Podium.add_freeform(slide, fill: "4472C4", line: "002060")
```

### Path Operations

| Function | Description |
|----------|-------------|
| `Freeform.new(x, y, opts)` | Start a new path at `(x, y)` |
| `Freeform.line_to(fb, x, y)` | Draw a line segment to `(x, y)` |
| `Freeform.move_to(fb, x, y)` | Move without drawing (starts a new contour) |
| `Freeform.close(fb)` | Close the current contour back to its start |
| `Freeform.add_line_segments(fb, vertices, opts)` | Add multiple segments at once |

### Batch Line Segments

Use `Freeform.add_line_segments/3` with a list of `{x, y}` vertices:

```elixir
alias Podium.Freeform

slide =
  Freeform.new({6.67, :inches}, {1.5, :inches})
  |> Freeform.add_line_segments([
    {{4.77, :inches}, {5.5, :inches}},
    {{10.17, :inches}, {3, :inches}},
    {{3.17, :inches}, {3, :inches}},
    {{8.57, :inches}, {5.5, :inches}}
  ], close: true)
  |> Podium.add_freeform(slide, fill: "FFD700", line: "CC9900")
```

### Coordinate Scaling

When working with abstract grid coordinates, use `:scale` to convert to EMU:

```elixir
alias Podium.Freeform

# 1 unit = 0.01 inches (9144 EMU)
fb =
  Freeform.new(0, 0, scale: 9144)
  |> Freeform.line_to(300, 0)
  |> Freeform.line_to(150, 260)
  |> Freeform.close()

slide = Podium.add_freeform(fb, slide,
  origin_x: {2, :inches}, origin_y: {2, :inches}, fill: "ED7D31")
```

For non-square scaling, use `:x_scale` and `:y_scale` instead of `:scale`.

### Multiple Contours

Use `Freeform.move_to/3` to start a new contour within the same shape:

![Multi-contour freeform with rectangular cutout](assets/advanced/connectors-and-freeforms/multi-contour-cutout.png)

```elixir
alias Podium.Freeform

# Square with a rectangular cutout
slide =
  Freeform.new({3, :inches}, {1.5, :inches})
  |> Freeform.add_line_segments([
    {{9, :inches}, {1.5, :inches}},
    {{9, :inches}, {5.5, :inches}},
    {{3, :inches}, {5.5, :inches}}
  ])
  |> Freeform.close()
  |> Freeform.move_to({5, :inches}, {2.5, :inches})
  |> Freeform.add_line_segments([
    {{7, :inches}, {2.5, :inches}},
    {{7, :inches}, {4.5, :inches}},
    {{5, :inches}, {4.5, :inches}}
  ])
  |> Freeform.close()
  |> Podium.add_freeform(slide, fill: "70AD47")
```

### Freeform Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:origin_x` | `emu_spec` | `0` | X offset for the bounding box |
| `:origin_y` | `emu_spec` | `0` | Y offset for the bounding box |
| `:fill` | `fill_spec` | `nil` | Fill color or fill tuple |
| `:line` | `line_spec` | `nil` | Line color or line opts |
| `:rotation` | `number` | `nil` | Rotation in degrees |

---

For embedding video and other media, see the [Video Embedding](video-and-media.md) guide.
