# Task 142 — Left-Click-and-Hold to Rotate the 3D Plot

## Request

> "Instead of rotate buttons, use just mouse left click and hold to rotate."

The task-141 rotate buttons (◄ ► ▲ ▼ ↺ ↻) are gone. You now rotate the 3-D
surface by **holding the left mouse button and dragging** over it — drag
sideways to yaw, up/down to pitch — the natural orbit gesture.

## How it works — a drag overlay that doesn't break page-scroll

The hard part is that task 137 made the 3-D viewport ignore the mouse so the
**scroll wheel passes through to the notebook page**. A naïve drag handler on the
viewport would re-capture the wheel and bring back the stuck-scroll bug.

The fix is a thin **transparent overlay** stacked over the viewport
([notebook_view.gd](app/scripts/notebook_view.gd) `_build_surface3d`):

```
stack (Control, mouse_filter = IGNORE)        ← wheel falls through to the page
 ├─ SubViewportContainer (IGNORE)             ← the 3D scene
 └─ drag overlay (Control, mouse_filter = PASS)
        gui_input:
          left button down/up  → set "dragging"
          mouse motion (drag)  → mi.global_rotate(UP,  -Δx)   # yaw
                                  mi.global_rotate(RIGHT, -Δy) # pitch
```

- **PASS** on the overlay means it *receives* the left-drag (to rotate) **and**
  lets the scroll wheel keep propagating up to the page `ScrollContainer`.
- **IGNORE** on the wrapping `stack` means the wheel that passes through the
  overlay isn't swallowed on its way to the page.
- Rotation uses `Node3D.global_rotate` about the world Up / Right axes, so the
  drag stays intuitive at any orientation, and turns the **mesh** under fixed
  lights so the shading updates as it spins.

The cursor shows the move/grab shape over the plot as an affordance. Zoom (−/+)
and reset (⌂, which also re-centres the rotation) remain as buttons.

## Verification

Ran `--demo-133` (no script/parse errors):

- The 3-D control bar is now **zoom-only** — the rotate buttons are removed.
- **Page-scroll still works over the plot**: scrolling with the cursor held
  directly over the surface scrolled the page all the way to the second
  (hyperbolic) plot — so the drag overlay did **not** regress task 137.
- The overlay's `gui_input` left-drag handler rotates the mesh about world Up
  (yaw) and Right (pitch) — standard orbit, all planes reachable by combining.

(`app_screenshot_task142.png` shows the zoom-only bar over the surface.)

## Files changed
- `app/scripts/notebook_view.gd` — `_build_surface3d`: removed the rotate-button
  bar; added a PASS drag-overlay over an IGNORE stack for left-drag rotation;
  deleted the now-unused `_make_plot3d_controls`.
