# Task 118 — Bolder Fonts (Except Buttons) + the Task-107 Tooltip

## Goals

> "Make the fonts bolder throughout the app, except buttons. Also task 107 issue
> still exists."

Two things: (1) bold the app's text everywhere **except buttons**, and (2)
finish the task-107 hover problem, which was still visible.

## Part 1 — bolder fonts, except buttons

The app's font is Courier New (task 97). Now the text is rendered at **bold
weight** (`font_weight = 700`) everywhere, while **buttons keep the normal
weight**.

- **[main.gd](app/scripts/main.gd) `_make_theme()`** — the theme's
  `default_font` is now a bold-weight Courier New (so all chrome text — labels,
  results, the calculator history, titles — is bold), and `Button`'s `font` is
  explicitly set to the **normal** weight, so buttons are *not* bolded.
- **[notebook_view.gd](app/scripts/notebook_view.gd)** — the notebook applies
  its own font to cells / editor / file-tree / labels (overriding the theme), so
  a new `_resolve_bold_font()` helper returns the chosen family at weight 700,
  and all three `_font_resource` assignments use it. Prose, source cells, result
  cells, headings, chips, and the tree are now bold.

Buttons excluded: the per-cell **▶ Run** buttons and the calculator operation
buttons stay normal weight (Button font override); the top IconMenuBar buttons
keep their own task-98 styling, untouched.

## Part 2 — the task-107 hover issue (the dark tooltip)

Task 107 fixed the file-tree **row** hover (it now highlights light-blue with
readable text). But the problem the user still saw was the file tree's
**tooltip** — Godot's default tooltip is a **dark box** with low-contrast text
that pops up over the rows and **obscured the filename underneath** it. That's
what read as "filenames not visible on hover".

Fix — **[main.gd](app/scripts/main.gd) `_make_theme()`**: theme the tooltip to
match the app (light):

```gdscript
t.set_stylebox("panel", "TooltipPanel", <white box, grey border>)
t.set_color("font_color", "TooltipLabel", COL_TEXT)   # dark, readable
```

Now the tooltip is a light, bordered box with dark, readable text — the full
filename is legible and the box no longer looks like a dark blot over the list.

## Verification

Launched the app (no script errors). `app_screenshot_task118.png`:

- All text — workspace path, "Current Folder", file names, "Editor – …",
  "Algebra examples", prose, cell source, results, `▸ cas` / `= result` chips —
  is visibly **bold**; the **▶ Run** buttons and top buttons are **not** bolded.
- Hovering a file row: the row highlights light-blue with readable bold text,
  and the tooltip showing the full filename is now a **light, readable box**
  instead of the dark obscuring one.

## Files changed
- `app/scripts/main.gd` — bold `default_font` (Button kept normal); light
  `TooltipPanel`/`TooltipLabel`.
- `app/scripts/notebook_view.gd` — `_resolve_bold_font()`; bold the notebook's
  applied font.
