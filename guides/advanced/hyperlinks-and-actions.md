# Hyperlinks and Click Actions

Add interactive links and navigation actions to text runs. Podium supports URL
hyperlinks, email links, tooltips, and slide navigation actions that work during
a slideshow.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/hyperlinks-and-actions.exs` to generate a presentation with all the examples from this guide.

```elixir
slide = Podium.add_text_box(slide, [
  [{"Visit our website", color: "0563C1", underline: true,
    hyperlink: "https://example.com"}]
], x: {1, :inches}, y: {1, :inches},
   width: {6, :inches}, height: {0.5, :inches})
```

## URL Hyperlinks

Add a hyperlink to any text run with the `:hyperlink` option. Pass a URL string
to create a standard web link:

![URL and email hyperlinks with tooltips](assets/advanced/hyperlinks-and-actions/url-email-links.png)

```elixir
slide = Podium.add_text_box(slide, [
  [
    {"Read the full report: ", font_size: 16},
    {"Q4 Analysis", font_size: 16, color: "0563C1", underline: true,
     hyperlink: "https://reports.example.com/q4-2025"}
  ]
], x: {1, :inches}, y: {1, :inches},
   width: {10, :inches}, height: {0.6, :inches})
```

The hyperlink activates when the viewer clicks the text during a slideshow.
PowerPoint does not auto-style hyperlinks -- you control the color and underline
through run formatting options.

## Email Links

Pass a `mailto:` URL to create an email link:

```elixir
slide = Podium.add_text_box(slide, [
  [
    {"Contact us: ", font_size: 16},
    {"support@acme.example.com", font_size: 16, color: "0563C1", underline: true,
     hyperlink: "mailto:support@acme.example.com"}
  ]
], x: {1, :inches}, y: {1, :inches},
   width: {8, :inches}, height: {0.6, :inches})
```

## Hyperlinks with Tooltips

Pass a keyword list with `:url` and `:tooltip` to show a tooltip on hover:

```elixir
slide = Podium.add_text_box(slide, [
  [{"example.com", color: "0563C1", underline: true,
    hyperlink: [url: "https://example.com", tooltip: "Visit Example.com"]}]
], x: {1, :inches}, y: {1, :inches},
   width: {4, :inches}, height: {0.5, :inches})
```

The tooltip appears when the viewer hovers over the link text in the slideshow.

## Slide Navigation Actions

Navigate between slides during a slideshow using action atoms. These create
internal PowerPoint actions that don't require external relationships.

```elixir
# Navigate to the next slide
{"Next", hyperlink: :next_slide}

# Navigate to the previous slide
{"Back", hyperlink: :previous_slide}

# Jump to the first slide
{"Start", hyperlink: :first_slide}

# Jump to the last slide
{"End", hyperlink: :last_slide}

# End the slideshow
{"Exit", hyperlink: :end_show}
```

### Navigation Example

![Navigation buttons with previous, next, and end show actions](assets/advanced/hyperlinks-and-actions/navigation-buttons.png)

```elixir
prs = Podium.new()
{prs, slide1} = Podium.add_slide(prs)
{prs, slide2} = Podium.add_slide(prs)

slide1 =
  slide1
  |> Podium.add_text_box(
    [[{"Next Slide -->", bold: true, hyperlink: :next_slide}]],
    x: {1, :inches}, y: {1, :inches},
    width: {3, :inches}, height: {0.5, :inches})
  |> Podium.add_text_box(
    [[{"End Show", bold: true, color: "CC0000", hyperlink: :end_show}]],
    x: {5, :inches}, y: {1, :inches},
    width: {3, :inches}, height: {0.5, :inches})

slide2 = Podium.add_text_box(slide2,
  [[{"<-- Previous", bold: true, hyperlink: :previous_slide}]],
  x: {1, :inches}, y: {1, :inches},
  width: {3, :inches}, height: {0.5, :inches})

