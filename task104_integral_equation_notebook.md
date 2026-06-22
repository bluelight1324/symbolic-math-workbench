# Task 104 — A "Difficult Integral Equation" Notebook

## Goal

> "Create a notebook file to solve a difficult integral equation, and load it in
> the app."

## The problem

A genuine **integral equation** (the unknown function appears *under* an
integral sign) — a Volterra equation of the second kind:

    y(x) = sin(x) + ∫₀ˣ (x − t) · y(t) dt

This can't be integrated directly because `y` is unknown inside the integral.

## Method (what the notebook does)

The standard technique: **differentiate twice (Leibniz' rule)** to convert the
integral equation into an ODE, which the CAS can solve and the result can be
verified.

1. Differentiate → `y'' − y = −sin(x)`, with `y(0)=0`, `y'(0)=1`.
2. **Solve the ODE** in a `cas` block: `odesolve(df(y,x,2) - y = -sin(x), y, x)`.
3. Apply the initial conditions → closed form **`y(x) = (sinh(x) + sin(x)) / 2`**.
4. **Verify** with three `cas` blocks (`df`, `sub`) that the closed form
   satisfies the ODE and both initial conditions.

### Why this method and not Laplace / definite integrals

The cleaner textbook route is the Laplace transform, and the direct check would
use a definite integral `∫₀ˣ …`. Both `laplace` and definite integration pull in
REDUCE packages that hit an `insufficient freestore` limit in this REDUCE build,
so the notebook deliberately uses only operations the app's engine handles
reliably — `odesolve`, `df`, `sub` (all proven in the task-95 math test). The
differentiate-to-ODE method is mathematically rigorous and fully verified.

## The notebook — `app/notebooks_sample/integral_equation.md`

Markdown prose explaining each step, with four `cas` blocks:

| Cell | Command | Result (computed by the app) |
|---|---|---|
| Solve | `odesolve(df(y,x,2) - y = -sin(x), y, x)` | `{y = e^x·C₂ + e^(−x)·C₁ + sin(x)/2}` |
| Verify ODE | `df((sinh(x)+sin(x))/2, x, 2) - (sinh(x)+sin(x))/2 + sin(x)` | **`0`** |
| Verify y(0)=0 | `sub(x=0, (sinh(x)+sin(x))/2)` | **`0`** |
| Verify y'(0)=1 | `sub(x=0, df((sinh(x)+sin(x))/2, x))` | **`1`** |

The `odesolve` output is the general solution (two `arbconst`s + the `sin(x)/2`
particular part); the three verification cells (`0`, `0`, `1`) confirm the
closed form `y(x) = (sinh(x) + sin(x)) / 2` is the solution.

## Loaded and run in the app

Added a `--demo-inteq` launch flag ([main.gd](app/scripts/main.gd)) — mirroring
the existing `--demo-plotnb` / `--demo-task37` demo flags — that opens
`integral_equation.md` and runs every cell. Launched the app with it:

- The file appears in the **Current Folder** tree and opens as
  **"Editor – integral_equation.md"**.
- Running the notebook produced the results above; the rendered notebook shows
  each `cas` cell followed by its `= result` cell inline (MATLAB theme), e.g. the
  verification cells visibly return **`0`**, **`0`**, **`1`**
  (`app_screenshot_task104.png`).

No script errors. The solved results are saved into the notebook file.

## Files
- `app/notebooks_sample/integral_equation.md` — the new notebook (added, ships
  with its solved results like the other sample notebooks).
- `app/scripts/main.gd` — `--demo-inteq` flag + `_open_inteq_and_run()`.
