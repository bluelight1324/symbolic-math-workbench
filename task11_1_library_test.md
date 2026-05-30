# Task 11.1 — Comprehensive Test of the Menu Library

Ran a real, automated test against **every problem** in
`ProblemLibrary.ALL` (the catalogue added in [task 11](task11_problem_menu.md))
through the live bundled engine, recorded each reply, and wrote a per-category
report. The test also caught a real bug in the plotting pipeline, which is now
fixed.

The full machine-generated report is in
[task11_test_report.md](task11_test_report.md).

---

## How the test runs

A throwaway-style harness scene + script lives in the project:

- [app/scripts/_libtest.gd](app/scripts/_libtest.gd)
- [app/scenes/_libtest.tscn](app/scenes/_libtest.tscn)

Run it headless:

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64_console.exe' `
    --headless --path 'i:\readtgodot\app' res://scenes/_libtest.tscn `
    --quit-after 7200
```

What it does:
1. Flattens `ProblemLibrary.ALL` into one list of items.
2. Dispatches every item through `MathEngine.evaluate(...)` — the **same**
   autoload the real UI uses, so the test exercises the engine, sentinel
   correlator, reader thread, and result routing end-to-end. No mocks.
3. For `kind:"plot"` items it sends the same sampling command the UI builds
   (200 samples over x ∈ [−10, 10] with a half-step offset; see "Bug found"
   below) and checks that ≥10 finite samples come back.
4. Waits for all results, writes
   [task11_test_report.md](task11_test_report.md), prints
   `REPORT_DONE pass=N fail=M total=T ms=…`, and quits.

The harness uses `result_ready(id, output, is_error)` for routing, so it does
not race the engine — each item is matched to its dispatch via the engine's
sentinel id.

## Final result

**72 passed / 0 failed / 72 total — wall time 1.9 s.** (Across 9 categories.)

| Category   | Pass / Total | Notes                                                                 |
|------------|--------------|-----------------------------------------------------------------------|
| Algebra    | 12 / 12      | Expand, factor (incl. cyclotomic `x⁶−1`), simplify, pf, gcd, lcm     |
| Calculus   | 13 / 13      | df (incl. `xˣ`, 3rd derivative), int (incl. `log`, partial fractions) |
| Equations  | 8 / 8        | Polynomials up to quintic (returns `root_of(...)`), 2×2 systems, trig |
| ODEs       | 8 / 8        | 1st & 2nd order, separable, linear, forced oscillator                 |
| Matrices   | 6 / 6        | Product, det, inverse (2×2 and 3×3), trace, M²                        |
| Series     | 7 / 7        | Taylor series, classic limits (sin x/x, (1+1/n)ⁿ, (1−cos x)/x²)       |
| Trig       | 5 / 5        | `trigsimp` Pythagorean / expand / combine, `d/dx tan`                 |
| Numbers    | 6 / 6        | gcd, integer factorisation, `binomial`, `100!`                        |
| Plots      | 7 / 7        | sin, x², 1/(x²+1), e^(−x²), sin(x)/x, sin+a·cos, tanh                 |

Selected reply samples (full table in the auto-generated report):

| Problem                            | Engine reply                                                    |
|------------------------------------|------------------------------------------------------------------|
| Factor x⁶ − 1                      | `{{x²+x+1,1}, {x²−x+1,1}, {x+1,1}, {x−1,1}}` (cyclotomic factors) |
| `d/dx xˣ`                          | `xˣ·(log(x)+1)`                                                  |
| `∫ 1/sqrt(1−x²) dx`                | `asin(x)`                                                        |
| Solve quintic `x⁵ − x − 1`         | `{x = root_of(x_⁵ − x_ − 1, x_, tag_1)}` (correct: not solvable by radicals) |
| Solve `sin(x) = 1/2`               | `{x = π(12·arbint(1)+5)/6, x = π(12·arbint(1)+1)/6}` (general)  |
| `y″ + y = sin(x)` (forced SHM)     | `(2·C₂·sin x + 2·C₁·cos x − cos(x)·x) / 2` (correct resonance form) |
| Inverse of `mat((1,2,3),(0,1,4),(5,6,0))` | `mat((-24,18,5),(20,-15,-4),(-5,4,1))`                      |
| `limit (1+1/n)^n at ∞`             | `e`                                                              |
| `100!`                             | 158-digit exact value                                            |

Wall times per item: median ~7 ms; the slowest non-trivial item
(`solve {x²+y=5, x+y=3}`) took ~120 ms; plots ~50–100 ms each.

---

## Bug found *and fixed* by this test

The very first test run was **71 / 72** with one failure:

```
❌ Plots — Plot sin(x)/x      ***** 0/0 formed
```

**Root cause.** The plot pipeline sampled at
`x = x_min + i·step` with `x_min=-10, step=0.1, i=0..200`, so `i=100` lands on
**exactly** `x=0`. For `sin(x)/x` (a removable singularity at zero) the engine
evaluates `0/0` and errors out, killing the whole plot — even though the
function has a clean limit of 1 there.

**Fix** ([main.gd:_request_plot](app/scripts/main.gd)):

```diff
- var cmd := "on rounded; for i:=0:%d collect sub(x=(%f)+i*(%f)%s, %s);
+ // Half-step offset so we never land exactly on x=0 (or other clean integers),
+ // avoiding "0/0 formed" for removable singularities like sin(x)/x.
+ var cmd := "on rounded; for i:=0:%d collect sub(x=(%f)+(i+0.5)*(%f)%s, %s);
```

The same shift was applied in the test harness so it mirrors the real app.
The visual difference of half a step on a 200-point plot is imperceptible, and
the test confirms `sin(x)/x` now produces valid samples (`{… 0.499 … 0.999 … 0.499 …}`
shape, peaking at 1 near x=0).

After the fix, the second run is **72 / 72 in 1.9 s**.

---

## Honest correction to the task-11 doc

The task-11 write-up said the catalogue had **64** problems. The actual count
across the 9 categories is **72** (12+13+8+8+6+7+5+6+7). The task-11 doc has
been corrected.

## What this proves

- Every menu item the user can click reaches the engine, is parsed correctly,
  and returns a non-error, non-empty answer.
- The persistent-session, sentinel-correlator, reader-thread, and result
  routing all hold up under burst load (72 evaluations dispatched in quick
  succession, all correctly correlated by id).
- A subtle plotting bug that would have hit users at `sin(x)/x`, `tan(x)/x`,
  and similar removable-singularity functions is now eliminated.

The harness is left in the project as a regression test — re-run it any time
problems are added or the engine pipeline is touched.
