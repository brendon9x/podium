# Podium Roadmap: From Spec-Faithful to LLM-Native

## End Goal

Podium should serve three audiences simultaneously, with each audience able to work at their preferred level of abstraction:

1. **The OOXML developer** — who understands PowerPoint internals, wants full control, and uses the existing API directly.
2. **The web developer** — who thinks in HTML, CSS, and grid systems, and wants to generate professional presentations without learning a new mental model.
3. **The LLM** — which can generate Podium DSL from a natural language description using only a short system prompt, drawing on its existing knowledge of HTML, CSS, and Bootstrap rather than needing Podium-specific training data.

These audiences are not in conflict. Each layer compiles cleanly to the one below it, meaning nothing is duplicated or reimplemented — the spec-faithful API remains the single source of truth for OOXML generation.

---

## Architecture: Three Layers

```
┌─────────────────────────────────────────────────┐
│  Layer 3: Macro DSL                             │
│  presentation/slide/row/col/text_box/chart      │
│  Declarative, LLM-native, zero positioning code │
├─────────────────────────────────────────────────┤
│  Layer 2: Web Helpers                           │
│  HTML text parsing, CSS units, Bootstrap grid   │
│  Percentage positioning, chart table input      │
├─────────────────────────────────────────────────┤
│  Layer 1: Spec API (existing)                   │
│  Full OOXML fidelity, EMU units, run/paragraph  │
│  format, all 29 chart types, tables, images     │
└─────────────────────────────────────────────────┘
```

All three layers are optional and independently useful. A web developer can use Layer 2 helpers with the Layer 1 API without touching the DSL. The DSL outputs Layer 1 calls. Nothing bypasses the spec layer.

---

## Layer 1: Spec API (Current State)

### What exists

- Rich text runs with full formatting (bold, italic, underline, strikethrough, superscript, subscript, color, font, size)
- 29 chart types across 10 families
- Tables with cell merging, rich text cells, full border control
- Images (PNG, JPEG) with masking and rotation
- Placeholders across 11 slide layouts
- Shape fills (solid, gradient, pattern) and line styling
- Speaker notes, footers, document metadata
- `{number, unit}` tuples for dimensions (`:inches`, `:cm`, `:pt`, `:percent`, raw EMU)
- `save/2` to file and `save_to_memory/1` for streaming
- HTML text input via `{:html, string}` tuples — parsed with Floki into native run/paragraph format
- Percentage positioning via `{value, :percent}` — resolved against slide dimensions at build time

### What to preserve

This layer should remain stable and complete. It is the foundation that makes the higher layers trustworthy — if something can be expressed in OOXML, it should be expressible here. Do not simplify or remove capability to accommodate the layers above.

### Minor additions worth considering

- **Named colors** alongside hex — `"red"`, `"navy"`, `"zappi_blue"` via a configurable palette. Useful in Layer 1, essential in Layer 3.
- **Theme color references** — `{:theme, :accent1}` etc., so presentations can respect a corporate theme.

---

## Layer 2: Web Helpers

Each helper is independent — they can be adopted incrementally without committing to the full DSL.

### 2.1 HTML Text Input ✅

Implemented. Wrap HTML in `{:html, "..."}` anywhere text is accepted. Parsed via Floki into the native run/paragraph format. Plain strings continue to work as before.

**HTML subset to support:**

| HTML | Maps to |
|------|---------|
| `<b>`, `<strong>` | `bold: true` |
| `<i>`, `<em>` | `italic: true` |
| `<u>` | `underline: true` |
| `<s>`, `<del>` | `strikethrough: true` |
| `<sup>` | `superscript: true` |
| `<sub>` | `subscript: true` |
| `<span style="color: #hex">` | `color: "hex"` |
| `<span style="font-size: 18pt">` | `font_size: 18` |
| `<span style="font-family: Arial">` | `font: "Arial"` |
| `<p>`, `<br>` | paragraph break |
| `<p style="text-align: center">` | `alignment: :center` |
| `<ul><li>` | `bullet: true` |
| `<ol><li>` | `bullet: :number` |
| Nested `<ul>/<ol>` | `level: n` |

**Implementation notes:**
- Use `Floki` for parsing — it handles malformed HTML gracefully.
- Multiple inline styles on a single `<span>` should all apply.
- This subset is intentionally limited to what LLMs generate naturally. Do not add custom tags.
- The same HTML parser should work inside table cells, placeholders, and anywhere else text is accepted.

**Why not Markdown?** Markdown has no inline color or font size syntax without extensions, and extension syntax is not in LLM training data. The HTML subset covers everything Markdown does plus the formatting options that matter for presentations.

### 2.2 Percentage Positioning ✅

Implemented. `{value, :percent}` works as a unit in all `add_*` functions. Percent values resolve against slide dimensions at build time — x/width against slide width, y/height against slide height. Mixing units freely (e.g. `x: {10, :percent}, height: {2, :inches}`) works.

CSS-style string positioning (`style: "left: 10%; top: 5%; width: 80%; height: 15%"`) is implemented — see `Podium.CSS` and the `style:` option on all positioning functions.

