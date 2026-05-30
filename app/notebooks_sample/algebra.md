# Algebra examples

Expand a binomial:

```cas
(x+1)^5
```
```cas-result
<!-- src-hash: c0924639a943 engine: csl-6547 -->
x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1

```

Factor a polynomial:

```cas
factorize(x^6 - 1)
```
```cas-result
<!-- src-hash: 55764b99737d engine: csl-6547 -->
{{x² + x + 1,1},
{x² - x + 1,1},
{x + 1,1},
{x - 1,1}}

```

Simplify a fraction:

```cas
(x^2 - 1) / (x - 1)
```
```cas-result
<!-- src-hash: 5925d85e4395 engine: csl-6547 -->
x + 1

```

## Tests

```cas-test
assert: (x+1)^2 = x^2 + 2*x + 1
```
```cas-test-result
<!-- src-hash: b9d8eee50dfa engine: csl-6547 -->
(verified)
lhs - rhs → 0

```

```cas-test
assert: df(sin(x), x) = cos(x)
```
```cas-test-result
<!-- src-hash: a08d01863947 engine: csl-6547 -->
(verified)
lhs - rhs → 0

```
