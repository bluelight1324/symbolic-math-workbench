# Task 69 — Notebook Menu Becomes the First IconMenuBar Button

[Task 66](task66_one_dropdown.md) collapsed the 13 notebook-view
widgets into a single MenuButton that sat on the **right** of the
notebook action bar. The brief for task 69: move that menu to the
**top-left**, into the global `IconMenuBar` alongside View, Algebra,
Calculus, etc., styled the same way as the other category buttons.

Now done. The notebook menu is the **first** button in the
`IconMenuBar` row, rendered as `☰ Notebook` with the same icon-glyph +
small label + blue-accent bottom border pattern every other category
button uses.

See the two screenshots:
- [app_screenshot_task69_small.png](app_screenshot_task69_small.png) — the
  toolbar with the Notebook button at the front.
- [app_screenshot_task69_open_small.png](app_screenshot_task69_open_small.png) — the
  popup opened from its new home, showing the full menu tree intact.

---

## What changed where

### `app/scripts/notebook_view.gd`

The notebook view's own MenuButton is gone. The popup it built is now
a **standalone PopupMenu** rather than `MenuButton.get_popup()`:

```diff
 func _build_menubar_popup() -> void:
-    _popup = _menu_btn.get_popup()
-    _popup.clear()
+    _popup = PopupMenu.new()
+    add_child(_popup)
+    _popup.clear()
```

`_build_ui` no longer instantiates `_menu_btn`; the action bar now has
just the workspace path label on the left and nothing else on the right.

A new accessor exposes the popup so `main.gd` can pluck it:

```gdscript
## Task 69 — exposed for main.gd so the global IconMenuBar can adopt this
## popup as its first category button.
func get_menu_popup() -> PopupMenu:
    return _popup
```

### `app/scripts/main.gd`

A new field `_icon_menubar: IconMenuBar` stores the bar so we can mutate
it after the notebook view is created. Right after
`_notebook = NotebookViewScript.new()`, the notebook's popup is
reparented into the IconMenuBar via the same `add_category` API every
other button uses:

```gdscript
if _icon_menubar:
    var notebook_popup := _notebook.get_menu_popup()
    if notebook_popup:
        # Detach from notebook before reparenting (avoids "already has parent" errors).
        if notebook_popup.get_parent():
            notebook_popup.get_parent().remove_child(notebook_popup)
        var nb_btn := _icon_menubar.add_category(
            "☰", "Notebook", notebook_popup, Color(0.55, 0.65, 0.95))
        _icon_menubar.move_child(nb_btn, 0)
```

Three things to flag in that block:

1. **Reparenting**. The PopupMenu starts as a child of the NotebookView.
   `add_category` calls `add_child(menu)` on the IconMenuBar, which
   would error if the menu still has a parent. The explicit
   `remove_child` first keeps the move atomic.
2. **`move_child(nb_btn, 0)`**. `add_category` appends to the end of the
   IconMenuBar's children. We slide the new button to index 0 so it
   renders first (left-most).
3. **`☰` glyph + blue accent**. Matches the convention of the other
   IconMenuBar buttons (View uses a similar `⊞` glyph + blue). The
   `add_category(icon, label, menu, accent)` signature is unchanged.

## What stays the same

- **Every menu item, every submenu, every check item, every keyboard
  shortcut display.** The popup tree built by `_build_menubar_popup()`
  is unchanged. Opening the Notebook button shows the same content
  task 66 introduced: File operations, Show Source, Font/Size/Theme/
  Style submenus, Looks bundles (task 68), Shadows + Animations toggles.
- **All handlers** (`_on_menu_id_pressed` and its routing constants).
- **Persistence** — the popup writes through to the same ConfigFiles.
- **The keyboard shortcuts** themselves (Ctrl+S, F5, Ctrl+F5) — wired
  in `main.gd._unhandled_input`, not via the menu. The menu only
  *displays* them as hints.

## What's now on the notebook view's action bar

```
Workspace: i:/readtgodot/app/notebooks_sample
```

Just the workspace path label. The bar feels noticeably lighter; the
File operations and preferences are one click away in the toolbar
above, where they belong with the other global navigation.

## Verification

- Project reimports headless with **exit 0, no script errors**.
- Closed-toolbar screenshot
  ([app_screenshot_task69_small.png](app_screenshot_task69_small.png))
  shows the new ordering at the top:
  ```
  ☰ Notebook | ⊞ View | 𝑎 Algebra | ∫ Calculus | = Equations |
  𝑦' ODEs | ▦ Matrices | ∑ Series | △ Trig | # Numbers | ↗ Plots | ? Help
  ```
- Open-popup screenshot
  ([app_screenshot_task69_open_small.png](app_screenshot_task69_open_small.png))
  shows the popup hanging off the Notebook button:
  Open workspace · New note · Save · Run notebook · Force re-run ·
  Export HTML · Show Source · Font ▶ · Size ▶ · Theme ▶ · Style ▶ ·
  Looks ⭐ ▶ · ☑ Shadows · ☑ Animations.
- Manual interaction: clicking each item routes through the existing
  `_on_menu_id_pressed` handler, which calls the same `_on_open_workspace`,
  `_on_run`, `_on_force_run`, etc. callbacks. Nothing about the
  semantics changed.

## Honest scope

- **The IconMenuBar is in main.gd; the popup is in notebook_view.gd.**
  Reparenting works but creates a small ownership ambiguity — if the
  notebook view is destroyed, the popup would be orphaned in the
  IconMenuBar. For now this can't happen (the notebook view is owned
  by main and persists for the app's lifetime), but a future
  scenario where views can be torn down would want to clean up here.
- **Calculator view inherits the toolbar layout.** Pressing F2 (toggle
  to calculator) keeps the IconMenuBar visible at the top — the
  Notebook button is still there, and clicking it opens the popup with
  notebook-specific actions even though the user is currently looking
  at the calculator. That's intentional in this iteration; treating the
  Notebook menu as a *navigation entry point* (open notebook view + run
  the action) rather than a "this only works when notebook is visible"
  control is the cleaner UX. Not all menu items make perfect sense in
  calc mode, but none crash either.
- **The popup's submenu names** (`FontMenu`, `SizeMenu`, `ThemeMenu`,
  `StyleMenu`, `LooksMenu`) are scoped within the popup, not globally.
  Multiple instances of NotebookView would conflict; we never have
  more than one.
- **The `_menu_btn` field declaration stays as nullable** in
  `notebook_view.gd` so the task-25/36 UI test references to it (if any)
  don't break. The handler that referenced it (`_show_menu` in old code)
  is removed.

---

## TL;DR

`_build_menubar_popup()` now builds `_popup` as a standalone
`PopupMenu`. The notebook view's MenuButton is gone from the action
bar. `main.gd` reparents the popup into the global IconMenuBar via the
existing `add_category(...)` API, then `move_child(...)` slides the
button to index 0. One reparent + one move, no logic / handler /
persistence changes. The Notebook menu now lives next to View where
the user wanted it.
