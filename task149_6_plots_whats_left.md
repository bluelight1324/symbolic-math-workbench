# Task 149.6 — What's Left to Do in the Plots

A **current** status of the plotting subsystem, taken *after* task 149.5 (implicit
surfaces + the nested-`^` parser fix). This supersedes the snapshot in
[149.2](task149_2_plotting_remaining.md); for the *benefit/payoff* of each
remaining item see the catalogue in [149.4](task149_4_remaining_benefits.md). This
doc focuses on **what is still missing and where the seams are now**.

## Where the plots stand today (done)

| Capability | Block | Status |
|---|---|---|
| 2-D function curves | `cas-plot` | ✅ zoom, hover read-out, axis ticks/numbers |
| 3-D height fields `z=f(x,y)` | `cas-plot3d` | ✅ lit, contour shader, Viridis, box, colour-bar, drag-rotate, zoom |
| Parametric `(u,v)` surfaces | `cas-surface` | ✅ same 3-D scene |
| Animated `z=f(x,y,t)` surfaces | `cas-anim` | ✅ real-time re-sample (149.3) |
| Vector fields | `cas-field` | ✅ MultiMesh arrows, magnitude colour (149.3) |
| **Implicit surfaces `f(x,y,z)=0`** | `cas-implicit` | ✅ Surface Nets (149.5) |
| Power with nested parens `(…)^2` | all 3-D kinds | ✅ balanced-paren parser (149.5) |

Shared plumbing: one `_plot3d_scene` (any `Node3D`), one contour material, one
`_make_plot3d_cell`, content-addressed result caching, 68 passing unit tests.

## What's left

### 0. Polish on what was just built (new seams from 149.3 / 149.5)
- **Implicit-surface build is synchronous** — meshing runs on the main thread, so a
  fine grid briefly freezes the UI. Needs threaded/async sampling (see §5).
- **Implicit resolution is fixed & modest** (grid `N=20`) — thin features and sharp
  corners are rounded. Wants higher/adaptive resolution and smoother normals.
- **Surface-Nets normals/winding aren't globally consistent** — it renders both
  sides (cull-disabled) so it always *reads*, but lighting on the inner shell is
  approximate; consistent winding or analytic normals would fix it.
- **Animated surfaces don't share a clock** — each `cas-anim` runs its own timer;
  no global play/pause/scrub (see §3 interaction, §4 animation authoring).
- **No on-cell export** — none of the rendered plots can be saved to a file yet.

### 1. New plot *kinds* still missing
- **`cas-domain`** — complex `f(z)` domain colouring (poles, zeros, branch cuts).
- **`cas-stream`** — streamlines/trajectories of a vector field (more readable than
  arrows for flow).
- **`cas-implicit2d`** — implicit *curves* `f(x,y)=0` in the 2-D panel (marching
  squares; the 2-D analogue of what 149.5 did in 3-D).

### 2. 2-D panel gaps
- **Multiple series + legend** (compare curves on one axis) — the single most
  common 2-D need.
- **Filled regions / between-curves** (shade integrals, bands).
- **Log / semilog / polar axes.**

### 3. Interaction
- **Probe** — click a surface/curve to read the exact symbolic value + gradient.
- **Draggable parameters** — bind a slider to a symbol; surface deforms live.
- **Camera pan** and **linked/brushed views** (2-D selection → 3-D highlight).
- **Shared animation transport** (global play/pause/scrub/speed for `cas-anim`).

### 4. Output & reach (nothing here exists yet)
- **PNG** figure export (the 3-D `SubViewport` makes this small) and **MP4** of an
  animated surface.
- **Vector SVG / PDF / TikZ** for publication.
- **WebGL** embed; **VR/AR** (OpenXR) walk-around.
- **Animation authoring** (keyframe timeline) and **style templates** (paper/slide/dark).

### 5. CAS-fusion, performance, foundations (the differentiators)
- **CAS-fusion:** analytic normals (symbolic gradient), curvature-adaptive sampling,
  exact singularity/discontinuity clipping, exact `solve f=c` contour curves.
- **Performance:** threaded sampling (fixes §0 freeze), LOD/culling for big meshes.
- **Foundations:** a declarative plot spec (grammar of graphics), a visual-regression
  (golden-image) harness, a Draft/Standard/Max quality switch, a `register_plot_kind`
  plugin API.

### 6. Frontier (long arc, mostly Godot-native — see task 148.7)
Symbolic→GLSL transpile (per-pixel exact, infinite zoom) · validated/interval plots ·
live GPU PDE simulation · neural-field super-resolution · AI explain / NL→plot ·
differentiable inverse design.

## Recommended next three (value-per-effort)

1. **2-D multiple series + legend** — biggest everyday 2-D gap, self-contained in
   `plot_panel`.
2. **PNG / MP4 export** — small (the 3-D viewport already has a texture), unlocks
   getting figures *out* of the app, including clips of the new animated surfaces.
3. **Threaded sampling** — directly removes the implicit/anim main-thread freeze
   noted in §0 and makes higher-resolution surfaces practical.

After those, the **CAS-fusion** group (§5) is the real moat — exact normals,
contours, and singularity handling are things only a CAS-in-an-engine can do.

## Files changed
- None — status / gap doc ("do 1 doc").
