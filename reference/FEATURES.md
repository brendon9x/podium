# Feature Tracker

Comprehensive list of Podium's features. Podium uses [python-pptx](https://github.com/scanny/python-pptx) as its reference implementation.

## Presentations and Slides

| Feature | Podium |
|---------|--------|
| New presentation | `Podium.new/1` with configurable options |
| Save | To file or to memory (binary) |
| Slide dimensions | 16:9 default, configurable width/height in any unit |
| Percent positioning | `{value, :percent}` for x/y/width/height — resolved against slide dimensions at build time |
| Grid layout | Bootstrap-style 12-column grid via `Podium.Layout` — `grid/2`, `row/2`, `cols/2` with `"col-N"` / `"col-N offset-M"` specs; configurable margins, gutters, column count |
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
| HTML text input | Auto-detected HTML strings parsed via Floki; `<b>`, `<i>`, `<u>`, `<s>`, `<sup>`, `<sub>`, `<span style>`, `<p>`, `<br>`, `<ul>`/`<ol>`/`<li>` with nesting; works in text boxes, table cells, placeholders, and auto shapes |

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
| Titles | Plain string or keyword list with text, font_size, bold, italic, color, font |
| Legends | Position atom or keyword list with position, font_size, bold, italic, color, font |
| Data labels | Simple list or keyword list with show, position (9 options), number_format, color; per-point overrides via series `data_labels` map |
| Category axis | title, gridlines, number_format, label_rotation, tick marks, reverse order, visibility, tick label color, axis line color |
| Value axis | title, gridlines, number_format, min/max, major/minor unit, crosses, tick marks, reverse order, visibility, tick label color, axis line color, major/minor gridlines color |
| Date axis | `type: :date` with base/major/minor time units |
| Series formatting | Solid color, pattern fill (54 presets), per-point colors, per-point line format, markers (10 symbols with size/fill/line) |
| Editable charts | Embedded Excel workbook via elixlsx with externalData link |
| Combo charts | Multi-plot via `add_combo_chart/5`: column+line, bar+line, area+line, stacked+line; secondary value axis; shared categories |

## Images

| Feature | Podium |
|---------|--------|
| Formats | PNG, JPEG, BMP, GIF, TIFF, EMF, WMF via magic-byte detection |
| Cropping | Per-side in 1/1000ths of percent |
| Auto-scale | When size omitted, reads native pixel dimensions + DPI from image headers |
| Aspect ratio | Preserved when only width or height given |
| Masking | Via `:shape` option (ellipse, diamond, roundRect, star5, etc.) |
| Dedup | SHA-1 content deduplication |
| Rotation | Clockwise degrees |

## Placeholders

| Feature | Podium |
|---------|--------|
| Layouts | All 11 slide layouts |
| Text placeholders | title, subtitle, content, body, caption, left/right content/heading |
| Picture placeholder | On picture_caption layout |
| Chart/table content | `set_chart_placeholder`/`set_table_placeholder` with position inherited from template layout |
| Footer/date/slide number | Presentation-level settings |

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
| Open existing .pptx | Create-only by design |
| Slide master/layout editing | Only needed for read-modify-write |
| Slide reorder/delete/duplicate | Editing operations, not creation |
| Group shapes | Primarily useful for read-modify-write |
| OLE object embedding | Extremely niche |
| Shadow effects | Cosmetic, easily applied in PowerPoint after creation |
| Shape adjustments | Massive surface area (180+ shapes × different handles) for minimal value |
| Picture cell fill | Too niche |
| Table cell unmerge | Create-only library |
| Master → layout → slide inheritance | Only needed for read-modify-write; Podium resolves positions from the template at parse time |

## Notes

- **python-pptx creatable chart types**: 29 total. The XL_CHART_TYPE enum has 73 entries, but stock, surface, 3D, and cone/cylinder/pyramid types have no XML writer — they can only be read from existing files, not created programmatically.
- **python-pptx table cell borders**: Not exposed in the public API. Podium supports per-side border color and width.
- **python-pptx audio**: No public API for audio embedding despite video support.
- **Pattern presets**: All 54 OOXML patterns are implemented.
- **Combo charts**: python-pptx can only *read* combo charts from existing files, not create them programmatically. Podium supports full creation including secondary axes.
