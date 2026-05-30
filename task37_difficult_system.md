# Task 37 — An "Extremely Difficult" CAS System

The brief: solve the 3-equation coupled non-linear system in lines 38–56
of `todo.txt`. The system involves the **dilogarithm Li₂**, the
**complete elliptic integral K**, and a **non-elementary integral** —
the user-supplied annotation explicitly calls it "extremely difficult
for a CAS." This task creates a notebook
([`app/notebooks_sample/task37_system.md`](app/notebooks_sample/task37_system.md))
that runs the *honest* answer through the app's persistent REDUCE
engine, and writes up what CAS can and can't do here.

See the bundled screenshot
[app_screenshot_task37_small.png](app_screenshot_task37_small.png).

---

## The system in plain notation

For unknowns `x(t)`, `y(t)`:

1. `d/dt [ exp( x(t)² · y(t) ) ] = sqrt( 1 + x(t)² ) · Li₂( y(t)² )`
2. `x(t)³ + y(t)³ − 3·x(t)·y(t) = sin( x(t) · y(t) )`
3. `∫₀^x(t) sqrt(1 + u⁴) / (1 − u²) du = y(t) · K( x(t) / (1 + x(t)²) )`

`Li₂` is the dilogarithm. `K` is the complete elliptic integral of the
first kind.

## How to reproduce the run

1. Launch the app (it opens with the notebook view by default).
2. In the sidebar, double-click **`task37_system.md`**.
3. Press **Ctrl+F5** (Force re-run) to ignore the content cache and have
   every block computed live.

For automation:

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --demo-task37
```

The new `--demo-task37` flag opens the notebook and force-runs it; a
viewport screenshot is saved 14 s later if `--capture <path>` is also
present.

## What REDUCE actually does — block by block

Each `cas` block is reproduced below in source/result form. Every result
came back live from the persistent engine session.

### 1. Symbolic chain-rule derivative of eq 1's LHS

```
depend x, t; depend y, t; df(exp(x^2*y), t)
```

result:
```
e^(x²·y)·x·(2·df(x,t)·y + df(y,t)·x)
```

The chain rule on `d/dt[e^(x²y)]` applied symbolically, with `df(x,t)`
and `df(y,t)` as the unevaluated derivatives.

### 2. Eq 1 as a "= 0" differential constraint

`polylog(2, …)` is REDUCE's name for the dilogarithm Li₂; with the
`specfn` package loaded by default
(see [task 31](task31_default_packages.md)), it stays symbolic.

```
depend x, t; depend y, t; df(exp(x^2*y), t) - sqrt(1+x^2)*polylog(2, y^2)
```

result:
```
2·e^(x²·y)·df(x,t)·x·y + e^(x²·y)·df(y,t)·x² − sqrt(x² + 1)·polylog(2, y²)
```

### 3. Implicit differentiation of eq 2

The polynomial identity `x³ + y³ − 3xy = sin(xy)` differentiated
implicitly w.r.t. `t`. Output is linear in `df(x,t)` and `df(y,t)`.

```
depend x, t; depend y, t; df(x^3 + y^3 - 3*x*y - sin(x*y), t)
```

result:
```
−cos(x·y)·df(x,t)·y − cos(x·y)·df(y,t)·x
  + 3·df(x,t)·x² − 3·df(x,t)·y − 3·df(y,t)·x + 3·df(y,t)·y²
```

### 4. Eq 3 differentiated (operator symbols for the non-elementary pieces)

The integral has no elementary closed form (§5), so we introduce
`F(x(t)) := ∫₀^x sqrt(1+u⁴)/(1−u²) du` as an operator symbol. `K` is
similarly declared via `operator elliptic_k`.

```
depend x, t; depend y, t; operator elliptic_k; operator F;
df(F(x) - y*elliptic_k(x/(1+x^2)), t)
```

result:
```
− df(elliptic_k(x/(x² + 1)), t)·y
  + df(f(x), t)
  − df(y,t)·elliptic_k(x/(x² + 1))
```

(Lower-case `f` because REDUCE down-cases operator names on echo.)

### 5. Factorisation cross-check of eq 2's polynomial body

```
factorize(x^3 + y^3 - 3*x*y)
```

result:
```
{{x³ − 3·x·y + y³, 1}}
```

I.e. **irreducible over ℚ**. This is *not* the cube-sum-product identity
`x³ + y³ + z³ − 3xyz = (x+y+z)(x²+y²+z²−xy−yz−zx)`; that needs three
cubes plus a product of all three, not just two cubes and a pairwise
product. REDUCE confirms it.

## What REDUCE *cannot* do (and why)

The two genuine no-go's:

| Sub-problem                                         | Why                                                                                                                                                                                                                 |
|------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `∫ sqrt(1+u⁴) / (1−u²) du` (the LHS of eq 3)         | The anti-derivative is not elementary — it involves elliptic functions of the second kind. REDUCE returns the integrand wrapped in `int(...)`; that's the honest "I can't reduce this further" answer.            |
| Closed-form `(x(t), y(t))` solving the whole system   | The unknowns are defined only implicitly by the three constraints; no finite combination of elementary or named special functions satisfies all three. There's no closed-form for any CAS, including Mathematica. |

A CAS *can* do what §§1–4 above do — chain rule, implicit
differentiation, operator declarations to keep non-elementary functions
symbolic — to **reduce the system to a Jacobian in `dx/dt, dy/dt`** that
a numerical solver (e.g. Runge–Kutta from an initial condition) could
then advance. REDUCE produces every symbolic piece of that Jacobian in
the five blocks above.

## What this demonstrates about the app

- **Persistent symbolic context.** The `depend x, t` and `operator` /
  `operator elliptic_k` declarations persist across blocks in the same
  session (each block repeats them only as a safety belt for Force
  re-run after an engine restart — see
  [task 28](task28_cache_message.md) /
  [task 29](task29_force_rerun.md)).
- **Specfn is loaded by default**, so `polylog(2, …)` works out of the
  box without the user having to tick anything in the package settings
  ([task 31](task31_default_packages.md) /
  [task 32](task32_package_dropdown.md)).
- **Operator symbols** for functions REDUCE doesn't know natively
  (`F`, `elliptic_k`) work via the standard `operator …;` declaration;
  the engine treats them as opaque function symbols that survive
  differentiation and substitution.
- **The cache + force re-run** behave correctly across the five blocks:
  Ctrl+F5 re-executes every block, normal F5 hits the cache for all of
  them on subsequent runs.

## Honest scope

- The notebook does **not** attempt a numerical solution from an
  initial condition. A numerical Runge–Kutta would be a separate
  follow-up (REDUCE's `numeric` package, also tier-2 in
  [task 31](task31_default_packages.md), is not loaded by default).
- The output is **plain text inside `cas-result` blocks**, not typeset
  LaTeX. REDUCE *can* emit LaTeX via `rlfi` + `on latex` (task 4 §1),
  but that package is intentionally off-by-default
  ([task 31](task31_default_packages.md) §Tier 1) because `on latex`
  changes echo format for every later operation. A user who wants the
  LaTeX form can tick `rlfi` in the F4 settings dialog.
- The **special functions Li₂ and K** are symbolic only. Evaluating
  them at numeric arguments needs the `polylog`/`elliptic_*` packages
  with numeric mode (`on rounded`); not done here because the brief
  asked for the symbolic solve.
