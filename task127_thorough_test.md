# Task 127 — Thorough Test of the Task-126 Features

## What was tested

All six features added in task 126, at two levels:

1. **Unit tests** — a headless harness ([_test126.gd](app/scripts/_test126.gd))
   that instantiates a `NotebookView` (without the scene tree) and asserts on the
   pure logic and the UI-state methods. Run with:
   `Godot --headless --path app -- --test126`
2. **Integration test** — a fresh end-to-end run of the demo notebook
   `features_126.md` (`--demo-126`) so the LaTeX `cas` blocks actually evaluate
   through the REDUCE engine and the 3D surfaces render.

## Unit-test results — 28 / 28 PASS

| Area | Cases | Result |
|---|---|---|
| **LaTeX → REDUCE** | no-op (plain REDUCE), `\frac`, `\sqrt`, `^{}`, definite integral + implicit mult, `\cdot`, `\infty`, greek, **nested `\frac` with `^{}`** | 9/9 |
| **`^` → `pow`** (3D evaluator) | `x^2`, `sin(x)^2`, `(x+y)^2` | 3/3 |
| **Implicit multiplication** | `(a)(b)`, `2x`, `sin(x)` untouched | 3/3 |
| **Wikilinks** | `[[foo]]`/`[[bar]]` → `[url=…]`, plain-text passthrough | 3/3 |
| **Clear outputs** | result block removed, source kept, prose kept | 3/3 |
| **Workspace search** | collects ≥8 `.md`, finds `algebra.md`, `"integral"` finds hits | 3/3 |
| **Distraction-free** | toggle hides then restores the sidebar | 2/2 |
| **3D surface builder** | valid expr → `SubViewportContainer`, bad expr → `Label` fallback | 2/2 |

## Bugs found by testing — and fixed

Testing was not a rubber-stamp; it caught **two real bugs** in the LaTeX
converter, both now fixed and re-verified:

1. **`x^{2}` was left unconverted.** The no-op guard returned early when the
   source had no backslash — but `^{…}` is LaTeX (REDUCE never writes `^{`). Fix:
   the guard now also triggers on `^{` / `_{`. `x^{2}` → `x^(2)`.
2. **Nested `\frac` with a superscript failed** — `\frac{1}{1+x^{2}}` produced
   `frac{1}{1+x^(2)}` because the inner `^{2}` braces nested inside the (non-
   nesting) `\frac` regex. Fix: convert `^{…}` → `^(…)` **before** `\frac`/`\sqrt`,
   so the fraction body is brace-free when the frac regex runs.
   `\int_{0}^{1}\frac{1}{1+x^{2}}\,dx` → `int(((1)/(1+x^(2))), x, 0, 1)`.

## Integration test — PASS

Cleared `features_126.md`'s cached results and re-ran it through REDUCE
(`--demo-126`), no runtime/parse errors:

| LaTeX `cas` block | REDUCE result |
|---|---|
| `\frac{1}{2}\cdot x^{2} + \sin(x)` | `(2·sin(x) + x²)/2` ✓ |
| `\int_{0}^{x} (x-t)\sin(t)^{3}\,dt` | `(−sin³x − 6·sin x + 6x)/9` ✓ (= task-120 result) |
| `z = sin(x)*cos(y)` (cas-plot3d) | renders a real 3D surface ✓ |
| `z = sin(x*x + y*y)` (cas-plot3d) | renders a real 3D surface ✓ |

The 3D surfaces were also confirmed visually in task 126
(`app_screenshot_task126.png`), and wikilinks render as blue clickable links
(`_t126_top` capture).

## Conclusion

All six task-126 features pass: **28/28 unit assertions + the end-to-end engine
run**, with two converter bugs found and fixed along the way. The app launches
and runs with no script/parse errors.

## Files changed
- `app/scripts/notebook_view.gd` — LaTeX converter fixes (guard on `^{`/`_{`;
  superscripts converted before fractions); extracted testable
  `_strip_result_blocks()`.
- `app/scripts/_test126.gd` — new headless test harness (28 assertions).
- `app/scripts/main.gd` — `--test126` flag to run the harness.
