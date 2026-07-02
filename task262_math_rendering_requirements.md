# Task 262 — Requirements: Math-Symbol Rendering in mathdot

A single consolidated **requirements specification** for everything proposed across
tasks **257–261** (best font → implement → improve → even more → even some more).
It is the authoritative spec: numbered, prioritised, testable requirements grouped by
tier, plus non-functional constraints, a phased roadmap, and a traceability matrix.

- **Scope:** how mathdot displays mathematics (symbols + 2-D structure) — the render
  path from REDUCE output to the notebook. Not the CAS itself, not plots.
- **Sources:** [257](task257_math_symbol_fonts.md) · [258](task258_implement_best_font.md) ·
  [259](task259_improve_math_rendering.md) · [260](task260_improve_even_more.md) ·
  [261](task261_improve_even_some_more.md).
- **Vision:** hold math as a machine-checkable, CAS-backed structure and render it so
  it is legible → beautiful → alive → a medium — always offline, non-blocking, and
  faithful to the CAS meaning.
- **Priority key (MoSCoW):** **P0 Must** · **P1 Should** · **P2 Could** ·
  **P3 Won't-yet** (research/long-arc). IDs are stable (`MR-*`).

---

## A. Foundation — glyph coverage (P0)

| ID | Requirement (the system **shall**…) | Pri | Source | Acceptance |
|---|---|---|---|---|
| MR-F1 | bundle a math-complete font (JuliaMono primary; Noto Sans Math last-resort), OFL-licensed, shipped by the installer | P0 | 258 | fonts land in `{app}\fonts`; installer size ↑ accordingly |
| MR-F2 | attach the math font as a **fallback** on every user-selectable family so no math glyph renders as tofu (□) | P0 | 257/258 | `font_resource("matlab").fallbacks` contains the math font; a notebook with `∫ ∑ ∂ ∇ ≤ ℝ` shows **zero** tofu in every family |
| MR-F3 | apply the same fallback to the "Default" family and the base UI theme | P0 | 258 | toolbar/menus/inputs show math glyphs too |

## B. Symbols & light 2-D structure (P0–P1)

| ID | Requirement | Pri | Source | Acceptance |
|---|---|---|---|---|
| MR-S1 | map operators/words to Unicode in `MathFormatter` (`int→∫`, `sum→∑`, `partial→∂`, `sqrt→√`, `<=→≤`, `>=→≥`, `!=→≠`, `->→→`, `infinity→∞`, Greek, `ℝℂℤℕℚ`) | P0 | 258 | unit: `to_display("int(f,x)")` contains `∫`; `"a<=b"`→`≤` |
| MR-S2 | render numeric **and** negative/parenthesised exponents, plus **subscripts** (`x_1→x₁`) | P1 | 258/259 | unit: `"x^(-2)"→x⁻²`; `"a_ij"` subscripted |
| MR-S3 | enable `RichTextLabel` BBCode and emit `[sup]`/`[sub]` for scripts | P1 | 258/259 | scripts render as true super/subscripts |
| MR-S4 | lay out matrices and stacked fractions via `[table]`/`[cell]` | P1 | 258/259 | a 2×2 matrix / a fraction renders stacked |
| MR-S5 | obtain **structured** output from REDUCE (LaTeX via `rlfi`, or MathML) instead of parsing linear ASCII | P1 | 259 | engine returns a LaTeX/MathML form for a test expr on the `-K 1000m` build |

## C. Quality, performance, accessibility (P1–P2)

| ID | Requirement | Pri | Source | Acceptance |
|---|---|---|---|---|
| MR-Q1 | render LaTeX → **SVG** (bundled offline KaTeX) and embed inline (like plots) | P2 | 259 | a fraction/radical renders as crisp vector, scales with zoom |
| MR-Q2 | **content-address** the rendered-math cache by expression hash (reuse `src-hash`) | P1 | 259 | identical expr renders once; cache hit on re-view |
| MR-Q3 | **pre-render on a worker thread** (reuse task-253 pattern); never block the UI | P1 | 259 | scrolling stays responsive while math typesets |
| MR-Q4 | typographic correctness: variable **italics**, upright function names, TeX operator **spacing**, OpenType features | P2 | 259 | `sin` upright, `x` italic; `∫ f dx` spaced |
| MR-Q5 | crisp-at-any-zoom glyphs (MSDF atlases) | P2 | 259 | zoomed math stays sharp |
| MR-Q6 | **quality tiers** Draft (Unicode) / Standard (BBCode) / Max (LaTeX→SVG), user- or context-selectable | P2 | 259 | switch changes fidelity; Draft stays fast |
| MR-Q7 | accessibility: MathML→**speech**, math-size control independent of prose, high-contrast palette | P2 | 259/261 | screen reader speaks an equation; math size adjustable |

## D. Liveness — from view to instrument (P2–P3)

