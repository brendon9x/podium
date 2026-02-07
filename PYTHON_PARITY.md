# Podium vs python-pptx Feature Parity Tracker

## What Podium Has Today

| Area | Details |
|------|---------|
| **Presentations** | New, save to file, save to memory |
| **Slide dimensions** | 16:9 default, configurable width/height in any unit |
| **Slides** | Add with layout: `:blank` (default), `:title_slide`, `:title_content`; also `:layout_index` for arbitrary index |
| **Text boxes** | Position, size, font_size, alignment, fill, line, rotation, text frame margins (lIns/rIns/tIns/bIns) |
| **Rich text** | bold, italic, underline (18 OOXML styles: single, double, heavy, dotted, wavy, etc.), strikethrough, superscript, subscript, color, font, font_size, lang, line breaks (`\n` and `:line_break`) |
| **Paragraph formatting** | alignment (left/center/right/justify), line_spacing, space_before, space_after, bullets (boolean/`:number`/custom char), level (0-based indent) |
| **Shape fill** | Solid (`"RRGGBB"`), gradient (`{:gradient, stops, angle: N}`), pattern (`{:pattern, preset, fg/bg}`), **picture fill (blip fill)** via `add_picture_fill_text_box/5` — all 54 OOXML pattern presets |
| **Shape line** | Color, width, 11 dash styles (dash, dot, dash_dot, long_dash, etc.); gradient fill (`{:gradient, ...}`), pattern fill (`{:pattern, ...}`) via `:fill` key |
| **Shape rotation** | Clockwise rotation in degrees on text boxes and images |
| **Images** | PNG, JPEG, BMP, GIF, TIFF, EMF, WMF via magic-byte detection; position, size, cropping (per-side in 1/1000ths of percent); SHA-1 deduplication; rotation; **auto-scale** when size omitted (reads native pixel dimensions + DPI from image headers); aspect-ratio preservation when only width or height given; **image masking** via `:shape` option (ellipse, diamond, roundRect, star5, etc.) |
| **Tables** | Cell text, rich text cells, solid/gradient/pattern fill, borders (per-side with color/width), padding (per-side), vertical anchor (top/middle/bottom), col_span, row_span, `:merge` placeholders; table style banding flags (`first_row`, `last_row`, `first_col`, `last_col`, `band_row`, `band_col`) |
| **Placeholders** | All 11 slide layouts (title_slide, title_content, section_header, two_content, comparison, title_only, blank, content_caption, picture_caption, title_vertical_text, vertical_title_text); text placeholders (title, subtitle, content, body, caption, left/right content/heading); picture placeholder on picture_caption layout; chart/table content placeholders (`set_chart_placeholder`/`set_table_placeholder`) with position inherited from template layout; footer, date, slide number as presentation-level settings |
| **Charts** | 7 types: column_clustered, column_stacked, bar_clustered, bar_stacked, line, line_markers, pie |
| **Chart titles** | Plain string or keyword list with text, font_size, bold, italic, color, font |
| **Chart legends** | Position atom or keyword list with position, font_size, bold, italic, color, font |
| **Chart data labels** | Simple list (`[:value, :category, :percent]`) or keyword list with show, position (9 options), number_format; **per-point data label overrides** via series `data_labels` map |
| **Chart axes** | category_axis and value_axis: title (string or formatted), major_gridlines, minor_gridlines, number_format, min, max, major_unit, minor_unit, crosses (auto_zero/min/max/numeric), label_rotation, major/minor tick marks (`:out`/`:in`/`:cross`/`:none`), reverse order, axis visibility; **date axis type** via `type: :date` with base/major/minor time units |
| **Series formatting** | Solid color, pattern fill (54 presets), per-point colors via `point_colors` map, **per-point line format** via `point_formats` map; series markers with style (10 symbols), size, fill, and line properties |
| **Editable charts** | Embedded Excel workbook via elixlsx with externalData link |
| **Slide background** | Solid, gradient, pattern fill via `:background` option on `add_slide/2` |
| **Core properties** | title, author, subject, keywords, category, comments, last_modified_by via `Podium.new/1` opts or `set_core_properties/2` |
| **OPC packaging** | Content types, relationships, ZIP round-trip |
| **Units** | inches, cm, pt → EMU; raw EMU integers also accepted |

