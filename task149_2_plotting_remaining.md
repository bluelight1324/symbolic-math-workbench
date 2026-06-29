# Task 149.2 — What's Left To Do on the Plots

A status audit of the plotting subsystem against the
[task-148.4 requirements](task148_4_plotting_requirements.md) (R0–R5). Marks each
item **done / partial / todo**, so it's clear what remains.

## Where the plots are today (done)

A genuinely capable, annotated, interactive plotter:

- **2-D `cas-plot`** — curve + grid + axes, **axis tick numbers**, **hover
  crosshair + (x,y) readout**, zoom, bold AA curve, 121-sample. (Inline-graphic
  rendering fixed via src-hash keying.)
- **3-D `cas-plot3d`** — PBR surface with **iso-height contour shader**,
  **Viridis** colormap, SSAO + soft shadows + filmic tonemap + bloom + MSAA8×/FXAA,
  dark background, **bounding box + axis tick numbers + colour-bar**,
  **drag-to-rotate**, zoom, scroll-through.
- **3-D `cas-surface`** — **parametric (u,v) surfaces** (tori, spheres, shells).
- **Calculator plot** — same `PlotPanel` (zoom, bigger).
- **Architecture** — a shared `_plot3d_scene` (pluggable mesh source) +
  `_contour_material`; "no extra GPU by default" honoured.

## What's left, by tier

### R0 — Foundations (mostly TODO)
| Item | Status |
|---|---|
| F1 declarative plot spec (grammar of graphics) | **todo** — kinds are still per-builder |
| F5 quality enum Draft/Standard/**Max** | **todo** |
| F6 visual-regression harness (golden-image diff) | **todo** — only structural unit tests today |
| F7 plugin API `register_plot_kind` | **todo** |
| F8 plot provenance | **partial** — result blocks carry `src-hash`; no full spec embed |

### R1 — Readability / 2-D core (mostly DONE)
| Item | Status |
|---|---|
| axes + tick numbers + colour-bar | **done** |
| Viridis / perceptual colormap | **done** |
| 2-D hover readout; auto y-range | **done** |
| **2-D multiple series + legend** | **todo** |
| **filled regions; log / polar axes** | **todo** |
| 3-D auto-frame / best-view | **partial** (fixed framing) |

### R2 — 3-D reach (parametric DONE, rest TODO)
| Item | Status |
|---|---|
| parametric surfaces (`cas-surface`) | **done** |
| **`cas-anim`** animated `z=f(x,y,t)` (TIME shader / `_process`) | **todo** |
| **`cas-field`** vector fields (`MultiMesh` arrows) | **todo** |
| **`cas-implicit`** `f=0` (marching cubes / SDF shader) | **todo** |
| surface **probe → exact value**; draggable parameters | **todo** |
| camera **pan**; linked/brushed 2-D↔3-D views | **todo** |

### R3 — CAS-graphical fusion (all TODO — the differentiator)
| Item | Status |
|---|---|
| analytic normals from symbolic gradient | **todo** |
| curvature-aware **adaptive sampling** | **todo** |
| exact **singularity / discontinuity** clipping | **todo** |
| exact **level-set contours** (`solve f=c`) | **todo** |
| complex **domain colouring** (`cas-domain`) | **todo** |

### R4 — Output / automation / performance (all TODO)
PNG + **MP4** export; **SVG/PDF/TikZ** export; **WebGL/VR**; animation authoring;
plot **styles/templates**; **sonification**; scrollytelling; **async/threaded**
sampling; LOD/culling; uncertainty/ensemble viz. — **todo**

### R5 — Frontier (all TODO; mostly Godot-native per task 148.7)
symbolic→**GLSL** transpile; **validated/interval** plots; **live GPU PDE sim**;
**neural-field** super-res; **AI** explain / NL→plot (local model); differentiable
inverse design; unified reactive world; semantic plots. — **todo**

## Recommended next builds (cheap, Godot-native, unlocked by the refactor)

The shared `_plot3d_scene` / `_contour_material` make new kinds short — a mesh
source + a `SRC_TO_RESULT` line + a render branch:

1. **`cas-anim`** (animated surface) — biggest wow; a `_process` re-sample with
   `TIME`. Turns the PDE notebooks into motion.
2. **`cas-field`** (vector field) — `MultiMeshInstance3D` arrow glyphs.
3. **`cas-implicit`** (`f=0`) — marching cubes or an SDF ray-march `ShaderMaterial`.
4. **2-D multi-series + legend** + filled regions — in `plot_panel`.
5. **PNG/MP4 export** — `Viewport.get_texture().get_image().save_png` + the
   existing ffmpeg-on-PATH path.
6. **F6 visual-regression harness** — render each kind → diff a golden PNG; makes
   all the rest safe to build.

Then the foundations (F1 spec, F5 quality, F7 plugins) for R3–R5 leverage.

## Honest summary

The plots are **clear, interactive and multi-kind** today (R1 essentially done,
R2 started with parametric surfaces). What's left is the **bulk of R2–R5** plus
the **R0 foundations** — most of it Godot-native and made cheaper by the recent
refactor. The CAS-fusion tier (R3) is the unique differentiator still entirely
ahead; the R5 frontier (symbolic→GLSL, live sim, validated, neural/AI/VR) is the
long arc.

## Files changed
- None — status/audit doc ("do 1 doc").
