# Slide Backgrounds and Speaker Notes

Customize slide appearance with the `:background` option on `Podium.add_slide/2`,
and add presenter notes with `Podium.set_notes/2`.

> #### Try it yourself {: .tip}
>
> Run `mix run demos/slide-backgrounds-and-notes.exs` to generate a presentation with all the examples from this guide.

```elixir
{prs, slide} = Podium.add_slide(prs, background: "003366")
slide = Podium.set_notes(slide, "Discuss Q1 results and highlight the 20% growth.")
```

## Slide Backgrounds

By default, slides follow the slide master's background -- typically white.
Override this per-slide by passing the `:background` option to `Podium.add_slide/2`.

### Solid Color Background

Pass an RGB hex string:

![Dark solid color background with white text](assets/advanced/slide-backgrounds-and-notes/solid-dark-background.png)

```elixir
{prs, slide} = Podium.add_slide(prs, background: "1A1A2E")

slide = Podium.add_text_box(slide, "Dark Theme Slide",
  x: {3, :inches}, y: {3, :inches},
  width: {7, :inches}, height: {1.5, :inches},
  font_size: 36, alignment: :center)
```

### Gradient Background

Pass a `{:gradient, stops, opts}` tuple:

![Deep blue gradient background](assets/advanced/slide-backgrounds-and-notes/gradient-background.png)

```elixir
{prs, slide} = Podium.add_slide(prs,
  background: {:gradient, [{0, "000428"}, {100_000, "004E92"}], angle: 5_400_000})
```

The `:angle` option is in 60,000ths of a degree. `5_400_000` produces a top-to-bottom
gradient.

### Pattern Background

Pass a `{:pattern, preset, opts}` tuple:

![Diagonal pattern background](assets/advanced/slide-backgrounds-and-notes/pattern-background.png)

```elixir
{prs, slide} = Podium.add_slide(prs,
  background: {:pattern, :lt_dn_diag, foreground: "CCCCCC", background: "FFFFFF"})
```

All 54 pattern presets from `Podium.Pattern` are available. See the
[Shapes and Styling](shapes-and-styling.md) guide for common presets.

### Picture Background

Pass a `{:picture, binary}` tuple with the image data:

![Picture background with text overlay](assets/advanced/slide-backgrounds-and-notes/picture-background.png)

```elixir
bg_image = File.read!("conference_hall.jpg")

{prs, slide} = Podium.add_slide(prs, background: {:picture, bg_image})

slide = Podium.add_text_box(slide,
  [{[{"Annual Conference 2026", bold: true, font_size: 44, color: "FFFFFF"}],
    alignment: :center}],
  x: {1, :inches}, y: {2.5, :inches},
  width: {11, :inches}, height: {2, :inches})
```

### Default Behavior

When no `:background` option is set, the slide inherits the slide master's
background. This is the standard behavior for consistent-looking presentations.

## Speaker Notes

Speaker notes appear in PowerPoint's Presenter View and in the notes pane
below the slide editor. Add them with `Podium.set_notes/2`:

```elixir
prs = Podium.new()
{prs, slide} = Podium.add_slide(prs, layout: :title_content)
slide = Podium.set_placeholder(slide, :title, "Q1 Financial Results")

slide = Podium.set_notes(slide,
  "Key talking points:\n" <>
  "- Revenue grew 20% quarter-over-quarter\n" <>
  "- New enterprise accounts: 15\n" <>
  "- Churn rate decreased to 2.1%")

prs = Podium.put_slide(prs, slide)
```

Notes text is a plain string. Use `\n` for line breaks within the notes.

### Notes in Presenter View

Speaker notes appear below the current slide in Presenter View, which is
visible only to the presenter (not the audience). They also print when you
select "Notes Pages" in PowerPoint's print settings.

> #### Tip {: .tip}
>
> Use speaker notes to store talking points, data sources, and context
> that the audience doesn't need to see on the slide itself.

Podium automatically creates the notes master parts in the .pptx package
the first time `set_notes/2` is called on any slide.

---

For end-to-end examples that combine backgrounds, notes, and other features,
see the [Building a Report](building-a-report.md) recipe.
