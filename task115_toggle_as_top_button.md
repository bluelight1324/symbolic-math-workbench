# Task 115 — Make the Source/Notebook Toggle a Top Button

## Goal

> "The new Show Source and Show Notebook buttons will not do. They have to be
> the same as the top buttons."

The view toggle added in tasks 110/111 was a one-off full-width button inside
the notebook view (a layout workaround). The user wants it to look like the
**top toolbar buttons** (the IconMenuBar categories: Notebook, View, Algebra, …,
Run All) — same size, glyph + label, styling.

## Change

The toggle is now a real **IconMenuBar action button**, sitting at the far right
next to **Run All**, styled identically to every other top button. It updates
to show what a click will do:

- In the **rendered** notebook → **`✎ Source`** (click to edit the source).
- In the **source** editor → **`▤ Notebook`** (click to render).

### How it's wired

- **[icon_menubar.gd](app/scripts/icon_menubar.gd)** — `_build_button` now
  records each button's icon/label `Label`s, and a new
  `set_button_glyph(btn, icon, label)` updates them (so a single action button
  can change its glyph/label as a toggle).
- **[notebook_view.gd](app/scripts/notebook_view.gd)** — removed the old
  full-width in-notebook toggle button. The view now emits a
  `view_mode_changed(is_notebook_view)` signal from `_apply_view_mode()`.
- **[main.gd](app/scripts/main.gd)** — adds the toggle via
  `_icon_menubar.add_action("✎", "Source", …)` right after Run All, and connects
  `NotebookView.view_mode_changed` to `_on_view_mode_changed()`, which calls
  `set_button_glyph()` to flip the button between **✎ Source** and **▤ Notebook**.

Because the label is driven by the signal, the button stays correct no matter how
the mode is changed — the top button itself, the **Ctrl+E** shortcut (task 111),
double-clicking a cell (task 110/111), or the "Show Source" menu item.

## Verification

Launched the app (no script errors). `app_screenshot_task115.png` shows the
toolbar in both states:

- Notebook view → the right-most button reads **`✎ Source`**, matching the other
  top buttons (size, bold font, coloured tile).
- After **Ctrl+E** → the same button reads **`▤ Notebook`** (glyph + label
  updated), and the editor switched to the editable source.

The awkward full-width button is gone; the toggle is now one of the top buttons,
exactly as asked.

## Files changed
- `app/scripts/icon_menubar.gd` — `set_button_glyph()` + per-button label refs.
- `app/scripts/notebook_view.gd` — removed the full-width toggle; emit
  `view_mode_changed`.
- `app/scripts/main.gd` — top-bar toggle button + label sync.
