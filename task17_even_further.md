# Task 17 — Even Further: From Notebook to Reasoning Environment

[Task 16](task16_beyond_zettlr.md) made the notebook smart: reactive cells,
inline typesetting, content-addressed caching, symbolic-aware search and
diff, embedded tests, pluggable kernels, backlinks, mobile targets, LLM
assist. That's the "Observable + Zettelkasten + CAS" frontier.

The next layer is qualitatively different. It pushes the workbench from "a
notebook where computation happens" to **a research environment for working
with mathematics**: it should help you *reason*, not just *compute*; the
editor should manipulate *math*, not just *text*; the output should travel
*beyond a single user's filesystem*.

The improvements below are organised by what they change about the *kind*
of artifact the app produces, not by ambition. They build on every layer
shipped so far — the persistent engine, the sentinel pipeline, the design
tokens, the plot panel, the menu/help framework — and on the proposals from
tasks 15 and 16. Each one explains the *why*, the *how on this stack*, and
the unique advantage we have over a from-scratch competitor.

---

## A. Reasoning, not just computing

### 1. Formal proof checking — `cas-prove` blocks

**Why:** symbolic computation gives you an answer; it does **not** give you a
proof. For research or teaching, that gap matters. The Lean / Coq / Z3
communities have spent two decades building rigorous provers; we should
plug into them, not duplicate them.

**How on this stack:** add a fence kind:

````markdown
```cas-prove backend=z3
forall x, sin(x)^2 + cos(x)^2 = 1
```
````

The block runner pipes the CAS-canonicalised goal into the bundled prover
(child process, same sentinel pattern as the CAS engine) and writes back a
`cas-proof-status` footer: ✅ `proved`, ❌ `disproved`, ⏱ `timed out`, or
🤔 `unknown`. The reactivity engine from task-16 §1 keeps proof results in
sync with the surrounding math.

**Unique angle:** the CAS does the symbolic massage *before* the prover sees
the goal — many results that Z3 can't solve directly become trivial once
factorised or trig-simplified. **CAS + prover** is more capable than either
alone, and nothing in the Lean-mathlib world does it ergonomically.

### 2. Step-by-step derivations, not opaque answers

**Why:** "the answer is `atan(x)`" doesn't teach anything. Mathematica's
classroom mode and Symbolab's step-by-step were the differentiators that
made them million-user products.

**How:** REDUCE exposes its rewrite rules. Instead of one black-box call we
run a *trace* (`trace df;` etc.) and parse the sequence of intermediate
forms into a folded derivation:

```
  ∫ 1/(x² + 1) dx
= [recognise standard form]
= atan(x) + C
```

Each step is a sub-block, individually re-runnable. Long derivations
collapse to a result with an "▾ show steps" disclosure.

**Unique angle:** the engine is right there. No Python+SymPy round-trip, no
LLM hallucination — every step is a *real* rewrite from the CAS's rule
database. Zettlr can't even open this door.

### 3. Equivalence-first search and "find similar"

