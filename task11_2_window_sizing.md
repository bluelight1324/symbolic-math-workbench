# Task 11.2 — Open Maximized + View Menu for Resizing

Two changes:
1. The app now **opens maximized** (as large as the screen allows).
2. A new **View menu** in the menu bar gives explicit window-size controls,
   including a fullscreen toggle and several preset sizes.

See [app_screenshot_task11_2.png](app_screenshot_task11_2.png) — captured at
**3440×1334** on this monitor, with `View | Algebra | Calculus | Equations |
ODEs | Matrices | Series | Trig | Numbers | Plots` visible across the top.

---

## "As large as possible" on startup

Two places set this so the window never appears small first:

[app/project.godot](app/project.godot):

```ini
window/size/mode=2           ; WINDOW_MODE_MAXIMIZED
window/size/resizable=true
window/size/viewport_width=1300   ; fall-back used if user picks "Default"
window/size/viewport_height=720
```

[main.gd `_ready()`](app/scripts/main.gd):

```gdscript
DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
```

The project-file setting takes effect before the first frame is shown, so
there's no flicker from "default size → maximized". The `_ready()` call
re-asserts it (idempotent) and protects against any platform that ignores the
project setting.

## View menu — explicit resize options

Added as the **first menu** in the bar (so it's available regardless of how
many problem categories exist):

```
View
 ├─ Maximize
 ├─ Toggle Fullscreen   (F11)
 ├─ ──────────────────
 ├─ Compact   1100×680
 ├─ Default   1300×720
 ├─ Large    1600×900
 └─ Full HD  1920×1080
```

Each item is wired in `_on_view_selected()`:

```gdscript
match id:
    0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
    1: _toggle_fullscreen()
    2: _set_window_size(1100, 680)
    3: _set_window_size(1300, 720)
    4: _set_window_size(1600, 900)
    5: _set_window_size(1920, 1080)
```

`_set_window_size()` switches the window out of maximized/fullscreen first,
applies the requested size, and **centres** the window on the current screen:

```gdscript
func _set_window_size(w: int, h: int) -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(w, h))
    var screen := DisplayServer.window_get_current_screen()
    var screen_size := DisplayServer.screen_get_size(screen)
    var screen_pos := DisplayServer.screen_get_position(screen)
    DisplayServer.window_set_position(screen_pos + (screen_size - Vector2i(w, h)) / 2)
```

## Keyboard shortcuts (also handled in `_unhandled_input`)

| Key       | Action                                                              |
|-----------|---------------------------------------------------------------------|
| **F11**   | Toggle fullscreen ↔ maximized                                       |
| **Escape**| Exit fullscreen (drops back to maximized; ignored when windowed)    |

Window-manager controls (the OS title-bar min/max/close, dragging the borders
to resize freely) still work as expected — `resizable=true` is set explicitly.

## Verification

- Project imports headless with **exit 0, no script errors** after the edits.
- A `--capture <path>` helper flag was added so the headed launch can save its
  own screenshot for verification without needing an external screenshot tool
  (PowerShell's `Add-Type` was flaky earlier in this session — see
  [task11_1_library_test.md](task11_1_library_test.md) and
  [task11_problem_menu.md](task11_problem_menu.md)).
- Launched with
  `Godot_v4.6.3-stable_win64.exe --path app -- --capture <path>` →
  captured a **3440×1334** screenshot of the maximized window with the View
  menu visible as the first menu, followed by all 9 problem categories.

## How to use it

```powershell
# Default launch — opens maximized.
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' --path 'i:\readtgodot\app'
```

From there: open **View** in the menu bar to pick a preset size, hit **F11**
for fullscreen, or drag the window borders normally.
