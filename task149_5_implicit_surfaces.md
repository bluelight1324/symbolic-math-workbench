# Task 149.5 — Improve the Plots: Implicit Surfaces + a Power-Parser Fix

## Request

> "Do everything which will improve the plots."

Working the highest-value remaining items from the [149.4 benefit catalogue](task149_4_remaining_benefits.md).
This session delivers the **biggest single capability gap** — implicit surfaces —
and a **cross-cutting parser fix** that improves *every* 3-D plot kind. Both pure
Godot, both verified.

## 1. `cas-implicit` — surfaces that aren't graphs (the headline)

Until now every 3-D surface was a *graph* — `z = f(x,y)` or a parametric `(u,v)`
patch. **Implicit surfaces** `f(x, y, z) = 0` (spheres, tori, level sets, blobs)
were the one common surface type still missing.

- **Syntax:** a `cas-implicit` block with `f(x,y,z)` — written as `expr` (meaning
  `expr = 0`), `expr = 0`, `f = expr`, or `lhs = rhs` (auto-differenced).
- **Meshing — Surface Nets (pure Godot):** sample `f` on a grid; for every cube
  that straddles the surface emit **one vertex** at the averaged edge-crossings;
  stitch a **quad across each sign-changing grid edge**. No 256-entry marching-cubes
  tables — compact and table-free. Rendered through the same lit/contoured
  viewport, Viridis colormap, bounding box, colour-bar and drag-rotate as every
  other 3-D plot.
- **Performance:** the mesher uses flat `PackedFloat32Array` / `PackedInt32Array`
  buffers and integer cube keys (no per-crossing lambdas or string-keyed dicts),
  so the grid builds without freezing the UI.
- **Graceful fallbacks:** a function with **no zero-crossing** in the box
  (e.g. `x²+y²+z²+9`) shows a clear message instead of an empty scene; an
  unparseable expression shows the usage hint.

**Verified:** the sphere `x²+y²+z²=4` renders as a clean round ball with Viridis +
contour bands + box + colour-bar (`app_screenshot_task1495.png`); the torus renders
too (below).

## 2. `_pow_to_func` now handles **nested** parentheses (improves all 3-D kinds)

Godot's `Expression` has no `^` power operator, so the 3-D evaluators rewrite
`a^b` → `pow(a,b)`. The old regex only matched **one** level of parentheses, so a
base like `(sqrt(x*x+y*y) - 1.6)^2` (the torus) was left with a literal `^` and
evaluated to garbage — **no surface**.

Replaced the regex with a **balanced-parenthesis scan** that grabs the full operand
on each side of `^` (number, identifier, function call, or nested group). Now
`(sqrt(x*x+y*y)-1.6)^2` → `pow((sqrt(x*x+y*y)-1.6),2)` correctly. This is shared by
**`cas-plot3d`, `cas-surface`, `cas-anim`, `cas-field` and `cas-implicit`** — every
3-D kind that accepts `^` benefits, not just implicit surfaces.

## Verification

- **Unit tests** (`--test126`): **68 / 68 pass** — 7 new for this task:
  - `_pow_to_func("(sqrt(x*x+y*y)-1.6)^2")` → `pow((sqrt(x*x+y*y)-1.6),2)`
    (plus the three existing power cases still pass — no regression).
  - implicit **sphere** and **nested-`^` torus** → a real plot wrapper (mesh built);
    **no-crossing** and **bad input** → a `Label` (graceful).
  - `cas-implicit` is parsed and made runnable by `pair_blocks`.
- **Integration** (`--demo-impl`): `implicit_surfaces.md` runs with no
  script/parse/shader errors and writes 2 `cas-implicit-result` blocks; the sphere
  renders in-app.

## Still remaining

The plotting now covers **2-D curves, 3-D height fields, parametric surfaces,
animated surfaces, vector fields, and implicit surfaces**. The remaining backlog
and the benefit of each item are catalogued in
[task 149.4](task149_4_remaining_benefits.md) — the next best value-per-effort
picks are **2-D multi-series + legend**, **PNG/MP4 export**, and **analytic
normals**; the long arc (R3 CAS-fusion, R4 output, R5 frontier) is unchanged.

## Files changed
- `app/scripts/notebook_view.gd` — `_build_implicit3d` (Surface Nets) +
  `_emit_sn_quad`; `_pow_to_func` rewritten as a balanced-paren scan + `_is_ident_char`.
- `app/scripts/notebook_runner.gd` — `cas-implicit` / `cas-implicit-result` kind,
  fence recognition, `SRC_TO_RESULT` pairing.
- `app/scripts/main.gd` — `--demo-impl` flag.
- `app/scripts/_test126.gd` — 7 new assertions (now 68/68).
- `app/notebooks_sample/implicit_surfaces.md` — demo notebook (sphere + torus).
