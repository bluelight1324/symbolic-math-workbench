# Complex Domain Colouring (`cas-domain`)

Task 251.0 adds **domain colouring** of a complex function `f(z)` — a whole new
class of plot. Each point of the image is a complex number `z`; its colour encodes
`f(z)`: **hue = arg f** (the phase) and **brightness = |f|** with log-spaced
magnitude rings. So **zeros** appear as dark hubs where every hue meets and
**poles** as bright spots. Pure Godot — evaluated with a small complex-number
interpreter.

## A quadratic — z² − 1  (zeros at ±1)

```cas-domain
z^2 - 1
```
```cas-domain-result
<!-- src-hash: fb9297a32174 engine: csl-6547 -->
domain colouring rendered inline (z^2 - 1)

```

## A simple pole — 1/z

```cas-domain
1/z
```
```cas-domain-result
<!-- src-hash: 730d2386a9e9 engine: csl-6547 -->
domain colouring rendered inline (1/z)

```

## Cube roots of unity — z³ − 1

```cas-domain
z^3 - 1
```
```cas-domain-result
<!-- src-hash: 98b7a55a0269 engine: csl-6547 -->
domain colouring rendered inline (z^3 - 1)

```
