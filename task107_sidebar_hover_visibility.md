# Task 107 — Filenames Invisible on Hover (Left Pane)

## Problem

In the left **Current Folder** file tree, hovering the mouse over a file made
its name **unreadable** — the hover highlight was a dark box and the filename
text is dark, so it became dark-on-dark (see the user's screenshot, where the
hovered `calculus.md` row is a murky grey box).

## Root cause

When the file tree was re-themed for the MATLAB light look (task 94), the
`Tree` got overrides for its `panel`, `selected`/`selected_focus` styleboxes and
`font_color`/`font_selected_color` — but **not** for the **hover** state. So
Godot's *default* `Tree` hover stylebox (a dark highlight) and default hover
font colour were used, which clash with the light scheme and hide the text.

## Fix — [notebook_view.gd](app/scripts/notebook_view.gd) `_apply_chrome_colors()`

Added scheme-aware hover overrides alongside the existing selection overrides:

```gdscript
var hov := StyleBoxFlat.new()
hov.bg_color = _color_scheme["src_border"].lerp(_color_scheme["bg"], 0.82)  # faint tint
_sidebar_tree.add_theme_stylebox_override("hovered", hov)
_sidebar_tree.add_theme_stylebox_override("hovered_dimmed", hov)
_sidebar_tree.add_theme_color_override("font_hovered_color", _color_scheme["text"])
_sidebar_tree.add_theme_color_override("font_hovered_dimmed_color", _color_scheme["text"])
```

The hover highlight is now a **faint, scheme-tinted** box (a lighter shade of the
selection blue) and the hover text colour is the normal text colour, so the
filename stays clearly readable while hovered. Because it's derived from the
active `_color_scheme`, it stays correct for every theme (light or dark), not
just MATLAB.

## Verification

Launched the app and hovered over file-tree rows: the hovered row now shows a
light-blue highlight with the filename in **readable dark text** (and the Tree's
tooltip still shows the full, un-truncated name legibly). No more dark-on-dark
disappearing filenames.

## Files changed
- `app/scripts/notebook_view.gd` — added `hovered` / `hovered_dimmed` styleboxes
  and `font_hovered_color` / `font_hovered_dimmed_color` to the sidebar tree.
