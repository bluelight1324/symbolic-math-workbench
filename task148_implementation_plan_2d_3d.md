# Task 148 — How to Implement the Task-147 Plotting Upgrades (2-D and 3-D)

This is the engineering plan for the task-147 vision: concrete Godot nodes, APIs,
data flow and code sketches for both 2-D and 3-D, grounded in the current
[plot_panel.gd](app/scripts/plot_panel.gd) (2-D) and `_build_surface3d`
([notebook_view.gd](app/scripts/notebook_view.gd)) (3-D).

## 0. Shared scaffolding (build once, reused by 2-D and 3-D)

1. **New fenced block kinds** in `notebook_runner.gd`
   (`KIND_*` + `kind_for_open`):
   `cas-plot` (have), `cas-plot3d` (have), and new
   `cas-surface` (parametric), `cas-implicit` (f=0), `cas-field` (vector field),
   `cas-anim` (time-animated). `_dispatch_next_block` routes each to a builder.
2. **Sampling layer** — one function that, given an expression + variable grid,
   returns values:
   - plain math → Godot `Expression.parse(expr, vars)` / `.execute(...)`
     (current 3-D path),
   - symbolic/REDUCE → the existing `on rounded; for…collect sub(...)` sampler
     (current 2-D path).
   Both already exist; factor them into `sample1d(expr,x0,x1,n)` and
   `sample2d(expr,gridX,gridY)`.
3. **`PlotTheme`** — pull axis/grid/curve/text colours from `_color_scheme` so
   2-D and 3-D match the notebook (already partly done via `set_theme_colors`).
4. **Quality enum** (Draft / Standard / Max) on a `plot.cfg` — gates the
   GPU-heavy 3-D passes so the default stays cheap (task 140) and "Max" is opt-in.

## 1. 2-D plots — promote `plot_panel.gd` to a `Plot2D`

Keep the custom-`_draw` approach (full control, cheap) and add:

| Feature | Implementation |
|---|---|
| **Multiple series + legend** | `_series: Array[{ys, color, label, style}]`; `set_samples` → `add_series`; `_draw` loops; legend = small boxed `draw_string` list (needs a `Font` ref). |
| **Axis tick marks + numbers** | a "nice numbers" routine (1·10ⁿ, 2·10ⁿ, 5·10ⁿ); for each tick draw a short line + `draw_string(font, pos, "%.3g" % v)`; x-axis from `_x_min/_x_max`, y from data range. |
| **Axis labels / title** | `x_label`, `y_label`, `title` strings drawn at the margins. |
| **Filled area / between curves** | `draw_colored_polygon(points + baseline, fill.with_alpha)`. |
| **Hover crosshair + (x,y) readout** | `mouse_filter = PASS`, `_gui_input`: on motion map px→data, find nearest sample, `queue_redraw` a vertical line + a label `(x, y)`. (Wheel still passes to the page — task 137 pattern.) |
| **Pan + box-zoom** | extend the existing `_zoom` transform with a pan offset (left-drag) and a rubber-band box (shift-drag) that sets `_x_min/_x_max`, `_y_min/_y_max`. |
| **Log / polar axes** | a `map_x/map_y` lambda (linear, `log10`, or polar r,θ→x,y) inserted between data and pixels. |
| **GPU-smooth thick curve** (optional) | swap `draw_polyline(...,true)` for a child `Line2D` (antialiased, `width_curve`, `gradient`) if extra polish is wanted. |
| **Heatmap / 2-D contour** | `sample2d(f)` → fill an `Image` (`set_pixelv`) with a colour ramp → `ImageTexture` on a child `TextureRect`; contour lines via marching-squares over the same grid drawn as `Line2D`s. |
| **2-D vector field** | `MultiMeshInstance2D` of an arrow texture, transform per grid point from `sample2d` of (u,v). |

Data flow: the notebook runner samples each `cas-plot` expression (already does);
multi-series = several expressions in one block (split on lines); heatmap/field =
`sample2d`.

## 2. 3-D plots — a `Plot3D` class with pluggable mesh sources

Refactor `_build_surface3d` into a `Plot3D` node that owns the `SubViewport`,
`world`, `Camera3D`, lights, `WorldEnvironment`, **axes**, **colour-bar**, and a
**mesh source**. Each `cas-*3d` kind supplies a different source:

