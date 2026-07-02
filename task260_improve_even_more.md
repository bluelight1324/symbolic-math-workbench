# Task 260 — How to Improve on Math Rendering *Even More* (the frontier)

Fourth in the sequence — [257](task257_math_symbol_fonts.md) (best font),
[258](task258_implement_best_font.md) (implement), [259](task259_improve_math_rendering.md)
(improve: structured LaTeX/MathML → cached SVG, polish, tiers). This doc answers
**"how will you improve on the above even more?"** — the frontier that takes mathdot
past *static publication-grade* into **live, animated, multimodal, validated, and
spatial** math. Research-grade and long-arc; most are Godot-native or WASM-embeddable.
(A doc; these are future work.)

## Where 259 tops out

259's ceiling is a **beautiful but static picture** of an expression: REDUCE → LaTeX
→ SVG, cached, zoom-crisp. Excellent to *read* and *print* — but it is still a
one-way, frozen, silent, flat, screen-bound image. Every item below breaks one of
those five walls: **one-way, frozen, silent, flat, screen-bound.**

## 1. Animated derivations — equations that *move* (the standout)

Not a new picture per step, but a **smooth choreography** between steps: terms
slide, cancel, factor, and combine (manim / 3Blue1Brown style). Because REDUCE gives
the **before and after AST** of every `simplify`/`factor`/`solve` step, mathdot can
**diff the two trees** and tween matched subterms — Godot's `Tween` + the SVG/box
layout already give per-glyph positions. A derivation becomes a short film, not a
wall of lines. This is the highest-value pedagogical leap and squarely in Godot's
wheelhouse (it's an animation engine).

## 2. Bidirectional, structural math — the render is *editable* (breaks "one-way")

Today display is output only. Make the typeset equation a **live, structural editor**:
click a subterm to select it, drag to rearrange, type to replace — and every edit
**round-trips back into REDUCE** (WYSIWYG ↔ CAS). The MathML/AST from 259 is the
shared model; the renderer becomes an editor over it. Math you *manipulate*, not just
view — the difference between a PDF and a spreadsheet.

## 3. Reactive, parametric equations (breaks "frozen")

Bind a symbol to a slider (reusing the draggable-parameter idea from the plot
backlog): the equation **re-derives and re-typesets in real time** as you drag `a`,
staying exact via the CAS. Couple it to a plot of the same expression and you have a
**reactive math document** — change a coefficient, watch both the formula and its
graph update together.

## 4. Validated / faithful rendering — typesetting that *cannot lie* (trust)

Mirror the "validated plots" frontier: after rendering, **re-parse the rendered form
and prove it equals the original CAS AST** (round-trip equality check). A badge marks
each equation as *verified faithful*. No silent precedence/bracket errors ever reach
the page — the render is guaranteed to mean what the CAS meant. Uniquely possible
because both sides are machine-checkable expressions.

## 5. Symbolic → GPU math (breaks "flat/blurry", enables live morphs)

Mirror the plotting "symbolic→GLSL" frontier for *notation*: render glyph outlines
and structure as **signed-distance fields on the GPU**, so equations are
infinite-resolution, freely animatable (item 1), and cheap to transform (zoom,
morph, colour-pulse a term) — the same crisp-at-any-zoom experience mathdot's plots
already have, applied to the math itself.

## 6. Multimodal input — ink, voice, natural language (breaks "silent", eases input)

- **Ink → math:** sketch an equation with mouse/stylus; an on-device recognizer turns
  strokes into REDUCE input. The most natural way to enter math.
- **Voice → math:** "integral of x squared dx" → LaTeX/REDUCE (local speech model).
- **NL → math:** type a problem in plain language; a local model proposes the CAS
  form (echoing the plotting "NL→plot" idea).
- **Math → speech / Braille (Nemeth):** read equations aloud and drive refreshable
  Braille — accessibility *and* a new channel.

## 7. AI-native math (explanation + intent)

A **local LLM** layered on the structured representation: auto-caption each equation,
**explain each step** of a derivation in prose, flag likely-intended next moves, and
translate between "what the user meant" and the exact CAS expression. Turns a result
into a tutor.

## 8. Spatial / VR math (breaks "screen-bound")

Render equations in **3-D / VR** (OpenXR, Godot-native — matching the VR-plot idea):
walk around a large tensor expression, manipulate matrix entries in space, lay out a
**commutative diagram** or proof tree you can inspect from any angle. Math as an
environment, not a line.

## 9. Perfect-fidelity, fully-offline engine

Beyond KaTeX's subset: embed a **real typesetting engine via WASM** — **microTeX**
(Rust, LaTeX-complete) or **Typst** (fast, modern, scriptable) — for 100% fidelity
with zero network, keeping the "pure-offline bundled app" promise while matching a
journal's output exactly.

## 10. Universal interchange — one model, every format

From the single structured representation, export **LaTeX · MathML · Typst · Unicode ·
SVG/PNG · Word OMML · speech · Nemeth Braille · Content-MathML** (semantic). mathdot
becomes a **math hub** — paste out to any tool, read in from any source — not a
dead-end viewer. (Extends the plot PNG/SVG export story to notation.)

## Ranking — the "even more" worth doing first

| # | Improvement | Wall it breaks | Leverage |
|---|---|---|---|
| 1 | **Animated derivations** | frozen | ★★★ pedagogy, native to Godot |
| 4 | **Validated faithful render** | trust | ★★★ uniquely possible, cheap on top of 259 |
| 2 | **Bidirectional structural editing** | one-way | ★★★ turns viewer into tool |
| 3 | **Reactive parametric equations** | frozen | ★★ pairs with plots |
| 7 | **AI step-explanations** | silent | ★★ tutor value |
| 6 | **Multimodal (ink/voice/NL/Braille)** | silent/input | ★★ reach + accessibility |
| 5 / 8 / 9 / 10 | GPU-SDF · VR · WASM-TeX · universal export | flat / screen / fidelity | ★ long arc |

## Bottom line

259 makes math **beautiful**. 260 makes it **alive**: derivations that animate (1),
renders that are provably faithful (4), equations you can edit back into the CAS (2)
and drive with sliders (3), explained by an AI (7), entered by ink or voice (6), and
one day inhabited in VR (8) — all on one structured, validated, universally-exportable
representation. The through-line: because both the math *and* its picture are
machine-checkable expressions, mathdot can do things a PDF or a web renderer
fundamentally cannot.

## Files
- This doc only (task 260 asks "how will you improve even more" — no code changed).
  Items 1 and 4 are the highest-value, most-tractable frontier follow-ups.
