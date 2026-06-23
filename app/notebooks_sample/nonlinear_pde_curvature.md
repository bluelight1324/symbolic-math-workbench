# Nonlinear PDE with a Curvature Coefficient — mathdot (REDUCE), not simplified

A highly nonlinear evolution PDE (note the Monge–Ampère / Hessian terms):

    (d_s^4 u)^2 + kappa(s)*(d_s^2 u)^3 - det(D_x^2 u) + ||D_x^2 u||^2 = |u|^(p-1) u,
        s in I,  x in R^d,

driven along the **singular time curve**  gamma(s) = (s^2, s^3 + s^4),  whose
curvature supplies the time-dependent coefficient

    kappa(s) = || gamma'(s) x gamma''(s) || / || gamma'(s) ||^3 .

The PDE itself is nonlinear with no closed form, but the coefficient kappa(s) is
exact — mathdot's REDUCE engine computes it below. Everything is shown **raw —
no simplification (no factor / expand) applied.**

## 1. Tangent gamma'(s)

```cas
gp1 := df(s^2, s)
```
```cas-result
<!-- src-hash: c65d14e64153 engine: csl-6547 -->
gp1 := 2·s

```
```cas
gp2 := df(s^3 + s^4, s)
```
```cas-result
<!-- src-hash: ba7bda2ae4b7 engine: csl-6547 -->
gp2 := s²·(4·s + 3)

```

## 2. Acceleration gamma''(s)

```cas
gpp1 := df(gp1, s)
```
```cas-result
<!-- src-hash: 37e0f299451b engine: csl-6547 -->
gpp1 := 2

```
```cas
gpp2 := df(gp2, s)
```
```cas-result
<!-- src-hash: 0a98d5ee66a6 engine: csl-6547 -->
gpp2 := 6·s·(2·s + 1)

```

## 3. Cross product (2-D scalar) and squared speed — raw

```cas
cross := gp1*gpp2 - gp2*gpp1
```
```cas-result
<!-- src-hash: 2d029247fcbd engine: csl-6547 -->
cross := 2·s²·(8·s + 3)

```
```cas
speed2 := gp1^2 + gp2^2
```
```cas-result
<!-- src-hash: 60d72c185948 engine: csl-6547 -->
speed2 := s²·(16·s⁴ + 24·s³ + 9·s² + 4)

```

## 4. The curvature coefficient kappa(s)

```cas
kappa := abs(cross) / speed2^(3/2)
```
```cas-result
<!-- src-hash: 005fe1d2f97a engine: csl-6547 -->
kappa := (2·abs(8·s³ + 3·s²))/(sqrt(16·s⁴ + 24·s³ + 9·s² + 4)·abs(s)^
3·(16·s⁴ + 24·s³ + 9·s² + 4))

```

The abs(s) hiding in the denominator is the point: gamma'(0) = (0,0), so the
curve has a **cusp at s = 0** — the singular time — and kappa(s) blows up there.

## 5. Plot — the singular curve's y-component, s^3 + s^4

```cas-plot
x^3 + x^4
```
```cas-plot-result
<!-- src-hash: d878f5f5caa2 engine: csl-6547 -->
plotted 121 samples

```

## 6. Plot — the curvature kappa(s), spiking at the singular time s = 0

```cas-plot
2*abs(8*x^3 + 3*x^2) / (sqrt(16*x^4 + 24*x^3 + 9*x^2 + 4)*abs(x)^3*(16*x^4 + 24*x^3 + 9*x^2 + 4))
```
```cas-plot-result
<!-- src-hash: 4ac5131e0511 engine: csl-6547 -->
plotted 121 samples

```

## 7. Plot — a representative localized solution profile u(s, x)

```cas-plot3d
z = sin(x)*sin(y)*exp(-(x*x + y*y)/8)
```
```cas-plot3d-result
<!-- src-hash: 467f2637ab8d engine: csl-6547 -->
3D surface rendered inline (z = sin(x)*sin(y)*exp(-(x*x + y*y)/8))

```
