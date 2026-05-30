# Task 31 — Which REDUCE Packages to Load by Default

A design doc: of REDUCE's many contributed packages listed at
[`reduce-algebra.sourceforge.io/documentation.php#contributed`](https://reduce-algebra.sourceforge.io/documentation.php#contributed)
(and bundled locally under
[`tools/reduce/packages/`](tools/reduce/packages/) — see
[task 30](task30_workdoc.md)), which ones should the app auto-load at
engine startup, and which should be opt-in?

Implementation of the user-facing chooser is [task 32](task32_package_dropdown.md);
this doc is the rationale behind the tiers it presents.

---

## What "default" means here

[math_engine.gd](app/autoload/math_engine.gd) currently emits at session
start, after `off nat; off echo;`, a single `load_package …` line for
each package the user has selected. Whatever's in that initial line is
"the default set" from the user's point of view — the operators those
packages add (`odesolve`, `taylor`, `limit`, `defint`, `int`, `sum`,
matrix inverse via `mat^(-1)`, etc.) are simply available everywhere in
the app: the calculator's operation buttons, the menu library, the
Advanced tab, the notebook view's `cas` blocks, the showcase.

The pre-task-31 startup string was:
`load_package odesolve; load_package taylor; load_package limits;` —
three packages, chosen ad hoc when those features were added in
tasks 7 / 8 / 19. This task formalises the picking criteria and proposes
a fuller, tiered default set.

## Criteria

1. **Universally useful** — operators that appear in the kind of math a
   reasonable percentage of users will touch.
2. **Cheap to load** — small package, fast cold-start (the app's `_start()`
   is paid every launch).
3. **Not state-changing** — loading the package shouldn't change how the
   *existing* operators behave (e.g. some packages globally enable a
   switch that affects output).
4. **Empirically loadable** in this build (verified by a probe — all 22
   candidates loaded cleanly against the bundled CSL REDUCE).

## Proposed tiers

| Tier | Default-on?  | Rationale                                                           |
|:---:|:-------------:|---------------------------------------------------------------------|
| 1   | **Yes**       | Tiny + broadly useful — operators a beginner reaches for             |
| 2   | No (opt-in)   | Useful for a specific domain (signals, transforms, matrix forms…)    |
| 3   | No (opt-in)   | Specialised / heavy (Gröbner, redlog, exterior calc)                 |

### Tier 1 (recommend default-load)

| Package | What it adds                                                  |
|---------|---------------------------------------------------------------|
| `odesolve` | `odesolve(eqn, y, x)` for ODEs                              |
| `taylor`   | `taylor(f, x, x₀, n)` Taylor series                         |
| `limits`   | `limit(f, x, x₀)`                                           |
| `defint`   | Definite integrals — `int(f, x, a, b)` form                  |
| `specfn`   | Bessel / Gamma / error / Riemann-zeta / digamma             |
| `sum`      | `sum(f, k, a, b)` for closed-form symbolic summation         |
| `roots`    | Polynomial root finding                                      |
| `rlfi`     | **Off by default** — turning it on changes echo via `on latex` |

The list lands at 7 tier-1 entries that are on by default + 1 tier-1
entry (`rlfi`) that's intentionally opt-in despite being tier-1-sized,
because the typical user doesn't want their results echoed as LaTeX
unless they ask.

### Tier 2 (opt-in)

| Package    | Domain it serves                                          |
|------------|-----------------------------------------------------------|
| `laplace`  | Laplace transforms (and inverse)                          |
| `ztrans`   | Z-transforms                                              |
| `assist`   | Misc helpers — set ops, defined-when, operator definitions |
| `linalg`   | Extended matrix algebra                                   |
| `normform` | Matrix normal forms (Jordan / Smith)                       |
| `residue`  | Residues for contour integration                          |
| `numeric`  | Numerical evaluation helpers                               |
| `rataprx`  | Padé / Chebyshev rational approximation                   |
| `tps`      | Truncated power-series arithmetic                         |
| `arnum`    | Algebraic numbers, extension fields                       |
| `algint`   | Algebraic-function integration                            |

### Tier 3 (opt-in, larger / specialised)

| Package    | What it enables                                            |
|------------|------------------------------------------------------------|
| `groebner` | Gröbner-basis computation for polynomial ideals            |
| `redlog`   | Quantifier elimination over real/integer/p-adic            |
| `excalc`   | Exterior calculus / differential forms / wedge products    |

Tier-3 packages are the headline features for users who want them, but
are real performance / memory costs on cold start and add operators
that look alien to non-specialists. They belong opt-in.

## The default-selected list

`PackageConfig.DEFAULT_SELECTED` in
[app/scripts/package_config.gd](app/scripts/package_config.gd):

```gdscript
const DEFAULT_SELECTED := [
    "odesolve", "taylor", "limits", "defint", "specfn", "sum", "roots",
    # `rlfi` deliberately *not* on by default — turning it on changes how the
    # engine echoes expressions for some operations. Users opt in.
]
```

That's the answer to task 31. Task 32 ships the UI that lets a user
override it per-machine.

## Why not "load everything by default"

Three reasons:

1. **Cold-start cost.** Loading each tier-3 package costs hundreds of ms;
   loading all 22 packages would add seconds to the first response.
2. **Surface-area cost.** Every loaded package adds operators / switches
   that can collide with user variable names or change behaviour
   surprisingly (e.g. `on latex` from `rlfi`, multiple Gröbner-ordering
   parameters from `groebner`).
3. **No graceful unload.** Once a package is loaded, REDUCE doesn't
   support unloading it from the running image. Restarting the engine is
   the only way back — implemented in
   [`MathEngine.restart()`](app/autoload/math_engine.gd) for task 32's
   Apply button. Keeping the default modest avoids that round-trip
   becoming a daily chore.

## What this leaves for later

- A profiling pass that measures real load times for each package in
  this build and validates the tier assignments.
- Per-notebook package selection (a notebook frontmatter declares the
  packages it expects; the engine restarts when opening it). Would
  belong on the [task 18 roadmap](task18_requirements.md) as a P3+ item.
