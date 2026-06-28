# Task 148.7 — Plotting in Godot, with AI / VR / Neural Back In

## The clarified scope

> "Only [the] plotting is via Godot. AI, VR, Neural, or anything else need not be
> excluded."

So: **Godot is the rendering/interaction substrate**, and the advanced layers
(AI, VR, neural representations, …) that task 148.6 excluded are now back in.

The important realisation — and the whole point of building on a game engine —
is that **Godot itself natively hosts most of these**, so "plotting via Godot"
and "AI/VR/Neural included" is not a contradiction:

| Advanced capability | Godot mechanism (native, no separate app) |
|---|---|
| **VR / AR** | **OpenXR is built into Godot** — a 3-D scene becomes VR by adding an `XROrigin3D` + `XRCamera3D`. |
| **Neural fields / super-res** | a SIREN/MLP is just mat-muls + `sin`; **run inference in a compute shader** (`RenderingDevice`) or a fragment shader. |
| **Live GPU PDE solving** | **compute shaders** step the field each frame. |
| **Symbolic → GPU** | a GDScript transpiler emits **GLSL** from the REDUCE AST. |
| **Validated / interval plots** | interval / Taylor-model arithmetic in **GDScript**. |
| **Local AI (explain / NL→plot)** | a small LLM via **GDExtension** (e.g. llama.cpp) runs on-device. |

So the only things that truly leave Godot are *optional*: a cloud AI API (and
even that is avoidable with a local model), offline neural **training**, and the
**XR headset** itself (hardware, not infrastructure).

## How each layer plugs into the Godot plot

### 1. VR / AR — walk around the plot (Godot-native)
Add OpenXR to the existing `SubViewport`/`Camera3D` 3-D scene
(`_plot3d_scene`): an `XROrigin3D` + `XRCamera3D`, and the same surface, axes and
colour-bar render in a headset at room scale. The drag-rotate becomes
grab-to-rotate with the controllers; the colour-bar and `Label3D` axis numbers
are already 3-D, so they work in VR unchanged. The curved-spacetime or time-
ellipsoid surface becomes something you can lean into.

### 2. Neural representations — infinite resolution (Godot compute)
Fit a tiny MLP (SIREN) to the CAS samples **offline**, then ship only its weights
and run **inference in a compute/fragment shader** per pixel. The surface is then
smooth and **infinitely zoomable** with analytic-quality normals, evaluated on
the GPU — no Python at runtime, just a weight buffer and a shader. Pairs with the
symbolic→GLSL path: neural where the function is sampled-only, exact GLSL where
it's symbolic.

### 3. AI assistance — explain & author (local model via GDExtension)
A local language model (llama.cpp through a `GDExtension`, fully on-device) reads
the **declarative plot spec** (task 148.4) plus sampled features and:
- writes a caption / spoken description ("saddle at the origin, poles at x=±1"),
- compiles **natural language → a plot spec** ("show the gradient field, top-down").
No cloud dependency required; an optional API backend is a drop-in if preferred.

### 4. GPU-native mathematics (pure Godot)
- **Symbolic → GLSL**: transpile the REDUCE expression AST to a shader →
  per-pixel exact evaluation, free animation, infinite exact zoom.
- **Live PDE simulation**: a compute-shader solver drives the surface each frame
  — the PDE notebooks (tasks 133/135) *run*.
- **Validated plots**: GDScript interval arithmetic gives a proven error bound so
  a thin spike is never missed.

### 5. The integrated experience
One plot can be: a **live, GPU-solved** PDE surface, **neural-super-resolved** for
crispness, **rendered by Godot** with PBR + contours + colour-bar + axes,
**walked around in VR**, and **explained by an on-device AI** — every layer either
native to Godot or a self-contained on-device extension. The notebook authors it;
the engine runs it.

## Architecture (how it all attaches)

- The **declarative plot spec** (148.4 R0) stays the hub: every layer reads/writes
  it (AI authors it, VR reads camera/scene from it, neural/GLSL choose the mesh
  source from it).
- `_plot3d_scene` (built in task 148.6) is the render core; VR, neural-shader
  surfaces, and live-sim meshes are just different **mesh sources / cameras**
  fed into it.
- A **capability/quality switch** gates the heavy layers (VR, neural, live-sim,
  cloud-AI) so the default plot stays cheap (task 140), and each is opt-in.

## Honest boundaries

- **Inside Godot, no external infra:** VR (OpenXR), neural *inference*, GPU PDE
  solving, symbolic→GLSL, validated plots, local AI inference (GDExtension).
- **Outside Godot (optional / one-time / hardware):** offline neural *training*,
  a cloud AI API if a local model isn't wanted, and the XR **headset** hardware.

That boundary is the precise answer to the task: the *plotting* is via Godot, and
AI / VR / Neural are included — largely *through* Godot, with only training,
optional cloud AI, and headset hardware living outside it.

## Files changed
- None — this is the "do 1 doc" integration plan (no code change).
