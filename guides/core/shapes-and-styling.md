# Shapes and Styling

Add pre-built shapes to your slides with `Podium.add_auto_shape/3`. Podium includes
187 shape presets covering rectangles, arrows, stars, callouts, flowchart symbols,
and more -- each with full control over fills, lines, and rotation.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/shapes-and-styling.exs` to generate a presentation with all the examples from this guide.

```elixir
slide = Podium.add_auto_shape(slide, :rounded_rectangle,
  x: {1, :inches}, y: {2, :inches},
  width: {3, :inches}, height: {1, :inches},
  fill: "4472C4", text: "Status: Active")
```

## Adding Auto Shapes

Use `Podium.add_auto_shape/3` with a preset atom, position, and size:

![Shape gallery with rectangles, ovals, arrows, stars, and more](assets/core/shapes-and-styling/shape-gallery.png)

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs)

slide =
  slide
  |> Podium.add_auto_shape(:rectangle,
    x: {0.5, :inches}, y: {1.5, :inches},
    width: {4, :inches}, height: {2, :inches}, fill: "4472C4")
  |> Podium.add_auto_shape(:oval,
    x: {5.5, :inches}, y: {1.5, :inches},
    width: {2, :inches}, height: {2, :inches}, fill: "ED7D31")
```

### Common Presets

| Category | Presets |
|----------|---------|
| Basic | `:rectangle`, `:rounded_rectangle`, `:oval`, `:diamond`, `:hexagon`, `:octagon` |
| Arrows | `:right_arrow`, `:left_arrow`, `:up_arrow`, `:down_arrow`, `:bent_arrow`, `:chevron` |
| Stars | `:star_4_point`, `:star_5_point`, `:star_6_point`, `:star_8_point`, `:star_12_point` |
| Callouts | `:balloon`, `:oval_callout`, `:rectangular_callout`, `:cloud_callout` |
| Flowchart | `:flowchart_process`, `:flowchart_decision`, `:flowchart_terminator`, `:flowchart_data` |
| Math | `:math_plus`, `:math_minus`, `:math_multiply`, `:math_divide`, `:math_equal` |

Call `Podium.AutoShapeType.all_types/0` for the full sorted list of all 187 presets.

![Solid, gradient, and pattern fills on shapes](assets/core/shapes-and-styling/fill-types.png)

## Fill Types

Every shape accepts a `:fill` option. Podium supports four fill types.

### Solid Fill

Pass an RGB hex string:

```elixir
slide = Podium.add_auto_shape(slide, :rectangle,
  x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {2, :inches}, fill: "FF6347")
```

### Gradient Fill

Pass a `{:gradient, stops, opts}` tuple. Each stop is a `{position, color}` pair
where position ranges from `0` to `100_000`:

```elixir
slide = Podium.add_auto_shape(slide, :rounded_rectangle,
  x: {1, :inches}, y: {1, :inches},
  width: {5, :inches}, height: {2, :inches},
  fill: {:gradient, [{0, "003366"}, {100_000, "66CCFF"}], angle: 5_400_000})
```

The `:angle` option is in 60,000ths of a degree. `5_400_000` is 90 degrees (top to bottom).

### Pattern Fill

Pass a `{:pattern, preset, opts}` tuple. Podium supports all 54 OOXML pattern presets:

```elixir
slide = Podium.add_auto_shape(slide, :rectangle,
  x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {2, :inches},
  fill: {:pattern, :dn_diag, foreground: "4472C4", background: "FFFFFF"})
```

Common presets include `:dn_diag`, `:up_diag`, `:lt_horz`, `:lt_vert`, `:cross`,
`:diag_cross`, `:sm_grid`, `:lg_grid`, `:wave`, `:plaid`, and percentage fills from
`:pct_5` through `:pct_90`. See `Podium.Pattern` for the full list.

### No Fill

Omitting `:fill` on an auto shape lets the theme's default styling apply. Setting
`fill: nil` on a text box explicitly removes the fill, producing a transparent shape.