Task-16 §5 added symbolic-aware search ("find notebooks whose result equals
this"). The improvement on top: **structural similarity** — given a result
like `cos(x)·x + sin(x)`, surface notebooks containing *isomorphic* expressions
(same shape, different variables). Built via REDUCE pattern matching
(`match` + `let` rules), so the lookup is the engine's own native operation.

---

## B. Editing math, not text

### 4. Bidirectional / projectional editing of typeset math

**Why:** LaTeX source in the editor is the part working mathematicians put up
with. Typesetting in-place ([task-16 §2](task16_beyond_zettlr.md)) is good;
**clicking on the typeset math to edit it structurally** is great. Drag a
term across an equals sign and the source regenerates with the term negated;
click a fraction's numerator and edit it directly.

**How on this stack:** the inline typeset image from task-16 §2 becomes a
`Control` with hit-test regions tied to source AST nodes. REDUCE already
gives an internal tree (`prefix`) when asked — we walk it to build the
hit-test map, then re-serialise on edit. Godot's input/`_draw` system makes
the hit-testing straightforward; we already do similar interactivity for
plot sliders.

### 5. Handwriting / stylus input on touch devices

**Why:** the mobile/web targets from task-16 §9 are wasted on a tiny on-screen
keyboard. Tablet + stylus + handwriting recognition is how anyone actually
*does* math on the go.

**How:** Godot has full touch input. A drawing canvas accepts strokes; pipe
them through an on-device math-OCR model (existing local ML, e.g. the
*MathPix* or open *im2latex* models) to LaTeX, then through `rlfi`-aware
parsing into a CAS expression. The same persistent engine evaluates it.

**Unique angle:** Zettlr cannot have this — it has no canvas, no engine
backend. We get it almost for free from Godot's input layer.

### 6. Voice input + spoken answers

The same pipeline with speech: local Whisper-tiny → math grammar parser →
CAS. Spoken answers via a local TTS that pronounces results using the typeset
form ("the integral of one over x squared plus one is arc-tangent of x").

For accessibility and for hands-free work (driving, lab benches), this is the
killer demo Mathematica still doesn't have.

---

## C. Visualisation, not just plots

### 7. 3D plots, vector fields, animations — using Godot's native renderer

The current plot panel uses 2D `_draw` (task-7 §5). Godot's main job is
rendering 3D. The proposal:

- **3D surfaces** for `z = f(x,y)`: build a triangle mesh from sampled
  values, drop it into a `Camera3D` viewport, free pan / orbit via the
  existing input handlers.
- **Parametric curves** in 3D from `{x(t), y(t), z(t)}`.
- **Vector fields** as glyphs sampled on a grid.
- **Animation** via a time-parameter slider — drag `t` and the surface /
  curve / field redraws each frame. Export as MP4 (Godot's
  `VideoStreamPlayer` + ffmpeg shell-out).

**Unique angle:** Zettlr / Jupyter / Observable all hand off 3D to web
WebGL or matplotlib; we just *have* a native, hardware-accelerated 3D
renderer one node away. This is the single biggest engine-choice win the
project ever made, and we've barely used it.

### 8. Manipulable geometric diagrams

For school/university use cases, geometric constructions (circles, lines,
intersections) you can **drag** are huge. Build with Godot's 2D nodes; back
the geometry by CAS (so dragging a point gives the *symbolic* equation of
the line through it). Effectively a Geogebra alternative inside our notebook.

---

## D. Workspace as a living, publishable artifact

### 9. Publish-as-site — workspace → interactive web

A workspace folder is already plain `.md`. Add a "Publish" command that
exports the whole tree as a static site (like Quarto, mdBook, Docusaurus —
but with **live cells**). The site bundles the cached `cas-result` blocks
for instant rendering, and embeds a small web build of the engine
(WASM-compiled REDUCE, or a JS port for the few operations needed) so
readers can edit and re-run.

**Stack fit:** Godot has an HTML5 export target; the engine cache is
already content-addressed, so what gets shipped is small.

### 10. Federated knowledge graph

`[[Note]]` links are intra-workspace. Improvement: support
`[[user/repo#note]]` resolved over Git or via simple HTTPS, with the result
cache from task-16 §3 used as the canonical reference. Build a public
network of citable, reproducible math notebooks — a *math-arXiv with
working code*.

### 11. Curriculum mode — chains of notebooks with progress

A workspace becomes a *course*: prerequisites, exercises, hints, progress
tracking. The `cas-test` blocks from task-16 §8 grade exercises; the LLM
from task-16 §10 generates hints when a student is stuck. Streaks,
flashcard-style spaced repetition for derivations.

For teachers, this is the upgrade path: turn one set of notebooks into a
publishable textbook *and* an interactive class.

---

## E. Engineering improvements

### 12. WASM-compiled engine — eliminate IPC

The piped-subprocess model from
[task 6](task6_combined_app_implementation.md) is robust but adds
~1 ms per call and limits us on the web target. Compiling REDUCE/CSL or
a smaller alternative kernel (e.g. SymPy in Pyodide, or a hand-rolled CAS
in Rust) to WebAssembly and loading it as a Godot extension removes the
process boundary. Same `MathEngine` API, in-process speed.

### 13. Plugin system (GDScript scriptable extensions)

The app exposes hooks: `register_block_kind(name, runner)`,
`register_menu_item(category, label, callable)`, `register_renderer(kind,
fn)`. Plugins are user-authored GDScript files in a `plugins/` folder,
loaded at startup. Lets the community grow the app without touching the
core — and lets advanced users build custom mini-languages (probabilistic
programming, lattice QFT, finance DSL) on top of the engine.

### 14. Local-first CRDT collaboration

Yjs or Automerge as a Godot extension; documents are CRDTs persisted to
the workspace folder. Two users opening the same notebook either via LAN
or via a thin relay see each other's edits live, even offline. Conflicts
are mathematically impossible (the *CRDT* part), not just merged
"heuristically."

This is the productivity-tool feature that turns a single-user app into a
team product.

---

## Priority and progression

| # | Theme       | Effort  | Differentiation                                  |
|---|-------------|---------|--------------------------------------------------|
| 7 | 3D / anim   | Medium  | Massive — engine-choice win finally cashed in    |
| 2 | Step-by-step| Medium  | Classroom-grade differentiator                   |
| 1 | Formal proof| Larger  | Research-grade differentiator                    |
| 12| WASM kernel | Larger  | Performance + web target                         |
| 4 | WYSIWYG math| Larger  | UX leap; reuses task-16 §2 infrastructure        |
| 9 | Publish-as-site | Medium | Distribution; turns notebooks into deliverables |
| 13| Plugin system | Small | Compounding value via community                  |
| 5/6| Stylus/voice | Medium | Only possible because Godot has the input layer  |
| 11| Curriculum mode | Medium | Education vertical                             |
| 8 | Geometric diagrams | Medium | Geogebra-class capability built-in           |
| 14| CRDT collab | Larger  | Team product                                     |
| 10| Federation  | Larger  | Ecosystem; needs critical mass                   |

If I had to commit to a **next three** that would most change the perceived
value of the app:

1. **Step-by-step derivations** — turn answers into teaching tools.
2. **3D plots + animations** — finally use what Godot is best at.
3. **WYSIWYG / projectional math editing** — go from "edit LaTeX, see math"
   to "edit math directly."

These three together change what the app *is*. Tasks 15 and 16 made it a
better notebook. Task 17 makes it the place where you'd actually *do
research* and *teach* — competing with Mathematica's notebook UX, Geogebra's
visualisation, and Lean's rigour, but stitched together with the persistent
engine and editor model the earlier tasks established.

---

## The throughline across tasks 15 → 16 → 17

Looking at the three direction docs together, the trajectory is consistent:

- **Task 15:** make the app *persistent and shareable* (Zettlr baseline).
- **Task 16:** make the persistent app *intelligent* (reactivity, cache,
  symbolic search, embedded tests).
- **Task 17:** make the intelligent app *expressive* (reasoning, structural
  editing, 3D, publishable artifacts).

Every layer leverages the same architectural decisions made early on:
persistent CAS subprocess, sentinel correlation, async result routing,
design-token theme, modular menu/help framework. None of these direction
docs requires throwing earlier work away; they all add *around* the
foundation. That's the strongest argument that the early choices were
right, and that this is a feasible roadmap rather than wishful thinking.
