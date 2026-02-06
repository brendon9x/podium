# Podium vs python-pptx Feature Parity Tracker

## What Podium Has Today

| Area | Status |
|------|--------|
| Presentations (new, save to file/memory) | Done |
| Slides (add, blank layout, title_slide, title_content layouts) | Done |
| Slide dimensions (16:9 default, configurable width/height) | Done |
| Text boxes (position, size, font_size, XML escaping) | Done |
| Rich text (bold, italic, underline, color, font, alignment, multiple paragraphs/runs) | Done |
| Shape fill (solid) & line (solid, configurable width) | Done |
| Images (PNG, JPEG with magic-byte detection) | Done |
| Tables (rows, cols, cell text, rich text cells, even distribution) | Done |
| Placeholders (title_slide, title_content layouts; title, subtitle, body) | Done |
| Charts — 7 types: column clustered/stacked, bar clustered/stacked, line, line+markers, pie | Done |
| Chart titles & legends (title text, legend position) | Done |
| Chart data labels (value, category, series, percent) | Done |
| Chart axis customization (title, gridlines, number format, min/max, major_unit) | Done |
| Series formatting (solid fill color per series, line stroke for line charts) | Done |
| Editable charts (embedded Excel via elixlsx, externalData link) | Done |
| OPC packaging (content types, relationships, ZIP round-trip) | Done |
| Units (inches, cm, pt to EMU) | Done |

## What python-pptx Has That We Don't

### Tier 1 — Remaining Gaps

All Tier 1 features have basic implementations. The remaining gaps within each are incremental improvements:

| Feature | python-pptx | Podium | Gap |
|---------|-------------|--------|-----|
| **Rich text** | spacing, bullets, superscript, strikethrough, language | bold, italic, underline, strikethrough, superscript, subscript, color, font, alignment, bullets, line spacing, space before/after | Language |
| **Images** | BMP, GIF, TIFF, EMF, WMF, cropping, deduplication | PNG, JPEG | More formats, cropping, dedup |
| **Tables** | merge, borders, fills, padding, vertical anchor | Rows/cols with rich text cells | Cell merge, borders, fills, padding |
| **Chart titles & legends** | Font formatting on titles/legends | Title text, legend position | Font formatting |
| **Chart data labels** | Position, number format per label | show value/category/series/percent | Label positioning, per-label format |
| **Chart axis customization** | Crossing, tick mark style, label rotation | Title, gridlines, number format, min/max, major_unit | Crossing, label rotation |
| **Series formatting** | Pattern, line format per point | Solid fill per series | Pattern fills, per-point formatting |
| **Placeholders** | 16+ types with master/layout/slide inheritance | title, subtitle, body on 3 layouts | More placeholder types, inheritance |
| **Shape fill & line** | Gradient, pattern, picture fills; line dash style | Solid fill, solid line with width | Gradient, pattern, dash styles |

### Tier 2 — Nice to Have

| Feature | python-pptx | Podium | Effort |
|---------|-------------|--------|--------|
| More chart types — area, scatter, bubble, doughnut, radar | 50+ types including 3D variants | 7 types | Medium per type |
| Core properties — author, title, subject | Full Dublin Core metadata | None | Small |
| Slide notes | Full (auto-create notes slide) | None | Small-Medium |
| Auto shapes — 100+ preset geometries (rounded rect, arrows, stars, callouts) | Full | text_box only | Medium |
| Hyperlinks — on text runs or shapes | Full (URL, mailto, slide jump) | None | Small-Medium |
| Connectors — lines between shapes | Full (straight, elbow, curved with endpoints) | None | Medium |
| Group shapes | Full (nested groups) | None | Medium |
| Slide background — solid/gradient fill | Full (with master inheritance control) | None (uses layout default) | Small |

### Tier 3 — Advanced / Niche

| Feature | python-pptx | Podium | Effort |
|---------|-------------|--------|--------|
| Open existing .pptx for modification | Yes (core feature) | No — create-only | Very Large |
| Video/audio embedding | Yes | No | Large |
| Freeform shapes (custom SVG-like paths) | Yes | No | Large |
| Combo/multi-plot charts | Yes | No | Large |
| Click actions (macros, slide navigation) | Yes (PP_ACTION enum) | No | Medium |
| Shadow/3D effects | Partial | No | Medium-Large |
| Text auto-size/fit to shape | Yes (font metrics) | No | Medium |
| Gradient/pattern fills | Yes | No | Medium |
| Slide master/layout editing | Yes | No | Large |
| Slide reorder/delete/duplicate | Yes | No | Small-Medium |
