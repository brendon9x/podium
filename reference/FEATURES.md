# Feature Tracker

Comprehensive list of Podium's features. Podium uses [python-pptx](https://github.com/scanny/python-pptx) as its reference implementation.

## Presentations and Slides

| Feature | Podium |
|---------|--------|
| New presentation | `Podium.new/1` with configurable options |
| Presentation from template | `Podium.from_template/2` builds on any slide-less pptx/potx (path or binary): keeps its masters, layouts, theme, media, notes master, slide size and notes size; no coordinate scaling |
| Template inspection | `Podium.Template.inspect/1` reports slide size, masters, and per layout its name, type, master and placeholders with `{type, idx}`, shape name and box resolved through master inheritance |
| Save | To file or to memory (binary) |
| Slide dimensions | 16:9 default, configurable width/height in any unit |
| Slide layouts | All 11: blank, title_slide, title_content, section_header, two_content, comparison, title_only, content_caption, picture_caption, title_vertical_text, vertical_title_text; also `:layout_index` for arbitrary index |
| Slide background | Solid, gradient, pattern, picture fill via `:background` option on `add_slide/2` |
| Speaker notes | `set_notes/2` with auto-created notes slide and notes master; visible in Presenter View |
| Core properties | title, author, subject, keywords, category, comments, last_modified_by, created, modified (DateTime with W3CDTF), revision (integer), content_status, language, version via `Podium.new/1` or `set_core_properties/2` |

## Text and Formatting

| Feature | Podium |
|---------|--------|
| Text boxes | Position, size, font_size, alignment, fill, line, rotation, text frame margins (lIns/rIns/tIns/bIns) |
| Rich text runs | bold, italic, underline (18 OOXML styles), strikethrough, superscript, subscript, color, font, font_size, lang, line breaks (`\n` and `:line_break`) |
| Paragraph formatting | alignment (left/center/right/justify), line_spacing, space_before, space_after, bullets (boolean/`:number`/custom char), level (0-based indent) |
| Text auto-size | `:none`, `:text_to_fit_shape`, `:shape_to_fit_text` on text boxes and auto shapes |
| Word wrap | `word_wrap: false` for `wrap="none"`, default `wrap="square"` |

## Shapes and Styling

| Feature | Podium |
|---------|--------|
| Shape fill | Solid (`"RRGGBB"`), gradient (stops + angle), pattern (54 OOXML presets with fg/bg), picture fill (blip fill) |
| Shape line | Color, width, 11 dash styles; gradient fill and pattern fill via `:fill` key |
| Rotation | Clockwise degrees on text boxes, images, and auto shapes |
| Auto shapes | 180+ preset geometries (rounded rect, arrows, stars, callouts, flowchart, etc.) with fill, line, text, rotation; theme-styled by default |
| Connectors | Straight, elbow, curved with coordinate-based begin/end points, auto flip calculation, line formatting (color, width, dash style); theme-styled |
| Freeform shapes | Custom vector paths via `Freeform` builder: `line_to`, `move_to`, `close`, `add_line_segments`; custom coordinate scales; multiple contours |

## Tables

| Feature | Podium |
|---------|--------|
| Cell content | Plain text and rich text cells |
| Cell fill | Solid, gradient, pattern |
| Borders | Per-side with color and width |
| Padding | Per-side |
| Vertical anchor | top, middle, bottom |
| Merging | col_span, row_span, `:merge` placeholders |
| Column/row sizing | Per-column `col_widths`, per-row `row_heights` with `{value, unit}` tuples; even distribution by default |
| Banding flags | `first_row`, `last_row`, `first_col`, `last_col`, `band_row`, `band_col` |

## Charts

| Feature | Podium |
|---------|--------|
| Chart types | 29 types across 10 families: column (3), bar (3), line (6), pie (2), area (3), doughnut (2), radar (3), scatter (5), bubble (2) |
| Chart text | `text` sets the font for all chart text (18pt without a size); every element takes the full run font vocabulary: font_size, bold/italic (true or false), underline, strikethrough, superscript/subscript, color, font, lang |
| Titles | Chart and axis titles: plain string, rich text (runs and paragraphs), or keyword list with text and font options |
| Legends | Position atom or keyword list with position (default right) and font options |
| Data labels | Simple list or keyword list with show, position (9 options), number_format and font options; per-point overrides (with font options) via series `data_labels` map |
| Category axis | title, gridlines (off by default, line formatting), number_format, label_rotation, tick marks, reverse order, visibility, tick label font options, axis line (any line format) |
| Value axis | title, gridlines (line formatting), number_format, min/max, major/minor unit, crosses, tick marks, reverse order, visibility, tick label font options, axis line (any line format) |
| Chart and plot area | `background` (`:none`, any fill, or fill and line) on the chart area; `plot_area` fill and line |
| Manual layout | Plot area (x/y/w/h, inner or outer target), legend (x/y, optional w/h) and chart and axis titles (x/y) as fractions of the chart frame; `overlay` on legend and titles |
| Element fill and line | Titles, axis titles, legend and data labels take `fill` and `line`; `:none` everywhere a fill or line is accepted, shapes included |
| Date axis | `type: :date` with base/major/minor time units |
| Series formatting | Colour (`:none` for unfilled or undrawn), any fill via `fill` (solid, gradient, pattern), line control (`:none` for markers only, colour, width, dash), outlines on bars/areas/slices/bubbles, invert_if_negative; per-point colours and fill/line formats; markers (10 symbols with size/fill/line); the same options on category, XY and bubble series |
| Editable charts | Embedded Excel workbook via elixlsx with externalData link |
| Combo charts | Multi-plot via `add_combo_chart/5`: column+line, bar+line, area+line, stacked+line; secondary value axis; shared categories |

