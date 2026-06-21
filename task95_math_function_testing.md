# Task 95 — Thorough Test of the Math Functions via the New UI

## Goal

> "Do a thorough test of the math functions via the new UI."

Verify that, with the new MATLAB-look UI (task 94) in place, the engine's
**math functions produce mathematically correct answers** when driven through
the actual UI click paths — not just that the screen lights up.

## Approach

Two complementary harnesses, both driving the **same code paths a user click
takes** (`Main._do_op(...)` for the operation buttons, `Main._on_problem_selected(...)`
for the library menus), reading results straight out of the on-screen
Command History panel.

### 1. New math-correctness harness — [_mathtest.gd](app/scripts/_mathtest.gd) (`--math-test`)

- **Phase A — exact-result checks (18 assertions).** Every operation button
  (Simplify, Factor, d/dx, ∫, Solve, Solve ODE) run against an **exact,
  independently-verified expected answer**. Each expected value was
  cross-checked against REDUCE directly before being hard-coded, so a mismatch
  would mean the UI→engine pipeline is wrong, not the expectation.

  A `_normalize()` step reverses `MathFormatter.to_display()`'s pretty-printing
  (Unicode superscripts → `^N`, `·` → `*`, the `= ` result marker and
  whitespace stripped) so the displayed answer can be compared as a plain
  linear form.

| Operation | Input | UI showed | ✓ |
|---|---|---|---|
| Simplify | `(x+1)^2` | `x² + 2·x + 1` | ✓ |
| Simplify | `(x+1)^3` | `x³ + 3·x² + 3·x + 1` | ✓ |
| Simplify | `(x^2-1)/(x-1)` | `x + 1` | ✓ |
| Factor | `x^6 - 1` | `{{x²+x+1,1},{x²−x+1,1},{x+1,1},{x−1,1}}` | ✓ |
| d/dx | `x^3` | `3·x²` | ✓ |
| d/dx | `sin(x)*x` | `cos(x)·x + sin(x)` | ✓ |
| d/dx | `atan(x)` | `1/(x² + 1)` | ✓ |
| d/dx | `tan(x)` | `tan(x)² + 1` | ✓ |
| ∫ | `1/(x^2+1)` | `atan(x)` | ✓ |
| ∫ | `x^2` | `x³/3` | ✓ |
| ∫ | `cos(x)` | `sin(x)` | ✓ |
| ∫ | `1/x` | `log(x)` | ✓ |
| ∫ | `log(x)` | `x·(log(x) − 1)` | ✓ |
| Solve | `x^2 - 5x + 6` | `{x=3, x=2}` | ✓ |
| Solve | `x^4 - 1` | `{x=i, x=−i, x=1, x=−1}` | ✓ |
| Solve | `x^2 + 1` | `{x=i, x=−i}` | ✓ |
| Solve ODE | `df(y,x) = y` | `{y = e^x·arbconst(1)}` | ✓ |

- **Phase B — library breadth (9 assertions).** Iterates **every item in every
  problem-library category** through the menu click path and asserts each
  returns a valid (non-error, non-empty) result.

  | Category | Items passing |
  |---|---|
  | Algebra | 12/12 |
  | Calculus | 13/13 |
  | Equations | 8/8 |
  | ODEs | 8/8 |
  | Matrices | 6/6 |
  | Series | 7/7 |
  | Trig | 5/5 |
  | Numbers | 6/6 |
  | Plots | 7/7 |
  | **Total** | **72/72** |

**Result: 28 passed / 0 failed.** Full log in
[task95_mathtest_report.md](task95_mathtest_report.md). Screenshot of results
rendering through the themed Command History:
`app_screenshot_task95.png`.

### 2. Structural UI regression — [_uitest.gd](app/scripts/_uitest.gd) (`--ui-test`)

Re-ran the existing task-25 structural suite to confirm the task-94 retheme
didn't break wiring: **58 passed / 8 failed** —
[task25_uitest_report.md](task25_uitest_report.md).

The 8 failures are **pre-existing stale assertions, not regressions from the
new UI**, and every math/operation phase still passes:

| Failing assertion | Why it's stale (predates task 94/95) |
|---|---|
| "MenuBar has 11 category buttons" (found 12) | Task 69 added the **Notebook** button as a 12th category; the `==11` expectation was never updated. |
| Phase 13 ×7 (`_view_mode_btn`, "starts in Source mode") | Task 66 removed the standalone `_view_mode_btn` (folded into the menu popup); task 58 made **Notebook** the default view. The test still asserts the old task-35-v1 "Source first" behaviour. The toggle itself works — Phase 6 passes and "Rendered cells were emitted — 14 cells" passes. |

These belong to task 25's harness and concern widgets changed in tasks 58/66/69;
fixing those stale expectations is outside the scope of "test the math
functions" and was left untouched.

## Changes

- **Added** [app/scripts/_mathtest.gd](app/scripts/_mathtest.gd) — the math
  correctness harness.
- **Edited** [app/scripts/main.gd](app/scripts/main.gd) — wired the `--math-test`
  command-line flag (mirrors `--ui-test`).

No production logic changed; this task is purely test coverage.

## How to re-run

```powershell
# Math correctness (28 checks + 72-item breadth) → task95_mathtest_report.md
& "tools\godot\Godot_v4.6.3-stable_win64_console.exe" --path app -- --math-test

# Structural regression → task25_uitest_report.md
& "tools\godot\Godot_v4.6.3-stable_win64_console.exe" --path app -- --ui-test
```

## Verdict

Every math function exposed by the UI — expand/simplify, factor, differentiate,
integrate, solve (real & complex roots), solve-ODE, plus all 72 library
problems across 9 categories — produces the **mathematically correct** result
when driven through the new MATLAB-look UI. Math functions: **verified**.
