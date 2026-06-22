# A Difficult Integral Equation

We solve the **Volterra integral equation of the second kind**

    y(x) = sin(x) + integral_0^x (x - t) * y(t) dt

Here the unknown function `y` appears *inside* the integral, so it cannot be
integrated directly. The standard technique is to **differentiate the equation
twice** (Leibniz' rule) to turn it into an ordinary differential equation.

## Step 1 — differentiate into an ODE

Differentiating once — the boundary term `(x - t) y(t)` vanishes at `t = x`:

    y'(x) = cos(x) + integral_0^x y(t) dt

Differentiating again removes the integral entirely:

    y''(x) = -sin(x) + y(x)

so the integral equation is equivalent to the linear ODE

    y'' - y = -sin(x),     with   y(0) = 0,   y'(0) = 1.

(The initial conditions come from setting `x = 0` in the original equation and
in the once-differentiated equation.)

## Step 2 — solve the ODE with the CAS

```cas
odesolve(df(y,x,2) - y = -sin(x), y, x)
```
```cas-result
<!-- src-hash: 237800e45a51 engine: csl-6547 -->
{y=(2·e^(2·x)·arbconst(2) + 2·arbconst(1) + e^x·sin(x))/(2·e^x)}

```

The general solution mixes a hyperbolic part (from `y'' - y`) with a
trigonometric particular solution (from the `-sin(x)` forcing term). Imposing
`y(0) = 0` and `y'(0) = 1` fixes the constants and gives the closed form

    y(x) = ( sinh(x) + sin(x) ) / 2

## Step 3 — verify the closed form

The candidate must satisfy `y'' - y = -sin(x)`, i.e. the expression below must
reduce to **0**:

```cas
df((sinh(x) + sin(x))/2, x, 2) - (sinh(x) + sin(x))/2 + sin(x)
```
```cas-result
<!-- src-hash: 8299d0bf1eca engine: csl-6547 -->
0

```

It must also satisfy the initial conditions `y(0) = 0` ...

```cas
sub(x=0, (sinh(x) + sin(x))/2)
```
```cas-result
<!-- src-hash: 9358028d1c0a engine: csl-6547 -->
0

```

... and `y'(0) = 1`:

```cas
sub(x=0, df((sinh(x) + sin(x))/2, x))
```
```cas-result
<!-- src-hash: ed9f91a9cd5f engine: csl-6547 -->
1

```

All three checks pass, so

    y(x) = ( sinh(x) + sin(x) ) / 2

is the solution of the integral equation.
