# Task 137 — Notebook Page Won't Scroll to the End (Stuck at 3D Plots)

## Report

> "In both the above tasks the notebook page does not scroll to the end, it gets
> stuck. Check and fix."

In the curved-spacetime (task 133) and nonlinear-PDE (task 135) notebooks the
page would not scroll all the way down — it **got stuck at a 3-D plot**, so the
sections below the first `cas-plot3d` surface were unreachable.

## Cause — the 3-D viewport swallowed the scroll wheel

The inline 3-D plot is a `SubViewportContainer` (`_build_surface3d` in
[notebook_view.gd](app/scripts/notebook_view.gd)). A `SubViewportContainer`
**forwards mouse input to its `SubViewport`** so the 3-D scene can be interacted
with. When the cursor was over the plot, the scroll-wheel event went *into* the
viewport (where nothing consumes it) and never propagated up to the notebook's
page `ScrollContainer`. So the wheel did nothing while hovering a plot, and since
the big 560-px plot filled most of the view, the page effectively stopped
scrolling there.

(2-D `cas-plot` panels did **not** have this problem — a plain `Control` that
doesn't handle the wheel lets it bubble up to the ScrollContainer. Only the
SubViewportContainer actively forwarded it.)

## Fix — let the wheel pass through the 3-D plot

`_build_surface3d` now sets the container's mouse filter to **IGNORE**:

```gdscript
container.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

With IGNORE the SubViewportContainer is transparent to mouse input, so the
scroll-wheel event propagates to the page `ScrollContainer` and the notebook
scrolls normally even while the cursor is over a 3-D surface. This is safe
because the plot has **no wheel-based interaction** — zooming is done with the
`−/+/⟳` buttons (task 136), which sit in a separate bar and still receive clicks.

## Verification

Re-ran `--demo-133` and scrolled with the cursor held **directly over the 3-D
plot**. The page now scrolls past it all the way to the **last section ("6.
HYPERBOLIC plot on the curved spacetime")**, which previously could not be
reached (`app_screenshot_task137.png`). No script/parse errors.

## Files changed
- `app/scripts/notebook_view.gd` — `_build_surface3d` sets the 3-D
  `SubViewportContainer` to `MOUSE_FILTER_IGNORE` so the page scrolls through it.
