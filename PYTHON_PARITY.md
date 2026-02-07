# Podium vs python-pptx Feature Parity Tracker

## What Podium Has Today

| Area | Status |
|------|--------|
| Presentations (new, save to file/memory) | Done |
| Slides (add, blank layout, title_slide, title_content layouts) | Done |
| Slide dimensions (16:9 default, configurable width/height) | Done |
| Text boxes (position, size, font_size, XML escaping) | Done |
| Rich text (bold, italic, underline, color, font, alignment, language, multiple paragraphs/runs) | Done |
| Shape fill (solid, gradient, pattern) & line (solid, configurable width, dash styles) | Done |
| Images (PNG, JPEG, BMP, GIF, TIFF with magic-byte detection, cropping, deduplication) | Done |
| Tables (rows, cols, cell text, rich text cells, even distribution, cell merge, borders, fills, padding) | Done |
| Placeholders (title_slide, title_content layouts; title, subtitle, body) | Done |
| Charts — 7 types: column clustered/stacked, bar clustered/stacked, line, line+markers, pie | Done |
| Chart titles & legends (title text, legend position, font formatting on titles and legends) | Done |
| Chart data labels (value, category, series, percent, label position, number format) | Done |
| Chart axis customization (title, gridlines, number format, min/max, major_unit, crossing, label rotation) | Done |
| Series formatting (solid fill, pattern fill, line stroke, per-point formatting) | Done |
| Editable charts (embedded Excel via elixlsx, externalData link) | Done |
| OPC packaging (content types, relationships, ZIP round-trip) | Done |
| Units (inches, cm, pt to EMU) | Done |

## What python-pptx Has That We Don't

### Tier 1 — Remaining Gaps

Most Tier 1 features are now fully implemented. Remaining gaps:

| Feature | python-pptx | Podium | Gap |
|---------|-------------|--------|-----|
| **Rich text** | spacing, bullets, superscript, strikethrough, language | All implemented | — |
| **Images** | BMP, GIF, TIFF, EMF, WMF, cropping, deduplication | PNG, JPEG, BMP, GIF, TIFF, cropping, dedup | EMF, WMF formats |
| **Tables** | merge, borders, fills, padding, vertical anchor | Merge, borders, fills, padding, anchor | — |
| **Chart titles & legends** | Font formatting on titles/legends | Font formatting on titles/legends | — |
| **Chart data labels** | Position, number format per label | Position, number format | Per-individual-label overrides |
| **Chart axis customization** | Crossing, tick mark style, label rotation | Crossing, label rotation | Tick mark style |
| **Series formatting** | Pattern, line format per point | Pattern fill, per-point solid fill | Per-point line format |
| **Placeholders** | 16+ types with master/layout/slide inheritance | title, subtitle, body on 3 layouts | More placeholder types, inheritance |
| **Shape fill & line** | Gradient, pattern, picture fills; line dash style | Gradient, pattern fill; dash styles | Picture fill |

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
| Slide master/layout editing | Yes | No | Large |
| Slide reorder/delete/duplicate | Yes | No | Small-Medium |