## Images

| Feature | Podium |
|---------|--------|
| Formats | PNG, JPEG, BMP, GIF, TIFF, EMF, WMF via magic-byte detection |
| Cropping | Per-side in 1/1000ths of percent |
| Auto-scale | When size omitted, reads native pixel dimensions + DPI from image headers. TIFF, EMF and WMF need an explicit `:width` and `:height` |
| Natural size | `Podium.Image.dimensions/1` returns the natural size in EMU for PNG, JPEG, BMP and GIF |
| Aspect ratio | Preserved when only width or height given |
| Masking | Via `:shape` option (ellipse, diamond, roundRect, star5, etc.) |
| Dedup | SHA-1 content deduplication |
| Rotation | Clockwise degrees |

## Placeholders

| Feature | Podium |
|---------|--------|
| Layouts | All 11 slide layouts |
| Text placeholders | title, subtitle, content, body, caption, left/right content/heading |
| Picture placeholder | On picture_caption layout, or any placeholder addressed by `{type, idx}` |
| Chart/table content | `set_chart_placeholder`/`set_table_placeholder` with position inherited from template layout |
| Addressing by type and idx | Every placeholder function takes the `{type, idx}` pair `Podium.Template.inspect/1` reports, so any template's layouts can be filled; `add_slide/2` validates each placeholder against its layout |
| Footer/date/slide number | Presentation-level settings, emitted at the idx the slide's layout uses and skipped when the layout has no such placeholder |

## Hyperlinks and Actions

| Feature | Podium |
|---------|--------|
| Hyperlinks | URL (http/https), mailto, file on text runs via `hyperlink:` option; tooltip support; external relationships |
| Slide navigation | `:next_slide`, `:previous_slide`, `:first_slide`, `:last_slide`, `:end_show` |
| Named slide jump | `{:slide, target}` on text runs |

## Video

| Feature | Podium |
|---------|--------|
| Embedding | `add_movie/4` with poster frame (default or custom) |
| Media dedup | SHA-1 deduplication |
| Playback | `<p:timing>` playback support |

## OPC Packaging and Units

| Feature | Podium |
|---------|--------|
| OPC | Content types, relationships, ZIP round-trip |
| Units | inches, cm, pt → EMU; raw EMU integers also accepted |

## Won't Implement

| Feature | Reason |
|---------|--------|
| Open an existing deck to edit | Create-only by design. `Podium.from_template/2` opens a slide-less template to write into, not a deck to modify |
| Slide master/layout editing | Only needed for read-modify-write |
| Slide reorder/delete/duplicate | Editing operations, not creation |
| Group shapes | Primarily useful for read-modify-write |
| OLE object embedding | Extremely niche |
| Shadow effects | Cosmetic, easily applied in PowerPoint after creation |
| Shape adjustments | Massive surface area (180+ shapes × different handles) for minimal value |
| Picture cell fill | Too niche |
| Table cell unmerge | Create-only library |
| Master → layout → slide inheritance | Only placeholder position is resolved: `Podium.Template.inspect/1` gives a layout placeholder without its own `xfrm` the box of the master placeholder of the matching type. Text and style inheritance is left to PowerPoint |

## Notes

- **python-pptx creatable chart types**: 29 total. The XL_CHART_TYPE enum has 73 entries, but stock, surface, 3D, and cone/cylinder/pyramid types have no XML writer — they can only be read from existing files, not created programmatically.
- **python-pptx table cell borders**: Not exposed in the public API. Podium supports per-side border color and width.
- **python-pptx audio**: No public API for audio embedding despite video support.
- **Pattern presets**: All 54 OOXML patterns are implemented.
- **Combo charts**: python-pptx can only *read* combo charts from existing files, not create them programmatically. Podium supports full creation including secondary axes.