![Solid, dashed, dotted, and gradient line styles](assets/core/shapes-and-styling/line-styles.png)

## Line Types

The `:line` option controls the shape's outline.

### Solid Line

Pass an RGB hex string for a default-width line, or a keyword list for more control:

```elixir
# Default width
slide = Podium.add_auto_shape(slide, :rectangle,
  x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {2, :inches}, line: "003366")

# Custom width and dash
slide = Podium.add_auto_shape(slide, :oval,
  x: {6, :inches}, y: {1, :inches},
  width: {3, :inches}, height: {3, :inches},
  line: [color: "FF0000", width: {2, :pt}, dash_style: :dash])
```

**Line options:** `:color` (hex string), `:width` (e.g. `{1.5, :pt}`), `:dash_style`

**Dash styles:** `:solid`, `:dash`, `:dot`, `:dash_dot`, `:long_dash`, `:long_dash_dot`,
`:long_dash_dot_dot`, `:sys_dot`, `:sys_dash`, `:sys_dash_dot`, `:sys_dash_dot_dot`

### Gradient and Pattern Lines

Lines can use gradient and pattern fills by passing `:fill` instead of `:color`:

```elixir
slide = Podium.add_auto_shape(slide, :rectangle,
  x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {2, :inches},
  line: [fill: {:gradient, [{0, "FF0000"}, {100_000, "0000FF"}], angle: 5_400_000}])
```

## Rotation

Rotate any shape with `:rotation`, specified in degrees clockwise:

```elixir
slide = Podium.add_auto_shape(slide, :cross,
  x: {5, :inches}, y: {2, :inches},
  width: {2, :inches}, height: {2, :inches}, rotation: 45)
```

## Text Inside Shapes

Add text with the `:text` option. It supports the same plain string and rich text
formats as `Podium.add_text_box/3`:

![Rich text inside shapes with rotation](assets/core/shapes-and-styling/text-in-shapes-rotation.png)

```elixir
slide = Podium.add_auto_shape(slide, :rounded_rectangle,
  x: {2, :inches}, y: {2, :inches},
  width: {4, :inches}, height: {1.5, :inches},
  fill: "003366",
  text: [{[
    {"Revenue: ", color: "FFFFFF"},
    {"$4.2M", bold: true, color: "00FF00"}
  ], alignment: :center}])
```

Shapes also support `:font_size`, `:alignment`, `:auto_size`, and `:word_wrap`.

## Theme Styling

When you omit `:fill` on an auto shape, PowerPoint applies the slide master's theme
colors. This gives shapes a consistent look that matches the presentation's color
scheme. Setting an explicit fill overrides the theme.

## Auto Shape Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:x` | `emu_spec` | required | Horizontal position |
| `:y` | `emu_spec` | required | Vertical position |
| `:width` | `emu_spec` | required | Shape width |
| `:height` | `emu_spec` | required | Shape height |
| `:fill` | `fill_spec` | `nil` | Fill color or fill tuple |
| `:line` | `line_spec` | `nil` | Line color or line opts |
| `:text` | `text_spec` | `nil` | Text content inside shape |
| `:font_size` | `number` | `nil` | Default font size (points) |
| `:alignment` | `atom` | `nil` | Default text alignment |
| `:rotation` | `number` | `nil` | Rotation in degrees clockwise |
| `:auto_size` | `atom` | `nil` | `:none`, `:text_to_fit_shape`, or `:shape_to_fit_text` |
| `:word_wrap` | `boolean` | `true` | Set to `false` for single-line text |
| `:margin_left` | `emu_spec` | `nil` | Left text margin |
| `:margin_right` | `emu_spec` | `nil` | Right text margin |
| `:margin_top` | `emu_spec` | `nil` | Top text margin |
| `:margin_bottom` | `emu_spec` | `nil` | Bottom text margin |

Positions and sizes accept EMU integers or `{value, unit}` tuples where unit is
`:inches`, `:cm`, or `:pt`.

---

For structured data display, see the [Tables](tables.md) guide.
