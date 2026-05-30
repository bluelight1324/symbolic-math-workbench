# Symbolic Math Workbench — capability showcase

A curated walk through what the app can do. Every `cas` block is run by the
persistent engine; the paired `cas-result` block is auto-generated with a
content hash, so re-running skips work that hasn't changed.

## 1. Algebra: factor a cyclotomic polynomial

The 12th cyclotomic polynomial breaks `x¹² − 1` into six irreducible factors
over the integers.

```cas
factorize(x^12 - 1)
```
```cas-result
<!-- src-hash: 926b6349829e engine: csl-6547 -->
{{x⁴ - x² + 1,1},
{x² + x + 1,1},
{x² - x + 1,1},
{x² + 1,1},
{x + 1,1},
{x - 1,1}}

```

## 2. Calculus: a non-trivial closed-form integral

The integral of `1/(x³ + 1)` mixes a logarithm with an arctangent.

```cas
int(1/(x^3 + 1), x)
```
```cas-result
<!-- src-hash: f7ca2401da64 engine: csl-6547 -->
(2·sqrt(3)·atan((2·x - 1)/sqrt(3)) - log(x² - x + 1) + 2·log(x + 1))/6

```

A derivative for variety — product rule on `atan(x)·log(x)`:

```cas
df(atan(x)*log(x), x)
```
```cas-result
<!-- src-hash: 90ff244cff0c engine: csl-6547 -->
(atan(x)·x² + atan(x) + log(x)·x)/(x·(x² + 1))

```

## 3. Series expansion

Truncated Taylor series for `eˣ · sin(x)` around 0, up to order 7. Notice the
quadratic and cubic terms, and the absence of the `x⁴` term.

```cas
taylor(exp(x)*sin(x), x, 0, 7)
```
```cas-result
<!-- src-hash: b3e287a425e4 engine: csl-6547 -->
taylor(x + x² + 1/3·x³ - 1/30·x⁵ - 1/90·x⁶ - 1/630·x⁷,x,0,7)

```

## 4. Differential equation: the forced harmonic oscillator

`y″ + y = sin(x)` — a textbook problem in classical mechanics. The answer
combines the homogeneous solution (general sin / cos with arbitrary
constants) and a particular `x·cos(x)` term, hinting at resonance.

```cas
odesolve(df(y,x,2) + y = sin(x), y, x)
```
```cas-result
<!-- src-hash: 97256145f547 engine: csl-6547 -->
{y=(2·arbconst(2)·sin(x) + 2·arbconst(1)·cos(x) - cos(x)·x)/2}

```

## 5. Linear algebra: invert a 3×3 matrix

```cas
mat((1,2,3),(0,1,4),(5,6,0))^(-1)
```
```cas-result
<!-- src-hash: 139e7011c144 engine: csl-6547 -->
mat((-24,18,5),(20,-15,-4),(-5,4,1))

```

Sanity-check by computing the determinant separately:

```cas
det mat((1,2,3),(0,1,4),(5,6,0))
```
```cas-result
<!-- src-hash: c753ce1bc0ef engine: csl-6547 -->
1

```

## 6. A step-by-step derivation

`cas-derive` evaluates the expression, then factorises, then trig-expands and
trig-combines it. For `sin(3x)` the trig-expand step recovers the textbook
triple-angle identity.

```cas-derive
sin(3*x)
```
```cas-derive-result
<!-- src-hash: 2b1ada312d72 engine: csl-6547 -->
1. evaluate → sin(3*x)
2. factorize → {{sin(3*x),1}}
3. trig-expand → sin(x)*( - 4*sin(x)**2 + 3)
4. trig-combine → sin(3*x)

```

## 7. Self-checking: verified identities

The pair below is checked by the engine, not just typeset. The runner
evaluates `(lhs) - (rhs)`; if it auto-simplifies to `0`, the test PASSES.

```cas-test
assert: (x+1)^4 = x^4 + 4*x^3 + 6*x^2 + 4*x + 1
```
```cas-test-result
<!-- src-hash: f6a68a86b802 engine: csl-6547 -->
(verified)
lhs - rhs → 0

```

```cas-test
assert: df(x*log(x) - x, x) = log(x)
```
```cas-test-result
<!-- src-hash: b5ce459d2ff5 engine: csl-6547 -->
(verified)
lhs - rhs → 0

```

## 8. Exact large-integer arithmetic

```cas
factorial(50)
```
```cas-result
<!-- src-hash: ee33b8441fb3 engine: csl-6547 -->
30414093201713378043612608166064768844377641568960512000000000000

```
