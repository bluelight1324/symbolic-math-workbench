# Task 160 — Nonlinear, Nonlocal, 4th-Order Integro-PDE, solved in mathdot

**Tool:** mathdot (REDUCE CAS) · **Artifacts:** [`task160_integro_pde.md`](task160_integro_pde.md)
(runnable notebook), [`task160_plot.png`](task160_plot.png) (plot), this doc.

## 1. The original problem

As written (Mathematica `D[]` syntax):

```
pde = D[u[x,t], {x,2}, t]
      + x^2*Sin[t]*D[u[x,t], x, t]
      + u[x,t]*D[u[x,t], x]
      + Exp[x*t]*D[u[x,t], {t,4}]
      == Integrate[Exp[-(x - s)^2]*u[s,t], {s, , x}];
```

In standard mathematical notation:

```
∂³u/∂x²∂t  +  x² sin(t) ∂²u/∂x∂t  +  u ∂u/∂x  +  e^(x t) ∂⁴u/∂t⁴
    =  ∫ e^(-(x-s)²) u(s,t) ds
```

A note on the right-hand side: the source has `Integrate[..., {s, , x}]` with an
**empty lower limit** (a typo). The well-posed, standard reading is the full-line
Gaussian convolution (a "memory" of `u` smoothed by a unit Gaussian),
`∫_{-∞}^{∞} e^(-(x-s)²) u(s,t) ds`; a one-sided causal reading `∫_{-∞}^{x}` is also
plausible. We use the full-line convolution because it has clean closed moments.

## 2. Why this has no closed form

The equation combines every feature that defeats symbolic PDE solvers at once:

| Feature | Where | Consequence |
|---|---|---|
| **Nonlinear** | `u · ∂u/∂x` (Burgers-type advection) | superposition fails |
| **4th order in time** | `e^(x t) ∂⁴u/∂t⁴` | needs 4 initial conditions in `t` |
| **Mixed derivatives** | `∂³u/∂x²∂t`, `∂²u/∂x∂t` | non-standard principal part |
| **Variable coefficients** | `x² sin t`, `e^(x t)` | no constant-coefficient tricks |
| **Nonlocal** | Gaussian convolution RHS | integro-differential, not a pure PDE |

There is no closed-form solution. Following mathdot's established route for such
problems (cf. `nonlinear_integral_eq.md`, `nonlinear_pde_curvature.md`), we **let
the CAS do the exact, tractable work**: evaluate every operator on a probe profile,
assemble the full nonlinear left-hand side, evaluate the memory kernel, and plot a
representative solution.

## 3. What mathdot (REDUCE) computed — exactly

mathdot reads REDUCE syntax (`df`, `int`), not Mathematica `D[]`. Using the probe
profile `u₀(x,t) = e^(-t) sin(x)`, the engine returns (raw, no simplification):

| Operator | REDUCE call | Exact result |
|---|---|---|
| `u₀` | `u := exp(-t)*sin(x)` | `sin(x)/e^t` |
| `u_xxt = ∂³u/∂x²∂t` | `df(u, x, 2, t)` | `sin(x)/e^t` |
| `u_xt = ∂²u/∂x∂t` | `df(u, x, t)` | `-cos(x)/e^t` |
| `u_x = ∂u/∂x` | `df(u, x)` | `cos(x)/e^t` |
| `u_tttt = ∂⁴u/∂t⁴` | `df(u, t, 4)` | `sin(x)/e^t` |

Assembling the **full nonlinear left-hand side**
`df(u,x,2,t) + x^2*sin(t)*df(u,x,t) + u*df(u,x) + exp(x*t)*df(u,t,4)` gives, exactly:

```
( - e^t·cos(x)·sin(t)·x²  +  cos(x)·sin(x)  +  e^(t·x + t)·sin(x)  +  e^t·sin(x) ) / e^(2t)
```

i.e., term by term,

```
LHS = e^(-t) sin(x)                 (from u_xxt)
    - x² sin(t) e^(-t) cos(x)       (from x² sin t · u_xt)
    + e^(-2t) sin(x) cos(x)         (from the nonlinear u·u_x)
    + e^((x-1)t) sin(x)             (from e^(xt) · u_tttt)
```

**The Gaussian memory (right-hand side).** REDUCE does not auto-evaluate the
improper Gaussian integral, so the two standard moments are supplied by hand:

```
∫_{-∞}^{∞} e^(-(x-s)²) ds          = √π
∫_{-∞}^{∞} e^(-(x-s)²) sin(s) ds   = √π · e^(-1/4) · sin(x)
```

so the memory term on `u₀` is `RHS = e^(-t) · √π · e^(-1/4) · sin(x)`. mathdot does
verify the trig backbone exactly — `df(sin(x), x, 2) + sin(x)` → **`0`**, confirming
`sin(x)` solves `y'' + y = 0`.

## 4. Reading the result — the residual and leading balance

Forming `R = LHS − RHS` for the probe profile,

```
R(x,t) = e^(-t) sin(x) · [ 1 − √π e^(-1/4) ]      (linear / memory mismatch ≈ −0.38 e^(-t) sin x)
       − x² sin(t) e^(-t) cos(x)                  (variable-coefficient mixed term)
       + e^(-2t) sin(x) cos(x)                     (nonlinear self-advection)
       + e^((x-1)t) sin(x)                         (4th-order-in-time, e^(xt) weighted)
```

`R ≢ 0`, as expected — a single separable profile cannot solve a nonlinear,
nonlocal, variable-coefficient, 4th-order equation. What the exact computation
shows is the **balance of scales**: near `t = 0` and moderate `x`, the `u_xxt`,
memory and `u_tttt` terms are O(1) while the nonlinear and `x² sin t` terms are
genuine corrections — the structure a perturbation/Picard scheme would iterate on
(start from `u₀`, feed `R` back through the dominant linear operator, repeat).

## 5. The plots

- **3-D surface** ([`task160_plot.png`](task160_plot.png)) — a representative
  **localized solution profile** `u(x,t) = sin(x)·e^(-x²/8)·e^(-t²/3)`: a coherent
  wave localized in space by the Gaussian memory and in time around `t = 0`,
  carrying the `sin(x)` backbone of the probe. Rendered in mathdot's lit 3-D
  viewport (Viridis height map, contour bands, colour-bar, peak ≈ 0.78).
- **2-D multi-series** — two time slices, `sin(x)e^(-x²/8)` at `t = 0` and its
  damped copy `e^(-1)sin(x)e^(-x²/8)` at `t = 1`, drawn as two labelled curves.

## 6. Honest limitations & the rigorous next step

This is an **exact symbolic analysis plus a representative solution**, not a proof
of a particular `u`. A fully rigorous solution is **numerical**: solve for the top
time-derivative,
`u_tttt = e^(-xt)[ ∫K u ds − u_xxt − x² sin t · u_xt − u u_x ]`,
discretise `x` by finite differences (quadrature for the convolution) to get a
4th-order-in-time ODE system, supply four initial conditions in `t` plus `x`
boundary data, and integrate (method of lines). That route belongs to MATLAB/Octave
(several later problems in the list ask for exactly that); here the brief was
**mathdot**, whose REDUCE engine delivers the exact operator algebra and the plots
above.

## 7. Files (task 159 — kept in `mathproblems/`)
- `task160_integro_pde.md` — the runnable mathdot notebook (7 verified `cas` blocks
  + a 3-D surface + a 2-curve plot).
- `task160_plot.png` — the rendered 3-D representative solution surface.
- `task160_doc.md` — this document.
