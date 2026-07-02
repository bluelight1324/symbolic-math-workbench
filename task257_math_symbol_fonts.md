# Task 257 — How mathdot Will Use Godot to Format Math Symbols (Best-Possible Font)

> "How will [we] use Godot to format math symbols, in the best possible font?"

This is a design answer, not a code change. It (1) states what "formatting math"
needs, (2) grounds it in what mathdot does today, (3) lays out Godot 4's real text
toolbox and its limits, (4) names the **best fonts** and why, and (5) recommends a
concrete path.

## 1. What "formatting math symbols" actually requires

Two separate problems, often conflated:

- **Glyph coverage** — the *symbols*: `∫ ∑ ∏ ∂ ∇ √ ∞ ± × ÷ ≤ ≥ ≠ ≈ ≡ → ⇒ ∈ ∉ ∀ ∃ ∮`,
  Greek `α β γ … Ω`, blackboard `ℝ ℂ ℤ ℕ ℚ`, script/fraktur, sub/superscripts.
- **2-D layout** — stacked *structure*: fractions with a vinculum, radicals with a
  bar, super/subscripts and big-operator limits (∑ from k=1 to n), matrices,
  stretchy delimiters, over/under-braces.

A "math font" mostly solves (1). Solving (2) well is TeX's whole job.

## 2. Where mathdot is today

- `MathFormatter.to_display()` converts the REDUCE linear form to readable text:
  `**`→`^`, **numeric exponents → real Unicode superscripts** (`x^2`→`x²`), `*`→`·`.
- Results render in a **`RichTextLabel` with `bbcode_enabled = false`** — i.e. plain
  Unicode text, no structural markup.
- The app bundles **no font files**; it uses **`SystemFont`** (default family
  `matlab` → Courier New). So today's symbol coverage is *whatever Courier New has* —
  fine for `² · − √`, but it lacks most of `∫ ∑ ∂ ∇ ≤ ≥` and blackboard letters, which
  then render as tofu (□).

That last point is the single biggest gap, and it's a **font** problem.

## 3. Godot 4's text toolbox (and its one hard limit)

- **TextServer Advanced** (HarfBuzz + ICU) is Godot 4's default shaper: full Unicode,
  bidi, ligatures, and **OpenType features** — so `->`→`→` style ligatures and
  stylistic sets work if the font provides them.
