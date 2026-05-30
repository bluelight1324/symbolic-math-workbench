# Task 25 — Comprehensive UI Test

A single harness drives every UI surface in the app — menu bar, operation
buttons, problem library, reset session, help wizard, notebook view, view
menu, keypad — through the same code paths a user would hit clicking. Each
phase records PASS/FAIL with a short detail, and the harness writes
[task25_uitest_report.md](task25_uitest_report.md) at the end.

**Final result: 34 passed / 0 failed in ~4.4 s.**

The harness lives at
[app/scripts/_uitest.gd](app/scripts/_uitest.gd) +
[app/scenes/…](app/scripts/_uitest.gd) and is kept in the project as a
regression test alongside the earlier
[library test](task11_1_library_test.md) and
[notebook test](task19_p0_p2_implementation.md).

---

## How to run it

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --ui-test
```

The new `--ui-test` flag in [main.gd](app/scripts/main.gd) instantiates
`_uitest.gd` as a child of Main; the harness drives Main's own properties
and methods directly. It writes progress to a marker file
(`i:/readtgodot/uitest_marker.txt`) as it runs, so even if the process
stalled mid-test you can see exactly which assertion got farthest.

## What it tests

| Phase | Surface | Assertions |
|------:|---------|----:|
| 1 | UI structure exists (input, history, plot, wizard, notebook, IconMenuBar with 11 buttons) | 7 |
| 2 | Each operation button (Simplify, Factor, d/dx, ∫ dx, Solve, Solve ODE, Plot) end-to-end through the live engine | 7 |
| 3 | One item from every problem-library category (9 of them) | 9 |
| 4 | **Task-24 regression**: Reset session followed by an evaluate has no leftover lines (`clear$`, `latex not defined`) | 1 |
| 5 | Help wizard — starts hidden, opens, advances 3 steps to step 4, closes | 4 |
| 6 | Notebook view — toggles visible, toggles back | 3 |
| 7 | View menu — Maximize and all four size presets execute without crashing | 2 |
| 8 | Keypad — token insertion appears in the input field | 1 |
| **Total** | | **34** |

Each operation assertion checks three things:
1. The engine returned a non-error result (no `_pending` left after timeout).
2. The history grew by exactly one entry (except Plot, which updates the
   plot panel instead).
3. The result text contains an expected substring (`cos` for `d/dx sin(x)*x`,
   `atan` for the integral, `arbconst` for the ODE, etc.).

For menu-library picks, the harness skips items with `kind: "plot"` (which
go through the plot pipeline rather than history) to keep the assertions
uniform.

## Honest bug found and fixed while writing this test

The first run failed at parse time with 14 errors:

```
SCRIPT ERROR: Parse Error: Cannot find member "text" in base "Callable".
SCRIPT ERROR: Parse Error: Function "set_caret_column()" not found in base Callable.
```

**Root cause.** Main exposes a `var _input: LineEdit` field — but
`Node._input(event)` is also a built-in *virtual method*. From outside the
script, GDScript resolves `_main._input` to the Callable for the virtual
method, **not** the field. The result: every `_main._input.text = ...`
treated `_input` as a Callable, didn't find `.text`, refused to compile.

**Fix.** The harness now caches each field once via dynamic property
lookup:

```gdscript
var _input: LineEdit
var _history_box: VBoxContainer
…
func _ready() -> void:
    _main = get_parent()
    _input = _main.get("_input") as LineEdit
    _history_box = _main.get("_history_box") as VBoxContainer
    …
```

After that, every `_input.text` / `_input.set_caret_column(0)` resolves to
the LineEdit. (Naming the field `_input` in Main is mildly hazardous; a
clean follow-up would rename it to `_input_field` to avoid the shadow.)

This is a real lesson worth capturing — anything starting with `_input`,
`_process`, `_ready`, `_unhandled_input`, `_draw` etc. should not be the
name of a stored field, because access from outside the script will
silently route to the built-in callable.

## Cross-referenced results from the report

A few highlights from the per-assertion lines (full text in
[task25_uitest_report.md](task25_uitest_report.md)):

```
✅ Simplify (x+1)^2  — text== x² + 2·x + 1
✅ Factor x^6-1     — text== {{x² + x + 1,1}, | {x² - x + 1,1}, | {x + 1,1}, | {x - 1,1}}
✅ ∫ 1/(x^2+1) dx   — text== atan(x)
✅ Solve ODE y'=y   — text== {y=e^x·arbconst(1)}
✅ Series → Taylor exp(x) at 0, order 5  — text== taylor(1 + x + 1/2·x² + 1/6·x³ + 1/24·x⁴ + 1/120·x⁵,x,0,5)
✅ Reset-then-evaluate has no leftover lines   — text== x² + 2·x + 1
✅ Wizard advanced to step 4  — current=3
```

Notable:
- **Unicode superscripts** + **·** for multiplication are present in every
  result, confirming `MathFormatter.to_display` is wired through.
- The **task-24 reset-leak regression** passes here, so that fix stays good.
- The **wizard** advances `current` from 0 → 3 (step 4 of 13).
- The **Series → Taylor exp(x)** problem returns the textbook 5-term Taylor
  series in one entry.

## What this test does NOT do

- **No visual checks**. It runs in a windowed Godot session but doesn't
  screenshot during the test or verify pixel colours. The earlier
  task-23 ([app_screenshot_iconbar.png](app_screenshot_iconbar.png)) and
  task-19 ([app_screenshot_notebook.png](app_screenshot_notebook.png))
  screenshots are the canonical visual evidence.
- **No headless verification of window-size effects**. Godot's
  `DisplayServer.window_set_size(...)` may be a no-op when running
  windowed-but-minimised; the test asserts the calls don't crash, not that
  the window actually resized.
- **No FileDialog driving**. Opening a workspace via the file picker
  requires user interaction; the bundled sample workspace path is wired in
  by `--notebook` separately and isn't part of this test.

These gaps are intentional — they trade away things only humans can verify
in exchange for a fast, deterministic regression suite the project can run
on every change.

## Summary

The whole UI — every menu category, every operation, the reset path, the
help wizard, the notebook toggle, the view menu, the keypad — works
end-to-end with the live engine. **34 / 34 PASS in 4.4 s.** Harness left
in-tree at [app/scripts/_uitest.gd](app/scripts/_uitest.gd) for future
regression runs.
