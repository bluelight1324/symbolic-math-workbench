# Sample Equations in STIX Two Math (task 272)

Every **result** below is rendered in the bundled **STIX Two Math** font (tasks
268/270) — variables, numbers, radicals, superscripts, matrices and symbols in one
coherent, textbook-quality math face. The prose and the `cas` source keep the
monospace UI font.

## Binomial expansion — (x + 1)⁵

```cas
(x + 1)^5
```
```cas-result
<!-- src-hash: 706aa6015efd engine: csl-6547 -->
x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1

```

## A radical — √(x² + y²)

```cas
sqrt(x^2 + y^2)
```
```cas-result
<!-- src-hash: b9a26d309fea engine: csl-6547 -->
√(x² + y²)

```

## An integral — ∫ (x³ + 2x) dx

```cas
int(x^3 + 2*x, x)
```
```cas-result
<!-- src-hash: 28df4bba0ccc engine: csl-6547 -->
(x²·(x² + 4))/4

```

## A symbolic derivative — d/dx xⁿ

```cas
df(x^n, x)
```
```cas-result
<!-- src-hash: 28a8219879d6 engine: csl-6547 -->
(x^n·n)/x

```

## A cubic expansion — (a + b)³

```cas
(a + b)^3
```
```cas-result
<!-- src-hash: 0ce82669df0e engine: csl-6547 -->
a³ + 3·a²·b + 3·a·b² + b³

```

## A matrix product

```cas
mat((1,2),(3,4)) * mat((0,1),(1,0))
```
```cas-result
<!-- src-hash: e9b92d3957b7 engine: csl-6547 -->
mat((2,1),(4,3))

```

## Roots of a quadratic — x² − 5x + 6 = 0

```cas
solve(x^2 - 5*x + 6, x)
```
```cas-result
<!-- src-hash: 5c535475b17a engine: csl-6547 -->
{x=3,x=2}

```
