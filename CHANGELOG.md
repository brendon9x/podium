# Changelog

## Unreleased

### Added

- `Podium.from_template/2` builds a presentation on a template package of your
  own, given a path or the bytes of a `.pptx`/`.potx`. The template's masters,
  layouts, theme, media, notes master and slide size are kept as they are, and
  coordinates are not scaled. The template must contain no slides.
- `Podium.add_slide/2` raises when the template has no slide layout at the
  slide's layout index, instead of writing a dangling relationship.

### Changed

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
