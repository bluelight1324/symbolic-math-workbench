# Task 136.1 — Apply Bigger / Clearer / Zoom to ALL Plots mathdot Creates

## Goal

> "Apply the above to all plots which mathdot creates."

Take the task-136 improvements (bigger, clearer, zoomable) and make sure they
cover **every** kind of plot the app produces, not just the two demo notebooks.

## The plots mathdot creates — and their status

There are exactly three plot-creation paths in the codebase. All three now have
the task-136 treatment:

| Plot path | Where | Bigger | Clearer | Zoom |
|---|---|---|---|---|
| **Notebook 2-D** `cas-plot` | `notebook_view.gd` `_emit_block_cell` | 440 px panel | 3.5 px curve, 121 samples | `−/+/⟳` bar |
| **Notebook 3-D** `cas-plot3d` | `notebook_view.gd` `_build_surface3d` | 560 px, 1120×560 | 44×44 mesh, MSAA 8× | `−/+/⟳` (camera dolly) |
| **Calculator 2-D** plot | `main.gd` calculator panel | 200 → **340 px** | shared `plot_panel` (3.5 px curve, 3 px axes) | `−/+/⟳` bar |

The shared `plot_panel.gd` is what makes most of this automatic: both the
notebook 2-D plots and the calculator's plot are the **same `PlotPanel`**, so the
bolder lines and the `zoom_in/out/reset` capability apply to both from a single
change. Task 136.1's remaining work was:

1. **Calculator plot** (`main.gd`) — enlarged to 340 px, `clip_contents = true`
   for clean zoom, and a `−/+/⟳` zoom bar wired to the panel's zoom methods.
2. Confirming **no other plot path exists** (verified by grepping for
   `PlotPanel`, `set_samples`, `SubViewport`, `_build_surface3d`).

## Verification

- **Test harness** (`--test126`): **28/28 pass**, including the updated
  `_build_surface3d` check (it now returns a zoom-bar-wrapped `VBoxContainer`).
- **Notebook plots** (`--demo-135`): no runtime errors; the `zoom − + ⟳` bar is
  visible on the 2-D curve cell (`app_screenshot_task136_1.png`), and the 3-D
  cells carry the same control.
- **Calculator plot**: the same `PlotPanel` + zoom bar; bigger panel.

## Note on scroll vs. zoom
Zoom is via **buttons**, not the scroll wheel, on purpose — a wheel-zoom over a
plot would compete with scrolling the notebook page (the stuck-scroll problem is
task 137). Buttons keep the two interactions separate.

## Files changed
- `app/scripts/main.gd` — calculator plot enlarged + `clip_contents` + zoom bar.
- `app/scripts/_test126.gd` — updated `_build_surface3d` return-type assertion +
  fuller colour/density stubs for the new zoom-bar code path.
- (notebook 2-D / 3-D plots already covered by the task-136 changes.)
