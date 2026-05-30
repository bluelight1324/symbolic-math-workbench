# Task 21 — Where Did All the Godot Functionality Go?

[Task 9](task9_larger_and_rebrand.md) deliberately scrubbed every
user-visible mention of "Godot" and "REDUCE" — the window title, the header,
the status text, the autoload name. To the user the app is now the
**Symbolic Math Workbench**, period.

Under the hood, **the whole thing is still Godot.** This doc maps every
feature the user touches back to the Godot subsystem that makes it work. If
you remove Godot, there is no app: the engine is the substrate for every UI
element, every async edge, the rendering, the IPC, the file system, the
window, the input, the themes — all of it.

Use it as a map: each category lists the relevant code path so you can jump
to it.

---

## Application shell

| Feature                                  | Godot piece                                  | Where in code                                                                 |
|------------------------------------------|----------------------------------------------|-------------------------------------------------------------------------------|
| Project metadata, app name, main scene   | `project.godot`                              | [app/project.godot](app/project.godot)                                        |
| Main window opens maximized              | `DisplayServer.window_set_mode(WINDOW_MODE_MAXIMIZED)` | [main.gd `_ready()`](app/scripts/main.gd), [project.godot `window/size/mode=2`](app/project.godot) |
| Resize via View menu                     | `DisplayServer.window_set_size`, `window_get_current_screen`, `screen_get_size`, `screen_get_position`, `window_set_position` | [main.gd `_set_window_size()`](app/scripts/main.gd) |
| Fullscreen toggle (F11 / Esc)            | `DisplayServer.window_get_mode`, `WINDOW_MODE_FULLSCREEN`, `WINDOW_MODE_EXCLUSIVE_FULLSCREEN` | [main.gd `_toggle_fullscreen()`](app/scripts/main.gd) |
| Autoload singleton                       | `[autoload] MathEngine="*…"` in project.godot | [project.godot](app/project.godot), [math_engine.gd](app/autoload/math_engine.gd) |
| Scene system + scene tree                | `.tscn` files, `add_child`, `_ready`         | [scenes/main.tscn](app/scenes/main.tscn), every script's `_ready()`           |
| Screenshot from inside the app           | `get_viewport().get_texture().get_image().save_png()` | [main.gd `_save_screenshot_after()`](app/scripts/main.gd) |

## Every UI element is a Godot Control node

The whole interface is built from Godot's `Control` hierarchy. Nothing is
custom-drawn except the plot. Every widget the user clicks comes from this
list:

| User-facing thing                  | Godot node(s)                          | First-seen in                                                                                    |
|------------------------------------|----------------------------------------|---------------------------------------------------------------------------------------------------|
| Layout backbone                    | `MarginContainer`, `VBoxContainer`, `HBoxContainer`, `GridContainer`, `HSplitContainer`, `CenterContainer`, `PanelContainer` | [main.gd `_build_ui()`](app/scripts/main.gd) |
| Background fill                    | `ColorRect`                             | [main.gd](app/scripts/main.gd), [help_wizard.gd](app/scripts/help_wizard.gd)                       |
| Title / status labels              | `Label`                                 | [main.gd](app/scripts/main.gd), [notebook_view.gd](app/scripts/notebook_view.gd)                    |
| Input field                        | `LineEdit`                              | [main.gd](app/scripts/main.gd)                                                                   |
| All buttons (Simplify, View menu, etc.) | `Button`                            | [main.gd](app/scripts/main.gd), [help_wizard.gd](app/scripts/help_wizard.gd), [notebook_view.gd](app/scripts/notebook_view.gd) |
| History entries with formatting    | `RichTextLabel` (with BBCode)           | [main.gd `_append_history()`](app/scripts/main.gd), [help_wizard.gd](app/scripts/help_wizard.gd)    |
| Scrolling history pane             | `ScrollContainer`                       | [main.gd](app/scripts/main.gd)                                                                   |
| Menu bar with dropdowns            | `MenuBar` + `PopupMenu`                 | [main.gd `_build_menubar()`](app/scripts/main.gd)                                                |
| Parameter sliders                  | `HSlider`                               | [main.gd `_rebuild_param_sliders()`](app/scripts/main.gd)                                        |
| Help-wizard modal overlay          | `Control` overlay + `Panel`             | [help_wizard.gd](app/scripts/help_wizard.gd)                                                     |
| Notebook editor                    | `CodeEdit` (gutter, scroll, tab markers) | [notebook_view.gd](app/scripts/notebook_view.gd)                                                |
| Workspace file tree                | `Tree`                                  | [notebook_view.gd `_populate_tree()`](app/scripts/notebook_view.gd)                              |
| Workspace folder picker            | `FileDialog` (`FILE_MODE_OPEN_DIR`)     | [notebook_view.gd](app/scripts/notebook_view.gd)                                                 |
| New-note name prompt               | `AcceptDialog` + `LineEdit`             | [notebook_view.gd](app/scripts/notebook_view.gd)                                                 |

## Theming — `Theme` + `StyleBoxFlat`

Task 9's rebrand and the larger fonts are pure Godot Theme system:

