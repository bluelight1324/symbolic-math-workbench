# Task 140 — Darker Plot Background + GPU-Free Improvements

## Request

> "The screen background needs to be darker for the plot. How can you improve
> even more on the plot without increase in GPU?" (ref `app_screenshot_task139.png`)

In task 139 the 3-D surface was drawn on the notebook's `src_bg` — **white** on
the MATLAB light theme — which washed out the lit surface, the rim light and the
bloom. This task darkens that background and makes the surface read more
three-dimensionally, all **without adding any GPU cost** (no new render passes,
no extra geometry, no higher AA).

## What changed

### 1. Dark plot background
[notebook_view.gd](app/scripts/notebook_view.gd) `_build_surface3d` — the 3-D
viewport's environment background is now a fixed dark charcoal
`Color(0.07, 0.08, 0.10)` regardless of the notebook theme:

```gdscript
env.background_color = Color(0.07, 0.08, 0.10)   # was _color_scheme["src_bg"] (white on light theme)
```

On the dark field the rim light, the specular highlights and the bloom (all
already present from task 139) finally stand out — bloom in particular only
"shows" against darkness, so this also makes the existing glow pass look better
for free.

### 2. Height drives brightness, not just hue (free depth cue)
The vertex colour ramp used to be a constant-brightness blue→red hue. It now maps
height to **both** hue and value — dark blue in the valleys, bright warm on the
crests:

```gdscript
var t := (h - zmin) / zr
Color.from_hsv(0.63 - 0.63 * t, 0.82, 0.40 + 0.55 * t)   # hue + brightness
```

Because the colour is computed on the CPU and baked into the mesh vertices, this
costs **nothing** at render time, yet it adds a strong sense of depth: low areas
recede (dark), high areas advance (bright).

## "How to improve more without increasing GPU" — the principle

All the cheap wins are **art / tuning of what's already drawn**, not new passes:

| Free lever | What it does |
|---|---|
| **Darker background** (done) | bloom/rim/contrast pop; pure colour change |
| **Height→brightness colormap** (done) | depth cue baked into existing vertex colours |
| **Tonemap exposure / contrast** | richer response from the post pass already running |
| **Light angles & energies** | better form-reveal; same two lights, no new shadows |
| **Material params** (roughness, rim, specular) | glossier / more defined; same shader |
| **Camera framing** | composition; free |
| **Vertex colour ramp choice** | a perceptual ramp reads better; baked, free |

What would **increase** GPU (and was deliberately *not* added): higher MSAA/
super-sampling, SDFGI/global illumination, sky + reflection probes, extra
shadow-casting lights, denser meshes, volumetric fog, multi-pass custom shaders.
The improvement here comes from *using the existing passes better*, not adding
more.

## Verification

Re-ran `--demo-133` (no script/parse errors). `app_screenshot_task140.png`: the
parabolic surface now sits on a dark charcoal field, valleys deep blue, crests
bright gold, with the rim light and a subtle bloom clearly visible — markedly
more three-dimensional than the white-background version in
`app_screenshot_task139.png`, at the same GPU cost.

## Files changed
- `app/scripts/notebook_view.gd` — `_build_surface3d`: dark fixed background;
  height-driven brightness in the vertex colour ramp.
