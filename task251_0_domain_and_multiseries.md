# Task 251.0 — Complex Domain Colouring + 2-D Multi-Series

## Request

> "Do New plot *kinds* no 1 and the recommended."

From the [149.6 "what's left" doc](task149_6_plots_whats_left.md): **new plot kind #1
= `cas-domain`** (complex domain colouring) and **recommended #1 = 2-D multiple
series + legend**. Both built, both pure Godot, both verified.

## 1. `cas-domain` — complex domain colouring (a whole new class of plot)

Domain colouring visualises a complex function `f(z)` as an image: every pixel is a
point `z` in the complex plane, and its colour encodes `f(z)` —
**hue = arg f** (the phase) and **brightness = |f|** with log-spaced magnitude
rings. So **zeros** read as dark hubs where every hue meets, and **poles** as bright
spots. It makes poles, zeros, branch cuts and periodicity *visible* at a glance.

- **`ComplexEval` — a small complex evaluator** ([complex_eval.gd](app/scripts/complex_eval.gd)).
  Godot's `Expression` is real-only, so this parses `f(z)` **once** into an AST
  (recursive-descent: `+ - * / ^`, unary minus, implicit multiplication like `2z`/`z(z+1)`,
  the variable `z`, constants `i`/`pi`/`e`, real literals, and `exp, log/ln, sqrt,
  sin, cos, tan, sinh, cosh, conj, abs, re, im`) and evaluates it per pixel with
  complex arithmetic. General complex power via `exp(b·log a)`.
- **Rendering:** sample a 280×280 grid over `z ∈ [−3, 3]²`, colour each pixel with an
  enhanced phase portrait, and show the `ImageTexture` framed with a caption.
  Unparseable input shows the parser's error message.

**Verified:** `z² − 1` (two zeros at ±1), `1/z` (a pole), and `z³ − 1` render as
proper phase portraits — the **cube-roots-of-unity** image shows the three dark
zeros 120° apart inside the colour-wheel with magnitude rings
(`app_screenshot_task2510_domain.png`).

## 2. 2-D multiple series + legend (the top recommended 2-D item)

A `cas-plot` block now draws **one curve per line** — each line is sampled
independently and the panel adds a colour-coded **legend**.

- **Sampling:** the runner builds one engine call per line (`for…collect sub(x=…, expr)`),
  and `_extract_brace_groups` splits the output into one `{…}` list per series
  (balanced-brace scan, so a long wrapped list stays intact); each is parsed to its
  own curve. A single expression still draws exactly one curve (no legend), so
  existing notebooks are unchanged.
- **Panel** ([plot_panel.gd](app/scripts/plot_panel.gd)): a unified draw path
  (single sample set = a one-element series), a 6-colour palette, a **legend** box
  (top-left, inset past the y-axis numbers so it stays on-screen even when a long
  chip widens the column), and a hover read-out with a dot on every series. The
  chip shows the curve count.

**Verified:** `sin(x)`, `cos(x)`, `sin(x)+cos(x)` draw as three distinct
blue/orange/green curves with a 3-entry legend; the chip reads "3 curves · 363
samples" (`app_screenshot_task2510.png`). A cubic + its derivative draw as two curves.

## Verification

- **Unit tests** (`--test126`): **88 / 88 pass** — 20 new this task:
  - `ComplexEval`: `(z²−1)|₂ = 3`, `(z²−1)|ᵢ = −2`, `(1/z)|ᵢ = −i`, `exp(0)=1`,
    garbage rejected; `_build_domain2d` → a cell, bad input → `Label`; domain colour
    saturated for finite values, white at a pole; `cas-domain` parses + pairs.
  - multi-series: `_plot_exprs` line-splitting (skips blanks/`#`), `_extract_brace_groups`,
    `set_series` stores N series with distinct colours, `set_samples` clears them.
- **Integration:** `--demo-domain` writes 3 `cas-domain` results and renders the
  portraits; `--demo-multi` writes "3 series / 2 series / 1 series" results and
  renders the multi-curve plots with the legend.

## Still remaining

Plotting now covers 2-D curves (now **multi-series**), 3-D height fields,
parametric/animated/implicit surfaces, vector fields, **and complex domain
colouring**. Next from [149.6](task149_6_plots_whats_left.md): the other recommended
items — **PNG/MP4 export** and **threaded sampling** (the domain/implicit grids
still build on the main thread) — then `cas-stream`, 2-D `cas-implicit` curves, and
the CAS-fusion tier.

## Files changed
- `app/scripts/complex_eval.gd` — **new** complex-number AST evaluator.
- `app/scripts/notebook_view.gd` — `_build_domain2d` + `_domain_color` + `_make_domain_cell`;
  multi-series `_plot_exprs` / `_extract_brace_groups`, multi-expr sampling, render routing.
- `app/scripts/plot_panel.gd` — multi-series (`set_series`, palette, legend, multi-hover).
- `app/scripts/notebook_runner.gd` — `cas-domain` kind + pairing.
- `app/scripts/main.gd` — `--demo-domain`, `--demo-multi` flags.
- `app/scripts/_test126.gd` — 20 new assertions (now 88/88).
- `app/notebooks_sample/domain_coloring.md`, `multi_series.md` — demo notebooks.
