# Text and Formatting

Add text to slides with `Podium.add_text_box/3`. Text can be a plain string for
simple cases or a structured list for rich formatting with multiple fonts, colors,
and paragraph styles.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/text-and-formatting.exs` to generate a presentation with all the examples from this guide.

```elixir
slide = Podium.add_text_box(slide, "Quarterly Results",
  x: {1, :inches}, y: {1, :inches},
  width: {8, :inches}, height: {1, :inches},
  font_size: 24)
```

## Plain Text

The fastest way to add text is with a plain string. Podium wraps it in a single
paragraph with a single run, and you control the defaults through text box options.

```elixir
slide = Podium.add_text_box(slide, "Revenue grew 35% year-over-year",
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {0.8, :inches},
  font_size: 18, alignment: :center)
```

The `:font_size` and `:alignment` options on the text box apply to every paragraph
and run inside it. This is all you need for headings, labels, and single-line text.

> #### Tip {: .tip}
>
> Start with plain strings. Only use the rich text format when you need
> per-run formatting or per-paragraph alignment.

## The Text Hierarchy

Text in Podium follows a hierarchy that mirrors the OOXML specification:

- **Presentation** contains slides
- **Slide** contains text boxes (and other shapes)
- **Text box** contains one or more **paragraphs**
- **Paragraph** contains one or more **runs**
- **Run** is a contiguous span of text with uniform formatting

When you pass a plain string to `add_text_box/3`, Podium creates one paragraph
with one run. When you need more control, you provide a list of paragraphs, each
containing a list of runs.

## Rich Text

Rich text is a list of paragraphs. Each paragraph is a list of runs. Each run is
either a plain string or a `{text, options}` tuple.

```elixir
slide = Podium.add_text_box(slide, [
  [{"Q1 Revenue Report", bold: true, font_size: 32, color: "003366"}],
  [{"Prepared by ", font_size: 14}, {"Engineering", bold: true, italic: true}]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {2, :inches})
```

![Mixed formatting with bold, italic, colors, and sizes](assets/core/text-and-formatting/mixed-formatting.png)

The first paragraph has one bold, blue, 32pt run. The second paragraph has two
runs: a plain 14pt run and a bold italic run. Each paragraph renders on its own
line.

### Paragraph Options

Wrap a paragraph's run list and options in a tuple to set paragraph-level formatting:

```elixir
slide = Podium.add_text_box(slide, [
  {[{"Executive Summary", bold: true, font_size: 28}], alignment: :center, space_after: 12},
  {[{"Key metrics improved across all regions."}], alignment: :left, line_spacing: 1.5}
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {3, :inches})
```

| Option | Type | Description |
|--------|------|-------------|
| `:alignment` | `:left \| :center \| :right \| :justify` | Horizontal text alignment |
| `:line_spacing` | `number` | Line spacing multiplier (e.g., `1.5` for 150%) |
| `:space_before` | `number` | Space before the paragraph in points |
| `:space_after` | `number` | Space after the paragraph in points |
| `:bullet` | `boolean \| :number \| String.t()` | Bullet type (see [Bullets](#bullets-and-numbered-lists)) |
| `:level` | `integer` | 0-based indent level for bullets |

## Run-Level Formatting

Each run can carry its own formatting options. These override any defaults set on
the text box.

```elixir
slide = Podium.add_text_box(slide, [
  [
    {"Normal text "},
    {"bold", bold: true},
    {" and ", font_size: 14},
    {"red italic", italic: true, color: "CC0000"}
  ]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {1, :inches})
```

| Option | Type | Description |
|--------|------|-------------|
| `:bold` | `boolean` | Bold text |
| `:italic` | `boolean` | Italic text |
| `:underline` | `atom \| boolean` | Underline style (see [Underline Styles](#underline-styles)) |
| `:strikethrough` | `boolean` | Strikethrough text |
| `:superscript` | `boolean` | Raise text as superscript |
| `:subscript` | `boolean` | Lower text as subscript |
| `:font_size` | `number` | Font size in points |
| `:color` | `String.t()` | Hex RGB color, e.g. `"FF0000"` |
| `:font` | `String.t()` | Font family name, e.g. `"Arial"` |
| `:lang` | `String.t()` | Language tag, e.g. `"en-US"`, `"pl-PL"` |
| `:hyperlink` | various | Link target (see [Hyperlinks and Click Actions](hyperlinks-and-actions.md)) |

### Superscript and Subscript

Use `:superscript` and `:subscript` for mathematical notation, chemical formulas,
and footnote references:

```elixir
slide = Podium.add_text_box(slide, [
  [{"E = mc", font_size: 18}, {"2", font_size: 12, superscript: true}],
  [{"H", font_size: 18}, {"2", font_size: 12, subscript: true}, {"O", font_size: 18}]
], x: {1, :inches}, y: {1, :inches},
   width: {6, :inches}, height: {1.5, :inches})
```

![Superscript, subscript, and underline styles](assets/core/text-and-formatting/superscript-underlines.png)

### Underline Styles

Podium supports all 18 OOXML underline styles. Pass `true` or `:single` for the
standard underline, or use a specific style atom:

| Atom | Appearance |
|------|------------|
| `:single` (or `true`) | Single line |
| `:double` | Double line |
| `:heavy` | Thick single line |
| `:dotted` | Dotted |
| `:dotted_heavy` | Thick dotted |
| `:dash` | Dashed |
| `:dash_heavy` | Thick dashed |
| `:dash_long` | Long dashed |
| `:dash_long_heavy` | Thick long dashed |
| `:dot_dash` | Dash-dot |
| `:dot_dash_heavy` | Thick dash-dot |
| `:dot_dot_dash` | Dash-dot-dot |
| `:dot_dot_dash_heavy` | Thick dash-dot-dot |
| `:wavy` | Wavy |
| `:wavy_heavy` | Thick wavy |
| `:wavy_double` | Double wavy |
| `:words` | Words only (spaces not underlined) |

```elixir
slide = Podium.add_text_box(slide, [
  [
    {"Single", underline: :single, font_size: 14},
    {"  Double", underline: :double, font_size: 14},
    {"  Wavy", underline: :wavy, font_size: 14}
  ]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {0.6, :inches})
```

## Bullets and Numbered Lists

Add bullet points by setting `:bullet` on a paragraph. Use `:level` to create
nested items.

```elixir
slide = Podium.add_text_box(slide, [
  {["Revenue up 35% year-over-year"], bullet: true},
  {["North America grew fastest"], bullet: true, level: 1},
  {["APAC close behind"], bullet: true, level: 1},
  {["Customer satisfaction at all-time high"], bullet: true}
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {3, :inches})
```

![Bullet points with nested levels and numbered list](assets/core/text-and-formatting/bullets-and-numbered.png)

### Numbered Lists

Pass `bullet: :number` for auto-numbered items:

```elixir
slide = Podium.add_text_box(slide, [
  {["Review quarterly data"], bullet: :number},
  {["Identify growth opportunities"], bullet: :number},
  {["Present findings to board"], bullet: :number}
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {2, :inches})
```

### Custom Bullet Characters

Pass any string to `:bullet` to use a custom character:

```elixir
{["Action item on track"], bullet: "-->"}
{["Hiring plan complete"], bullet: "-->"}
```

## Line Breaks

There are two ways to insert a line break within a single paragraph.

**Newline in a string** -- Podium automatically splits the text at `\n` and inserts
line breaks between segments:

```elixir
slide = Podium.add_text_box(slide, "Line 1\nLine 2\nLine 3",
  x: {1, :inches}, y: {1, :inches},
  width: {4, :inches}, height: {2, :inches})
```

**`:line_break` atom** -- Insert an explicit break in a rich text run list:

```elixir
slide = Podium.add_text_box(slide, [
  [
    {"First line", bold: true},
    :line_break,
    {"Second line", color: "4472C4"}
  ]
], x: {1, :inches}, y: {1, :inches},
   width: {6, :inches}, height: {1.5, :inches})
```

Both methods produce the same OOXML `<a:br/>` element. The difference is that
`:line_break` lets you change formatting between lines within a single paragraph,
while `\n` keeps the same run formatting on both sides.

## Text Box Options

Beyond position and size, text boxes accept several formatting options that apply
to the entire text frame.

```elixir
slide = Podium.add_text_box(slide, "Padded and styled",
  x: {1, :inches}, y: {1, :inches},
  width: {6, :inches}, height: {2, :inches},
  fill: "E8EDF2",
  line: [color: "003366", width: {1, :pt}],
  margin_left: {0.3, :inches},
  margin_right: {0.3, :inches},
  margin_top: {0.15, :inches},
  margin_bottom: {0.15, :inches},
  alignment: :center,
  font_size: 16)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:x` | `emu_spec` | required | Horizontal position |
| `:y` | `emu_spec` | required | Vertical position |
| `:width` | `emu_spec` | required | Width |
| `:height` | `emu_spec` | required | Height |
| `:fill` | `fill_spec` | `nil` | Shape fill (solid, gradient, or pattern) |
| `:line` | `line_spec` | `nil` | Shape border |
| `:rotation` | `number` | `nil` | Rotation in degrees |
| `:alignment` | `atom` | `nil` | Default text alignment for all paragraphs |
| `:font_size` | `number` | `nil` | Default font size for all runs (points) |
| `:margin_left` | `emu_spec` | `nil` | Left internal margin |
| `:margin_right` | `emu_spec` | `nil` | Right internal margin |
| `:margin_top` | `emu_spec` | `nil` | Top internal margin |
| `:margin_bottom` | `emu_spec` | `nil` | Bottom internal margin |
| `:auto_size` | `atom` | `nil` | Auto-size mode |
| `:word_wrap` | `boolean` | `true` | Set to `false` to disable word wrapping |

### Auto-Size Modes

Control how the text box and its text interact when the content grows:

| Mode | Description |
|------|-------------|
| `:none` | No auto-sizing. Text may overflow the box. |
| `:text_to_fit_shape` | Shrink the font to fit the text inside the shape. |
| `:shape_to_fit_text` | Grow the shape to fit the text content. |

```elixir
slide = Podium.add_text_box(slide, "This text shrinks to fit",
  x: {1, :inches}, y: {1, :inches},
  width: {3, :inches}, height: {0.5, :inches},
  auto_size: :text_to_fit_shape)
```

## Putting It All Together

Here is a complete example combining plain text, rich paragraphs, bullets, spacing,
and formatting:

```elixir
prs = Podium.new()
slide = Podium.Slide.new()

slide =
  slide
  |> Podium.add_text_box(
    [
      {[{"Q4 2025 Summary", bold: true, font_size: 28, color: "003366"}],
       alignment: :center, space_after: 12}
    ],
    x: {0.5, :inches}, y: {0.3, :inches},
    width: {12, :inches}, height: {0.8, :inches},
    fill: {:gradient, [{0, "E8EDF2"}, {100_000, "FFFFFF"}], angle: 5_400_000})
  |> Podium.add_text_box(
    [
      {[{"Key Results", bold: true, font_size: 20}], space_after: 6},
      {["Revenue grew 35% to $18.2M"], bullet: true},
      {["North America led growth"], bullet: true, level: 1},
      {["APAC expanded 42%"], bullet: true, level: 1},
      {["Operating margin improved to 28%"], bullet: true},
      {[{"Next Steps", bold: true, font_size: 20}], space_before: 12, space_after: 6},
      {["Finalize APAC expansion plan"], bullet: :number},
      {["Launch self-service portal"], bullet: :number},
      {["Target 95% satisfaction by Q2"], bullet: :number}
    ],
    x: {0.5, :inches}, y: {1.5, :inches},
    width: {12, :inches}, height: {5, :inches})

prs = Podium.add_slide(prs, slide)
Podium.save(prs, "text_demo.pptx")
```

![Complete text example with gradient header bar and bulleted content](assets/core/text-and-formatting/putting-it-together.png)

---

Text formatting is the foundation for every slide. Next, learn how to present
structured data with [Tables](tables.md), or add visual elements with
[Shapes and Styling](shapes-and-styling.md).