### 2.3 Bootstrap-Style Grid

**The problem:** Absolute positioning requires knowing coordinates. A web developer building a two-column slide does not want to calculate that the right column starts at 52% of the slide width.

**The solution:** A 12-column grid system using Bootstrap vocabulary. LLMs have seen Bootstrap in an enormous fraction of their training data — the column class names are effectively memorised.

```elixir
Podium.Layout.row(slide) do
  col "col-7" do
    Podium.add_chart(slide, :line, data, ...)
  end
  col "col-5" do
    Podium.add_text_box(slide, html, ...)
  end
end
```

**Configuration:**

```elixir
Podium.Layout.configure(
  columns: 12,          # default
  margin: {5, :percent}, # slide edge margin
  gutter: {2, :percent}  # gap between columns
)
```

**Row system:**
- Rows stack vertically.
- Row height defaults to equal division of remaining vertical space.
- Explicit row heights can be set via percentage.

**Offset support:** `col-offset-2` shifts a column right by 2 units, matching Bootstrap semantics exactly.

### 2.4 Chart Data as Pipe-Delimited Table

**The problem:** Building `ChartData` structs requires multiple function calls. For an LLM generating a chart from described data, this is unnecessary friction.

**The solution:** Accept a pipe-delimited string as chart data input, where rows are series and columns are categories:

```elixir
Podium.add_chart(slide, :bar, """
             | Q1   | Q2   | Q3   | Q4
  Revenue    | 1500 | 4600 | 5156 | 3167
  Expenses   | 1000 | 2300 | 2500 | 3000
""",
  x: {5, :percent}, y: {20, :percent},
  width: {90, :percent}, height: {70, :percent},
  colors: ["4472C4", "ED7D31"],
  legend: :bottom
)
```

This format is trivially parseable and trivially generatable by an LLM from any tabular data description.

---

## Layer 3: Macro DSL

### Philosophy

The DSL is a compile-time syntax transformation. Every macro expands to Layer 1 and Layer 2 function calls. There is no runtime overhead beyond what the underlying calls already incur.

The DSL should read like a document description, not imperative construction code. Someone reading it should immediately understand the slide structure without knowing Podium at all.

### Core structure

```elixir
import Podium.DSL

presentation do
  theme "corporate"   # optional — sets default fonts, colors

  slide :title_slide do
    title "Annual Report 2025"
    subtitle "Engineering Division"
    notes "Speaker notes go here"
  end

  slide do
    row height: "20%" do
      col "col-12" do
        text "<h2>Q4 Performance</h2>"
      end
    end

    row do
      col "col-8" do
        chart :column_clustered do
          data """
                 | Q1   | Q2   | Q3   | Q4
          Revenue | 1500 | 4600 | 5156 | 3167
          Costs   | 1000 | 2300 | 2500 | 3000
          """
          legend :bottom
          data_labels [:value]
          colors ["4472C4", "ED7D31"]
        end
      end

      col "col-4" do
        text """
          <b>Key Takeaways</b>
          <ul>
            <li>Revenue up <span style="color: #2ECC71">32%</span></li>
            <li>Costs stabilised in Q3</li>
            <li>Q4 ahead of forecast</li>
          </ul>
        """
      end
    end
  end
end
|> Podium.save("report.pptx")
```

### Macro expansion model

Each block macro accumulates children into a data structure, then calls the equivalent Layer 1/2 function:

- `presentation do` → `Podium.new/1` + `Podium.add_slide/2` for each slide
- `slide do` → `Podium.Slide.new/1`
- `row do` → `Podium.Layout.row/2` computing vertical position
- `col "col-N" do` → `Podium.Layout.col/2` computing x/width from column span
- `text` → `Podium.add_text_box/3` with HTML parsing
- `chart do` → `Podium.add_chart/4` with table data parsing
- `image` → `Podium.add_image/3`
- `title`, `subtitle`, `body` → `Podium.set_placeholder/3`
- `notes` → speaker notes

### Named templates

Pre-built slide compositions for common patterns:

```elixir
slide :two_column, split: "60/40" do
  left do
    chart :bar, data
  end
  right do
    text html
  end
end

slide :title_body do
  title "Section Header"
  body html
end

slide :full_chart do
  chart :line, data, legend: :bottom
end
```

These are macros over the grid system — not special cases, just named presets.

### `use Podium` integration

```elixir
defmodule MyApp.Reports do
  use Podium

  def quarterly_report(data) do
    presentation do
      slide do
        ...
      end
    end
    |> Podium.save_to_memory()
  end
end
```

`use Podium` imports the DSL macros, making the `presentation/slide/row/col` vocabulary available without a separate `import`.

---

## LLM-Native Design Considerations

This deserves its own section because it is a first-class design constraint, not an afterthought.

### The core principle

Every place where there is a choice between inventing a new Podium convention and borrowing an existing web convention, borrow the web convention. The LLM's existing fluency in that convention is worth more than the elegance of a purpose-designed API. The DSL is being designed for two audiences — human web developers and LLMs — and those two audiences have nearly identical prior knowledge.

### What LLMs know well (and therefore Podium should use)