## What python-pptx Has That We Don't

### Tier 1 — Complete

All actionable Tier 1 features are implemented. Remaining items are intentionally deferred:

| Feature | python-pptx | Podium | Status |
|---------|-------------|--------|--------|
| **Tables** | Cell fill supports solid, gradient, pattern, picture; split (unmerge) | Cell fill: solid, gradient, pattern; table style banding flags | ~~Picture cell fill~~ (Won't implement — too niche), ~~unmerge~~ (Won't implement — create-only library) |
| **Placeholders** | 16+ types (title, body, picture, chart, table, date, slide_number, footer, etc.) with master → layout → slide inheritance | All 11 layouts; text, picture, chart/table content, footer, date, slide_number placeholders | ~~master → layout → slide inheritance chain~~ (Won't implement — only needed for read-modify-write workflows where a slide overrides its layout; Podium is create-only and already resolves positions from the template at parse time) |

### Tier 2 — Nice to Have

| Feature | python-pptx | Podium | Effort |
|---------|-------------|--------|--------|
| **More chart types** | 29 creatable types: area (3), bar/column stacked_100 (2), bubble (2), doughnut (2), line stacked variants (4), pie_exploded, radar (3), scatter (5) | 7 types | Medium per type |
| **Slide notes** | Full support: auto-create notes slide, notes_text_frame, notes_placeholder | None | Small-Medium |
| **Auto shapes** | 180+ preset geometries (rounded rect, arrows, stars, callouts, flowchart, etc.) via MSO_SHAPE enum | text_box only | Medium |
| **Hyperlinks** | URL (http/https), email (mailto), file, slide jump — on text runs and shapes | None | Small-Medium |
| **Connectors** | Straight, elbow, curved; begin/end points | None | Medium |
| **Group shapes** | Nested groups with shared transforms | None | Medium |
| **Slide background** | Picture fill; follow_master_background flag | Solid, gradient, pattern fill | Slide background picture fill, follow_master flag |
| **Text auto-size** | NONE, SHAPE_TO_FIT_TEXT, TEXT_TO_FIT_SHAPE; fit_text with font metrics | None | Medium |
| **Core properties** | created/modified dates, revision, language, content_status | title, author, subject, keywords, category, comments, last_modified_by | Date/revision/language fields |

### Tier 3 — Advanced / Niche

| Feature | python-pptx | Podium | Effort |
|---------|-------------|--------|--------|
| Open existing .pptx for modification | Yes (core feature, read-modify-write) | No — create-only | Very Large |
| Video embedding | Yes (EXPERIMENTAL: add_movie with poster frame) | No | Large |
| Freeform shapes | Yes (custom SVG-like paths via FreeformBuilder) | No | Large |
| Combo/multi-plot charts | Yes (multiple plots in one chart frame) | No | Large |
| Click actions | Yes (PP_ACTION: hyperlink, slide nav, macros, run program, 12+ action types) | No | Medium |
| Shadow effects | Partial (ShadowFormat on shapes) | No | Medium |
| Text word wrap | Yes (word_wrap property on TextFrame) | No | Small |
| Slide master/layout editing | Yes (shapes, placeholders, background on masters/layouts) | No | Large |
| Slide reorder/delete/duplicate | Yes (index, remove via collection) | No | Small-Medium |
| OLE object embedding | Yes (add_ole_object with prog_id) | No | Large |
| Shape adjustments | Yes (AdjustmentCollection for parameterized geometry) | No | Medium |
| Table column/row sizing | Yes (per-column width, per-row height) | Even distribution only | Small |

## Notes

- **python-pptx creatable chart types**: 29 total. The XL_CHART_TYPE enum has 73 entries, but stock, surface, 3D, and cone/cylinder/pyramid types have no XML writer — they can only be read from existing files, not created programmatically.
- **python-pptx table cell borders**: Not exposed in the public API. Podium actually exceeds python-pptx here with per-side border color and width support.
- **python-pptx audio**: No public API for audio embedding despite video support.
- **Pattern presets**: All 54 OOXML patterns are now implemented.
