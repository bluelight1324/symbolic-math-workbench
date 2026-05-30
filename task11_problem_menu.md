# Task 11 — Menu Bar with a Large Library of Preset Problems

Added a menu bar at the top of the app with **72 preset problems** spanning
everything the engine can solve, organised into 9 categories. Picking a menu
item drops the problem into the input field and runs it through the same
async engine pipeline as the buttons. See
[app_screenshot_task11.png](app_screenshot_task11.png) for the running app.

---

## The catalogue ([app/scripts/problem_library.gd](app/scripts/problem_library.gd))

A single data file — `ProblemLibrary.ALL` — defines every menu item, so adding
problems is a one-line edit. Each entry has `label`, `input` (what shows in the
field as a record), `cmd` (the engine command), and an optional `kind:"plot"`
to route through the plot pipeline.

| Category | # items | Examples                                                 |
|----------|---------|----------------------------------------------------------|
| Algebra  | 12      | Expand `(1+x+x²)³`, Factor `x⁶−1`, GCD/LCM, partial fractions |
| Calculus | 13      | `d/dx xˣ`, `∫ 1/sqrt(1−x²)dx`, 3rd derivative, log integrals |
| Equations| 8       | Quadratics, cubics, quartics, quintics, 2×2 systems, trig roots |
| ODEs     | 8       | `y′=y`, separable, linear, SHM `y″+y=0`, forced oscillator |
| Matrices | 6       | Product, determinant, inverse 2×2 & 3×3, trace, M²       |
| Series   | 7       | Taylor `exp`/`sin`/`log`/geometric, classic limits        |
| Trig     | 5       | `trigsimp` (Pythagorean, expand, combine), `d/dx tan`     |
| Numbers  | 6       | gcd, integer factorisation, `binomial`, `100!`           |
| Plots    | 7       | `sin x`, `x²`, `1/(x²+1)`, `e^(−x²)`, `sin x + a·cos x`   |
| **Total**| **72**  |                                                          |

(Categories live as separate dropdowns in the menu bar; their short names —
ODEs, Matrices, Series, Trig, Numbers — were chosen so all 9 fit in the bar
at the default window width.)

## Wiring it up ([main.gd](app/scripts/main.gd))

```gdscript
func _build_menubar(parent: Control) -> void:
    var bar := MenuBar.new()
    for cat_idx in range(ProblemLibrary.ALL.size()):
        var cat: Dictionary = ProblemLibrary.ALL[cat_idx]
        var menu := PopupMenu.new()
        menu.name = cat["name"]
        for it_idx in range(cat["items"].size()):
            menu.add_item(cat["items"][it_idx]["label"], it_idx)
        var ci := cat_idx
        menu.id_pressed.connect(func(id): _on_problem_selected(ci, id))
        bar.add_child(menu)
    parent.add_child(bar)
```

`_on_problem_selected()` drops the item's `input` into the field, appends a
history row, and either evaluates the raw engine command (default) or routes
into the plot pipeline (`kind: "plot"`). The async result lands in the right
history row exactly like a button click — no extra plumbing.

## Engine-side preparation

To make the catalogue actually solvable, [math_engine.gd](app/autoload/math_engine.gd)
now loads the relevant packages once at session start, alongside the existing
ODE package:

```
off nat; off echo; load_package odesolve; load_package taylor; load_package limits;
```

`pf`, `trigsimp`, `factorize`, `gcd`, `binomial`, `factorial`, and matrix
operations are built-in and need no loading.

## What I verified before shipping each menu item

Ran every "non-trivial" cmd directly against the bundled engine and confirmed:

| Sample item               | cmd                                        | Engine reply                                           |
|---------------------------|--------------------------------------------|--------------------------------------------------------|
| trig expand               | `trigsimp(sin(x+y), expand)`               | `cos(x)·sin(y) + cos(y)·sin(x)`                        |
| trig double-angle         | `trigsimp(cos(2x), expand)`                | `−2·sin(x)² + 1`                                       |
| product-to-sum            | `trigsimp(sin(x)·cos(y), combine)`         | `(sin(x−y) + sin(x+y))/2`                              |
| 2×2 system                | `solve({x+y=3, x−y=1}, {x,y})`             | `{{x=2, y=1}}`                                         |
| trig solve                | `solve(sin(x) − 1/2, x)`                   | `{x = π(12·arbint(1)+5)/6, x = π(12·arbint(1)+1)/6}`   |
| matrix trace              | `trace mat((1,2,3),(4,5,6),(7,8,9))`       | `15`                                                   |
| limit at infinity         | `limit((1+1/n)^n, n, infinity)`            | `e`                                                    |
| limit at 0                | `limit((1−cos x)/x², x, 0)`                | `1/2`                                                  |
| 100!                      | `factorial(100)`                           | `93326215443944152681699238856266700490715968264…00`   |
| non-solvable quintic      | `solve(x⁵ − x − 1, x)`                     | `{x = root_of(x_⁵ − x_ − 1, x_, tag_1)}` (RootOf form) |

Also tested the simpler integer cases (`factorize 360 → {{2,3},{3,2},{5,1}}`,
`gcd(60,84) → 12`, `binomial(10,3) → 120`) and the existing ODE/df/int items
from earlier tasks.

The `partial` package isn't bundled in this build (load fails) — but `pf` is
built-in, so the partial-fraction menu items use `pf(...)` directly and work.

## Running the demo

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --demo-menu
```

The flag triggers `_run_menu_demo()`, which programmatically picks one item
from six different categories so a single headed launch exercises the catalogue
end-to-end. After 3 s the app also saves the viewport to
`app_screenshot_task11.png` (Godot does its own screenshot via
`get_viewport().get_texture().get_image().save_png()` — useful when external
screenshot tools can't run, which actually happened during this task; see the
honest note below).

## Verification

The screenshot shows:
- All 9 categories visible in the menu bar at the top.
- 6 menu-driven results in the history with correct answers — including
  `int(1/(x²+1), x) = atan(x)`, the 2×2 system → `{{x=2, y=1}}`,
  `limit sin(x)/x = 1`, and `binomial(10,3) = 120`.
- The input field reflecting the last-picked item (`det mat(...)`).

The project also imports headless with **exit 0, no script errors** after the
edits.

## Honest notes from doing this task

- The bundled REDUCE briefly stopped booting (`pages_count <= 0 / insufficient
  freestore`) — root cause was 13 orphaned MCP-server processes piling up in
  the background and starving the system. Killing them fixed it. Documented
  here because it's the kind of issue users could hit on their own machines.
- PowerShell's `Add-Type` then started failing with "Insufficient memory" even
  with 2 GB free — likely fragmentation under that same pressure. Worked around
  it by having **Godot itself** save the screenshot from inside the app, which
  is also more reliable for repeat runs and worth keeping (see
  `_save_screenshot_after()` in [main.gd](app/scripts/main.gd)).
- Originally named the categories "Differential Equations", "Linear Algebra",
  etc. — but all 9 didn't fit in the menu bar at default width. Shortened to
  "ODEs", "Matrices", "Series", "Trig", "Numbers" and bumped the default
  window from 1100×680 to 1300×720 so the whole bar is visible.
