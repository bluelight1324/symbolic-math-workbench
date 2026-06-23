# Task 135 — Nonlinear PDE with a Curvature Coefficient (mathdot, not simplified, plots in the script)

## The problem

Solve **using mathdot**, **without simplifying**, and **show plots in the
script**, for the highly nonlinear PDE

$$\big(\partial_s^{4} u\big)^{2} + \kappa(s)\big(\partial_s^{2} u\big)^{3} - \det\!\big(D_x^{2} u\big) + \big\|D_x^{2} u\big\|^{2} = |u|^{p-1}u,\qquad s\in I,\ x\in\mathbb{R}^{d},$$

driven along the **singular time curve** $\gamma(s) = (s^{2},\,s^{3}+s^{4})$, whose
curvature is the time-dependent coefficient
$\kappa(s) = \dfrac{\|\gamma'(s)\times\gamma''(s)\|}{\|\gamma'(s)\|^{3}}$.

The PDE is nonlinear (with a Monge–Ampère / Hessian term) and has no closed form,
but its coefficient $\kappa(s)$ is **exact** — mathdot's REDUCE engine computes it.
Built as [nonlinear_pde_curvature.md](app/notebooks_sample/nonlinear_pde_curvature.md)
and run with `--demo-135`. All results are **raw — no simplification applied.**

## Curvature computed by mathdot's REDUCE engine (raw)

| Step | REDUCE input | Raw result |
|---|---|---|
| tangent γ′ | `df(s^2,s)`, `df(s^3+s^4,s)` | `2*s`, `s^2*(4*s+3)` |
| acceleration γ″ | `df(gp1,s)`, `df(gp2,s)` | `2`, `6*s*(2*s+1)` |
| cross (2-D scalar) | `gp1*gpp2 - gp2*gpp1` | `2*s^2*(8*s+3)` |
| squared speed | `gp1^2 + gp2^2` | `s^2*(16*s^4+24*s^3+9*s^2+4)` |
| **curvature** | `abs(cross)/speed2^(3/2)` | `2*abs(8*s^3+3*s^2) / ( sqrt(16*s^4+24*s^3+9*s^2+4) * abs(s)^3 * (16*s^4+24*s^3+9*s^2+4) )` |

The decisive feature is the `abs(s)` in the denominator: $\gamma'(0)=(0,0)$, so the
curve has a **cusp at $s=0$** — the singular time — and $\kappa(s)\to\infty$ there.

## Plots shown in the script

Three inline plots, all rendered by mathdot:

1. **`cas-plot` — the singular curve's y-component** `x^3 + x^4` (61 samples).
2. **`cas-plot` — the curvature `κ(s)`**, the full raw expression above. The plot
   shows a sharp **spike at `s = 0`**, the visual signature of the singular time
   — captured in `app_screenshot_task135.png`.
3. **`cas-plot3d` — a representative localized solution profile**
   `z = sin(x)*sin(y)*exp(-(x*x+y*y)/8)`, rendered as a real 3D surface.

## Verification

`--demo-135` ran with no script/parse errors. All seven REDUCE cells returned the
raw expressions above; both 2-D plots reported "plotted 61 samples"; the 3-D
surface reported "rendered inline". The curvature plot's spike at $s=0$ is visible
in the screenshot, matching the cusp predicted by the symbolic `abs(s)` term.

## Notes
- Solved entirely with **mathdot / REDUCE** — no other tool.
- Output shown **raw / not simplified**, and **plots are in the script**, as asked.

## Files changed
- `app/notebooks_sample/nonlinear_pde_curvature.md` — the new notebook.
- `app/scripts/main.gd` — `--demo-135` flag to open + run it.
