# Multiple Series in One Plot (task 251.0)

A `cas-plot` block now draws **one curve per line** — each line is sampled
independently and the panel adds a colour-coded **legend**.

## sin, cos, and their sum

```cas-plot
sin(x)
cos(x)
sin(x) + cos(x)
```
```cas-plot-result
<!-- src-hash: 6d387736c4fd engine: csl-6547 -->
plotted 3 series, 363 samples

```

## A cubic and its derivative

```cas-plot
x^3 - 3*x
3*x^2 - 3
```
```cas-plot-result
<!-- src-hash: 3e3217849be9 engine: csl-6547 -->
plotted 2 series, 242 samples

```

## A single expression still draws exactly one curve (no legend)

```cas-plot
sin(x)/x
```
```cas-plot-result
<!-- src-hash: 8f36ac46538a engine: csl-6547 -->
plotted 1 series, 121 samples

```
