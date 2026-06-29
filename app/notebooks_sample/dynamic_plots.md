# Animated Surfaces & Vector Fields (pure Godot)

Task 149.3 adds two new plot kinds, both rendered by Godot:
**`cas-anim`** (an animated `z = f(x, y, t)` surface that evolves in real time) and
**`cas-field`** (a vector field drawn as arrow glyphs).

## Animated surface — a travelling wave

```cas-anim
z = sin(x + t)*cos(y)
```
```cas-anim-result
<!-- src-hash: d1711fdfcc31 engine: csl-6547 -->
animated surface rendered inline (z = sin(x + t)*cos(y))

```

## Animated surface — an expanding ripple

```cas-anim
z = sin(2*(x*x + y*y) - 3*t)
```
```cas-anim-result
<!-- src-hash: 2d12f9f3efcb engine: csl-6547 -->
animated surface rendered inline (z = sin(2*(x*x + y*y) - 3*t))

```

## Vector field — rotational  (u, v, w) = (−y, x, 0)

```cas-field
u = -y
v = x
w = 0
```
```cas-field-result
<!-- src-hash: d97ed1bbeeb2 engine: csl-6547 -->
vector field rendered inline (u = -y
v = x
w = 0)

```

## Vector field — saddle with vertical swirl

```cas-field
u = x
v = -y
w = sin(x)*cos(y)
```
```cas-field-result
<!-- src-hash: ec81b666c9d9 engine: csl-6547 -->
vector field rendered inline (u = x
v = -y
w = sin(x)*cos(y))

```
