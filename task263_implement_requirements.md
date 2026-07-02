# Task 263 — How to Implement the Math-Rendering Requirements

The engineering plan for building the [262 requirements](task262_math_rendering_requirements.md)
into mathdot. 262 says *what*; this says *how* — the architecture, a phase-by-phase
build order tied to real files, the hard problems and their solutions, and the test /
rollout strategy. (A doc; the code is the follow-up work.)

## 1. Architecture — one pipeline, pluggable renderers

Everything hinges on one seam: today `MathFormatter.to_display()` returns a `String`
that a `RichTextLabel` shows. Replace that single call site with a **render pipeline**
so tiers and future backends drop in without touching the notebook:

```
REDUCE output ──▶ MathExpr (model) ──▶ Renderer[tier] ──▶ Control ──▶ cell
                     ▲                      │   ▲
             structured (LaTeX/MathML)      │   └─ reads active colour scheme + font
             or parsed linear form          └─ cache (hash) + worker prerender
```

New GDScript modules (all under `app/scripts/math/`):

- **`math_expr.gd`** — the model. A lightweight AST / MathML wrapper built either from
  REDUCE's structured output (MR-S5) or parsed from the linear form (fallback). One
  source of truth for every renderer, the animation diff, and validation.
- **`math_render.gd`** — the dispatcher: `render(expr, tier, ctx) -> Control`. Picks a
  renderer by the active **quality tier** (MR-Q6), consults the **cache** (MR-Q2), and
  hands heavy work to a **worker** (MR-Q3).
- **`renderers/unicode_renderer.gd`** (Draft), **`bbcode_renderer.gd`** (Standard),
  **`svg_renderer.gd`** (Max) — the strategy backends, each `Control`-returning.
- **`math_cache.gd`** — content-addressed store keyed by `hash(expr, tier, theme, font)`,
  reusing `NotebookRunner.source_hash`'s scheme.

`notebook_view.gd`'s result-cell code changes from "`res_text.text = to_display(out)`"
to "`cell.add_child(MathRender.render(expr, _math_tier, ctx))`". That's the only
integration point; everything else is additive.

## 2. Phase 1 — "Legible" (foundation, low-risk, do first)

Delivers MR-F1–F3, MR-S1–S4, MR-N8/N9. This is essentially the
[258 blueprint](task258_implement_best_font.md), now framed inside the pipeline.

1. **Fonts (MR-F1/F2/F3).** Add `app/fonts/JuliaMono-Regular.ttf` + `NotoSansMath`;
   `FontConfig.math_font()` builds the fallback chain; `font_resource()` attaches it to
   every family; `main.gd` theme + Default family covered. Ship via `mathdot.iss`.
2. **UnicodeRenderer (MR-S1/S2).** Move + widen `MathFormatter.to_display` into
   `unicode_renderer.gd`: full operator/Greek/blackboard map, sub/superscripts incl.
   negative/parenthesised. Returns a `RichTextLabel`.
3. **BBCodeRenderer (MR-S3/S4).** `bbcode_enabled = true`, emit `[sup]`/`[sub]` and
   `[table]`/`[cell]` for scripts / matrices / fractions.
4. **Wire the pipeline** minimally: `MathRender.render` chooses Unicode (Draft) or
   BBCode (Standard); default tier = Standard where safe, Draft otherwise.

**Exit criteria:** `--test126` green with new asserts (fallback present; `to_display`
maps `∫∑∂≤`, `x^(-2)→x⁻²`, `x_1→x₁`); a tofu-probe notebook shows **zero □**;
existing notebooks unchanged in Draft (MR-N9).

## 3. Phase 2 — "Beautiful"

Delivers MR-S5, MR-Q1–Q7, MR-N4/N5.

- **Structured output (MR-S5).** Add an engine mode: for a result, also request
  REDUCE's LaTeX (`load_package rlfi; on latex;`) or MathML on the `-K 1000m` build.
  `math_expr.gd` prefers this; falls back to linear parsing. Runs on the *existing*
  async engine path, so no UI cost.
- **SvgRenderer (MR-Q1).** LaTeX → **SVG** offline. Options, in order of pragmatism:
  1. **KaTeX in an embedded JS engine** — bundle QuickJS via a small GDExtension
     (`godot-quickjs`) and run KaTeX's `renderToString` → MathML/HTML → SVG; **or**
  2. **Typst / microTeX via WASM** — run a WASM build under a `godot-wasm` GDExtension
     (Rust, LaTeX-complete, fully offline); **or**
  3. **pure-GDScript TeX-subset → SVG** — no extension, most work, matches the
     "pure-Godot" ethos.
  Godot rasterises the resulting **SVG with ThorVG at a chosen scale**, so output is
  crisp at any zoom (covers much of MR-Q5 without a separate MSDF path).
- **Cache + worker (MR-Q2/Q3).** `math_cache.gd` stores the rendered `Texture2D`/BBCode
  by hash; `MathRender` runs SvgRenderer through the **task-253 `_async_plot` worker
  pattern** (placeholder → swap), so typesetting never blocks scrolling.
