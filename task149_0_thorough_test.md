# Task 149.0 — Thorough Test of the Plotting Implementation (148.5 / 148.6)

## What was tested

The tasks 148.1–148.4 and 148.7 were docs; the **code** went in at **148.5**
(readability + a 2-D rendering fix) and **148.6** (colour-bar, parametric
surfaces, the renderer refactor, two bug fixes). Both were tested at two levels.

1. **Unit tests** — the headless harness
   [_test126.gd](app/scripts/_test126.gd), extended with 13 new assertions.
   `Godot --headless --path app -- --test126`.
2. **Integration** — the relevant demo notebooks re-run from clean.

## Unit-test results — 53 / 53 PASS

The 40 earlier tests still pass; the **13 new** ones all pass:

| Area | Assertions | Result |
|---|---|---|
| **Viridis colormap** (148.5) | `viridis(0)` is dark; `viridis(1)` is bright yellow | 2/2 |
| **2-D ticks / format** (148.5) | `_nice_ticks` returns several, in range; `_fmt(3.14159)`→"3.14"; `_fmt(0)`→"0" | 4/4 |
| **Parametric surfaces** (148.6) | valid → `VBoxContainer`; bad input → `Label`; surface mesh present; uses contour `ShaderMaterial` | 4/4 |
| **3-D scene additions** (148.6) | the height-field scene now has ≥3 meshes (surface + axes box + colour-bar) | 1/1 |
| **`cas-surface` plumbing** (148.6) | parser recognises `cas-surface`; `pair_blocks` makes it runnable | 2/2 |

These verify the new structure directly — e.g. that the colour-bar/axes meshes
exist in the scene, that the parametric path produces the same contour-shader
surface as the height-field path, and that `cas-surface` is wired through the
runner (the bug that left it unrun in 148.6).

## Integration test — PASS

Cleared and re-ran the demos (no script / parse / **shader** errors):

- **`parametric_surfaces.md`** (`--demo-surf`): all **3 `cas-surface` blocks ran**
  (3 result blocks written) and rendered — torus, sphere, twisted shell — with
  Viridis, contour bands, bounding box, colour-bar and numbered axes.
- **`nonlinear_pde_curvature.md`** (`--demo-135`): both **2-D plots rendered**
  ("plotted 121 samples" ×2) as inline graphics with axis tick numbers — the
  src-hash fix from 148.5 holds (no fall-back to text).

## Bugs this testing confirmed fixed

- **2-D plots rendering as text** (148.5) — inline graphics return after a fresh
  run; integration shows the curve + axis numbers, not "plotted N samples" text.
- **`%g` format** (148.6) — axis/colour-bar labels show real numbers (covered by
  `_fmt` unit tests and the integration screenshots).
- **`cas-surface` not runnable** (148.6) — `pair_blocks` unit test + the 3 written
  result blocks confirm it now runs.

## Conclusion

Everything implemented in 148.5/148.6 passes: **53/53 unit assertions + a clean
two-notebook integration run**, with the three fixed bugs each independently
verified. No script, parse, or shader errors.

## Files changed
- `app/scripts/_test126.gd` — 13 new assertions for the 148.5/148.6 plotting work.
