# An "Impossible" Coupled System — Honest CAS Output

A coupled non-linear system involving the dilogarithm Li₂, the complete
elliptic integral K, and a non-elementary integral. Pulled verbatim from
the task-37 brief in `todo.txt`.

## The system

For unknowns `x(t)`, `y(t)`:

1. `d/dt [ exp(x(t)² · y(t)) ] = sqrt(1 + x(t)²) · Li₂(y(t)²)`
2. `x(t)³ + y(t)³ − 3·x(t)·y(t) = sin( x(t)·y(t) )`
3. `∫₀^x(t) sqrt(1+u⁴) / (1−u²)  du  =  y(t) · K( x(t) / (1 + x(t)²) )`

where Li₂ is the **dilogarithm** and K is the **complete elliptic
integral of the first kind**.

> Each `cas` block below repeats its `depend` / `operator` declarations so
> the block stands alone — that way a `Force re-run` (Ctrl+F5) after an
> engine restart still works without needing the previous blocks'
> in-session state.

## 1. Symbolic chain-rule derivative of eq 1's LHS

REDUCE applies the chain rule directly. Recognising that `x` and `y`
depend on `t`, `d/dt[e^(x²y)]` becomes `e^(x²y)·(2·x·dx/dt·y + x²·dy/dt)`,
which factors as below.

```cas
depend x, t; depend y, t; df(exp(x^2*y), t)
```
```cas-result
<!-- src-hash: d957ff8838bf engine: csl-6547 -->
e^(x²·y)·x·(2·df(x,t)·y + df(y,t)·x)

```

## 2. Eq 1 as a "= 0" differential constraint

`polylog(2, …)` is REDUCE's built-in name for the dilogarithm Li₂.
With the `specfn` package (loaded by default per
[task 31](../../../task31_default_packages.md)), it stays symbolic.

```cas
depend x, t; depend y, t; df(exp(x^2*y), t) - sqrt(1+x^2)*polylog(2, y^2)
```
```cas-result
<!-- src-hash: 8b47e503e7fd engine: csl-6547 -->
2·e^(x²·y)·df(x,t)·x·y + e^(x²·y)·df(y,t)·x² - sqrt(x² + 1)·polylog(2,
y²)

```

## 3. Implicit differentiation of eq 2

The polynomial relation `x³ + y³ − 3xy = sin(xy)` differentiated w.r.t.
`t` becomes a linear equation in `dx/dt`, `dy/dt` whose coefficients are
real functions of `x`, `y`.

```cas
depend x, t; depend y, t; df(x^3 + y^3 - 3*x*y - sin(x*y), t)
```
```cas-result
<!-- src-hash: 4a6c0a32b99f engine: csl-6547 -->
- cos(x·y)·df(x,t)·y - cos(x·y)·df(y,t)·x + 3·df(x,t)·x² - 3·df(x,t)·y - 3·df
(y,t)·x + 3·df(y,t)·y²

```

## 4. Eq 3 differentiated

The LHS integral has no elementary closed form (see §5 below), so we
introduce an operator symbol `F` that stands in for it:
`F(x(t)) := ∫₀^x sqrt(1+u⁴)/(1−u²) du`. K stays symbolic via the
`operator elliptic_k` declaration.

Differentiating `F(x(t)) − y(t)·K(x/(1+x²)) = 0` gives a relation
involving `dF/dx · dx/dt − dy/dt · K − y · dK/dt`. REDUCE keeps the
`df(F(x), t)` and `df(elliptic_k(...), t)` symbols intact because both
functions are operator-only.

```cas
depend x, t; depend y, t; operator elliptic_k; operator F; df(F(x) - y*elliptic_k(x/(1+x^2)), t)
```
```cas-result
<!-- src-hash: 7d36547da244 engine: csl-6547 -->
- df(elliptic_k(x/(x² + 1)),t)·y + df(f(x),t) - df(y,t)·elliptic_k(x/(x² +
1))

```

## 5. What REDUCE *cannot* do (and why)

The LHS integral of eq 3 isn't elementary — its anti-derivative involves
elliptic functions of the second kind. Sending the bare `int(...)`
through REDUCE returns the integrand wrapped in `int(...)` (i.e. the
integral itself, symbolic). Asking the CAS to "solve" the original
3-equation system in closed form is not possible: the unknowns
`x(t), y(t)` are only defined implicitly by these constraints, and no
analytic solution exists in elementary or named special functions.

What a CAS *can* legitimately do is the work in §§1–4 above — chain
rule, implicit differentiation, operator declarations — to **reduce the
problem to a Jacobian system in `dx/dt`, `dy/dt`** that a numerical
solver (e.g. Runge–Kutta from an initial condition) could then advance.

## 6. The Jacobian system, assembled

Combining §§1–4 into one expression yields a 3-equation symbolic system
whose only undetermined quantities are `dx/dt` and `dy/dt`. We can also
factorise eq 2's polynomial body — REDUCE confirms it's irreducible over
ℚ.

```cas
factorize(x^3 + y^3 - 3*x*y)
```
```cas-result
<!-- src-hash: 1a1f44e57cc8 engine: csl-6547 -->
{{x³ - 3·x·y + y³,1}}

```

The full Jacobian collapses to a triple of linear constraints in
`(dx/dt, dy/dt)` whose coefficients carry `polylog`, `cos(xy)`,
`elliptic_k(x/(1+x²))`, etc. — i.e. the right shape for a numerical
solver, not for a closed-form CAS answer.