- **`RichTextLabel` + BBCode** gives structural markup: **`[sup]` / `[sub]`**
  (Godot 4 *does* have these — the code's "no `[sup]` tag" note predates them),
  **`[table]` / `[cell]`** (matrices, and stacked fraction cells), `[font]`,
  `[font_size]` (size a `∑`/`∫` up), `[color]`, `[center]`, and **`[img]`** (inline
  images — the escape hatch for true typesetting, see §5-C).
- **Font system:** `FontFile` (bundle a `.ttf`/`.otf`), `SystemFont` (by name),
  **`FontVariation`** (weight, spacing, `opentype_features`), and — crucially —
  **font fallback chains** (`Font.fallbacks`): a primary UI font can fall back to a
  symbol-rich font for any glyph it lacks.
- **`_draw` / `draw_string` / `draw_char`** for a fully custom layout engine.

**The limit:** Godot does **not** implement the OpenType **MATH table**. HarfBuzz
ships `hb-ot-math`, but Godot doesn't drive math layout — no automatic script
positioning, stretchy-delimiter assembly, or radical construction. So a math font
gives you its **glyphs and design**, but you still lay out 2-D structure yourself
(BBCode tables, or your own boxes) or render it externally (§5-C).

## 4. The best possible font(s)

Two honest "bests", depending on the look you want:

| Need | Best font | Why |
|---|---|---|
| **mathdot's monospace / MATLAB-CAS identity** | **JuliaMono** (SIL OFL) | Built for scientific computing; ~10 000 glyphs covering essentially all math/technical Unicode (`∫ ∑ ∂ ∇ ⊗ ⟨⟩ ℝℂℤ` …) in a clean fixed-width design that matches the code aesthetic. **Recommended primary for mathdot.** |
| **Textbook / journal typography** | **STIX Two Math** or **Latin Modern Math** (OFL) | Real OpenType **MATH** fonts (the LaTeX/journal look). You'll only get their *glyphs* in Godot (no MATH-table layout), but the design is publication-grade. |
| **Windows-native** | **Cambria Math** | Ships on Windows; superb math coverage. Good zero-install fallback. |
| **Universal gap-filler (fallback only)** | **Noto Sans Math** + **Noto Sans Symbols 2** | Google-maintained, enormous symbol coverage; ideal as the *last* link in a fallback chain so nothing ever renders as tofu. |

Avoid relying on Courier New / generic system fonts for math — their symbol coverage
is partial, which is exactly today's tofu problem.

## 5. Recommended approach for mathdot (ranked)

Because mathdot is a **bundled, offline Godot app**, the sweet spot is native text +
a great font, escalating only if publication-grade 2-D is required.

**A. Linear Unicode + a math-complete font + a fallback chain — do this first.**
The cheapest, most robust, fully-offline win:
1. **Bundle a font** (`FontFile` from `res://fonts/JuliaMono.ttf`, or STIX Two Math).
2. **Set it as a fallback** behind the user's chosen family
   (`primary.fallbacks = [math_font]`), so every `∫ ∑ ∂ ∇ ℝ` renders even when the
   primary font lacks it — *this alone kills the tofu*.
3. **Expand `MathFormatter`** to map more operators to Unicode
   (`int`→`∫`, `sum`→`∑`, `df`/`partial`→`∂`, `sqrt`→`√…`, `<=`→`≤`, `>=`→`≥`,
   `!=`→`≠`, `->`→`→`, `infinity`→`∞`, Greek names → `α…Ω`), extend superscripts to
   negative/parenthesised exponents, and add **subscripts** (`x_1`→`x₁`).

**B. Turn on BBCode for light 2-D.** Set `bbcode_enabled = true` on the result
`RichTextLabel` and emit **`[sup]`/`[sub]`** for scripts, **`[table]`/`[cell]`** for
matrices and stacked fractions, and **`[font_size]`** to enlarge big operators.
Gets matrices and fractions "structurally right" with no external engine.

**C. LaTeX → image → `[img]` (only if you need journal-quality 2-D).** Render a
formula with KaTeX/MathJax or a TeX engine to SVG/PNG and embed it inline (or as a
`TextureRect`, exactly like mathdot already embeds plots). Best fidelity — true
fractions, radicals, stretchy delimiters — but it needs an external renderer bundled
(a headless KaTeX, or MathJax-node), which is heavy and against the "pure-offline,
pure-Godot" grain the project has kept for plots.

**D. Native math-layout engine (long-term ceiling).** Read an OpenType MATH font's
metrics and do TeX-style box-and-glue layout in GDScript, drawing via `_draw`. Highest
native fidelity; a large, standalone project.

## 6. Bottom line

- **Best font:** **JuliaMono** for mathdot's monospace CAS identity (or **STIX Two
  Math** for a textbook look), with **Noto Sans Math/Symbols 2** as the final
  fallback link.
- **Best method:** bundle that font and wire it as a **fallback** (fixes symbol
  coverage immediately), expand `MathFormatter`'s Unicode map, and enable
  `RichTextLabel` BBCode (`[sup]`/`[sub]`/`[table]`) for scripts, matrices and
  fractions. Reserve a LaTeX-to-image pipeline for future publication-grade output.
- **Reality check:** Godot renders any Unicode beautifully and shapes it with
  HarfBuzz, but it does **not** do OpenType MATH-table layout — so the *glyphs* come
  from the font while the *2-D structure* comes from your BBCode/markup (or an image).

## Files
- This doc only (task 257 asks "how" — no code changed). The concrete edits in §5-A/B
  are a natural follow-up task.