| Source | How to build |
|---|---|
| **Height field z=f(x,y)** (have) | `SurfaceTool` grid (current code). |
| **Parametric (u,v)→(x,y,z)** (`cas-surface`) | sample `x(u,v),y(u,v),z(u,v)` over a (u,v) grid; same `SurfaceTool` triangulation → tori, spheres, Möbius, Klein. |
| **Implicit f(x,y,z)=0** (`cas-implicit`) | **marching cubes**: sample f on an N³ grid, run a marching-cubes pass → triangles; **or** an SDF ray-march `ShaderMaterial` on a `BoxMesh` (pure GPU, no CPU mesh). |
| **Vector field** (`cas-field`) | `GPUParticles3D` advected by the field in a `process` shader, **or** `MultiMeshInstance3D` of arrow meshes oriented per grid point. |
| **Animated u(t,x)** (`cas-anim`) | a vertex `ShaderMaterial` deforming by `TIME` (GPU), or per-frame vertex rebuild in `_process`; drive playback with a `Tween`/`AnimationPlayer`. |

### Axes, ticks, colour-bar (the biggest readability win)
- **Axes + bounding box**: `ImmediateMesh` (`surface_begin(PRIMITIVE_LINES)`) for
  the 3 axes and the box edges.
- **Tick numbers**: `Label3D` (billboarded) at each tick along the axes.
- **Colour-bar**: a thin quad with a gradient `ShaderMaterial` matching the
  height colour-map, plus min/mid/max `Label3D`s.

### Camera controller
- Extend the current drag-rotate into an **orbit** (yaw/pitch — done), add
  **pan** (middle- or shift-drag → move the look-at target) and **dolly**
  (zoom buttons + optional `Ctrl`+wheel so plain wheel still scrolls the page).
- Optional **inertia**: keep an angular velocity in `_process`.

### Quality mode (`WorldEnvironment`)
- **Draft/Standard**: current (SSAO + soft shadow + bloom + filmic), cheap.
- **Max**: add `sdfgi_enabled`, a `ReflectionProbe` + `ProceduralSkyMaterial`,
  `volumetric_fog_enabled`, DoF (`dof_blur_*`), and supersampling
  (`SubViewport.scaling_3d_scale = 2.0`). Gated by the quality enum so the
  default honours "no extra GPU" (task 140).

### GPU-compute sampling (the scalability unlock)
- A `RenderingDevice` compute shader evaluates f over the grid and writes vertex
  positions into a storage buffer; read back into an `ArrayMesh` (or keep on GPU
  for `cas-anim`, dispatching each frame). Replaces CPU `Expression` sampling →
  100×+ grid density and real-time animation; marching-cubes can run as a second
  compute pass for `cas-implicit`.

## 3. Notebook syntax (what the user writes)

```
```cas-plot              y = f(x)        (2-D; multiple lines = multiple series)
```cas-plot3d            z = f(x,y)      (height field, have)
```cas-surface           x=…; y=…; z=…   over u,v                (parametric)
```cas-implicit          f(x,y,z) = 0                            (marching cubes)
```cas-field             u=…; v=…; w=…   (vector field)
```cas-anim              z = f(x,y,t)    (animated; t is time)
```

`notebook_runner.parse_blocks` already returns `kind`; add the new kinds and a
`Plot3D.from_kind(kind, body)` factory in `_emit_block_cell`.

## 4. Export
- Figure: `vp.get_texture().get_image().save_png(path)`.
- Animation: in `_process`, grab frames to a PNG sequence, then the existing
  pandoc/ffmpeg-on-PATH shell-out assembles an MP4.

## 5. Sequencing (lowest risk → highest)

1. **Axes + tick numbers + colour-bar** (2-D `draw_string`, 3-D `Label3D`/
   `ImmediateMesh`) — pure additive, cheap, biggest clarity gain.
2. **2-D multi-series + legend + hover readout**; **3-D pan/inertia camera**.
3. **Parametric surfaces** (`cas-surface`) — reuses `SurfaceTool`, low risk.
4. **Animated `cas-anim`** via a `TIME` vertex shader — turns PDE `u(t,x)` into
   motion.
5. **Implicit `cas-implicit`** (marching cubes / SDF shader) — new algorithm.
6. **Quality "Max" mode** (SDFGI / reflections / fog / supersampling) — opt-in.
7. **Compute-shader sampling** + **export** — scale + deliverables.

Each step is independently shippable and keeps the existing plots working.

## Files changed
- None — implementation plan / doc ("do 1 doc").
