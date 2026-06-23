# Task 138 — Notebook Page Needs to Scroll Some More

## Report

> "Notebook page needs to scroll some more."

After task 137 (the page no longer gets *stuck* at a 3-D plot), it still didn't
scroll quite far enough: the **last** cell — typically a tall 440-px 2-D plot or
a 560-px 3-D surface — ran right up against the bottom edge and couldn't be
scrolled fully into view. There was no slack past the final element.

## Fix — extra scroll room at the bottom

`_rebuild_rendered_cells()` ([notebook_view.gd](app/scripts/notebook_view.gd))
now appends a blank spacer after the last cell:

```gdscript
var tail := Control.new()
tail.custom_minimum_size = Vector2(0, 480)
_rendered_box.add_child(tail)
```

That 480 px of empty trailing space lets the `ScrollContainer` scroll past the
final cell, so the last plot (even a full-height 3-D surface) can be brought
completely into the viewport instead of clinging to the bottom edge.

## Verification

Re-rendered the curved-spacetime and nonlinear-PDE notebooks — the page now
scrolls comfortably past the last plot, with clear breathing room at the end.

## Files changed
- `app/scripts/notebook_view.gd` — `_rebuild_rendered_cells()` appends a 480-px
  trailing spacer for extra end-of-page scroll room.
