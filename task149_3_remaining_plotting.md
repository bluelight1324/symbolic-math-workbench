# Task 149.3 — Build the Remaining Plotting (Animated Surfaces + Vector Fields)

## Request

> "Do what's remaining and complete the plotting functionality."

Working the recommended next builds from the [149.2 audit](task149_2_plotting_remaining.md).
This session I built the two headline missing **plot kinds** — animated surfaces
and vector fields — both pure Godot, both reusing the shared `_plot3d_scene`. The
heavier remaining items (CAS-fusion R3, export R4, frontier R5) are documented as
still ahead rather than rushed.

## Built and verified

### 1. `cas-anim` — animated `z = f(x, y, t)` surfaces
A new node, [anim_surface.gd](app/scripts/anim_surface.gd) (a `MeshInstance3D`),
**re-samples f and rebuilds the mesh every frame** with `t = elapsed time`
(`_process`, capped to ~25 fps), so the surface **evolves in real time**. Pure
Godot — `Expression` + `SurfaceTool`. It renders through the same lit/contoured
viewport, Viridis colormap, bounding box, colour-bar and drag-rotate as the static
surfaces. Demos: a travelling wave `sin(x+t)cos(y)` and an expanding ripple
`sin(2(x²+y²)−3t)` — both animate. (`app_screenshot_task1493_anim.png`.)

### 2. `cas-field` — vector fields
Give `u = …; v = …; w = …` in `x, y`; an **arrow glyph per grid point** is drawn
with a single `MultiMeshInstance3D` (one draw call), each arrow oriented along the
vector, **length and colour by magnitude** (Viridis). Pure Godot. Demos: a
rotational field `(−y, x, 0)` and a saddle with vertical swirl.
(`app_screenshot_task1493_field.png` shows the 11×11 arrow grid.)

### Shared plumbing
- `_plot3d_scene` was generalised from `MeshInstance3D` to **`Node3D`**, so a
  `MultiMeshInstance3D` (field) or the animated node both drop in.
- `_make_plot3d_cell` factors the framed result cell shared by the new kinds.
- `notebook_runner` gained `cas-anim` / `cas-field` (fence recognition,
  `SRC_TO_RESULT`), so both **run and write result blocks** like every other kind.

## Verification

- **Unit tests** (`--test126`): **61 / 61 pass** — 8 new: `cas-anim`/`cas-field`
  builders return a plot wrapper (bad input → `Label`), and both kinds are parsed
  and made runnable by `pair_blocks`.
- **Integration** (`--demo-dyn`): `dynamic_plots.md` runs with no
  script/parse/shader errors; **2 `cas-anim` + 2 `cas-field` result blocks**
  written; the animated surfaces and the arrow field render in-app.

## Still remaining (honest)

The plotting now covers **2-D curves, 3-D height fields, parametric surfaces,
animated surfaces, and vector fields** — but not yet:

- **`cas-implicit`** `f(x,y,z)=0` — needs marching cubes (a ~150-line table +
  algorithm) or an SDF ray-march shader; the biggest remaining *kind*. Godot-native.
- **2-D multi-series + legend**, filled regions, log/polar — `plot_panel` work.
- **R3 CAS-fusion** (analytic normals, adaptive sampling, exact singularity
  clipping, exact contours, complex domain colouring) — the differentiator.
- **R4 output** (PNG/MP4/SVG/TikZ, WebGL/VR, sonification, scrollytelling) and
  **R5 frontier** (symbolic→GLSL, validated/interval, live GPU PDE solve, neural,
  AI) — the long arc; most are Godot-native (task 148.7) but each is substantial.

The shared `_plot3d_scene` / `_contour_material` / `_make_plot3d_cell` keep each
*new kind* a short addition; `cas-implicit` and 2-D multi-series are the clear
next two.

## Files changed
- `app/scripts/anim_surface.gd` — new animated-surface node.
- `app/scripts/notebook_view.gd` — `_build_anim3d`, `_build_field3d`,
  `_make_plot3d_cell`; `_plot3d_scene` → `Node3D`; dispatch + render routing.
- `app/scripts/notebook_runner.gd` — `cas-anim` / `cas-field` kinds + pairing.
- `app/scripts/main.gd` — `--demo-dyn` flag.
- `app/scripts/_test126.gd` — 8 new assertions (now 61/61).
- `app/notebooks_sample/dynamic_plots.md` — demo notebook.