prs = prs |> Podium.put_slide(slide1) |> Podium.put_slide(slide2)
```

## Jumping to a Specific Slide

Link to a specific slide by passing a `{:slide, slide_struct}` tuple. Use the
slide struct returned by `Podium.add_slide/2`:

```elixir
prs = Podium.new()
{prs, intro_slide} = Podium.add_slide(prs)
{prs, data_slide} = Podium.add_slide(prs)
{prs, nav_slide} = Podium.add_slide(prs)

nav_slide = Podium.add_text_box(nav_slide, [
  [{"Go to Introduction", color: "0563C1", underline: true,
    hyperlink: {:slide, intro_slide}}],
  [{"Go to Data Analysis", color: "0563C1", underline: true,
    hyperlink: {:slide, data_slide}}]
], x: {1, :inches}, y: {1, :inches},
   width: {6, :inches}, height: {1, :inches})

prs = Podium.put_slide(prs, nav_slide)
```

Podium creates an internal slide-to-slide relationship in the PPTX package. The
link activates during the slideshow and jumps directly to the target slide.

## Hyperlinks in Auto Shapes

You can create interactive buttons by combining hyperlinks with auto shapes. Add
the hyperlink on a text run inside the shape's `:text` option:

```elixir
slide = Podium.add_auto_shape(slide, :rounded_rectangle,
  x: {1, :inches}, y: {2, :inches},
  width: {3, :inches}, height: {0.8, :inches},
  fill: "4472C4",
  text: [{[{"Next Section", bold: true, color: "FFFFFF",
            hyperlink: :next_slide}], alignment: :center}])
```

This creates a blue rounded rectangle that acts as a navigation button.

## Hyperlinks in Placeholders

Hyperlinks also work inside placeholder text:

```elixir
{prs, slide} = Podium.add_slide(prs, layout: :title_content)

slide = Podium.set_placeholder(slide, :content, [
  [{"Click here for details", color: "0563C1", underline: true,
    hyperlink: "https://reports.example.com"}]
])
```

## Where Hyperlinks Work

| Context | Supported |
|---------|-----------|
| Text box runs | Yes |
| Placeholder text runs | Yes |
| Auto shape text runs | Yes |
| Table cells | No |
| Chart labels | No |
| Image shapes | No |

Hyperlinks are a run-level feature. They work anywhere you can provide a text run
with formatting options.

## Table of Contents Example

Combine slide jumps to build a clickable table of contents:

![Clickable table of contents with slide jump links](assets/advanced/hyperlinks-and-actions/table-of-contents.png)

```elixir
prs = Podium.new()
{prs, toc_slide} = Podium.add_slide(prs)
{prs, finance_slide} = Podium.add_slide(prs)
{prs, ops_slide} = Podium.add_slide(prs)
{prs, summary_slide} = Podium.add_slide(prs)

toc_slide =
  toc_slide
  |> Podium.add_text_box(
    [{[{"Table of Contents", bold: true, font_size: 28}], alignment: :center}],
    x: {2, :inches}, y: {0.5, :inches},
    width: {9, :inches}, height: {0.8, :inches})
  |> Podium.add_text_box([
    [{"1. Financial Results", font_size: 18, color: "0563C1",
      underline: true, hyperlink: {:slide, finance_slide}}],
    [{"2. Operations Update", font_size: 18, color: "0563C1",
      underline: true, hyperlink: {:slide, ops_slide}}],
    [{"3. Summary", font_size: 18, color: "0563C1",
      underline: true, hyperlink: {:slide, summary_slide}}]
  ], x: {2, :inches}, y: {1.8, :inches},
     width: {9, :inches}, height: {3, :inches})

prs = Podium.put_slide(prs, toc_slide)
```

Each line jumps directly to the corresponding slide during the slideshow.

---

With hyperlinks and navigation, your presentations become interactive. For
reusable patterns that keep styling consistent across slides, see
[Styling Patterns](styling-patterns.md).
