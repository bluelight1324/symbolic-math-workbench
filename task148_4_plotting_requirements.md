# Task 148.4 — Consolidated Requirements: mathdot Plotting (Tasks 147–148.3)

A single requirements document for **all** plotting improvements proposed across
tasks 147, 148, 148.1, 148.2, 148.3 — deduplicated, ID'd, ranked by dependency and
value, with effort and a tiered roadmap. (Same spirit as
[task18_requirements.md](task18_requirements.md).)

## 1. Vision

Turn mathdot's plotting from "charts drawn in a window" into a **CAS-driven,
GPU-native, interactive, reproducible 3-D instrument** — plots that know their own
mathematics, run as live simulations, can be manipulated and composed, are
publication- and web-ready, and are provably faithful.

## 2. Scope & ranking criteria

- **In scope:** the 2-D + 3-D plotting subsystem (`plot_panel.gd`,
  `_build_surface3d`, the `cas-plot*` block kinds) and its supporting
  architecture.
- **Non-goals (here):** the notebook engine, the CAS itself, non-plot UI.
- **Rank by:** (1) is it a *foundation* others depend on; (2) value per unit
  effort; (3) does it honour the "cheap by default, opt-in for heavy GPU" rule
  (task 140). Effort: **L** ≤ a few days, **M** ≤ a sprint, **H** > a sprint /
  research.

## 3. Master requirements

### R0 — Foundations (everything depends on these)

| ID | Requirement | Src | Dep | Effort |
|---|---|---|---|---|
| F1 | **Declarative plot spec** — a `{kind, expr, domain, colormap, axes, quality, anim}` dictionary; plots become serialisable data, not ad-hoc code | 148.1 | — | M |
| F2 | **New fenced kinds** `cas-surface`, `cas-implicit`, `cas-field`, `cas-anim`, `cas-domain` in `notebook_runner` | 148/.1/.2 | — | L |
| F3 | **`Plot2D` / `Plot3D` classes** with a pluggable **mesh-source** interface | 148 | F1,F2 | M |
| F4 | **Sampling layer** `sample1d/2d` (Godot `Expression` + REDUCE `sub`) factored out | 148 | — | L |
| F5 | **Quality enum** Draft/Standard/Max gating GPU-heavy passes | 148,140 | F3 | L |
| F6 | **Visual-regression harness** (render→PNG→diff golden) in the `--test126` style | 148.1 | F3 | M |
| F7 | **Plugin API** `register_plot_kind(name, builder)` | 148.1 | F1,F3 | L |
| F8 | **Plot provenance** — embed full spec+engine+grid+seed in the result (extends `src-hash`) | 148.2 | F1 | L |

### R1 — Readability & 2-D core (highest value/effort)

| ID | Requirement | Src | Dep | Effort |
|---|---|---|---|---|
| A1 | **Axes + tick numbers + bounding box + colour-bar** (2-D `draw_string`; 3-D `Label3D`/`ImmediateMesh`) | 148 | F3 | M |
| A2 | Perceptual / CVD-safe / cyclic **colour-maps**, auto-chosen by data type | 148.1/.2 | F1 | L |
| A3 | **Auto-frame** + auto axis ranges/ticks; best-view detection | 148.1 | F3 | L |
| 2D1 | 2-D **multiple series + legend** | 148 | F3 | L |
| 2D2 | 2-D **hover crosshair + (x,y) readout** | 148 | F3 | L |
| 2D3 | 2-D **pan + box-zoom + autoscale** | 148 | F3 | L |
| 2D4 | 2-D filled regions, log/polar axes, `Line2D` GPU curves | 148 | F3 | M |
| 2D5 | 2-D **heatmap / contour / vector field** | 148 | F4 | M |

### R2 — 3-D reach & interaction

| ID | Requirement | Src | Dep | Effort |
|---|---|---|---|---|
| 3D1 | **Parametric surfaces** (`cas-surface`) | 148 | F3 | M |
| 3D2 | **Orbit / pan / dolly camera** + inertia (extends drag-rotate) | 148 | F3 | M |
| 3D3 | **Probe surface → exact symbolic value** (ray-pick + REDUCE `sub`) | 148.1 | F3 | M |
| 3D4 | **Draggable parameters** (slider/point bound to a symbol → live re-mesh) | 148.1 | F1,F3 | M |
| 3D5 | **Animated surfaces** (`cas-anim`, `TIME` vertex shader) | 148 | F3 | M |
| 3D6 | **Implicit surfaces** (`cas-implicit`; marching cubes or SDF ray-march) | 148 | F3 | H |
| 3D7 | **Vector / tensor fields** (`GPUParticles3D`/`MultiMesh`; ellipsoid glyphs) | 148/.2 | F3 | M |
| 3D8 | **Linked / brushed** 2-D↔3-D views | 148.1 | F1 | M |

### R3 — CAS-graphical fusion (the differentiator)

| ID | Requirement | Src | Dep | Effort |
|---|---|---|---|---|
| C1 | **Analytic normals** from the symbolic gradient | 148.1 | F4 | L |
| C2 | **Curvature-aware adaptive sampling** (uses `df`) | 148.1 | F4 | M |
| C3 | **Exact singularity/discontinuity** handling + mesh clipping | 148.1 | F4 | M |
| C4 | **Exact level-set contours** (`solve(f=c)`) | 148.1 | F4 | M |
| C5 | **Complex domain colouring** (`cas-domain`, `repart`/`impart`) | 148.1 | F2,F4 | M |
| C6 | **Numerical hardening** (NaN/complex/pole), informed by C3 | 148.1 | C3 | L |

