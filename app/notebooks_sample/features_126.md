# Task 126 — New Features Demo

This note exercises the features added in task 126. See also [[algebra]] and
[[calculus]] — those are **wikilinks**: click them in the rendered view to jump
to those notebooks.

## LaTeX input in a cas block

You can now write a `cas` block in **LaTeX** — it's converted to REDUCE before
running. A fraction and a power:

```cas
\frac{1}{2}\cdot x^{2} + \sin(x)
```
```cas-result
<!-- src-hash: 32ebff999f65 engine: csl-6547 -->
(2·sin(x) + x²)/2

```

A definite integral written in LaTeX (the same Volterra term from task 120):

```cas
\int_{0}^{x} (x-t)\sin(t)^{3} \, dt
```
```cas-result
<!-- src-hash: 24f2001a03e5 engine: csl-6547 -->
( - sin(x)³ - 6·sin(x) + 6·x)/9

```

## Real 3D surface plot

A `cas-plot3d` block now renders a **real 3D surface** (Godot Camera3D viewport),
not a placeholder:

```cas-plot3d
z = sin(x)*cos(y)
```
```cas-plot3d-result
<!-- src-hash: b88dc809095d engine: csl-6547 -->
3D surface rendered inline (z = sin(x)*cos(y))

```

Another surface — a radial ripple:

```cas-plot3d
z = sin(x*x + y*y)
```
```cas-plot3d-result
<!-- src-hash: 1dc7bc5d31ad engine: csl-6547 -->
3D surface rendered inline (z = sin(x*x + y*y))

```

## Also added
- **Clear all outputs** (menu) empties every result block so the notebook runs
  fresh.
- **Search workspace** (Ctrl+Shift+F) greps every `.md` and jumps to a hit.
- **Distraction-free** (menu) hides the file tree for a full-width editor.
