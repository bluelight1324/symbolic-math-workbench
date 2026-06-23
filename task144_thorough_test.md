# Task 144 — Thorough Test of Tasks 133–143

## What was tested

Everything implemented in the recent batch — the GR/PDE notebooks, the
bigger/clearer/zoomable plots, the scroll fixes, drag-to-rotate, the 3D graphics
upgrades and the contour shader — at two levels:

1. **Unit tests** — the headless harness
   [_test126.gd](app/scripts/_test126.gd), extended with 12 new assertions for
   tasks 136–143. Run with `Godot --headless --path app -- --test126`.
2. **Integration** — both demo notebooks re-run from clean through the REDUCE
   engine (`--demo-133`, `--demo-135`).

## Unit-test results — 40 / 40 PASS

The 28 task-126/127 tests still pass; the **12 new** ones all pass too:

| Area | Assertions | Result |
|---|---|---|
| **3D plot structure** | wrapper = VBox(controls + stack); stack = viewport + drag overlay; viewport is `SubViewportContainer` | 3/3 |
| **Task 137 scroll fix** | viewport `mouse_filter == IGNORE`; stack `IGNORE` (wheel passes to page) | 2/2 |
| **Task 142 drag-rotate** | drag overlay `mouse_filter == PASS` (rotates *and* passes the wheel) | 1/1 |
| **Task 143 contour shader** | surface mesh present; material is a `ShaderMaterial`; shader code contains the contour math (`fract(s)`) | 3/3 |
| **Task 136 2D zoom** | `zoom_in` raises, `zoom_out` lowers, `zoom_reset` → 1.0 | 3/3 |

(These verify the exact structure that makes tasks 137/138/142 work — e.g. the
IGNORE/PASS filters that keep page-scroll alive while enabling drag-rotate — so a
regression there would fail a test, not just look wrong.)

## Integration test — PASS

Cleared both notebooks' cached results and re-ran them through REDUCE
(no script / parse / **shader-compile** errors in either):

- **`curved_spacetime.md`** (task 133): all 4 REDUCE cells returned their raw
  results, and both `cas-plot3d` surfaces rendered (now with the task-143 contour
  shader, the task-140 dark background, and the task-136/139 PBR/SSAO/bloom).
- **`nonlinear_pde_curvature.md`** (task 135): the raw curvature
  `kappa := (2·abs(8·s³+3·s²))/(sqrt(16·s⁴+24·s³+9·s²+4)·abs(s)³·…)` came back,
  and both 2-D plots reported **"plotted 121 samples"** — confirming the task-136
  finer sampling is live.

## Coverage of the recent tasks

| Task | Verified by |
|---|---|
| 133 / 135 (notebooks) | integration: REDUCE results + plots render |
| 136 / 136.1 (bigger/clearer/zoom, all plots) | unit: 2D zoom; integration: 121 samples |
| 137 / 138 (scroll fix + spacer) | unit: IGNORE filters |
| 139 / 140 (3D graphics, dark bg) | integration: surfaces render, no errors |
| 141 → 142 (rotate → drag) | unit: PASS overlay |
| 143 (contour shader) | unit: ShaderMaterial + shader code; integration: no shader errors |

## Conclusion

All of tasks 133–143 pass: **40/40 unit assertions + a clean two-notebook engine
run** with no script, parse, or shader errors. Bugs would surface as failing
structural assertions, not just visual oddities.

## Files changed
- `app/scripts/_test126.gd` — 12 new assertions covering the task-136–143 work.
