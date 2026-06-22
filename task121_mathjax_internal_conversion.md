# Task 121 — Can mathdot Convert a MathJax Problem Internally?

## Question

> "How will it do a problem given in MathJax? Can it be converted internally?"

A follow-up to task 120. Does mathdot have any **built-in LaTeX/MathJax → REDUCE**
translation, so you could paste `\int_0^x (x-t)f(t)\,dt` and have it run?

## Answer: No — there is no internal LaTeX-input conversion today.

I searched the whole app (`app/scripts`, `app/autoload`). There is **no** LaTeX
or MathJax *input* parser anywhere — no `parse_latex`, no `latex_to_reduce`, no
`\int`/`\frac` handling. A `cas` block is sent to REDUCE **verbatim**, so it must
already be REDUCE syntax.

### The one LaTeX feature that exists is *output*, not input

REDUCE ships an `rlfi` package ("LaTeX output via `on latex`",
[package_config.gd:31](app/scripts/package_config.gd#L31)). It makes REDUCE
*print results as* LaTeX. It does **not** read LaTeX. mathdot deliberately leaves
it **off** by default ([math_engine.gd:138](app/autoload/math_engine.gd#L138) —
`off latex` is even skipped because the switch only exists once `rlfi` is
loaded). So the only LaTeX in the system flows **outward** (CAS → LaTeX), never
inward (LaTeX → CAS).

## So how do you "do" a MathJax problem? — translate it (task 120)

You convert the LaTeX to REDUCE syntax by hand, e.g.:

| MathJax | REDUCE (what mathdot runs) |
|---|---|
| `\int_{a}^{b} g(t)\,dt` | `int(g(t), t, a, b)` |
| `\frac{a}{b}` | `(a)/(b)` |
| `x^{n}` | `x^n` |
| `\sin x`, `\lambda`, `\infty` | `sin(x)`, `lambda`, `infinity` |
| `f''(x)` | `df(f(x), x, 2)` |

This is exactly the translation done in task 120.

## Could it be converted internally? — yes, but it's a real feature, not a flag

A LaTeX→REDUCE **preprocessor** is feasible and would be the natural enhancement:
a pass over the `cas` block that rewrites a useful subset of LaTeX
(`\int_a^b…\,dx`, `\frac`, `^{}`, `\sin`/`\cos`/`\sqrt`, `\cdot`, `\left(`/`\right)`,
Greek names) into REDUCE before sending it to the engine.

Caveats that make it a scoped project rather than a quick switch:

- **LaTeX is ambiguous for a CAS.** `\int f\,dx` names its variable by the `dx`;
  `f(t)^3` vs `f(t^3)`; implicit multiplication (`2x`, `\sin x`) all need rules.
- **It would be a *subset*.** Full LaTeX (matrices, cases, custom macros) is out
  of scope; the translator would cover common calculus/algebra notation and
  reject the rest with a clear message.
- **Round-trip nicety:** since `rlfi` already emits LaTeX, a paired importer would
  let a notebook read and write the same notation.

## Conclusion

- **Now:** mathdot does **not** convert MathJax internally — you translate to
  REDUCE syntax (task 120). REDUCE's only LaTeX capability is *output* via `rlfi`.
- **Possible:** an internal LaTeX→REDUCE preprocessor is a sensible, self-contained
  feature to add later; it would cover a practical subset, not all of LaTeX.

## Files changed
- None — investigation + explanation (no code change requested).
