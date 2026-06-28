# Task 148.1 — How to Improve *On* the Plotting Plan

Task 148 maxes out *rendering*. The next tier is the leap a tool gets from being
**a CAS *and* a game engine at once** — things a plain plotter (or a plain
renderer) can't do. These improve on the plan along seven axes.

## A. Symbolic–graphical fusion (the biggest, most unique win)

The renderer currently samples f numerically and is blind to the maths. Let
REDUCE *inform* the graphics:

- **Adaptive, curvature-aware sampling.** Ask REDUCE for f′/f″ (it already does
  `df`); refine the mesh where |f″| is large, coarsen where flat → publication
  smoothness at the *same* triangle budget. (148 uses a uniform grid.)
- **Exact singularity / discontinuity handling.** REDUCE knows where f is
  undefined (poles, branch cuts, `abs(s)` cusps — cf. task 135). Query those and
  **clip the mesh** / draw asymptote planes instead of the current "skip
  non-finite" guess. No more spurious spikes across a pole.
- **Exact level sets.** Replace the shader's approximate iso-bands with **true
  contours**: `solve(f = c, …)` per level → crisp analytic curves, even where the
  surface is steep.
- **Analytic normals for lighting.** Use the symbolic gradient `(∂f/∂x, ∂f/∂y)`
  for exact per-vertex normals instead of `generate_normals()` → perfect shading.
- **Domain colouring of complex functions** — a *whole new plot class*. For
  f: ℂ→ℂ, colour each pixel by hue = arg f(z), brightness = |f(z)| (REDUCE gives
  `repart`/`impart`). One `cas-domain` block visualises complex analysis.

## B. Direct manipulation (GeoGebra-class interaction)

- **Draggable parameters.** A slider (or a draggable point in the scene) bound to
  a symbol `a`; on drag, re-`sub` and re-mesh live → explorable explanations. The
  CAS makes this exact, not interpolated.
- **Probe the surface.** Click a point → ray-pick the mesh, map back to (x,y), and
  show the **exact symbolic value** f(x,y) and gradient there (REDUCE `sub`), not
  just the interpolated z.
- **Linked / brushed views.** Select a region on the 2-D plot → highlight the
  matching band on the 3-D surface (shared data model).

## C. Publication-grade output (beyond raster PNG)

- **Vector export (SVG / PDF)** for 2-D — crisp, infinitely-scalable figures for
  papers, generated from the same sample arrays (not a screen grab).
- **TikZ / PGFPlots export** — drop a mathdot plot straight into a LaTeX document.
- **Offline high-fidelity render** — a compute-shader path tracer (or a Blender
  bridge: export the mesh + camera as glTF) for ray-traced publication stills,
  beyond the real-time raster path of task 148.

## D. Reach — the same plot, everywhere (Godot exports natively)

- **Web (HTML5/WebGL2)** — Godot's web export turns an interactive plot into a
  page; exported notebooks could embed *live, rotatable* figures.
- **VR / AR (OpenXR)** — walk around the PDE solution at room scale; the time
  ellipsoid or curved-spacetime surface in 3-D space.
- **Stereoscopic / anaglyph** — cheap depth for talks.

## E. Automation & UX intelligence

- **Auto-everything**: fit the camera to the data (auto-frame), pick axis ranges
  and ticks from the data, and choose a **perceptual, data-aware colour-map**
  (viridis/turbo, reversed for diverging data) instead of a fixed HSV ramp.
- **"Best view" detection** — orient the camera to maximise visible surface area.
- **Animation authoring** — keyframe camera + parameters on a timeline; render to
  MP4 (the ffmpeg-on-PATH path) — turn a parameter sweep into a clip.
- **Plot styles / templates** — named looks (paper, slide, dark) like the
  existing notebook "Looks".

## F. Performance & robustness ceiling

- **Async / threaded sampling** (Godot `WorkerThreadPool`) so a 200×200 grid or a
  marching-cubes pass never blocks the UI.
- **Level-of-detail (LOD)** — coarse mesh while orbiting, refine when still;
  frustum/distance culling for huge surfaces.
- **Numerical hardening** — graceful handling of complex/overflow/NaN values
  (informed by REDUCE's domain knowledge, axis A), with optional clipping volumes.

## G. Architecture — make it a *grammar*, not ad-hoc code

- **Declarative plot spec** (a grammar-of-graphics / Vega-lite-style dictionary):
  `{kind, expr, domain, colormap, axes, quality, anim}`. Plots become data, so
  they're serialisable, themeable, testable, and scriptable — a big step up from
  the per-kind builder functions of task 148.
- **Visual-regression tests** — render each plot kind to an image and diff against
  a golden PNG in the `--test126`-style harness, so graphics changes are caught
  automatically (today only structure is unit-tested).
- **Plugin API** — `register_plot_kind(name, builder)` so new plot types (and
  community ones) drop in without touching core.

## Priority — what actually moves the needle first

1. **Analytic normals + adaptive sampling + exact singularities** (axis A) — uses
   the CAS we already have; immediately better, more correct surfaces.
2. **Probe-the-surface readout + draggable parameter** (axis B) — turns figures
   into explorable explanations.
3. **Perceptual colormap + auto-framing + vector (SVG) export** (axes E, C) —
   publication quality.
4. **Declarative plot spec + visual-regression tests** (axis G) — makes all the
   rest cheap and safe to build.
5. **Web export, then VR** (axis D) — reach, once the above is solid.

## Bottom line

Task 148 makes the *picture* maximal. Improving on it means making the plot
**know its own mathematics** (CAS-informed sampling, exact singularities and
contours, complex-domain colouring), **manipulable** (drag parameters, probe
exact values), **publication- and web-ready** (vector + WebGL + VR export), and
**principled** (a declarative spec with visual-regression tests). Those are the
moves a CAS-in-a-game-engine can make that nothing else in this category can.

## Files changed
- None — this is the "how will you improve on the above" doc ("do 1 doc").
