# Task 136 — Bigger, Clearer Plots + Zoom (for tasks 133 & 135)

## Goal

> "In the above 2 tasks the plots need to have increased clarity and be bigger.
> Provide ability to zoom in or out on the plots."

The plots in the curved-spacetime (task 133) and nonlinear-PDE (task 135)
notebooks — both the 2-D `cas-plot` curves and the 3-D `cas-plot3d` surfaces —
are now larger, sharper, and **zoomable**. The change is global, so **every**
notebook plot benefits.

## 2-D plots (`cas-plot`)

| | was | now |
|---|---|---|
| panel height | 260 px | **440 px** ([notebook_view.gd](app/scripts/notebook_view.gd)) |
| samples per curve | 61 | **121** (n 60→120) — smoother curve, sharper features like the κ spike |
| curve line width | 2.0 | **3.5** ([plot_panel.gd](app/scripts/plot_panel.gd)) |
| axis line width | 2.0 | **3.0** |

The finer sampling matters for task 135's curvature κ(s): the spike at the
singular time s = 0 is now resolved cleanly instead of being a coarse zig-zag.

## 3-D plots (`cas-plot3d`)

| | was | now |
|---|---|---|
| viewport height | 360 px | **560 px** |
| render resolution | 680 × 360 | **1120 × 560** — crisper surface |
| mesh density | 28 × 28 | **44 × 44** — smoother surface, finer detail |
| anti-aliasing | MSAA 4× | **MSAA 8×** — smoother edges |
| camera | (4.5, 4.0, 4.5) | **(4.0, 3.5, 4.0)** — closer, so the surface fills the frame |

## Zoom in / out

Each plot now carries a small **`zoom  −  +  ⟳`** control bar:

- **2-D (`cas-plot`)** — `−`/`+` magnify the curve about the panel centre
  (`plot_panel.zoom_out/zoom_in`, a `draw_set_transform` scale with
  `clip_contents` hiding overflow); `⟳` resets to 1×.
- **3-D (`cas-plot3d`)** — `−`/`+` dolly the `Camera3D` out / in (kept aimed at
  the surface); `⟳` returns to the default framing.

Buttons (rather than scroll-wheel zoom) keep zooming from fighting page-scroll —
relevant to the scroll issue in task 137.

## Verification

Re-ran both notebooks (`--demo-135`, `--demo-133`) after clearing their cached
plot results so the curves re-sample at the new density — no script/parse errors.

`app_screenshot_task136.png` shows task 135's two 2-D plots at the new size: the
`x^3 + x^4` curve filling the taller panel with the bolder blue line, and below
it the curvature κ(s) plot with its sharp, well-resolved **spike at s = 0**. The
3-D surfaces use the same enlarged viewport / finer-mesh path (parameter bumps in
the already-verified `_build_surface3d`).

## Files changed
- `app/scripts/plot_panel.gd` — bolder curve (3.5) and axes (3.0); zoom
  (`zoom_in/out/reset` + centred scale transform).
- `app/scripts/notebook_view.gd` — 2-D panel 440 px + 120-sample density; 3-D
  viewport 560 px / 1120×560 / 44×44 mesh / MSAA 8× / closer camera;
  `_make_zoom_bar` control on both 2-D and 3-D cells (3-D dollies the camera).
