# Task 139 — Maximizing the 3D Plot Graphics with Godot

## Question

> "How will you improve the graphics of the 3D plot to maximum possible,
> considering you're running the Godot game engine?"

The 3-D plot (`cas-plot3d` → `_build_surface3d`) runs inside a real-time renderer,
so it can use the same techniques a game does. I both **explain** the full menu
and **implemented** the high-value subset; the surface now looks like a lit,
shaded 3-D object rather than a flat coloured mesh.

## What I implemented (Godot renderer features now on the surface)

[notebook_view.gd](app/scripts/notebook_view.gd) `_build_surface3d`:

| Technique | Setting | What it buys |
|---|---|---|
| **PBR material** | `roughness 0.42`, `metallic 0.12`, `metallic_specular 0.6` | physically-based shading → real specular highlights, a glossy sheen |
| **Rim light** | `rim_enabled`, `rim 0.35` | the silhouette/edges glow, separating the surface from the background |
| **Real-time shadows** | key `DirectionalLight3D.shadow_enabled` | the surface self-shadows in its folds → depth |
| **SSAO** | `Environment.ssao_enabled` (r 0.7, i 2.2) | screen-space ambient occlusion darkens the valleys/creases |
| **Filmic tonemapping** | `tonemap_mode = FILMIC`, exposure 1.05 | richer, film-like colour response instead of flat sRGB |
| **Bloom** | `glow_enabled` (intensity 0.32, threshold 1.1) | a soft highlight bloom on the brightest crests — the game-engine "wow" |
| **Anti-aliasing** | `MSAA 8×` + `screen_space_aa = FXAA` | crisp, jaggy-free edges |
| **Finer mesh** | `N = 56` (≈ 6.3 k tris) | smoother curvature, more surface detail |
| **Two-light rig** | key + fill `DirectionalLight3D`, colour ambient | form-revealing shading, no flat areas |

Result (`app_screenshot_task139.png`): the parabolic well renders as a glossy,
height-coloured bowl with rim light, a subtle bloom on the rim, and occluded
valleys — a clear step up from the previous flat vertex-coloured mesh.

## The fuller menu (what Godot could still add, "to maximum")

These are available and would push quality further, at more cost/complexity:

- **Sky / reflection environment** — a `ProceduralSkyMaterial` so the glossy
  surface reflects a real environment (`ambient_source = SKY`, reflections).
- **SDFGI or a ReflectionProbe** — real global illumination / accurate
  reflections instead of a flat ambient term.
- **Custom shader** (`ShaderMaterial`) — animated iso-contour bands, a height
  colour-ramp texture, fresnel edges, or a glass/translucent look; even
  GPU-side surface deformation for time-animated `u(s,x)`.
- **Normal / detail maps** — micro-surface relief without more triangles.
- **Volumetric fog + light shafts** — depth cueing for tall surfaces.
- **TAA** + higher internal resolution (supersampling) — maximal edge/temporal
  smoothness (TAA can ghost in a SubViewport, so I used MSAA+FXAA instead).
- **Orbit/trackball camera & on-surface readouts** — gameplay-style interaction
  (drag to rotate, hover to read z), beyond the current button zoom.
- **Wireframe / point overlays** and **contour projection** on a floor plane —
  classic "math viz" overlays a game engine draws cheaply.

## Why this is the right level

The implemented set maximises *perceived* quality (lighting, shadows, AO, bloom,
AA, mesh density) while staying cheap enough to render many plots in one notebook
and to re-render on theme/zoom changes. The heavier items (SDFGI, custom shaders,
sky reflections) are listed as the next tier rather than shipped, since they add
real GPU cost and are overkill for an inline notebook figure.

## Verification

Re-ran `--demo-133` (no script/parse errors — all PBR/SSAO/tonemap/glow/FXAA
properties valid). The enhanced surface is captured in `app_screenshot_task139.png`.

## Files changed
- `app/scripts/notebook_view.gd` — `_build_surface3d`: PBR + rim material,
  shadows, SSAO, filmic tonemap, bloom, FXAA, `N = 56` mesh.
