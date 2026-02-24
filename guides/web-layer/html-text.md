# HTML Text Input

Wrap HTML strings in `{:html, "..."}` anywhere text is accepted — `add_text_box`,
table cells, `set_placeholder`, and auto shapes. Podium parses the HTML into the
same internal paragraph structure.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/html-text.exs` to generate a presentation with all the examples from this guide.

## Basic Formatting

```elixir
slide = Podium.add_text_box(slide,
  {:html, "<p><b>Bold</b>, <i>italic</i>, and <u>underlined</u></p>"},
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {1, :inches})
```

Plain strings without the `{:html, ...}` wrapper still work exactly as before —
no change to existing code.

![Basic HTML formatting: bold, italic, underline, colors, and fonts](assets/web-layer/html-text/basic-formatting.png)

## Supported HTML Elements

### Inline elements

| Element | Effect |
|---------|--------|
| `<b>`, `<strong>` | Bold |
| `<i>`, `<em>` | Italic |
| `<u>` | Underline |
| `<s>`, `<del>` | Strikethrough |
| `<sup>` | Superscript |
| `<sub>` | Subscript |
| `<span>` | Inline container (with `style` attribute) |

### Block elements

| Element | Effect |
|---------|--------|
| `<p>` | Paragraph (with optional `style` for alignment) |
| `<br>` | Line break |
| `<ul>` | Unordered list |
| `<ol>` | Ordered list |
| `<li>` | List item |

## Styled Spans

Use `<span style="...">` to set color, font size, and font family on a run:

```elixir
slide = Podium.add_text_box(slide,
  {:html, ~s(<span style="color: #FF0000; font-size: 24pt; font-family: Arial">Styled text</span>)},
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {1, :inches})
```

### Supported CSS properties

| Property | Example | Maps to |
|----------|---------|---------|
| `color` | `color: #FF0000` or `color: #F00` | `:color` (hex RGB) |
| `font-size` | `font-size: 18pt` | `:font_size` (points) |
| `font-family` | `font-family: Arial` | `:font` |
| `text-align` | `text-align: center` (on `<p>`) | `:alignment` |

> #### Tip {: .tip}
>
> Shorthand hex colors (`#F00`) are expanded automatically to full hex (`FF0000`).

## Paragraphs and Alignment

Each `<p>` becomes a separate paragraph. Set alignment with `text-align`:

```elixir
slide = Podium.add_text_box(slide,
  {:html, """
  <p style="text-align: center"><b>Centered Title</b></p>
  <p style="text-align: left">Left-aligned body text</p>
  """},
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {2, :inches})
```

The `alignment` and `font_size` options on `add_text_box` serve as defaults —
they apply to any paragraph or run that doesn't already specify its own value.

## Lists

Unordered lists (`<ul>`) produce bullet points. Ordered lists (`<ol>`) produce
numbered items. Nesting is supported.

```elixir
slide = Podium.add_text_box(slide,
  {:html, """
  <ul>
    <li>Revenue up 35%</li>
    <li>Customer satisfaction at all-time high</li>
    <ul>
      <li>NPS score improved across regions</li>
    </ul>
  </ul>
  """},
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {3, :inches})
```

![Bullet and numbered lists rendered from HTML](assets/web-layer/html-text/lists.png)

## HTML in Tables

Table cells accept `{:html, "..."}` tuples the same way text boxes do:

```elixir
slide = Podium.add_table(slide, [
  [{:html, "<b>Name</b>"}, {:html, "<b>Status</b>"}],
  ["Alice", {:html, ~s(<span style="color: #228B22"><b>Active</b></span>)}],
  ["Bob", {:html, ~s(<span style="color: #CC0000"><b>On Leave</b></span>)}]
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {3, :inches})
```

![Table with HTML-formatted cells for bold headers and colored status text](assets/web-layer/html-text/html-in-tables.png)

## HTML in Placeholders

Placeholders also accept `{:html, "..."}`:

```elixir
slide =
  Podium.Slide.new(:title_content)
  |> Podium.set_placeholder(:title, {:html, "<b>HTML</b> Title"})
  |> Podium.set_placeholder(:content, {:html, "<ul><li>Point one</li><li>Point two</li></ul>"})
```

## Rich Text API vs HTML

Both approaches produce the same PowerPoint output. Use whichever fits your
workflow better:

```elixir
# HTML — compact, familiar to web developers
Podium.add_text_box(slide,
  {:html, ~s(<p>Revenue grew <span style="color: #228B22"><b>35%</b></span></p>)},
  x: {1, :inches}, y: {1, :inches},
  width: {10, :inches}, height: {1, :inches})

# Rich text API — explicit, no parsing step
Podium.add_text_box(slide, [
  [{"Revenue grew "}, {"35%", bold: true, color: "228B22"}]
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {1, :inches})
```

> #### Tip {: .tip}
>
> HTML text is great when content comes from a web app or CMS. The rich text
> API is better when you need fine-grained control over paragraph spacing,
> line spacing, or custom bullet characters.

---

HTML text input is part of the Web Layer, making it easy to bridge web content
into PowerPoint. For the full text formatting reference, see
[Text and Formatting](../core/text-and-formatting.md).
