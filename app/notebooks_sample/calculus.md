# Calculus playground

```cas
df(sin(x)*x, x)
```
```cas-result
<!-- src-hash: aef5d6659d59 engine: csl-6547 -->
cos(x)·x + sin(x)

```

```cas
int(1/(x^2 + 1), x)
```
```cas-result
<!-- src-hash: 61e96a3505b0 engine: csl-6547 -->
atan(x)

```

A small step-by-step derivation:

```cas-derive
sin(x+y) * cos(x-y)
```
```cas-derive-result
<!-- src-hash: 37004de04905 engine: csl-6547 -->
1. evaluate → cos(x - y)*sin(x + y)
2. factorize → {{cos(x - y),1},{sin(x + y),1}}
3. trig-expand → cos(x)*sin(x) + cos(y)*sin(y)
4. trig-combine → (sin(2*x) + sin(2*y))/2

```
