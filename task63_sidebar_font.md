# Task 63 — Sidebar (Left Panel) Font Matches the Overall Font

Before this task, the user-picked font from
[task 58](task58_notebook_primary_and_fonts.md) /
[task 62](task62_more_fonts.md) only applied to the source `CodeEdit`
and the rendered cell labels. The **sidebar Tree** on the left — the
file browser — kept the app's default theme font, so picking a Serif
or Monospace family left the workspace listing in the original
Sans-Serif. Visually inconsistent.

Fix: extend `_apply_font()` to also override the sidebar Tree and the
chrome around the editor (workspace-path label, status label) with the
user's choice.

---

## What changed

[notebook_view.gd](app/scripts/notebook_view.gd) — `_apply_font()`:

```gdscript
func _apply_font() -> void:
    # Editor (unchanged)
    if _editor:
        _editor.add_theme_font_size_override("font_size", _font_size)
        if _font_resource:
            _editor.add_theme_font_override("font", _font_resource)
        else:
            _editor.remove_theme_font_override("font")
    # NEW — left-panel Tree.
    if _sidebar_tree:
        _sidebar_tree.add_theme_font_size_override("font_size", _font_size)
        if _font_resource:
            _sidebar_tree.add_theme_font_override("font", _font_resource)
        else:
            _sidebar_tree.remove_theme_font_override("font")
    # NEW — status + workspace-path labels (chrome around the editor).
    for lbl in [_path_label, _status]:
        if lbl == null:
            continue
        lbl.add_theme_font_size_override("font_size", _font_size)
        if _font_resource:
            lbl.add_theme_font_override("font", _font_resource)
        else:
            lbl.remove_theme_font_override("font")
    if _is_notebook_view:
        _rebuild_rendered_cells()
```

`remove_theme_font_override("font")` on the "Default" choice is
important — it cleanly removes any previous override so the theme
default takes over again.

## What this covers

The font override now applies to **every text-bearing widget the user
sees inside the notebook view**:

| Widget                         | Before          | After           |
|--------------------------------|-----------------|-----------------|
| Source `CodeEdit`              | ✓ (font + size) | ✓               |
| `▸ cas` chip labels            | ✓ (size)        | ✓               |
| Source `RichTextLabel` body    | ✓               | ✓               |
| `= result` chip labels         | ✓ (size)        | ✓               |
| Result `RichTextLabel` body    | ✓               | ✓               |
| Prose `RichTextLabel`          | ✓               | ✓               |
| **Sidebar `Tree` (file rows)** | ✗ → **fixed**   | **✓**           |
| **Workspace path Label**       | ✗ → **fixed**   | **✓**           |
| **Status Label**               | ✗ → **fixed**   | **✓**           |

What's still on the original theme font (intentionally):

| Widget                                  | Why                                                                                     |
|------------------------------------------|------------------------------------------------------------------------------------------|
| Action-bar Buttons (Open / Save / Run …) | They're styled with the StyleBoxFlat-based theme from [task 9](task9_relabel.md). Changing font on them per-press is a separate concern. |
| Theme / Style / Font dropdowns           | Same theme.                                                                              |
| IconMenuBar at the top                   | Outside the notebook view — owned by main.gd, not notebook_view.gd.                      |

The user's brief was "the font on the left panel should match the
overall font," and that's now true. Expanding to the action-bar buttons
too is a one-line further follow-up if it comes up.

## Verification

Pre-seeded `user://font.cfg` with `family = "serif"`, launched the app,
captured [app_screenshot_task62_63_small.png](app_screenshot_task62_63_small.png):

- The sidebar files (`algebra.md`, `calculus.md`, `ode.md`, etc.) render
  in the Serif face (Cambria on the capture machine) — matches the
  notebook view's prose + cell text.
- The `Workspace: i:/readtgodot/app/notebooks_sample` label at the top
  of the action bar is also Serif.
- The status label at the bottom (`Opened i:/readtgodot/app/notebooks_sample/algebra.md`)
  is Serif.
- Switching the dropdown to any other family (Monospace, Inter, Roboto,
  System UI, …) updates all three places in one step.

## Honest scope

- **Tree's per-cell font** (Godot lets you set
  `TreeItem.set_custom_font(...)` per row) isn't touched. The
  *whole tree* takes the override — which is the simple,
  consistent-with-everything-else behaviour the user asked for.
- **Action-bar buttons** keep the app theme font. The reason: the
  font-control widgets themselves live in the action bar; changing
  *their* font as the user adjusts the choice would be visually
  jarring (the dropdown text would change mid-click).
- **The IconMenuBar toolbar at the very top** is in main.gd's domain,
  not the notebook view's. Routing the font selection up to it would
  mean making FontConfig a global setting consumed by `main.gd` too
  — bigger refactor; deferred.

---

## TL;DR

Three more `add_theme_font_override` calls in `_apply_font()` and the
left-panel Tree + chrome labels now match the user's font choice across
size and family. No new dropdown, no new config — just plumbing.
