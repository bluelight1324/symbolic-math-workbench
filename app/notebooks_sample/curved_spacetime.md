# Curved Spacetime — solved with mathdot (REDUCE), not simplified

A conformally flat **static Lorentzian spacetime**:

    ds^2 = -dt^2 + Omega(x)^2 (dx_1^2 + ... + dx_n^2),    (t, x) in R x R^n

whose conformal factor blows up on three **nested** submanifolds
Sigma_2 ⊂ Sigma_1 ⊂ Sigma_0 ⊂ R^n  (with alpha_0, alpha_1, alpha_2 > 0):

    Omega(x) = 1 / ( dist(x, Sigma_0)^a0 · dist(x, Sigma_1)^a1 · dist(x, Sigma_2)^a2 )

Every cell below is evaluated by mathdot's REDUCE engine and shown **raw — no
simplification (no factor / expand / trigsimp) is applied.**

## 1. Metric determinant (shown for 1+2 dimensions)

The metric is g = diag(-1, Omega^2, Omega^2). Its determinant:

```cas
det(mat((-1,0,0),(0,om^2,0),(0,0,om^2)))
```
```cas-result
<!-- src-hash: 2b3361b1eeb0 engine: csl-6547 -->
- om⁴

```

So det g = -Omega^(2n) (here -Omega^4), which never vanishes away from the
Sigma_i — the spacetime is regular off the nested singular set.

## 2. The light cone — the HYPERBOLIC characteristic

The metric is Lorentzian, so the wave operator is hyperbolic. The null condition
-dt^2 + Omega^2 d|x|^2 = 0 gives the cone slope c = dt/d|x|:

```cas
solve(-c^2 + om^2, c)
```
```cas-result
<!-- src-hash: 61e859555197 engine: csl-6547 -->
{c=om,c= - om}

```

c = +/- Omega: the two null directions. These are the **hyperbolic
characteristics** that propagate signals on the curved spacetime.

## 3. Conformal metric derivative (a Christoffel building block)

With Omega depending on the spatial coordinates, the metric's derivative (raw):

```cas
depend om, x1, x2; df(om^2, x1)
```
```cas-result
<!-- src-hash: 88f939071b8a engine: csl-6547 -->
2·df(om,x1)·om

```

(= 2*Omega*Omega_,1 — the quantity every conformal Christoffel symbol is built
from.)

## 4. Radial light-cone profile

Near a single nested Sigma the factor behaves like Omega = r^(-a) with
a = a0 + a1 + a2. The light cone reaches t(r) = integral of Omega dr:

```cas
int(r^(-a), r)
```
```cas-result
<!-- src-hash: 7613908b57bf engine: csl-6547 -->
( - r)/(r^a·(a - 1))

```

t(r) = r^(1-a)/(1-a): the nesting exponent a sets the cone's shape — straight
(a = 0), concave, or steepening without bound as the nested Sigma are
approached.

## 5. PARABOLIC plot on the curved spacetime

Near a *smooth* Sigma the conformal-factor well 1/Omega ~ dist^a is a **parabolic**
profile. Drawn here as a paraboloid warped (saturated) by the curved-spacetime
conformal factor:

```cas-plot3d
z = (x*x + y*y) / (1 + 0.12*(x*x + y*y))
```
```cas-plot3d-result
<!-- src-hash: c236f87c87b6 engine: csl-6547 -->
3D surface rendered inline (z = (x*x + y*y) / (1 + 0.12*(x*x + y*y)))

```

## 6. HYPERBOLIC plot on the curved spacetime

The Lorentzian light-cone structure is **hyperbolic** — a saddle z = x^2 - y^2 —
warped by the same conformal factor of the curved spacetime:

```cas-plot3d
z = (x*x - y*y) / (1 + 0.12*(x*x + y*y))
```
```cas-plot3d-result
<!-- src-hash: 6a5db30397a6 engine: csl-6547 -->
3D surface rendered inline (z = (x*x - y*y) / (1 + 0.12*(x*x + y*y)))

```
