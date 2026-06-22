# Task 120 — Solving a MathJax Problem in mathdot

## The question

> "How will it satisfy if the problem is in MathJax like this? Solve using
> mathdot:"
>
> ```latex
> f(x)=\lambda\int_{-\infty}^{\infty}e^{-(x-t)^2}f(t)\,dt
>      +\int_{0}^{x}(x-t)f(t)^3\,dt+\sin x
> ```

Two parts: **how** mathdot handles a problem written in MathJax/LaTeX, and
whether mathdot can **solve** this particular equation.

## Part 1 — how mathdot "satisfies" a MathJax problem

mathdot notebooks evaluate **REDUCE syntax**, not LaTeX. So a MathJax problem is
first **translated** term-by-term:

| MathJax | mathdot / REDUCE |
|---|---|
| `\int_{-\infty}^{\infty} e^{-(x-t)^2} f(t)\,dt` | `int(e^(-(x-t)^2)*f(t), t, -infinity, infinity)` |
| `\int_{0}^{x}(x-t) f(t)^3\,dt` | `int((x-t)*f(t)^3, t, 0, x)` |
| `\sin x`, `\lambda` | `sin(x)`, `lambda` |

mathdot reads `int(...)`, `df(...)`, `sin(x)` — it does **not** parse `\int`,
`\sin`, `\lambda`. (Rendered *output* uses pretty math — superscripts, `·`, `π` —
but *input* is REDUCE.)

## Part 2 — can mathdot solve it? What kind of equation is this?

This is a **nonlinear integral equation**:

- the `f(t)³` term makes it **nonlinear** (so superposition / resolvent-kernel
  methods don't apply);
- it mixes a **Fredholm** term (infinite limits, Gaussian kernel, linear in f)
  with a **Volterra** term (limit `x`, cubic in f).

Such an equation has **no closed-form solution**. The realistic method —
the one mathdot supports well — is **Picard iteration**: start from the forcing
term `f₀(x) = sin(x)` and substitute it back through the integrals to get f₁,
f₂, … converging (for small λ) to the solution.

## What mathdot actually computed

I built the notebook
[nonlinear_integral_eq.md](app/notebooks_sample/nonlinear_integral_eq.md) and ran
it in the app (REDUCE with the task-114 heap fix). Real engine output:

- **Volterra cubic term** for f₀ = sin(x) — mathdot evaluates it directly:

  ```
  int((x-t)*sin(t)^3, t, 0, x)   →   ( - sin(x)³ - 6·sin(x) + 6·x)/9
  ```

- **Trig backbone check** — confirms sin(x) solves y″ + y = 0:

  ```
  df(sin(x), x, 2) + sin(x)   →   0
  ```

- **Fredholm (Gaussian) term** — `∫_{-∞}^{∞} e^(-(x-t)^2) sin(t) dt`. Here mathdot
  hits a **genuine limit**: REDUCE's `defint` does **not** evaluate this
  infinite-limit Gaussian integral (it returns it unchanged, and forcing it makes
  the run hang). The value is the standard result, supplied by hand:

  ```
  ∫_{-∞}^{∞} e^(-(x-t)^2) sin(t) dt = sqrt(pi)·e^(-1/4)·sin(x)
  ```

  (substitute u = t−x; the odd part vanishes, leaving `√π·e^(-1/4)` times sin(x)).

### First Picard iterate (the answer mathdot builds)

    f₁(x) = sin(x)
            + λ·√π·e^(-1/4)·sin(x)                 (Fredholm, linear in λ)
            + (-sin(x)³ - 6·sin(x) + 6·x)/9         (Volterra cubic, computed by mathdot)

Verified rendered in the app — `app_screenshot_task120.png` shows Step 1's result
`( - sin(x)³ - 6·sin(x) + 6·x)/9` under the cell.

## Honest summary

- **Yes** for the tractable, dominant work: mathdot evaluates the Volterra cubic
  integral and drives the Picard iteration symbolically.
- **No, not fully automatic**: the improper Gaussian Fredholm integral is beyond
  REDUCE's `defint`, and the equation is nonlinear so there is no closed form —
  mathdot gives the perturbation/iteration solution, not a single tidy `f(x) =`.

This is the realistic answer for a MathJax problem of this difficulty: translate
to REDUCE syntax, recognise the structure (nonlinear + Fredholm + Volterra ⇒
iterate), let the CAS do the heavy tractable integrals, and supply the one
improper integral it can't.

## Files changed
- `app/notebooks_sample/nonlinear_integral_eq.md` — new demonstration notebook.
- `app/scripts/main.gd` — added the `--demo-nlie` flag (opens + runs that
  notebook, matching the existing `--demo-inteq` / `--demo-diffint` demos).
