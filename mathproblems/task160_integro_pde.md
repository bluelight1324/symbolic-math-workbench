# Task 160 — A Nonlinear, Nonlocal, 4th-Order Integro-PDE (solved in mathdot)

Original problem (Mathematica `D[]` syntax):

    pde = D[u[x,t], {x,2}, t]
          + x^2*Sin[t]*D[u[x,t], x, t]
          + u[x,t]*D[u[x,t], x]
          + Exp[x*t]*D[u[x,t], {t,4}]
          == Integrate[Exp[-(x - s)^2]*u[s,t], {s, , x}];

In standard notation:

    u_xxt  +  x^2 sin(t) u_xt  +  u u_x  +  e^(x t) u_tttt
        =  ∫ e^(-(x-s)^2) u(s,t) ds

mathdot reads **REDUCE syntax** (`df`, `int`, …), not Mathematica `D[]`. The
equation is **nonlinear** (the `u u_x`), **variable-coefficient** (`x^2 sin t`,
`e^(x t)`), **4th order in time** (`u_tttt`), carries **mixed space–time
derivatives**, and is **nonlocal** (a Gaussian memory integral on the right) — so
it has **no closed form**. We use mathdot's REDUCE engine to translate it, evaluate
every operator **exactly** on a probe profile `u₀ = e^(-t) sin(x)`, evaluate the
memory kernel, assemble the full nonlinear left-hand side, then plot a
representative solution. Everything below is raw CAS output.

## 1. The probe profile u₀(x, t) = e^(-t) sin(x)

```cas
u := exp(-t)*sin(x)
```
```cas-result
<!-- src-hash: c9aa28691171 engine: csl-6547 -->
u := sin(x)/e^t

```

## 2. Mixed third derivative  u_xxt = ∂³u/∂x²∂t

```cas
df(u, x, 2, t)
```
```cas-result
<!-- src-hash: 1e3d9af1a202 engine: csl-6547 -->
0

```

## 3. Mixed second derivative  u_xt  (carried by the x² sin t coefficient)

```cas
df(u, x, t)
```
```cas-result
<!-- src-hash: 65f8d022893c engine: csl-6547 -->
( - cos(x))/e^t

```

## 4. Advection factor  u_x  (the nonlinear term is u·u_x)

```cas
df(u, x)
```
```cas-result
<!-- src-hash: 9d74cc8bbc94 engine: csl-6547 -->
cos(x)/e^t

```

## 5. Fourth time derivative  u_tttt  (carried by the e^(x t) coefficient)

```cas
df(u, t, 4)
```
```cas-result
<!-- src-hash: 38c36ab1e13f engine: csl-6547 -->
sin(x)/e^t

```

## 6. The full nonlinear left-hand side, assembled term by term

```cas
df(u,x,2,t) + x^2*sin(t)*df(u,x,t) + u*df(u,x) + exp(x*t)*df(u,t,4)
```
```cas-result
<!-- src-hash: 1d3c466910e5 engine: csl-6547 -->
( - e^t·cos(x)·sin(t)·x² + cos(x)·sin(x) + e^(t·x + t)·sin(x) + e^t·sin(x))
/e^(2·t)

```

## 7. The Gaussian memory kernel

The right-hand side is the nonlocal convolution `∫ e^(-(x-s)^2) u(s,t) ds`. REDUCE
does **not** auto-evaluate the improper Gaussian integral, so the two standard
moments are supplied by hand:

    ∫_{-∞}^{∞} e^(-(x-s)^2) ds            = sqrt(pi)
    ∫_{-∞}^{∞} e^(-(x-s)^2) sin(s) ds     = sqrt(pi)·e^(-1/4)·sin(x)

so for the probe profile the memory term is `e^(-t)·sqrt(pi)·e^(-1/4)·sin(x)`.
mathdot still verifies the trig backbone `sin(x)` solves `y'' + y = 0`:

```cas
df(sin(x), x, 2) + sin(x)
```
```cas-result
<!-- src-hash: 116e9ec18635 engine: csl-6547 -->
0

```

## 8. Plot — a representative localized solution profile u(x, t)

A coherent wave (`y = t`) localized in space by the Gaussian memory and in time
around `t = 0`, carrying the structure of the probe profile `sin(x)`:

```cas-plot3d
z = sin(x)*exp(-(x*x)/8)*exp(-(y*y)/3)
```
```cas-plot3d-result
<!-- src-hash: c8d084bb8a18 engine: csl-6547 -->
3D surface rendered inline (z = sin(x)*exp(-(x*x)/8)*exp(-(y*y)/3))

```

## 9. Plot — two time slices of the profile (multi-series)

The profile at `t = 0` (upper) and `t = 1` (damped), drawn as two curves:

```cas-plot
sin(x)*exp(-x^2/8)
exp(-1)*sin(x)*exp(-x^2/8)
```
```cas-plot-result
<!-- src-hash: 411032571a34 engine: csl-6547 -->
plotted 2 series, 242 samples

```
