# Task 141 — Rotating the 3D Plot in All Planes

## Question

> "How will you rotate the plot in all planes?"

The `cas-plot3d` surface can now be rotated about **all three axes** — yaw,
pitch, and roll — from the plot's control bar.

## How it works

Each 3-D plot cell carries a control bar (`_make_plot3d_controls` in
[notebook_view.gd](app/scripts/notebook_view.gd)) with rotation buttons that turn
the surface mesh about a **global** axis through its centre:

| Button | Axis | Plane it rotates in |
|---|---|---|
| **◄ ►** | global **Up** (Y) | horizontal plane — **yaw** (spin left/right) |
| **▲ ▼** | global **Right** (X) | vertical plane — **pitch** (tilt toward/away) |
| **↺ ↻** | global **Forward** (Z) | view plane — **roll** |
| **⌂** | — | reset rotation + camera to the default framing |

Each press rotates 18°:

```gdscript
_zoom_btn("◄", func(): mi.global_rotate(Vector3.UP, step))      # yaw
_zoom_btn("▲", func(): mi.global_rotate(Vector3.RIGHT, step))   # pitch
_zoom_btn("↺", func(): mi.global_rotate(Vector3.FORWARD, step)) # roll
```

`Node3D.global_rotate(axis, angle)` rotates about a **world-space** axis, so the
three controls stay intuitive no matter how the surface is already oriented
(yaw always spins about world-up, etc.). Composed, they reach **any** orientation
— rotation in all planes. The bar also keeps the **zoom** (−/+) and a single
**⌂** that restores both rotation and camera.

Because it's the **mesh** that turns (under fixed lights), the shading, rim light
and ambient-occlusion update realistically as the surface spins — you see the far
side lit differently, which reads as genuine 3-D motion.

## Why buttons, not mouse-drag

A drag-to-orbit would need the `SubViewportContainer` to receive mouse input, but
task 137 set it to `MOUSE_FILTER_IGNORE` so the **scroll wheel passes through to
the notebook page**. Re-capturing the mouse for dragging would bring back the
stuck-scroll problem. Buttons keep page-scroll, zoom, and rotation cleanly
separate — and still give full all-axis control.

## Verification

Ran `--demo-133` (no script/parse errors). `app_screenshot_task141.png` shows the
control bar on the 3-D cell: **rotate ◄ ► ▲ ▼ ↺ ↻   zoom − +   ⌂**, above the
dark-background surface. The rotation buttons are wired to `mi.global_rotate`
about Up / Right / Forward, so they cover yaw, pitch and roll.

## Files changed
- `app/scripts/notebook_view.gd` — `_make_plot3d_controls` (yaw/pitch/roll + zoom
  + reset); `_build_surface3d` uses it instead of the zoom-only bar.
