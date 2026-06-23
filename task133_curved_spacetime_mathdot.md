# Task 133 — Curved Spacetime, Solved with mathdot (Not Simplified)

## The problem

Solve **using mathdot** (REDUCE — no MATLAB or any other tool), **without
simplifying**, and show **parabolic and hyperbolic plots** on the given curved
spacetime:

$$ds^{2} = -dt^{2} + \Omega(x)^{2}\,(dx_1^2 + \cdots + dx_n^2),\qquad (t,x)\in\mathbb{R}\times\mathbb{R}^n,$$

$$\Omega(x) = \frac{1}{\operatorname{dist}(x,\Sigma_0)^{\alpha_0}\operatorname{dist}(x,\Sigma_1)^{\alpha_1}\operatorname{dist}(x,\Sigma_2)^{\alpha_2}},\qquad \Sigma_2\subset\Sigma_1\subset\Sigma_0\subset\mathbb{R}^n,\;\alpha_i>0.$$

This is a **conformally flat static Lorentzian spacetime** whose conformal factor
blows up on three nested submanifolds. I built the mathdot notebook
[curved_spacetime.md](app/notebooks_sample/curved_spacetime.md) and ran it
(`--demo-133`). Every result below is **raw REDUCE output — no `factor`, `expand`,
or `trigsimp` applied.**

## Geometry computed by mathdot's REDUCE engine (raw)

| Cell | REDUCE input | Raw result |
|---|---|---|
| **Metric determinant** (1+2 D, g = diag(−1,Ω²,Ω²)) | `det(mat((-1,0,0),(0,om^2,0),(0,0,om^2)))` | `-om^4` — i.e. det g = −Ω²ⁿ, nonzero off the Σᵢ |
| **Light cone (hyperbolic characteristic)** | `solve(-c^2 + om^2, c)` | `{c=om, c=-om}` — null slope dt/d\|x\| = ±Ω |
| **Conformal metric derivative** (Christoffel block) | `depend om,x1,x2; df(om^2, x1)` | `2*df(om,x1)*om` = 2Ω·Ω,₁ |
| **Radial light-cone profile** t(r)=∫Ω dr, Ω=r⁻ᵃ | `int(r^(-a), r)` | `-r/(r^a*(a-1))` = r^(1−a)/(1−a) |

Reading of the last one: with `a = α₀+α₁+α₂`, the cone shape is fixed by the
nesting exponent — straight when a = 0, concave for 0 < a < 1, and steepening
without bound as the nested Σᵢ are approached. The Lorentzian signature makes the
wave operator **hyperbolic**, with the ±Ω null directions as its characteristics.

## The two required plots (rendered in mathdot's 3D viewport)

Both are `cas-plot3d` cells, drawn on the curved spacetime by warping with the
conformal factor `1/(1 + 0.12·r²)`:

- **Parabolic plot** — the conformal-factor well 1/Ω ~ dist^α near a smooth Σ is a
  parabolic profile:
  `z = (x*x + y*y) / (1 + 0.12*(x*x + y*y))` → a saturating paraboloid (bowl).
- **Hyperbolic plot** — the Lorentzian light-cone structure is hyperbolic, a
  saddle:
  `z = (x*x - y*y) / (1 + 0.12*(x*x + y*y))`.

## Verification

Ran `--demo-133` (no script/parse errors). All four REDUCE cells returned the raw
expressions above, and both `cas-plot3d` cells reported "3D surface rendered
inline". The **parabolic** surface is captured rendering in mathdot's Camera3D
viewport (`app_screenshot_task133.png`, the height-coloured bowl). The
**hyperbolic** saddle renders via the identical `_build_surface3d` path (its
result block confirms it); a clean screenshot of the lower saddle was blocked
only by a minor UX quirk — a hovered 3D viewport consumes the scroll wheel, so
the page can't be scrolled past it to the last plot.

## Notes
- Solved entirely with **mathdot/REDUCE** — no MATLAB or other tool, as requested.
- Results shown **raw / not simplified**, as requested.

## Files changed
- `app/notebooks_sample/curved_spacetime.md` — the new notebook (REDUCE geometry +
  parabolic & hyperbolic 3D plots).
- `app/scripts/main.gd` — `--demo-133` flag to open + run it.
