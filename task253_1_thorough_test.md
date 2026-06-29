# Task 253.1 — Thorough Test of the Plotting Work

## Request

> "Do a thorough test of what you implemented in the above."

A full verification pass over the plotting features added in tasks **251.0**
(2-D multi-series + complex domain colouring), **252.0** (PNG export) and **253.0**
(threaded sampling) — plus a regression check of the earlier plot kinds. Three
layers: unit tests, demo integration, and export integration. **All green.**

## 1. Unit tests — `--test126`: **123 / 123 pass, exit 0**

The harness grew from 93 → **123 assertions** (25 new "thorough" checks for 253.1).
Coverage by area:

- **Complex evaluator** (`ComplexEval`, domain colouring): exact arithmetic on
  `z·z` (`(1+i)² = 2i`), `sqrt(4)=2`, `sin(0)=0`, `cos(0)=1`, implicit multiplication
  `2z|₃ = 6`, `conj(1+2i)=1-2i`, **Euler** `exp(iπ) ≈ -1`, unary minus, and
  `1/0 → non-finite`. Error handling: unbalanced parens, empty input, and garbage
  are all rejected (not crashed).
- **2-D multi-series**: `_plot_exprs` splits lines and skips blanks/`#` comments
  (3 curves from a 5-line block); `_extract_brace_groups` returns the right
  **top-level** groups even when nested (`{{3},{4}}` kept whole) and none when
  there are no lists; `set_series` stores N curves with distinct palette colours
  and `set_samples` clears them.
- **Domain image**: `_domain_image` returns a **280×280 RGB8** `Image`; the colour
  is **dark near a zero** and **brighter for large |f|** (the magnitude encoding);
  saturated for finite values, white at a pole.
- **Implicit surfaces**: `_implicit_surftool` returns a `SurfaceTool` for a plane /
  sphere and **null** for a no-crossing function; `_implicit_finish(null)` → a
  message `Label`, `_implicit_finish(SurfaceTool)` → the lit 3-D scene.
- **PNG export**: `_find_subviewport` / `_find_texrect` locate the capture source
  (including a **deeply-nested** viewport) and return null when absent; `_png_btn`
  builds a button; an export target adds exactly one button to the control bar.
- **Threaded wrapper**: `_async_plot` returns an instant placeholder cell and, when
  detached (no live tree), runs the build synchronously and threads the worker's
  data through to `finish`.
- **Regression**: the original suite (LaTeX→REDUCE, implicit multiplication,
  wikilinks, clear-outputs, workspace search, distraction-free, surface/parametric
  builders, zoom, Viridis, ticks, `^→pow` incl. nested parens) all still pass.

## 2. Demo integration — every plot kind renders, **0 script errors**

Each demo notebook was run in a real window; result blocks written and stderr
scanned for errors:

| Demo | Notebook | Result blocks | Script errors |
|---|---|---|---|
| `--demo-multi` | multi_series.md | 3 × `cas-plot-result` | 0 |
| `--demo-domain` | domain_coloring.md | 3 × `cas-domain-result` | 0 |
| `--demo-impl` | implicit_surfaces.md | 2 × `cas-implicit-result` | 0 |
| `--demo-dyn` | dynamic_plots.md | 2 × `cas-anim-result` + 2 × `cas-field-result` | 0 |
| `--demo-surf` | parametric_surfaces.md | 3 × `cas-surface-result` | 0 |

So all eight plot kinds (2-D curves incl. multi-series, 3-D height fields,
parametric, animated, vector field, implicit, domain colouring) run end-to-end.

## 3. Export integration — `--test-export`: both branches, **exit 0**

Exercises the two native-resolution export paths in one run:

- **3-D (SubViewport branch)**: `implicit_surfaces.md` → `EXPORT_RESULT ok 1088×560`.
- **Domain (TextureRect branch)**: `domain_coloring.md` → `EXPORT_RESULT ok 280×280`
  — the saved file (`app_screenshot_task2531_domain_export.png`) is a valid `z²−1`
  portrait (two zeros, phase wheel, magnitude rings).

Exit code **0** with **0 script errors** — confirming the 253.0 threading fixes
(commit/texture on the main thread, `_process` apply, exit-join) hold under the
build-then-export-then-quit sequence that previously crashed at shutdown.

## Findings

- **No defects found.** Every feature behaves as designed, including edge cases
  (no-crossing surfaces, poles, malformed input) and the threaded shutdown path.
- One **benign pre-existing warning** remains (`Screen-space AA is only available on
  Forward+/Mobile`) — a renderer-capability notice emitted whenever a 3-D scene is
  built; it is not an error and does not affect output. Out of scope here (not a
  regression from this work).

## Files changed
- `app/scripts/_test126.gd` — +25 thorough assertions (now **123/123**).
- `app/scripts/main.gd` — `--test-export` now covers the 3-D **and** domain export
  branches (`_report_export` helper).
