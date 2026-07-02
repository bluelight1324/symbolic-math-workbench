# Task 272 — Sample Equations in the New STIX Font (live in the app)

## Request

> "Show some sample equations using the new font by starting the app. Do 1 doc."

I built a showcase notebook, **started the app**, ran it, and captured the equations
rendered in the bundled **STIX Two Math** font (tasks 268/270). Screenshot:
`app_screenshot_task272.png`.

## The showcase — `notebooks_sample/stix_showcase.md` (run with `--demo-272`)

Seven `cas` blocks; each **result** renders entirely in STIX (variables, numbers,
radicals, superscripts, matrices, symbols), while the prose and the `cas` source keep
the monospace UI font:

| Equation | REDUCE result (rendered in STIX) |
|---|---|
| `(x + 1)^5` | `x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1` |
| `sqrt(x^2 + y^2)` | `√(x² + y²)` |
| `int(x^3 + 2*x, x)` | `(x²·(x² + 4))/4` |
| `df(x^n, x)` | `xⁿ·n / x` (the `n` raised via the task-266 effect) |
| `(a + b)^3` | `a³ + 3·a²·b + 3·a·b² + b³` |
| `mat((1,2),(3,4)) * mat((0,1),(1,0))` | a **2×2 grid** `2 1 / 4 3` |
| `solve(x^2 - 5*x + 6, x)` | `{x=3, x=2}` |

In the screenshot the binomial expansion and the radical read like a **textbook** —
serif glyphs, real Unicode superscripts, a proper √ — against the Courier prose/source.

## A bug the showcase caught (and fixed)

Running real equations immediately surfaced a formatting bug: `sqrt(x^2 + y^2)` rendered
as **`√(x² + y²`** — a **missing closing parenthesis**. Cause: `MathFormatter._superscript`
used one greedy regex `\^\(?…\)?`, whose optional trailing `\)?` **ate the `)` that
closes `sqrt(…)`** whenever a numeric exponent sat right before it.

**Fix:** split it into two ordered passes — pass 1 matches only a fully-parenthesised
`^(…)` (consuming both parens), pass 2 matches a bare `^…` (no parens), so a `)`
belonging to an enclosing call is never touched. Now `sqrt(x^2 + y^2)` → `√(x² + y²)`,
`(a^2)` → `(a²)`, `f(x^3)` → `f(x³)`, while `x^(12)` / `x^(-2)` / `x**2` still work.

## Verification

- **Unit tests** (`--test126`): **183 / 183 pass, exit 0** — including **3 new
  regression** checks that a numeric exponent before `)` keeps the paren
  (`sqrt(x^2+y^2)`, `(a^2)`, `f(x^3)`).
- **In-app** (`--demo-272`): all seven results computed and rendered in STIX with no
  errors; the corrected `√(x² + y²)` is visible in `app_screenshot_task272.png`.

## Files changed
- **New:** `app/notebooks_sample/stix_showcase.md` (the showcase notebook).
- `app/scripts/math_formatter.gd` — `_superscript` split into `_sup_pass` two-pass
  (paren-safe) — **bug fix**.
- `app/scripts/main.gd` — `--demo-272` flag.
- `app/scripts/_test126.gd` — 3 new regression assertions (now 183/183).
