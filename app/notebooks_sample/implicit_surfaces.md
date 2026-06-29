# Implicit Surfaces (`cas-implicit`) — f(x, y, z) = 0

Task 149.5 adds **implicit surfaces** — surfaces that aren't graphs `z=f(x,y)`,
defined by `f(x, y, z) = 0`. Meshed with **Surface Nets** (pure Godot) and rendered
through the same lit/contoured viewport, colour-bar and drag-rotate.

## A sphere — x² + y² + z² = 4

```cas-implicit
x*x + y*y + z*z - 4
```
```cas-implicit-result
<!-- src-hash: 7479affa55d1 engine: csl-6547 -->
implicit surface rendered inline (x*x + y*y + z*z - 4)

```

## A torus — (√(x²+y²) − 1.6)² + z² = 0.5

```cas-implicit
(sqrt(x*x + y*y) - 1.6)^2 + z*z - 0.5
```
```cas-implicit-result
<!-- src-hash: 7b8efbb007b6 engine: csl-6547 -->
implicit surface rendered inline ((sqrt(x*x + y*y) - 1.6)^2 + z*z - 0.5)

```
