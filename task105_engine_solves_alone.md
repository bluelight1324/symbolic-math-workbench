# Task 105 — What the Engine Can Do On Its Own

## Goal

> "Do not add your commentary or the solution. What can it do on its own. Show
> another difficult integral. Do 1 doc."

Unlike task 104 (where the method and the answer were written out by hand), this
task hands the engine hard problems with **no method, no commentary, and no
solution from me** — the notebook contains *only the problems*, and the app's
REDUCE engine produces every answer itself.

## The notebook — `app/notebooks_sample/difficult_integral.md`

As authored, it is just a title and four bare `cas` blocks — no prose, no
worked solution:

```
# Another difficult integral

```cas
int(exp(-x^2), x)
```
```cas
int(1/(1 + x^6), x)
```
```cas
int((x^2 + 1)/(x^4 + 1), x)
```
```cas
int(x^2*log(x), x)
```
```

## What the engine produced — entirely on its own

Running it in the app, REDUCE filled in every result with no help:

| Problem | Engine's answer (unaided) |
|---|---|
| `∫ e^(−x²) dx` | `(√π · erf(x)) / 2` — recognises it has **no elementary form** and returns it via the **error function** |
| `∫ 1/(1+x⁶) dx` | `(−2·atan(√3−2x) + 2·atan(√3+2x) + 4·atan(x) − √3·log(−√3·x+x²+1) + √3·log(√3·x+x²+1)) / 12` |
| `∫ (x²+1)/(x⁴+1) dx` | `(√2·(−atan((√2−2x)/√2) + atan((√2+2x)/√2))) / 2` |
| `∫ x²·log(x) dx` | `(x³·(3·log(x) − 1)) / 9` |

The standout is the Gaussian `∫ e^(−x²) dx`: it has no antiderivative in
elementary functions, and the engine answered with the special function
`erf` — something a CAS knows but a hand calculation can't produce. The
`1/(1+x⁶)` integral (sixth-degree denominator) is likewise far beyond a quick
hand computation, yet the engine returns the complete closed form.

## How it was run

A `--demo-diffint` launch flag ([main.gd](app/scripts/main.gd)) — alongside the
task-104 `--demo-inteq` flag, both now sharing a small
`_open_named_notebook_and_run()` helper — opens `difficult_integral.md` and runs
every cell. The rendered notebook shows each `cas` problem followed by its
engine-generated `= result` inline (`app_screenshot_task105.png`); for example
the first cell reads `int(exp(-x^2), x)` → `(sqrt(pi)·erf(x))/2`.

## Note on "integral equation" vs "integral"

A *true* integral equation (the unknown function under the integral sign, as in
task 104) has no single REDUCE command that solves it unaided — the Laplace and
definite-integral packages it would need are available, but assembling them is
itself "providing the solution." Honouring "what can it do **on its own** /
don't add the solution," this notebook poses difficult **integrals** that the
engine solves directly in one command — the clearest demonstration of its
autonomous power, special functions included.

## Files
- `app/notebooks_sample/difficult_integral.md` — problems only (the engine wrote
  the results on run).
- `app/scripts/main.gd` — `--demo-diffint` flag + shared
  `_open_named_notebook_and_run()` helper.
