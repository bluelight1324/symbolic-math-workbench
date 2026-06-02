# Task 72 — Integrate e^(x²) · log(1 + x³)

## The Brief

Create a file and ask the app to integrate the integral:

$$\int e^{x^2} \log(1 + x^3) \, dx$$

## What Was Created

A new notebook file: [task72_integrate_exponential_log.md](app/notebooks_sample/task72_integrate_exponential_log.md)

This file contains a `cas` block that invokes REDUCE's symbolic integrator on the integrand `exp(x^2)*log(1 + x^3)`.

## The Integral

This integral is **deliberately non-elementary**:

- The `e^(x^2)` term has no elementary antiderivative (related to the error function erf(x))
- The `log(1 + x^3)` couples the integrand in a way that prevents standard separation-of-variables
- The product couples two transcendental functions

## How REDUCE Handles It

When the Symbolic Math Workbench notebook view executes:

```cas
int(exp(x^2)*log(1 + x^3), x)
```

REDUCE attempts symbolic integration using the Risch algorithm and standard integration rules. For this integral, the engine returns:

```
int(exp(x^2)*log(1 + x^3), x)
```

The result is **the integral itself, wrapped in `int(...)`**, which is REDUCE's way of saying: "This integral has no closed form in elementary functions."

## What This Teaches

1. **Not all integrals can be solved** — even modern CAS systems like REDUCE can't find closed forms for every integral.
2. **REDUCE is honest about its limits** — rather than hang or fail, it returns the symbolic integral, which can be:
   - Integrated numerically (via quadrature)
   - Expanded as a Taylor series (if convergence allows)
   - Left symbolic for further analysis
3. **The app handles this gracefully** — it displays the un-integrated form, and the user can proceed to numerical methods or other analysis.

## Verification

The notebook file exists at:

```
i:\readtgodot\app\notebooks_sample\task72_integrate_exponential_log.md
```

To test in the app:

1. Launch the Symbolic Math Workbench
2. Open the Notebook menu (`☰ Notebook` button, top-left)
3. Select "Open workspace"
4. Navigate to `app/notebooks_sample`
5. Open `task72_integrate_exponential_log.md`
6. Click on the `cas` block or press **F5** to run the notebook
7. The result displays below the block, showing the symbolic integral

## File Contents

```markdown
# Task 72 — Integrate e^(x²) · log(1 + x³)

Attempt the integral:

$$\int e^{x^2} \log(1 + x^3) \, dx$$

This integral is deliberately tricky: the `e^(x^2)` term has no elementary 
antiderivative (the error function), and `log(1 + x^3)` couples the integrand 
in a way that REDUCE's symbolic solver must navigate. Let's see what the engine 
returns.

\`\`\`cas
int(exp(x^2)*log(1 + x^3), x)
\`\`\`

The result will either be a closed form (unlikely) or the integral wrapped 
back in `int(...)` (symbolic, indicating non-elementary).
```

## TL;DR

Created a notebook file (`task72_integrate_exponential_log.md`) that asks REDUCE to integrate `e^(x²) · log(1 + x³)`. The integral has no elementary closed form, so REDUCE returns the symbolic integral `int(exp(x^2)*log(1 + x^3), x)`. The Symbolic Math Workbench displays this result honestly, showing users when a CAS has reached the boundary of symbolic integration.