- **Typography (MR-Q4)** via `FontVariation` (italic variables, upright functions,
  OpenType features) in the Unicode/BBCode tiers; SVG tier gets it from KaTeX.
- **Quality tiers (MR-Q6).** A `_math_tier` setting (Draft/Standard/Max) in the
  Notebook menu (reuse the existing submenu + `about_to_popup` sync from task 255),
  persisted in a `ConfigFile` like fonts/colours.
- **Theme-aware (MR-N5).** Renderers take a `ctx` carrying `_color_scheme`; SVG colours
  are substituted per theme; cache key includes the theme so switches re-render.
- **A11y (MR-Q7).** Keep the MathML from MR-S5 attached to each cell for a future
  speech/size path.

**Exit criteria:** a fraction/radical renders crisp vector in Max tier; switching tiers
changes fidelity; scrolling stays smooth while math typesets; cache hit on re-view.

## 4. Phase 3 — "Alive"

Delivers MR-L1, L3, L4, L8 first (highest leverage), then L2/L5–L7/L9.

- **Animated derivations (MR-L1).** REDUCE already returns each step's expression; build
  `MathExpr` for step *n* and *n+1*, **diff the trees** (match subterms by structure/id),
  and **`Tween`** matched glyph boxes between their two layouts. The box positions come
  free from the BBCode/SVG layout.
- **Validation (MR-L4).** After rendering, re-parse the rendered form back to a
  `MathExpr` and assert **AST-equality** with the source; show a "verified" badge, log a
  mismatch. Cheap, and it satisfies MR-N7 (faithful).
- **Reactive params (MR-L3).** Bind a free symbol to a slider (the plot backlog's
  draggable-parameter mechanism); on change, re-`sub` in REDUCE and re-render — cache
  keyed by the parameter value.
- **Export (MR-L8).** From `MathExpr`, serialise to LaTeX / MathML / SVG / PNG (Typst,
  OMML, Braille later) — a menu action, mirroring the plot PNG export (task 252).
- L2 (bidirectional editing), L5 (ink/voice/NL), L6 (AI), L7 (VR), L9 (WASM-TeX) are
  independent follow-ups built on the same `MathExpr` model.

## 5. Phase 4 — "Medium" (frontier, plugin-shaped)

MR-M1–M10. Each is a module over `MathExpr`: semantic zoom (LOD folding of the tree),
cross-representation morphing (bridge to the plot/numeric subsystems mathdot already
has), provenance DAG (record the step tree REDUCE produces), proof-carrying (external
Lean/Isabelle), knowledge-graph (DLMF/OEIS matcher), collaboration (CRDT over the
model). Built only after Phases 1–3 make the model + renderers solid.

## 6. Hard problems & how they're solved

| Problem | Solution |
|---|---|
| **Offline LaTeX→SVG** in a bundled Godot app (no browser) | Embed QuickJS+KaTeX, or Typst/microTeX WASM, via a GDExtension; or a pure-GDScript TeX subset. Rasterise SVG with Godot's built-in ThorVG. |
| **Lossy linear→structure parsing** | Get **structured LaTeX/MathML from REDUCE** (MR-S5) on the large-heap build; parse linear only as fallback. |
| **Heavy typesetting blocking the UI** | Content-address cache + the task-253 worker/placeholder-swap pattern (proven). |
| **Animation needs glyph positions** | Reuse the BBCode/SVG layout's box positions; diff ASTs for correspondence; `Tween`. |
| **"Is the render faithful?"** | Round-trip re-parse + AST-equality check (MR-L4). |
| **Theme + zoom churn** | Cache key = (expr, tier, theme, font); SVG rasterised at the current zoom scale. |

## 7. Testing & rollout

- **Unit (`_test126.gd`):** fallback wiring, the widened `to_display` map, BBCode
  emission, cache hit/miss, `MathExpr` build/round-trip, tier dispatch.
- **Visual:** tofu-probe notebook (Phase 1), fraction/radical crispness (Phase 2),
  a derivation animation (Phase 3) — screenshotted like the plot tasks.
- **Rollout:** everything behind the **tier switch**; **Draft ≡ today** (MR-N9) so
  nothing regresses, Standard becomes default once BBCode is solid, Max opt-in until
  the SVG backend is bundled. Rebuild app + installer per the task-254 flow after each
  phase.

## 8. Sequencing summary

1. **Phase 1 (fonts + fallback + Unicode/BBCode)** — days, low-risk, kills tofu.
2. **Phase 2 (structured output + SVG + cache/worker + tiers)** — the real build; the
   SVG backend choice (KaTeX-JS vs Typst-WASM vs pure-GDScript) is the key decision.
3. **Phase 3 (animation, validation, reactive, export)** — differentiators on the model.
4. **Phase 4 (frontier)** — plugins, opportunistic.

The whole plan rests on two early investments — the **`MathExpr` model** and the
**pipeline seam** — after which every tier and every frontier feature is additive.

## Files
- This doc only (task 263 asks "how will you implement" — no code changed). The new
  `app/scripts/math/` module tree + the Phase-1 edits are the first implementation task.
