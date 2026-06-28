# Task 147 — Maximizing mathdot's Plotting with Godot, to the Full

## Question

> "How will you improve the graphing/plotting ability of mathdot to the maximum
> possible graphical level, considering it uses Godot? Use Godot's capabilities
> to the full."

mathdot already renders plots inside a real-time game engine, so its ceiling is
not "a chart library" — it's "a real-time 3-D renderer + GPU compute + a scene
graph." This doc lays out, end to end, how to drive the plotting to that ceiling,
mapping every improvement to a concrete Godot facility.

## Where we are now (the baseline this builds on)

- **2-D** (`plot_panel.gd`): custom `_draw` curve, axes, grid; theme-coloured;
  120-sample; zoom (tasks 99, 136).
- **3-D** (`_build_surface3d`): `ArrayMesh` surface, PBR `ShaderMaterial` with
  **iso-height contour lines**, height colour-map, SSAO, soft shadows, filmic
  tonemap, bloom, MSAA 8× + FXAA, dark background, **drag-to-rotate** + zoom
  (tasks 126, 136–143).

That already uses a slice of Godot. The rest of the engine is the headroom.

## 1. 2-D plotting → maximum

| Capability | Godot facility |
|---|---|
| GPU-smooth, thick, glowing curves | `Line2D` (antialiased, width-curve, gradient) instead of `draw_polyline`; or a canvas `ShaderMaterial` |
| Multiple series + legend, axis tick **numbers**/labels | `Label`/`Font.draw_string` in `_draw`; a `Theme`d legend box |
| Filled areas / between-curves shading | `Polygon2D` with a gradient |
| Crosshair + live (x, y) readout on hover | `_gui_input` + a follow label (the data is already sampled) |
| Pan + box-zoom + autoscale | extend the existing zoom transform with drag-pan and a fit button |
| Log / semilog / polar axes | a coordinate-transform function feeding `_draw` |
| Heatmaps / 2-D contour / vector fields | a `TextureRect` fed by an `Image` (or a canvas shader) sampling f(x,y); arrows via `MultiMesh` |
| Parametric & implicit 2-D curves | sample (x(t), y(t)); marching-squares for f(x,y)=0 |

## 2. 3-D plotting → maximum

| Capability | Godot facility |
|---|---|
| **Parametric surfaces** (u,v)→(x,y,z), not just z=f(x,y) | same `SurfaceTool`, two-parameter sampling — tori, spheres, Möbius, Klein |
| **Implicit surfaces** f(x,y,z)=0 | marching cubes on the CPU, **or** an SDF ray-march `ShaderMaterial` (pure GPU) |
| **Volume / density fields** | ray-marching fragment shader through a `Texture3D` |
| **Vector fields & streamlines in 3-D** | `GPUParticles3D` advected by a velocity field; or `MultiMeshInstance3D` of arrow glyphs |
| **Point clouds / lattices** (millions of points) | `MultiMeshInstance3D` (one draw call) |
| **Animated surfaces** u(t,x) — the PDE time evolution | rebuild vertices per frame, or a vertex `ShaderMaterial` that deforms by time `TIME`; drive with `AnimationPlayer`/`Tween` |
| **Axes, ticks, numbers, bounding box, colour-bar** | `Label3D`/`TextMesh` for numbers, `ImmediateMesh` for axes/box, a gradient quad legend |
| **Wireframe / iso-contour overlays / floor projection** | a second pass material; contour already done — add a projected contour on a floor plane |
| **Transparency, clipping planes, cross-sections** | alpha materials + a clip-plane shader uniform |
| **True orbit/trackball camera, pan, dolly, inertia** | a camera controller (extends the current drag-rotate) |

## 3. Use the engine "to the full" — the GPU/scene levers

- **Compute shaders** — evaluate f(x,y[,z]) and build the mesh **on the GPU**
  (`RenderingDevice` compute). Replaces CPU `Expression` sampling → 100×+ grid
  density, real-time animation, and marching-cubes for implicit surfaces.
- **Spatial/canvas/particle shaders** — custom colour ramps (viridis/turbo),
  fresnel, animated contour flow, glass/translucent surfaces, hatching.
- **WorldEnvironment, full** — SSAO (done) + SSIL, **SDFGI** global illumination,
  **ReflectionProbe** + procedural sky (reflections), volumetric fog, depth-of-
  field, screen-space reflections. (These raise GPU cost — opt-in "quality"
  toggle, since task 140 wanted a no-cost default.)
- **MultiMesh / GPUParticles** — vast point/glyph counts in one draw call.
- **Label3D / TextMesh** — proper typeset 3-D annotations and axis numbers.
- **AnimationPlayer / Tween** — record parameter sweeps, smooth view transitions.
- **Picture-in-picture / multi-view** — extra `SubViewport`s for synced top/side
  orthographic views alongside the perspective one.
- **Export** — `Viewport.get_texture().get_image().save_png()` for figures, and a
  frame-grab loop → PNG sequence (→ MP4 via the existing ffmpeg-on-PATH path) for
  animations.

## 4. Architecture to make it scale

- A small **`Plot3D` scene/class** owning camera, lights, environment, axes,
  colour-bar, and a pluggable *mesh source* (z=f, parametric, implicit, particles)
  — so every `cas-plot3d` variant reuses one renderer.
- A **render-quality setting** (Draft / Standard / Max) gating the GPU-heavy
  passes (SDFGI, reflections, fog, supersampling), honouring "no extra GPU by
  default" (task 140) while exposing a "max" mode on demand.
- New fenced kinds: `cas-plot3d` (have), `cas-surface` (parametric),
  `cas-field` (vector field), `cas-implicit` (f=0), `cas-anim` (time-animated).

## 5. Phased roadmap (highest value first)

1. **Axes + tick numbers + colour-bar (2-D and 3-D)** — biggest readability win;
   `Label3D` + `ImmediateMesh`. Cheap.
2. **Orbit camera + crosshair readout** — interaction polish; cheap.
3. **Parametric & implicit surfaces** — new maths reach; SurfaceTool / SDF shader.
4. **Animated surfaces** for PDE time-evolution — `TIME` vertex shader; turns the
   notebooks' u(t,x) into motion.
5. **Compute-shader sampling + marching cubes** — the scalability unlock.
6. **Quality mode**: SDFGI / reflections / DoF / fog — the cinematic ceiling,
   opt-in.
7. **Image / video export** — deliverable figures and animations.

## Bottom line

Plotting maximised means: **CPU `Expression` sampling → GPU compute**, **single
height-field → parametric/implicit/volume/particle sources**, **static figure →
animated, annotated, orbit-able scene with axes and a colour-bar**, and **the full
`WorldEnvironment`** behind an opt-in quality switch. Each item is a named Godot
feature, not a new dependency — the engine already ships everything required.

## Files changed
- None — this is the plan / vision doc requested ("do 1 doc").
