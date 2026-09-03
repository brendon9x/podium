# Changelog

## Unreleased

### Added

- `Podium.from_template/2` builds a presentation on a template package of your
  own, given a path or the bytes of a `.pptx`/`.potx`. The template's masters,
  layouts, theme, media, notes master and slide size are kept as they are, and
  coordinates are not scaled. The template must contain no slides.
- `Podium.add_slide/2` raises when the template has no slide layout at the
  slide's layout index, instead of writing a dangling relationship.
- `Podium.Template.inspect/1` reports what is in a template package: its slide
  size, its masters, and for every layout the layout's name, its type, the
  master it sits on, and each placeholder's `{type, idx}`, shape name and
  bounding box. Boxes resolve through master inheritance the way PowerPoint
  does, matching the master placeholder by type. Accepts a path, pptx bytes or
  a parts map.
- Placeholders can be addressed by the `{type, idx}` pair inspection reports,
  as well as by the bundled template's names, so a template of your own can be
  filled: `Podium.set_placeholder/3`, `Podium.set_picture_placeholder/3`,
  `Podium.set_chart_placeholder/6` and `Podium.set_table_placeholder/5` all
  take either. Charts and tables placed by `{type, idx}` take their position
  and size from the layout placeholder's box.
- `Podium.OPC.Package.resolve_partname/2` resolves a relationship target
  against the partname of the part that owns it.
- `Podium.Image.dimensions/1` returns the natural size of image data in EMU,
  the size `Podium.Image.new/2` uses when given neither `:width` nor
  `:height`, so callers can fit an image to a region themselves.

### Fixed

- `bold: false` and `italic: false` on a run now write `b="0"` and `i="0"`
  rather than nothing at all. A run that leaves the option out still writes no
  attribute and inherits the placeholder's or the theme's style, but a run that
  asks for regular text inside a placeholder styled bold now gets it, which is
  what a bold lead-in followed by a regular sentence needs.
- `Podium.set_notes/2` keeps the line breaks in the notes it is given. Each
  line becomes its own paragraph in the notes slide, and a blank line becomes
  an empty paragraph, instead of the whole string going into one run where the
  notes pane showed it as a single block.
- A JPEG's pixel density is read from the right offset in its JFIF segment.
  It was read two bytes early, off the version field, so a 96 DPI image was
  taken as 257 DPI across and 96 down and placed at the wrong aspect ratio
  when `add_image` was given neither `:width` nor `:height`. The segment's
  `JFIF` identifier is now checked too, since the bytes it starts with also
  occur inside compressed image data.

### Changed

- `Podium.add_slide/2` validates every placeholder on the slide against the
  layout it sits on, raising when the layout has no placeholder at that idx or
  has one of a different type.
- Footer, date and slide number are emitted at the idx the slide's layout uses
  rather than at fixed 11, 10 and 12, and are skipped for a layout that has no
  such placeholder. The bundled template's layouts still yield 11, 10 and 12.
- A `p:ph` element is written without its `type` attribute when the type is
  `"obj"` and without its `idx` attribute when the idx is 0, matching the OOXML
  defaults. A picture placeholder writes the layout placeholder's own type
  rather than a fixed `"pic"`, so a picture in a content placeholder keeps that
  placeholder's `p:ph`.
- `Podium.Placeholder.new_footer/2`, `new_date/2` and `new_slide_number/1` take
  the idx to emit.
- `Podium.Presentation`'s `placeholder_positions` field is replaced by
  `template_info`, holding the `%Podium.Template{}` inspection of the template
  the presentation was built on.

- `presentation.xml` is now edited in place rather than regenerated, so the
  template's own settings survive. For the bundled template this means
  `notesSz` is the template's 7.5" x 10" portrait page rather than a value
  derived from the slide size.
- PowerPoint's section list is stripped from the presentation, because it
  references slide ids that Podium reissues.
- Content type extensions are matched case-insensitively.

### Removed

- `Podium.OPC.ContentTypes.from_template/0`, replaced by
  `Podium.OPC.ContentTypes.parse/1` over the template's own
  `[Content_Types].xml`.
- `Podium.OPC.Package.read_template/0`, renamed to `read_default_template/0`.
- `Podium.TemplatePlaceholders`, replaced by `Podium.Template.inspect/1`, which
  resolves boxes for every placeholder on every layout rather than only for the
  bundled template's named ones.

## 0.2.1

### Fixed

- Notes slides numbered by parent slide index instead of sequentially

### Added

- Markdown documentation guides for ex_doc

## 0.2.0

### Added

- Color options for chart axes: `:color` (tick label text), `:line_color` (axis line)
- Color options for gridlines: `:major_gridlines_color`, `:minor_gridlines_color`
- Color option for data labels: `:color`
- Data label `:font_size` support

## 0.1.0

Initial release.
