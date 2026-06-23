# Task 143 — Implement the Deferred (Doc-Only) Items

## Request

> "Implement the above tasks which are still doc."

Reviewing the recent batch, almost everything had been built; the documented-but-
**not-built** part was the **"fuller menu" of 3D-graphics improvements listed in
task 139** (I shipped a subset there and described the rest). This task builds the
one that both raises quality *and* respects task 140's "no GPU increase":
**custom-shader iso-height contour lines** on the surface.

## What was implemented — a contour-line spatial shader

[notebook_view.gd](app/scripts/notebook_view.gd) `_build_surface3d` now uses a
`ShaderMaterial` instead of `StandardMaterial3D`. The shader keeps the full PBR
look (vertex-colour albedo, roughness, metallic, rim) **and** draws anti-aliased
**iso-height contour lines** across the surface:

```glsl
shader_type spatial;
render_mode cull_disabled;
uniform float bands = 9.0;
varying float v_h;
void vertex() { v_h = VERTEX.y; }
void fragment() {
    ALBEDO = COLOR.rgb;                 // the height colour-map
    ROUGHNESS = 0.42; METALLIC = 0.12; RIM = 0.35; RIM_TINT = 0.2;
    float s = v_h * bands;
    float d = min(fract(s), 1.0 - fract(s));
    float w = fwidth(s) * 1.3 + 0.012;  // screen-space AA line width
    ALBEDO = mix(line_color, ALBEDO, smoothstep(0.0, w, d));
}
```

- The contour lines are computed from the model-space height (`VERTEX.y`), spaced
  by `bands` — the classic topographic/level-set read for a maths surface.
- `fwidth` keeps the lines a constant ~1 px regardless of zoom (crisp, no
  aliasing).
- It is **one fragment shader, no extra render pass**, so GPU cost is essentially
  unchanged — exactly the "improve without increasing GPU" constraint from task
  140. The existing SSAO / shadows / tonemap / bloom (post passes) still apply.

## Why not the other task-139 menu items

The remaining task-139 "next tier" ideas were intentionally left out because each
**would** increase GPU and so conflicts with task 140:

- Sky + reflection environment, ReflectionProbe → reflection rendering.
- SDFGI → real-time global illumination (heavy).
- Volumetric fog / light shafts → extra volumetric pass.
- TAA / supersampling → higher internal resolution.

The orbit-camera item from that menu was already delivered (drag-to-rotate, task
142). So the contour shader is the single deferred item that fits *both* "more
graphics" (139) and "no more GPU" (140).

## Verification

Ran `--demo-133` — no script/parse/**shader-compile** errors. The surface renders
with the height colour-map **plus** dark iso-height contour bands
(`app_screenshot_task143.png`), a clear topographic improvement over the smooth
shading in task 140, at the same GPU cost.

## Files changed
- `app/scripts/notebook_view.gd` — `_build_surface3d`: `StandardMaterial3D` →
  `ShaderMaterial` with a PBR + iso-height-contour spatial shader.
