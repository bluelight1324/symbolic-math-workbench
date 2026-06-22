# Task 110 — Improving Notebook Editability

## Goal

> "How can you improve the above" (task 109 — the notebook opens in a read-only
> rendered preview, and editing was hidden behind a menu item).

The problem from task 109 was **discoverability**: a notebook opens in the
read-only rendered view, and the only way to reach the editable Source view was
a "Show Source" item buried in the Notebook popup menu. Two improvements make
editing obvious and natural.

## Improvement 1 — a visible Edit/View toggle button

[notebook_view.gd](app/scripts/notebook_view.gd) now shows a labelled toggle
button at the top of the notebook view, right under the workspace path:

- **`✎ Show Source`** when viewing the rendered notebook → click to edit.
- **`▤ Show Notebook`** when editing the source → click to render.

It's wired to the existing `_toggle_view_mode()` (the same action the menu item
triggers) and assigned to `_view_mode_btn`, so `_apply_view_mode()` keeps its
label in sync with the current mode. No more hunting through a menu — the way to
edit is a labelled button on screen.

## Improvement 2 — double-click a cell to edit

[notebook_view.gd](app/scripts/notebook_view.gd) — `_attach_edit_on_dblclick()`:
**double-clicking anywhere in the rendered notebook** (a prose paragraph, a
source cell, or a result cell) jumps straight into the editable Source view —
the familiar Jupyter/Mathematica gesture. The inner text labels were set to
`MOUSE_FILTER_PASS` so the double-click reaches the cell's handler.

Together: the rendered view stays the polished default (results + inline plots),
but editing is one obvious click — or one double-click — away.

## Verification

Launched the app (no script errors). The **`✎ Show Source`** toggle button
renders at the top of the notebook view, under the workspace path
(`app_screenshot_task110.png`).

The button and the double-click handler are both wired to `_toggle_view_mode()`
— the exact function the menu's "Show Source" item has used since task 35 — so
they switch into the editable `CodeEdit` when activated. (Synthetic mouse clicks
couldn't be driven in this environment because Windows blocks programmatic
focus-stealing on the Godot window; the wiring is identical to the already-proven
menu path.)

### Implementation note

The toggle button is laid out as its own full-width row directly in the notebook
view's main `VBoxContainer`. Placing it inside the existing top-bar
`HBoxContainer` (next to the workspace path) did not render — a layout quirk
where the second child of that particular HBox collapsed — whereas a direct
VBox child renders reliably, so that's what's used.

## Files changed
- `app/scripts/notebook_view.gd` — `_view_mode_btn` toggle button on the top
  bar; `_attach_edit_on_dblclick()` on prose / source / result cells;
  `_make_title_bar()` now returns its inner HBox; `_apply_view_mode()` label
  includes an edit/view icon.