| ID | Requirement | Pri | Source | Acceptance |
|---|---|---|---|---|
| MR-L1 | **animate derivations** by diffing before/after ASTs and tweening matched subterms | P2 | 260 | a `factor`/`simplify` step plays as a smooth transition |
| MR-L2 | **bidirectional** structural editing: edit the rendered equation → round-trip to REDUCE | P3 | 260 | edit a subterm; CAS state updates |
| MR-L3 | **reactive parametric** equations: bind a symbol to a slider; re-derive + re-typeset live | P2 | 260/261 | dragging `a` updates the formula (and its plot) |
| MR-L4 | **validated faithful render**: re-parse the render and prove equality to the source AST | P2 | 260 | mismatch flagged; a "verified" badge on pass |
| MR-L5 | **multimodal I/O**: ink→math, voice→math, NL→math; math→speech/Nemeth Braille | P3 | 260/261 | sketch/utterance produces valid REDUCE input |
| MR-L6 | **AI step-explanations** from the structured form (local model) | P3 | 260 | each derivation step gets a prose explanation |
| MR-L7 | **spatial / VR** math (OpenXR, Godot-native) | P3 | 260/261 | an equation is inspectable in 3-D/VR |
| MR-L8 | **universal export**: LaTeX · MathML · Typst · OMML · SVG/PNG · speech · Braille | P2 | 259/260/261 | one expr exports to each format losslessly |
| MR-L9 | full-fidelity **offline engine** (microTeX/Typst via WASM) for 100% LaTeX | P3 | 260 | journal-exact output, no network |

## E. Medium — the far frontier (P3)

| ID | Requirement | Pri | Source | Acceptance |
|---|---|---|---|---|
| MR-M1 | **semantic zoom / LOD**: detail level tracks zoom; fold/unfold subexpressions | P3 | 261 | zoom out collapses to `∫=F(b)−F(a)`; zoom in unfolds |
| MR-M2 | **cross-representation morphing**: slide between formula ⇄ graph ⇄ table ⇄ figure ⇄ sim | P3 | 261 | continuous morph between two forms of one object |
| MR-M3 | **reader-adaptive notation** (field/level/convention; notation translation) | P3 | 261 | same expr renders in ≥2 dialects |
| MR-M4 | **proof-carrying** math (Lean/Isabelle); verified vs conjectural, proof explorable | P3 | 261 | a result shows a machine-checked proof |
| MR-M5 | **knowledge-graph tethering** (DLMF/OEIS/arXiv recognition + links) | P3 | 261 | Gaussian integral links to DLMF |
| MR-M6 | **provenance / time-travel** derivation DAG; scrub + branch | P3 | 260/261 | rewind a derivation; branch a counterfactual |
| MR-M7 | **collaborative real-time** editing (CRDT) with presence | P3 | 261 | two users edit one equation live |
| MR-M8 | **multisensory / tangible**: sonify, haptics, 3-D print | P3 | 261 | a structure is audible / printable |
| MR-M9 | **generative / self-improving notation** (learns preferences) | P3 | 261 | novel structure gets readable auto-notation |
| MR-M10 | **uncertainty-native** notation (distributions/intervals/error bars inline) | P3 | 261 | a random term renders with its spread |

## F. Non-functional requirements

| ID | Requirement | Pri |
|---|---|---|
| MR-N1 | **Offline** — core rendering requires no network (bundled fonts/engines only) | P0 |
| MR-N2 | **Pure-Godot preferred** — external engines (KaTeX/microTeX/Typst) only if bundled + offline | P1 |
| MR-N3 | **Licensing** — fonts SIL OFL, KaTeX MIT; ship each `LICENSE`/`OFL.txt` | P0 |
| MR-N4 | **Non-blocking** — all heavy rendering cached + worker-threaded; never freeze the notebook | P1 |
| MR-N5 | **Theme-aware** — math respects the active colour scheme (dark/light/contrast) | P1 |
| MR-N6 | **Platform** — requires TextServer **Advanced** (HarfBuzz/ICU) and the bundled REDUCE `-K 1000m` build | P0 |
| MR-N7 | **Faithful** — the render must not misrepresent the CAS expression (see MR-L4) | P0 |
| MR-N8 | **Testable** — formatter, fallback wiring, cache, and structure covered by `--test126` unit tests | P0 |
| MR-N9 | **Backward-compatible** — existing notebooks render unchanged (Draft tier ≡ today's Unicode path) | P0 |

## G. Phased roadmap

| Phase | Delivers | Requirements |
|---|---|---|
| **1 — Legible** | no tofu; correct symbols + light 2-D | MR-F1–F3, MR-S1–S4, MR-N1/3/6/8/9 |
| **2 — Beautiful** | structured output, LaTeX→SVG, cache, threads, tiers, a11y | MR-S5, MR-Q1–Q7, MR-N2/4/5 |
| **3 — Alive** | animation, reactivity, validation, export, AI/multimodal | MR-L1, L3, L4, L8 → L2, L5–L7, L9 |
| **4 — Medium** | zoom, morphing, provenance, adaptive, proof, graph, collab, senses | MR-M1–M10 |

**80/20:** Phase 1 (MR-F1/F2 especially) removes today's tofu at low risk and is the
prerequisite for everything else.

## H. Traceability

| Source | Requirements introduced |
|---|---|
| 257 (fonts) | MR-F1, MR-F2, MR-N3, MR-N6 |
| 258 (implement) | MR-F1–F3, MR-S1–S4, MR-N8, MR-N9 |
| 259 (improve) | MR-S5, MR-Q1–Q7, MR-L8, MR-N4 |
| 260 (even more) | MR-L1–L9 |
| 261 (some more) | MR-M1–M10, MR-Q7, MR-N5, MR-N7 |

## Files
- This doc only (task 262 asks for a requirements doc — no code changed). It supersedes
  257–261 as the single point of reference for implementing math rendering.
