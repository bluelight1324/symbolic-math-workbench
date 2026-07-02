# Task 271 — Thorough Test of the Math-Rendering Work

A full verification pass over everything **implemented** in the math-rendering
sequence — tasks **264** (font fallback + Unicode symbol map), **265** (BBCode matrix
grids), **266** (cross-platform fallback + custom `[sup]`/`[sub]` effects), **268**
(bundled STIX Two Math), **270** (STIX as the primary math font). Two layers: unit
tests and integration. **All green.**

## 1. Unit tests — `--test126`: **180 / 180 pass, exit 0**

The harness grew to **180 assertions** (25 new "thorough" checks for 271). Coverage by
implemented feature:

### Symbol map — `MathFormatter.to_display` (task 264)
- **Operators:** `<= ≤`, `>= ≥`, `!= ≠`, `/= ≠`, `<> ≠`, `-> →`, `=> ⇒`.
- **Words / Greek:** `sqrt √`, `int ∫`, `partial ∂`, `nabla ∇`, `infinity`/`infty ∞`,
  `omega ω`, `theta θ`, `pi π` — **whole-word only** (verified `alpha_1` and `sin(x)`
  are left untouched; only exact identifier tokens map).
- **Exponents:** `x**2 → x²`, `x**23 → x²³` (multi-digit), `x^(-3) → x⁻³` (signed,
  parenthesised); a symbolic `x^n` correctly keeps its caret.

### BBCode 2-D — `MathFormatter.to_bbcode` (tasks 265/266)
- **Matrices → `[table]` grids:** 1×1, 2×2, 3-col, **negative** entries, and cells
  holding **nested calls** (`cos(t)`) — the depth-aware comma splitter keeps inner
  commas intact.
- **Superscripts → `[sup]`:** `2^k`, `x^(n+1)`, and `x^n+1` raising **only** `n`.
- **Ordering:** a matrix whose cell has a power (`mat((x^2,1),(0,1))`) yields
  `[cell]x[sup]2[/sup][/cell]` — table first, then superscript, correctly.
- **Escaping:** every literal `[` becomes `[lb]` before any tag is injected; plain
  expressions pass through unchanged.

### Effects + bundled font (tasks 266/268/270)
- Both `rt_superscript.gd` / `rt_subscript.gd` load and are `RichTextEffect`s.
- The bundled **`STIXTwoMath-Regular.otf`** and its **`OFL.txt`** are present; the
  configured path is an `.otf`.
- The **math fallback reaches every family** (spot-checked sans/serif/inter/mono all
  carry it), while the `"default"` family still returns `null` (no override).

### Regression
The full pre-existing suite (LaTeX↔REDUCE, `^→pow`, plotting: surfaces / implicit /
domain / multi-series / PNG export / threaded async, dialogs, menus, …) still passes —
the math-rendering changes touched only the display path.

## 2. Integration — `--demo-264`, **0 errors**

The math-rendering demo notebook ran in a real window:

- **No `SCRIPT ERROR`, no `load_dynamic` font error** — the bundled STIX loads cleanly.
- **Formatted output is correct** end-to-end (engine → formatter → cell):
  - `sqrt(x^2+1)` → **`√(x² + 1)`** (symbol map, task 264)
  - `df(1/sqrt(x),x)` → **`( - 1)/(2·√(x)·x)`**
  - matrix product → **`mat((19,22),(43,50))`**, rendered as a **2×2 grid** (task 265)
  - `df(x^(n+1),x)` → **`x^n·(n + 1)`**, rendered with a **raised superscript** (task 266)

These reproduce the visual confirmations captured across the sequence: the full symbol
row with **zero tofu** (264/268), the **matrix grid** (265), the **raised superscript**
(266), STIX loading with no error (268), and result cells rendered **entirely in STIX**
while prose/source keep the user font (270).

## Findings

- **No defects.** Every implemented feature behaves as designed, including edge cases
  (multi-digit / signed exponents, whole-word-only symbol replacement, negative and
  nested-call matrix cells, bracket escaping, table-then-superscript ordering, the
  `default`-family null path).
- **One known non-goal, not a bug:** true OpenType-MATH-table layout (stretchy
  delimiters, radicals) is out of scope for native Godot text — it's the SVG-path
  ceiling documented in tasks 259/269.

## Files changed
- `app/scripts/_test126.gd` — +25 thorough assertions (now **180/180**).
