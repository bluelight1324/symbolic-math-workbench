# Plotting

A simple `cas-plot` block. Running it shows the curve in an inline plot
strip below the editor — only when it's needed. (Task 35.)

```cas-plot
sin(x) + sin(2*x)/2
```
```cas-plot-result
<!-- src-hash: 2ae48890a503 engine: csl-6547 -->
plotted 61 samples

```

After the plot strip appears, press **Hide plot** to dismiss it without
running anything else. Running another non-plot block leaves the strip
visible until you dismiss it.

A second plot, a different function:

```cas-plot
exp(-x^2)
```
```cas-plot-result
<!-- src-hash: c0719d7743ef engine: csl-6547 -->
plotted 61 samples

```