- `Theme` resource attached to the root, inherited by every `Control` ⇒
  [main.gd `_make_theme()`](app/scripts/main.gd).
- `StyleBoxFlat` for rounded buttons / panels (corner radius, bg color,
  content margins) ⇒ same function.
- `theme.default_font_size` plus per-class overrides (`set_font_size` for
  `Label`, `Button`, `LineEdit`, `RichTextLabel`, `PopupMenu`, `MenuBar`)
  give the larger UI from task 9.
- The help wizard's panel uses its own `StyleBoxFlat` with rounded corners
  ⇒ [help_wizard.gd `_build_ui()`](app/scripts/help_wizard.gd).

## 2D drawing — the plot panel

The function plot is the only thing that isn't a stock widget. It is *pure
Godot `_draw()`*:

- `_draw()`, `draw_rect`, `draw_line`, `draw_polyline` (antialiased) ⇒
  [plot_panel.gd](app/scripts/plot_panel.gd).
- `queue_redraw()` to invalidate when samples change.
- 3D plots ([task 17 §7](task17_even_further.md), [task 19 §P2 #9](task19_p0_p2_implementation.md))
  would extend this using Godot's `Camera3D` + mesh nodes — already
  scaffolded as `cas-plot3d` in the runner.

## Input handling

| User action                                    | Godot mechanism                                                              | Where                                                                                                              |
|------------------------------------------------|------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| Press Enter in input field → evaluate          | `LineEdit.text_submitted` signal                                            | [main.gd `_build_ui()`](app/scripts/main.gd)                                                                       |
| F1 (Help), F2 (Notebook), F5 (Run), F11 (Fullscreen), Esc (Exit fullscreen / wizard) | `_unhandled_input(event)` + `event.keycode` + `set_input_as_handled()` | [main.gd `_unhandled_input()`](app/scripts/main.gd), [help_wizard.gd](app/scripts/help_wizard.gd)                  |
| Ctrl+S to save the notebook                    | Same — `event.ctrl_pressed`                                                  | [main.gd](app/scripts/main.gd)                                                                                     |
| Button click                                   | `Button.pressed` signal                                                      | every UI construction                                                                                              |
| Menu item picked                               | `PopupMenu.id_pressed` signal                                                | [main.gd `_build_menubar()`](app/scripts/main.gd)                                                                  |
| Tree row double-clicked                        | `Tree.item_activated`                                                        | [notebook_view.gd](app/scripts/notebook_view.gd)                                                                   |
| History link reused                            | `RichTextLabel.meta_clicked` (BBCode `[url]`)                                | [main.gd `_append_history()`](app/scripts/main.gd)                                                                 |

## Async pipeline — the persistent CAS subprocess

This is the load-bearing thing the user *never sees* but everything depends on.

| Concern                                          | Godot piece                                                                                                |
|--------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| Spawn the engine child with stdio pipes          | `OS.execute_with_pipe(exe, ["-w"])` returning `{pid, stdio, stderr}` ⇒ [math_engine.gd `_start()`](app/autoload/math_engine.gd) |
| Long-lived bidirectional pipe                    | `FileAccess` (used as the pipe)                                                                             |
| Read on a worker thread                          | `Thread.new()` + `start(reader_loop)` ⇒ [math_engine.gd `_reader_loop()`](app/autoload/math_engine.gd)      |
| Protect the request FIFO from the reader thread  | `Mutex`                                                                                                     |
| Deliver results back to the main thread          | `call_deferred("emit_signal", "result_ready", …)`                                                            |
| App-side reaction                                | Connect handler to `MathEngine.result_ready` signal                                                          |
| Kill the child on exit                           | `OS.kill(pid)` ⇒ [math_engine.gd `_exit_tree()`](app/autoload/math_engine.gd)                              |
| Detect prompts via regex                         | `RegEx.new()` + `compile()` + `search()`                                                                    |

If you take Godot's `OS.execute_with_pipe`, `Thread`, `Mutex`, `FileAccess`,
and `Signal/call_deferred` away, the whole architecture (the foundation laid
in [task 6](task6_combined_app_implementation.md)) collapses.

## File system + notebook persistence

Task 19's notebook view is entirely on top of Godot's I/O primitives:

| Need                            | Godot piece                                  | Where                                                                              |
|---------------------------------|----------------------------------------------|-------------------------------------------------------------------------------------|
| Read / write `.md` files        | `FileAccess.open(path, READ|WRITE)`         | [notebook_view.gd `_open_file_at`, `_on_save`](app/scripts/notebook_view.gd)        |
| List a workspace folder         | `DirAccess.open(dir).list_dir_begin/get_next` | [notebook_view.gd `_populate_tree`](app/scripts/notebook_view.gd)                  |
| Check existence                 | `DirAccess.dir_exists_absolute`, `FileAccess.file_exists` | various                                                              |
| Path joining                    | `String.path_join`, `String.get_base_dir`, `String.get_basename`, `String.get_file` | various                              |
| Content hash for the cache      | `String.sha1_text()`                          | [notebook_runner.gd `source_hash`](app/scripts/notebook_runner.gd)                  |
| Resource preloading             | `preload("res://…")`                         | [main.gd](app/scripts/main.gd)                                                     |

## Async control flow (no Promises in GDScript — `await` + `Timer`)

- `await get_tree().create_timer(seconds).timeout` — every sequence that
  needs to wait (engine boot, async result polling, screenshot delays, help
  wizard demos) uses this.
- `await get_tree().process_frame` for "yield to next frame."
- `Callable.call_deferred()` to schedule a call on the next idle.
- `CONNECT_ONE_SHOT` flag for one-time signal hookups.

Examples in: every `*test.gd`, `_save_screenshot_after`, `_run_ode_demo`,
`_open_showcase_and_run`.

## Strings, types, collections

Godot's standard library carries the implementation:

- `String` methods: `strip_edges`, `replace`, `substr`, `contains`,
  `xml_escape`, `to_lower`, `trim_suffix`, `begins_with`, `split`, `join`.
- `PackedStringArray`, `PackedFloat64Array`, `PackedVector2Array` —
  zero-overhead value-type arrays for the plot samples and BBCode lines.
- `Dictionary`, `Array`, typed `Array[int]` — used throughout.
- `RegEx` + `RegExMatch` for sentinel parsing, prompt detection,
  free-symbol extraction (parameter sliders), source-hash extraction.
- `Vector2`, `Vector2i`, `Color`, `Rect2` — UI math.
- `Time.get_ticks_msec()` — used for response-time measurements and
  marker-file timestamps in the test harnesses.

## Command-line surface

Several flags landed during the build:

| Flag         | What it does                                                | Engine API used                       |
|--------------|-------------------------------------------------------------|----------------------------------------|
| `--demo-ode` | Auto-run an ODE on startup (task 8)                          | `OS.get_cmdline_user_args()`           |
| `--demo-menu`| Auto-pick items from the menu library (task 11)              | same                                   |
| `--tour`     | Auto-open the help wizard (task 12)                          | same                                   |
| `--notebook` | Switch to notebook view + open algebra.md (task 19)          | same                                   |
| `--showcase` | Switch to notebook view, open showcase.md, run it (task 20)  | same                                   |
| `--capture <path>` | Save a viewport screenshot after a delay              | `get_viewport().get_texture().get_image().save_png()` |

All of these are surfaced because Godot exposes the full command line via
`OS.get_cmdline_user_args` / `OS.get_cmdline_args`.

## Headless mode — the test substrate

Every regression test in the project (the menu-library test from
[task 11.1](task11_1_library_test.md), the notebook test from
[task 19](task19_p0_p2_implementation.md)) runs in Godot's headless mode:

```
godot --headless --path app res://scenes/<test>.tscn --quit-after <frames>
```

Headless gives us the autoload (`MathEngine`), the engine child process, the
async signal pipeline, the file system, the regex — **everything except
rendering**. That's exactly what we need for fast CI-style validation.

## What Godot gives us that we'd otherwise have to build

These items are essentially free because we picked Godot:

1. **A high-quality `Control` UI toolkit** with anchors, theming, scrolling,
   styled text — replacing what would otherwise be Qt or a hand-rolled GUI.
2. **A safe, supervised child process API** with stdio pipes
   (`OS.execute_with_pipe`) — replacing `Boost.Process` / `subprocess.py`.
3. **A scene + autoload model** that gives us a tested app shell with
   lifecycle (`_ready` / `_exit_tree`) we didn't write.
4. **An async-friendly signal + `await` system** that lets a sequential
   `evaluate(); await result;` loop be written without threading hazards.
5. **A regex engine, threading primitives, file system, hashing
   (`String.sha1_text`)** — everything the cache + runner need.
6. **A 2D renderer with `_draw()` plus the latent 3D renderer** — the plot
   panel uses it today, the 3D plot proposal from
   [task 17 §7](task17_even_further.md) sits ready to use it.
7. **A native screenshot API** — `viewport.get_texture().get_image().save_png()`
   — which we leaned on when PowerShell's `Add-Type` got memory-flaky during
   [task 11](task11_problem_menu.md) and again during
   [task 19](task19_p0_p2_implementation.md).
8. **Cross-platform export targets** — Windows ships today, Mac / Linux /
   Android / iOS / HTML5 are all one export setting away when the binaries
   for the engine ship for those platforms (see
   [task 16 §9](task16_beyond_zettlr.md), [task 17 §12](task17_even_further.md)).

## So where did the Godot functionality go?

**Nowhere.** It just lost its top-bar mention. Every section of this doc
points back to it; the entire user experience is Godot's
`Control`/`Theme`/`Signal`/`OS`/`FileAccess`/`DisplayServer` stack, plus
GDScript's typed collections and `await` model, plus the headless harness
for tests. The CAS engine (REDUCE) provides the math; Godot provides the
*application* — UI, IPC, I/O, scheduling, rendering, packaging.

The fastest way to see it for yourself: open
[app/scripts/main.gd](app/scripts/main.gd) and search for `Godot` (no hits
in code), then search for `Control`, `Button`, `Signal`, `Thread`, `OS.`,
`DisplayServer`, `FileAccess`, `RegEx`, `Theme`. Every match is the engine
showing through.
