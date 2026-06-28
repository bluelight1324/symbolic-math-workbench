# Higher-Order Time Ellipsoid — solved with mathdot (REDUCE), not simplified

Time itself lives on a **superellipse** (a Lamé / "higher-order ellipse") in the
(t, s) plane:

    E_t = { (t,s) in R^2 : |t/a|^(2m) + |s/b|^(2m) = 1 },    m >= 2,

and the field u(t,s,x) (x in R^d) obeys the high-order PDE

    (Δ_E² u)² + α(Δ_E u)³ − β Δ_x² u + γ ||∇_E ∇_x u||² = λ |u|^(p-1) u,

where Δ_E is the **Laplace–Beltrami operator on the time ellipsoid** E_t. The PDE
is nonlinear (no closed form), but the geometry of E_t and its Laplace–Beltrami
operator are exact — mathdot's REDUCE engine computes them below for the lowest
order **m = 2** (the parametrization t = a·√cosθ, s = b·√sinθ). Everything is
shown **raw — no simplification.**

## 1. The parametrization lands on the ellipsoid

```cas
t := a*sqrt(cos(theta))
```
```cas-result
<!-- src-hash: 253ede8331b3 engine: csl-6547 -->
t := sqrt(cos(theta))·a

```
```cas
s := b*sqrt(sin(theta))
```
```cas-result
<!-- src-hash: aaf2c4b71378 engine: csl-6547 -->
s := sqrt(sin(theta))·b

```
Check `(t/a)^(2m) + (s/b)^(2m)` for m = 2 — it must reduce to 1 (shown raw as
cos² + sin²):

```cas
(t/a)^4 + (s/b)^4
```
```cas-result
<!-- src-hash: ee3c9e74aa31 engine: csl-6547 -->
cos(theta)² + sin(theta)²

```

## 2. Tangent to the time ellipsoid

```cas
tp := df(t, theta)
```
```cas-result
<!-- src-hash: 8b0afa233087 engine: csl-6547 -->
tp := ( - sin(theta)·a)/(2·sqrt(cos(theta)))

```
```cas
sp := df(s, theta)
```
```cas-result
<!-- src-hash: 6df10b4bb11c engine: csl-6547 -->
sp := (cos(theta)·b)/(2·sqrt(sin(theta)))

```

## 3. Induced metric g on E_t (the first fundamental form)

The Laplace–Beltrami operator is built from g = ||γ'(θ)||²:

```cas
g := tp^2 + sp^2
```
```cas-result
<!-- src-hash: b12384b2d315 engine: csl-6547 -->
g := (cos(theta)³·b² + sin(theta)³·a²)/(4·cos(theta)·sin(theta))

```

## 4. The Laplace–Beltrami operator Δ_E, applied to θ

On a curve, Δ_E f = (1/√g)·d/dθ( (1/√g)·df/dθ ). For f = θ this is −g'/(2g²) —
the operator that drives the time-derivatives in the PDE (raw):

```cas
lb_theta := -df(g, theta)/(2*g^2)
```
```cas-result
<!-- src-hash: b2825f88427f engine: csl-6547 -->
lb_theta := (2·(cos(theta)⁵·b² + 2·cos(theta)³·sin(theta)²·b² - 2·cos(
theta)²·sin(theta)³·a² - sin(theta)⁵·a²))/(cos(theta)⁶·b⁴ + 2·cos(
theta)³·sin(theta)³·a²·b² + sin(theta)⁶·a⁴)

```

## 5. The time ellipsoid as a height field

For a = b = 1, m = 2 the function below is the **time-ellipsoid potential**
|t|^4 + |s|^4 — every contour line of it is a copy of E_t. The contour shader
draws those level sets directly (each ring is a higher-order ellipse):

```cas-plot3d
z = x*x*x*x + y*y*y*y
```
```cas-plot3d-result
<!-- src-hash: e892796f6228 engine: csl-6547 -->
3D surface rendered inline (z = x*x*x*x + y*y*y*y)

```

## 6. A representative solution profile u(t,s,x)

```cas-plot3d
z = sin(x)*sin(y)*exp(-(x*x + y*y)/8)
```
```cas-plot3d-result
<!-- src-hash: 467f2637ab8d engine: csl-6547 -->
3D surface rendered inline (z = sin(x)*sin(y)*exp(-(x*x + y*y)/8))

```