### R4 — Output, automation, performance

| ID | Requirement | Src | Dep | Effort |
|---|---|---|---|---|
| O1 | **PNG figure + MP4 animation** export (Viewport image + ffmpeg path) | 148/.1 | F3 | L |
| O2 | **Vector SVG/PDF** + **TikZ/PGFPlots** export (from sample arrays) | 148.1 | F1 | M |
| O3 | **WebGL (HTML5)** export of interactive plots | 148.1 | F3 | M |
| O4 | **VR / AR** (OpenXR) viewing | 148.1 | F3 | H |
| U1 | **Animation authoring** (keyframe camera + params timeline) | 148.1 | F1,3D5 | M |
| U2 | **Plot styles / templates** (paper / slide / dark) | 148.1 | F1 | L |
| U3 | **Sonification** + screen-reader descriptions (accessibility) | 148.2 | F1 | M |
| U4 | **Scrollytelling** + math-anchored annotations | 148.2 | F1,U1 | M |
| P1 | **Async/threaded sampling** (`WorkerThreadPool`) | 148.1 | F4 | M |
| P2 | **LOD + frustum/distance culling** | 148.1 | F3 | M |
| P3 | **Uncertainty / ensemble** visualisation; units on axes | 148.2 | A1 | M |

### R5 — Frontier (research-grade)

| ID | Requirement | Src | Dep | Effort |
|---|---|---|---|---|
| X1 | **Symbolic → GLSL transpilation** (REDUCE AST → shader; per-pixel exact, zero CPU sampling) | 148.3 | F4 | H |
| X2 | **Validated / interval (Taylor-model) plots** + certificate | 148.3 | F4 | H |
| X3 | **Live GPU PDE simulation** (compute-shader solver drives the surface) | 148.2 | X1 | H |
| X4 | **Automated discovery** (critical points / symmetry / bifurcation atlas) | 148.3 | F1 | H |
| X5 | **Neural-field** representation / super-resolution | 148.2 | F4 | H |
| X6 | **AI auto-explanation** + **NL→plot** (compiles to F1 spec) | 148.2 | F1 | M |
| X7 | **Differentiable pipeline / inverse design**; on-manifold optimisation | 148.3 | X1 | H |
| X8 | **Unified reactive notebook world** + dependency-DAG | 148.3 | F1,F3 | H |
| X9 | **Plot algebra / sketch-to-function**; **semantic/Zettelkasten links** | 148.3 | F1 | H |

## 4. Tiered roadmap (ship order)

1. **R0 Foundations** — F1–F8. Nothing else is clean without the spec, the
   Plot2D/Plot3D classes, the sampling layer, the quality gate, and the
   visual-regression harness. (1 sprint)
2. **R1 Readability + 2-D core** — axes/ticks/colour-bar, colour-maps,
   auto-frame, multi-series, hover, pan/zoom. Biggest clarity-per-effort. (1 sprint)
3. **R2 3-D reach** — parametric surfaces, orbit/pan camera, probe, draggable
   params, animation. (1–2 sprints)
4. **R3 CAS fusion** — analytic normals, adaptive sampling, exact
   singularities/contours, domain colouring. The moat. (1–2 sprints)
5. **R4 Output/automation/perf** — export, styles, sonification, scrollytelling,
   async/LOD, uncertainty. (1–2 sprints)
6. **R5 Frontier** — symbolic→GLSL first (unlocks live sim + differentiable),
   then validated plots, discovery, neural fields, reactive world. (research)

## 5. Cross-cutting acceptance criteria (Definition of Done)

- Every new plot kind: parses, renders, **passes a golden-image regression test**
  (F6), carries provenance (F8), and respects the quality gate (F5).
- No regression to existing behaviour: page-scroll-through (task 137), drag-rotate
  (142), zoom (136), contour shader (143) all still pass `--test126`.
- "Standard" quality adds **no** GPU cost over today's default; all heavy passes
  live behind "Max" (task 140).
- Docs + a sample notebook per kind in `notebooks_sample`.

## 6. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Scope explosion (~60 reqs) | strict tiers; R0–R3 deliver 80% of value; R5 is explicitly research |
| GPU cost creeping into the default | the F5 quality gate is a *foundation*, enforced by an acceptance test |
| Symbolic→GLSL (X1) coverage gaps | transpile a defined subset; fall back to CPU/`Expression` sampling otherwise |
| Visual changes hard to verify | the F6 regression harness is built in R0, before the visual features |
| Heavy items (VR, neural, validated) over-promised | gated to R5, clearly labelled research; nothing below depends on them |

## 7. Honest notes

- **R0–R2 are the real product** — a clear, annotated, interactive, multi-kind
  plotter. R3 (CAS fusion) is the unique differentiator. R4–R5 are upside.
- Effort totals are large; this is a *menu and an order*, not a commitment to all
  60. The dependency column makes any subset buildable safely.
- Most items are **named Godot/REDUCE facilities, not new dependencies** — the
  engine and CAS already ship what's required (the exceptions, R5's neural/AI/RT,
  are flagged).

## Files changed
- None — this is the requirements document requested ("do a requirements doc").
