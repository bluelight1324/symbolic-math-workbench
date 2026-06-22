# A Nonlinear Integral Equation (given in MathJax)

The problem, as written in MathJax/LaTeX:

    f(x) = λ ∫_{-∞}^{∞} e^{-(x-t)²} f(t) dt  +  ∫_0^x (x-t) f(t)³ dt  +  sin x

mathdot notebooks take **REDUCE syntax**, not LaTeX, so the three pieces are:

- Fredholm term (Gaussian kernel, linear in f):
  `lambda * int(e^(-(x-t)^2)*f(t), t, -infinity, infinity)`
- Volterra term (CUBIC in f):
  `int((x-t)*f(t)^3, t, 0, x)`
- forcing term: `sin(x)`

This equation is **nonlinear** (the `f(t)³`) and mixes a Fredholm and a Volterra
integral, so it has **no closed-form solution**. The standard route is **Picard
iteration**: start from the forcing term `f₀(x) = sin(x)` and feed it back
through the integrals to build successive approximations f₁, f₂, …

## Step 1 — the Volterra cubic term for f₀ = sin(x)

mathdot evaluates this directly:

```cas
int((x-t)*sin(t)^3, t, 0, x)
```
```cas-result
<!-- src-hash: 835bcaef764e engine: csl-6547 -->
( - sin(x)³ - 6·sin(x) + 6·x)/9

```

## Step 2 — the Fredholm (Gaussian) term

The Fredholm term is `∫_{-∞}^{∞} e^(-(x-t)^2) sin(t) dt`. Substituting u = t − x
splits it into an odd part (→ 0) and an even part, giving the **standard result**

    ∫_{-∞}^{∞} e^(-(x-t)^2) sin(t) dt = sqrt(pi)·e^(-1/4)·sin(x).

REDUCE does **not** auto-evaluate this infinite-limit Gaussian integral (its
`defint` package returns it unchanged), so this piece is supplied by hand — a
real limit of the CAS on improper integrals. mathdot still verifies the trig
backbone of the forcing term, `sin(x)` satisfying y″ + y = 0:

```cas
df(sin(x), x, 2) + sin(x)
```
```cas-result
<!-- src-hash: 116e9ec18635 engine: csl-6547 -->
0

```

## Step 3 — the first Picard iterate

Combining Step 1 and the Step-2 result:

    f₁(x) = sin(x)
            + λ·sqrt(pi)·e^(-1/4)·sin(x)            (Fredholm, linear in λ)
            + (-sin(x)³ - 6·sin(x) + 6·x)/9          (Volterra cubic, from Step 1)

Higher Picard iterates f₂, f₃, … substitute f₁ back into the two integrals; each
step's polynomial-/trig-kernel Volterra integral is again something mathdot
evaluates directly.

## How mathdot "satisfies" a MathJax problem

1. **Translate** the LaTeX to REDUCE syntax (shown above) — mathdot reads
   `int(...)`, `df(...)`, `sin(x)`, not `\int`, `\sin`.
2. **Recognise the structure**: nonlinear + Fredholm + Volterra ⇒ no closed form
   ⇒ iterate.
3. **Let the CAS do the heavy, tractable integrals** (the Volterra cubic term
   here), and supply the one improper Gaussian integral it can't.
