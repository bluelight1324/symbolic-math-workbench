# Task 259 — How to Improve on the Best-Font Math Rendering (roadmap)

Third in the sequence: [257](task257_math_symbol_fonts.md) chose the fonts/method,
[258](task258_implement_best_font.md) is the implementation blueprint. This doc
answers **"how will you improve on the above?"** — the levers that take mathdot from
"correct glyphs + light 2-D" to publication-grade, ranked by leverage. (A doc, per
the task; the items are future work.)

## Where 258 tops out

The 258 baseline (math-complete font + fallback chain + a wider Unicode map + BBCode
`[sup]`/`[sub]`/`[table]`) gets you **every glyph rendered** and **light 2-D**
(scripts, table-based matrices/fractions). Its ceiling:

- The conversion **reverse-engineers REDUCE's linear ASCII** (`x**2/(1+x**2)`) into
  Unicode — inherently lossy and ambiguous (precedence, implicit multiplication,
  nested fractions).
- No **true** fractions/radicals with a proper bar, no **stretchy delimiters**
  (parentheses that grow), no stacked **big-operator limits** (∑ with `n` above,
  `k=1` below), no real math **baseline alignment**.

Every improvement below removes one of those ceilings.

## 1. Feed *structured* CAS output, not linear ASCII (biggest single win)

REDUCE can emit math in structured, unambiguous forms — **LaTeX** (the `rlfi`
package: `load_package rlfi; on latex;`) and **MathML** — instead of the linear form
mathdot currently parses. Rendering REDUCE's *own* LaTeX/MathML:

- **eliminates the entire class of lossy-parse bugs** (`MathFormatter` no longer
  guesses structure), and
- **unlocks true 2-D** for free (LaTeX already encodes fractions, radicals, scripts,
  matrices).

Caveat, verified: `rlfi` needs a large heap — a small-heap REDUCE returns
`insufficient freestore to run this package`. **mathdot already launches REDUCE with
`-K 1000m`**, so the bundled build has the room; the interface just needs a mode
flag on the engine call and a parallel "rendered form" alongside today's linear one.

This is the qualitative jump: *CAS → LaTeX/MathML → typeset*, rather than
*CAS → ASCII → Unicode guess*.

## 2. True 2-D typesetting (two routes)

- **2a. LaTeX → SVG → inline (recommended).** Bundle **KaTeX** (offline, self-
  contained JS, MIT) or a small TeX-subset renderer; convert the REDUCE LaTeX to
  **SVG** (vector — scales with mathdot's plot-style zoom and any DPI) and drop it
  inline via `[img]` or a `TextureRect`, exactly as plots are already embedded.
  Publication-grade fractions, radicals, stretchy delimiters, stacked limits.
- **2b. Native GDScript math engine.** Parse the MathML/LaTeX and do TeX-style
  box-and-glue layout using an OpenType **MATH** font's metrics (STIX Two Math),
  drawing via a Control's `_draw`. Pure-offline, no JS runtime — matches the
  "pure-Godot" ethos the project kept for plots — but a large build; option 2a is the
  faster path to the same visual result.

Both should **content-address the render cache** by expression hash (reuse the
existing `src-hash` cache) and **pre-render on a worker thread** (reuse the task-253
threaded pattern) so heavy typesetting never freezes the notebook.

## 3. Typographic correctness (cheap, high-impact polish)

Independent of the big routes, these make even the linear/BBCode path read like a
textbook:

- **Math italics** — single-letter *variables* italic, **function names upright**
  (`sin`, `log`), the universal math convention.
- **TeX spacing** — thin/medium/thick spaces around operators; different spacing for
  relations (`=`, `≤`) vs binary operators (`+`, `·`) vs `∫ … dx`.
- **OpenType features** via `FontVariation.opentype_features` — contextual
  alternates / stylistic sets for cleaner `→ ⇒ ≤` ligatures where the font offers them.
- **Stretchy delimiters, radical bars, stacked limits** — the payoff of routes 1–2.

## 4. Crisp at any zoom (MSDF)

mathdot's plots already zoom; math should match. Rendering glyphs from **MSDF**
(multi-channel signed-distance-field) font atlases keeps symbols razor-sharp at any
zoom level and DPI, so a zoomed-in derivation stays clean instead of blurring.

## 5. Interactivity & semantics

Move from a static image to a live object:

- **Click a subterm** to act on it (differentiate, simplify, substitute).
- **Hover** to reveal the exact REDUCE form / copy **as LaTeX or MathML**.
- **Colour-coded terms** (à la structured editors) and **reveal-steps** for
  derivations — turning results into an explorable artifact.

## 6. Accessibility

The MathML from §1 is the enabler: **screen-reader speech** of formulas, a
**high-contrast** math palette, and a **math-size control independent of prose** (so
users can enlarge equations without reflowing everything).

## 7. The pragmatic framing — math quality tiers

Rather than one renderer, offer a **Draft / Standard / Max** switch (mirroring the
plot-quality idea from [149.4](task149_4_remaining_benefits.md)):

| Tier | Renderer | Use |
|---|---|---|
| **Draft** | Unicode + fallback font (task 258) | fast, always-on, inline scrolling |
| **Standard** | BBCode `[sup]`/`[sub]`/`[table]` 2-D | matrices, fractions, most notebooks |
| **Max** | REDUCE LaTeX → KaTeX → SVG (§1–2) | export, presentation, publication |

Context or the user picks: the fast path stays fast, the beautiful path is one toggle
away, and everything is cached + worker-rendered so quality never costs
responsiveness.

## Bottom line — the ranked path to improve

1. **Get structured output from REDUCE** (LaTeX/MathML via `rlfi`; the large-heap
   build already supports it) — the single change that removes the lossy-parse
   ceiling and unlocks true 2-D.
2. **Render it as SVG** (KaTeX, offline) inline, **cached by hash** and
   **worker-prerendered** — publication-grade, zoom-crisp, non-blocking.
3. **Layer typographic polish** (math italics, TeX spacing, OpenType features) and
   **MSDF** crispness.
4. **Add interactivity, accessibility, and quality tiers** on top of the structured
   representation.

Each builds on 258; together they take mathdot from "reads well" to "prints well."

## Files
- This doc only (task 259 asks "how will you improve" — no code changed). Items 1–2
  are the highest-leverage follow-up implementation tasks.
