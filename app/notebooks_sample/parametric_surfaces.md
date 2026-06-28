# Parametric Surfaces (`cas-surface`) — pure Godot

Task 148.6 adds **parametric (u, v) surfaces** — give `x = …; y = …; z = …` in the
parameters `u, v` (each ranges over [0, 2π]). Built entirely in Godot
(`Expression` sampling + `SurfaceTool`), with the same lit/contoured viewport,
bounding box, colour-bar and drag-rotate as the height-field plots.

## A torus

```cas-surface
x = cos(u)*(2 + cos(v))
y = sin(u)*(2 + cos(v))
z = sin(v)
```
```cas-surface-result
<!-- src-hash: 899da15b1735 engine: csl-6547 -->
parametric surface rendered inline (x = cos(u)*(2 + cos(v))
y = sin(u)*(2 + cos(v))
z = sin(v))

```

## A sphere

```cas-surface
x = cos(u)*sin(v)
y = sin(u)*sin(v)
z = cos(v)
```
```cas-surface-result
<!-- src-hash: 72f676fc2c6d engine: csl-6547 -->
parametric surface rendered inline (x = cos(u)*sin(v)
y = sin(u)*sin(v)
z = cos(v))

```

## A twisted shell

```cas-surface
x = cos(u)*(1.5 + cos(v))
y = sin(u)*(1.5 + cos(v))
z = sin(v) + 0.6*u
```
```cas-surface-result
<!-- src-hash: 42bed910d44a engine: csl-6547 -->
parametric surface rendered inline (x = cos(u)*(1.5 + cos(v))
y = sin(u)*(1.5 + cos(v))
z = sin(v) + 0.6*u)

```
