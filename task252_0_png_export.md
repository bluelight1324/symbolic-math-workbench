# Task 252.0 — PNG Export (Get Plots Out of the App)

## Request

> "Do what will improve the plots even more next."

The top remaining recommendation from [149.6](task149_6_plots_whats_left.md) and
[251.0](task251_0_domain_and_multiseries.md) was **PNG export** — until now nothing
could get a rendered plot *out* of the app, into a paper, slide, or message. This
task adds one-click PNG export to **every** plot kind. Pure Godot, verified
end-to-end.

## What was built

- **A "⤓ PNG" button on every plot cell** — 2-D curves, all 3-D surfaces
  (height-field / parametric / implicit / animated / vector field), and complex
  domain images. It lives in the plot's control bar next to the zoom buttons.
- **Best-quality capture per type** (`_export_plot_png`):
  - **3-D plots** save the `SubViewport` texture directly — **native 1088×560
    resolution**, independent of window size or scroll position, with no UI chrome.
  - **Domain images** save the `ImageTexture` at its native pixel resolution.
  - **2-D curve panels** (which draw straight onto the canvas, with no off-screen
    buffer) are captured from the window framebuffer cropped to the panel — so the
    plot just needs to be scrolled into view.
- **Sensible output path** — saved next to the notebook as
  `<notebook>_<kind>.png` (e.g. `implicit_surfaces_plot3d.png`), auto-numbered to
  avoid clobbering, with the saved path shown in the status bar.

## How it works

`_export_plot_png(target, hint)` walks the cell for a `SubViewport` (→ native 3-D
image) or a `TextureRect` (→ native domain image); failing both it grabs the
window framebuffer and crops to the target's on-screen rect (the 2-D case). The
button is added by `_make_zoom_bar(…, export_target, hint)` for the 2-D/3-D bars
and directly in the domain cell. Helpers `_find_subviewport` / `_find_texrect`
locate the capture source.

## Verification

- **Unit tests** (`--test126`): **93 / 93 pass** — 5 new: `_find_subviewport` /
  `_find_texrect` locate the right node (and return null when absent), `_png_btn`
  builds a `Button`, and passing an export target adds exactly one extra button to
  the control bar.
- **Integration** (`--test-export`): runs `implicit_surfaces.md`, exports its first
  plot, and reports `EXPORT_RESULT ok 1088x560 …png`. The saved file
  (`app_screenshot_task2520_export.png`) is a clean native-resolution render of the
  implicit sphere — surface, contour bands, bounding box, axis numbers and
  colour-bar, no window chrome.

## Still remaining

Export is now covered for **PNG** (the most-requested format). Next from
[149.6](task149_6_plots_whats_left.md): **MP4** capture of an animated surface,
vector **SVG/PDF/TikZ** for publication, and **threaded sampling** (the
domain/implicit grids still build on the main thread). A native off-screen render
for 2-D (so it exports regardless of scroll, like the 3-D path) is a small future
refinement.

## Files changed
- `app/scripts/notebook_view.gd` — `_export_plot_png`, `_png_btn`,
  `_find_subviewport`, `_find_texrect`, `export_first_plot`; `_make_zoom_bar` gains
  an optional export target; export buttons wired into the 2-D, 3-D and domain cells.
- `app/scripts/main.gd` — `--test-export` integration check.
- `app/scripts/_test126.gd` — 5 new assertions (now 93/93).
