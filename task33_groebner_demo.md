# Task 33 — Solving a Gröbner-Basis Problem in the App

A live demonstration: enable the `groebner` package via the tick-box
settings from [task 32](task32_package_dropdown.md), then use the
Calculator view to compute Gröbner bases for a couple of polynomial
systems through the persistent engine. The screenshot
([app_screenshot_groebner_small.png](app_screenshot_groebner_small.png))
shows three results in the history pane, including a cross-check via
`solve`.

---

## The math, briefly

A **Gröbner basis** for a polynomial ideal `I ⊂ k[x₁, …, xₙ]` is a
canonical generator set with the property that ideal membership and
elimination both become "look at the leading term." In practice the
useful consequence is that the Gröbner basis of a system of polynomial
equations is *triangular*: the last polynomial only mentions the last
variable, the second-to-last polynomial only mentions the last two
variables, and so on. You solve the whole system by **back substitution
from the bottom up**.

That's the trick the app demonstrates below.

## Example 1 — circle ∩ line `y = x`

System: `x² + y² − 1 = 0`, `x − y = 0`. Geometrically: where does the
unit circle hit the line `y = x`?

Command typed into the input field, with **Simplify** clicked:

```
groebner({x^2 + y^2 - 1, x - y}, {x, y})
```

Result rendered in the history:

```
{x - y,  2·y² - 1}
```

Read directly off the triangular form:
- The last polynomial `2y² − 1 = 0` ⇒ `y = ±1/√2`
- The first polynomial `x − y = 0` ⇒ `x = y`
- Combine ⇒ two intersection points: **`(1/√2, 1/√2)`** and
  **`(−1/√2, −1/√2)`**.

## Example 2 — circle ∩ hyperbola `x·y = 1`

System: `x² + y² − 1 = 0`, `x·y − 1 = 0`. Geometrically: where does
the unit circle hit the hyperbola `xy = 1`?

```
groebner({x^2 + y^2 - 1, x*y - 1}, {x, y})
```

Result:

```
{x + y³ - y,  y⁴ - y² + 1}
```

The univariate polynomial in y is `y⁴ − y² + 1`. Its discriminant as a
quadratic in `y²`:

```
Δ = 1 − 4 = −3   <   0
```

So `y² = (1 ± √(−3))/2` — complex. There are **no real solutions**, in
agreement with the obvious geometric fact that the unit circle and
`xy = 1` don't intersect in ℝ². The Gröbner basis exposed this by
producing a univariate polynomial in y whose real solutions we can
inspect at a glance.

## Example 3 — cross-check via `solve`

To confirm the back-substitution from Example 1, the same first system
was sent through REDUCE's `solve(...)`:

```
solve({x^2 + y^2 - 1, x - y}, {x, y})
```

Result, exactly as predicted:

```
{{x = 1/√2,   y = 1/√2},
 {x = -1/√2,  y = -1/√2}}
```

Both intersection points, identical to what the Gröbner basis told us
by inspection.

## How to reproduce in the app

1. Launch the app:
   ```powershell
   & 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' --path 'i:\readtgodot\app'
   ```
2. Press **F4** (or **View → Engine packages…**) to open the
   package-settings dialog from [task 32](task32_package_dropdown.md).
3. Tick the **`groebner`** checkbox under Tier 3.
4. Click **Apply (engine restart)**. The status bar reads
   `Restarting engine with new packages… → Engine restarted`.
5. In the input field type
   `groebner({x^2 + y^2 - 1, x - y}, {x, y})` and click **Simplify**.
   The history row shows `{x - y, 2·y² - 1}`.
6. Repeat with `groebner({x^2 + y^2 - 1, x*y - 1}, {x, y})` and any
   other ideal you like.

For an automated reproduction of the three results in the screenshot:

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --demo-groebner
```

`--demo-groebner` is a new startup flag in
[main.gd](app/scripts/main.gd) that:
1. Appends `groebner` to the persisted package selection so
   `MathEngine`'s next `_start()` loads it automatically.
2. Waits for `session_started`, then drives the three examples through
   the same `_do_op("simplify")` path the user's clicks would.

## What this demonstrates about the app

- **Optional packages really are runtime-toggleable** (task 32). Adding
  `groebner` to the tick-list takes effect via the engine restart and
  the new operator works in the calculator without any other change.
- **The persistent session keeps holding up under load** (task 6 + 24).
  A Gröbner-basis computation is one of the larger things REDUCE does;
  it returns within a second through the same sentinel-correlated
  pipeline that handles every other request.
- **The Unicode-display formatter** (task 19 / 23) renders `2·y² - 1`
  with proper superscripts and middle-dot multiplication, so the
  triangular form reads cleanly without LaTeX.
- **Cross-checking with `solve`** in the same session is one extra
  click, because the engine state is shared.

## Honest scope

- The `groebner` package is **off by default** per task 31's tier-3
  rationale (load time, surface area). Users wanting Gröbner bases on
  every launch tick it once and the saved `packages.cfg` keeps it
  enabled.
- These examples are 2-variable for visual clarity. The same operator
  handles arbitrarily many variables — task 30's
  [`workdoc/groebner/groebner.tst`](workdoc/groebner/groebner.tst)
  has dozens more worked examples up to 6 variables.
- No 3D rendering of the actual intersection curve / surface — that's
  the [task 17 §7](task17_even_further.md) follow-up, still queued.
