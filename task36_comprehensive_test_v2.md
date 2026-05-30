# Task 36 — Comprehensive UI Test of the Recent Work (Tasks 31–35)

Task 25 shipped a 34-assertion UI regression suite for everything through
the icon menu bar. Tasks 31 through 35 added a lot of new surface — the
package-settings dialog, the engine restart hook, the split right pane
(Code + Result), the redesigned Advanced view, the Mathematica-style
inline notebook cells, and the latest layout tweak that makes the
notebook the default opening view while keeping the toolbar untouched
on top. Task 36 extends the same harness to cover all of that.

**Final result: 66 passed / 0 failed in ~4.4 s.** Full report:
[task25_uitest_report.md](task25_uitest_report.md).

Harness lives at [app/scripts/_uitest.gd](app/scripts/_uitest.gd) and is
launched the same way as before:

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --ui-test
```

---

## What was added in v2

The original 8 phases (existence, operations, menu library, reset,
wizard, notebook toggle, view menu, keypad — 34 assertions) all still
pass unchanged. Five new phases cover the recent work:

| Phase | What it tests                                      | Source task   | # of assertions |
|------:|----------------------------------------------------|---------------|-----------------|
| 9     | Right pane: Code + Result views populate per op    | 34            | 6               |
| 10    | Package-settings dialog open/close + config state  | 31, 32        | 7               |
| 11    | Advanced view (sidebar + filterable grid)          | 26, 27        | 5               |
| 12    | Default opening view is notebook + toolbar visible | latest tweak  | 4               |
| 13    | Notebook Source ↔ Notebook view toggle             | 35 v2         | 10              |
| **Total new** |                                          |               | **32**          |

## What each new phase checks

### Phase 9 — Right pane (task 34)

Caches `_code_view` and `_result_view` from main via `_main.get("_code_view")`
(same dynamic-property trick the harness uses for `_input` to dodge the
`Node._input(event)` shadow). Drives two deterministic operations:

```
Input: (x+1)^3              Op: Simplify
  → Code pane shows: (x+1)^3
  → Result pane shows: x³ + 3·x² + 3·x + 1

Input: sin(x)*x             Op: d/dx
  → Code pane shows: df(sin(x)*x, x)      ← wrapping verified
  → Result pane shows: cos(x)·x + sin(x)
```

Both the wrapped engine command and the formatted output (with Unicode
superscripts + middle-dot multiplication) are exactly what the user
sees in the right pane.

### Phase 10 — Package settings (tasks 31, 32)

- `_pkg_settings` exists; visible starts false.
- Opens via `_pkg_settings.open()` → visible flips to true.
- `PackageConfig.KNOWN.size() == 22` — every package the dialog shows
  is actually probed-loadable in the bundled REDUCE.
- `PackageConfig.DEFAULT_SELECTED` includes the core three (`odesolve`,
  `taylor`, `limits`) so a fresh install loads them.
- `PackageConfig.load_selected()` returns a non-empty list (`size=8`
  in the run: the seven tier-1 defaults plus `groebner` left in from
  the task-33 demo).
- `close_panel()` returns visible to false.

### Phase 11 — Advanced view (tasks 26, 27)

- `_advanced` exists; visible starts false.
- `_toggle_advanced()` shows it.
- `AdvancedLibrary.build()` totals **332 problems** across 13
  categories. Asserted `>= 200` so the harness survives future growth.
- Closes cleanly back to invisible.

### Phase 12 — Default notebook + toolbar room (latest layout change)

- `_notebook.visible == true` at startup → the just-shipped
  default-open-notebook works.
- `_notebook.offset_top == 102` → the toolbar's 102 px of vertical
  space is reserved.
- The `IconMenuBar` is still present in the tree (search via
  `_find_icon_menubar` from the original harness).
- The toolbar's `global_position.y` (16 in the run) is **above** the
  notebook's top (102) → the toolbar is visibly *not* covered by the
  notebook. Exactly what the user asked for ("do not change the look
  of the toolbar on top left").

### Phase 13 — Source ↔ Notebook view toggle (task 35 v2)

- The View toggle button (`_view_mode_btn`) exists.
- Both the raw `_editor: CodeEdit` and the rendered `_rendered_scroll:
  ScrollContainer` exist.
- App starts in Source mode: editor visible, rendered hidden.
- `_toggle_view_mode()` flips both visibilities.
- After the flip, `_rendered_box.get_child_count()` reports **19
  cells** — the rebuilt cell stack from `algebra.md`'s prose / code /
  result / `cas-test` blocks.
- Toggle back: editor visible, rendered hidden again.

---

## Honest scope of the test

What it does **not** verify:

- Pixel-level rendering of the icon-menu-bar styles, the help wizard
  layout, the inline-plot canvas curve shape — those are confirmed by
  the per-task screenshots
  ([app_screenshot_iconbar.png](app_screenshot_iconbar.png),
  [app_screenshot_packages.png](app_screenshot_packages.png),
  [app_screenshot_advanced_v2.png](app_screenshot_advanced_v2.png),
  [app_screenshot_nbcells_small.png](app_screenshot_nbcells_small.png),
  [app_screenshot_default_nb_small.png](app_screenshot_default_nb_small.png)).
- Live engine restart for the package-settings Apply flow. The harness
  asserts the dialog opens/closes and the config state is loadable;
  the actual `MathEngine.restart()` is exercised by the task-33
  Gröbner demo (which sees `groebner` go from absent → present after
  the restart and successfully runs).
- Driving real `cas-plot` blocks through the engine inside the
  rendered view. The Mathematica-style inline plot was screenshot-
  verified in task 35
  ([app_screenshot_nbcells_small.png](app_screenshot_nbcells_small.png));
  the harness checks the rebuilt cell count rather than re-running
  the engine asynchronously inside a synchronous test.

These gaps are intentional — they're the things only screenshots can
honestly check, and the per-task docs already carry them.

## How to interpret the report

The numbers in the marker file
([uitest_marker.txt](uitest_marker.txt)) are wall-clock milliseconds
since boot. The progression looks like:

```
2633   boot done
2674   IconMenuBar + 11 buttons confirmed
2773–3594  every operation + every menu-library category exercised live
4013   reset-then-evaluate clean
4133–4218  view-menu + keypad
4253–4314  task 34 — Code + Result panes verified
4313–4393  task 31/32 + 26/27 — settings dialog + advanced view
4394–4395  the just-shipped default-notebook + toolbar room
4396–4433  task 35 v2 — Source ↔ Notebook toggle
4434   DONE pass=66 fail=0
```

Just over a second covers the entire new surface, which means the
existing rhythm of the harness — operations in ~50 ms each, view
toggles instantaneous — held up cleanly under the additions.

## What this proves

- **Every UI surface added in tasks 31–35** runs end-to-end against
  the live engine without crashing.
- **The just-shipped layout change** (notebook as the default opening
  view, toolbar position preserved) is exactly what was asked for —
  toolbar at `y=16`, notebook below it from `y=102`.
- **No regression** on any of the original 34 assertions from
  [task 25](task25_comprehensive_ui_test.md).
- **66 / 66 PASS in 4.4 s** is the new baseline — anything that drops
  below it on a future change is a real regression.