- HTML inline formatting tags
- CSS inline style strings with percentage values
- Bootstrap 12-column grid class names
- Hex color values
- CSS font properties (`font-size: 18pt`, `font-weight: bold`)
- Pipe-delimited tabular data
- Markdown headings (usable inside HTML blocks)

### The minimal system prompt

If the design is right, an LLM should be able to generate correct Podium DSL from this prompt alone:

> *Generate Elixir Podium DSL to create a PowerPoint presentation.*
> *Text content uses HTML: `<b>`, `<i>`, `<u>`, `<s>`, `<sup>`, `<sub>`, `<span style="color: #hex; font-size: Npt">`, `<ul>/<ol>/<li>`, `<p style="text-align: center">`.*
> *Layout uses Bootstrap 12-column grid classes (`col-N`, `col-offset-N`) inside `row do / col "col-N" do` blocks.*
> *Chart data is a pipe-delimited table with series as rows and categories as columns.*
> *Colors are hex strings without `#`. Positions can be CSS absolute style percentages.*

That is under 100 words of instruction for the entire DSL, because the rest is already in the model's weights.

### Anti-patterns to avoid

- **Custom tags or DSL keywords that have no web equivalent** — the LLM will hallucinate or get them wrong.
- **EMU values in the DSL layer** — percentages only.
- **Positional arguments where keyword arguments would be clearer** — LLMs generate keyword arguments more reliably.
- **Deeply nested option structures** — flat keyword lists are more reliably generated than nested maps.

---

## Implementation Sequence

### Phase 1 — HTML Text Parsing (Layer 2) ✅

Implemented. `{:html, string}` tuples are accepted anywhere text is accepted — `add_text_box`, table cells, `set_placeholder`, and auto shapes. Parsed via Floki into native run/paragraph format. Supports `<b>`, `<i>`, `<u>`, `<s>`, `<sup>`, `<sub>`, `<span style>`, `<p>`, `<br>`, `<ul>`/`<ol>`/`<li>` with nesting.

### Phase 2a — Percentage Positioning (Layer 2) ✅

Implemented. `{value, :percent}` works in all `add_*` functions for x/y/width/height. Percent values resolve against slide dimensions (width for x/width, height for y/height) at build time — domain modules and XML rendering are unaffected.

### Phase 2b — CSS Style Strings (Layer 2) ✅

Implemented. `style: "left: 10%; top: 5%; width: 80%; height: 15%"` accepted on all positioning functions as an alternative to `{value, :unit}` tuples. Supports `%`, `in`, `cm`, `pt`, and raw EMU values. Explicit opts take precedence over style values. See `Podium.CSS`.

### Phase 3 — Chart Table Input (Layer 2)

Add pipe-delimited string parsing to `ChartData`. Implement as `Podium.Chart.ChartData.from_table/2`.

Deliverable: chart data can be expressed as a formatted string.

### Phase 4 — Bootstrap Grid (Layer 2)

Implement `Podium.Layout` with row/column computation. Configurable margins, gutters, and column count. Offset support.

Deliverable: multi-column layouts without manual coordinate calculation.

### Phase 5 — Macro DSL (Layer 3)

Build `Podium.DSL` on top of Phases 1–4. Implement `presentation`, `slide`, `row`, `col`, `text`, `chart`, `image`, `title`, `subtitle`, `notes`. Add `use Podium` convenience import.

Deliverable: full declarative DSL.

### Phase 6 — Named Templates (Layer 3)

Common slide compositions as named macros: `:two_column`, `:title_body`, `:full_chart`, `:section_divider`, etc.

Deliverable: one-line slide construction for the most common patterns.

### Phase 7 — Theme System (Layer 1/2)

Named color palettes, default font configuration, corporate theme support. Used by the DSL `theme` directive but also available in Layer 1.

Deliverable: consistent styling across a presentation without per-element color specification.

---

## Hex Package Strategy

Two packages or one with optional components is worth considering:

- **`podium`** — the spec-faithful API as it exists today. Stable, versioned, no DSL dependency.
- **`podium_web`** — Layers 2 and 3, depends on `podium` and adds `floki`. Could eventually be merged into `podium` behind a compile-time flag.

The separation keeps the core library lean for users who only need OOXML generation, and allows the DSL to iterate faster without affecting the stable API.

---

## Open Questions

- **Sigil support** — `~PPTX` or `~P` for inline DSL in Phoenix templates or LiveView? Mostly aesthetic but worth deciding early so the architecture supports it.
- **Streaming / chunked generation** — for large reports generated in a web request, is there value in a lazy/streaming generation model rather than building the full structure in memory first?
- **Reverse direction** — parsing an existing `.pptx` back to DSL. Not in scope now but the existence of a clean DSL makes this a natural future feature (and useful for LLM-assisted editing of existing presentations).
- **LLM integration module** — a thin `Podium.AI` wrapper that takes a natural language description and a model client, sends the minimal system prompt, and returns a presentation. Essentially a one-function module, but makes the LLM-native story explicit and easy to demo.
- **Testing strategy for the DSL** — macro expansion should be tested at the AST level, not just end-to-end. Worth establishing a pattern early.
