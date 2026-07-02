# Task 265 — Implement the Remaining Math Rendering (BBCode 2-D)

## Request

> "Implement the remaining and do 1 doc."

"The remaining" after [task 264](task264_implement_math_fonts.md) (Phase 1: font
fallback + Unicode symbol map) is, from the [263 plan](task263_implement_requirements.md):
bundling a font file (**MR-F1 finish**), **BBCode 2-D** (MR-S3/S4), structured
LaTeX/SVG (MR-S5/Q1, Phase 2), and the liveness/frontier tiers (Phases 3–4). Of
these, the tractable-now piece is **BBCode 2-D**; the font bundle is blocked on
downloadable assets, and SVG/liveness are large Phase-2+ builds. So this task
implements the BBCode 2-D layer.

## What was implemented — matrices render as grids (MR-S4)

The result cells now have **`bbcode_enabled = true`** and route their text through a
new **`MathFormatter.to_bbcode()`** applied at *display time only* (the saved `.md`
keeps the clean Unicode form — `bbcode` is a rendering concern, not stored data):

- **Matrices → `[table]` grids.** REDUCE prints a matrix in the engine's `off nat`
  linear mode as `mat((r1c1,r1c2),(r2c1,r2c2))`. `to_bbcode` parses that with a
  balanced-paren / depth-aware comma splitter (so nested calls like `sin(t)` in a
  cell stay intact) and emits a `[table=cols]…[cell]…[/cell]…[/table]` grid.
- **Literal `[` escaped** (`[` → `[lb]`) before any tags are injected, so a stray
  bracket in a result can never be mis-parsed as BBCode.

**Result:** `mat((1,2),(3,4)) * mat((5,6),(7,8))` now renders as a real
**2×2 grid**

```
19  22
43  50
```

instead of the flat `mat((19,22),(43,50))` (`app_screenshot_task265.png`).

## What is NOT possible here — `[sup]`/`[sub]` (a Godot limitation)

The plan's MR-S3 (multi-character super/subscripts via `[sup]`/`[sub]`) turned out
**not achievable in Godot 4.6.3**: unlike `[table]`, the engine's `RichTextLabel` has
**no built-in `[sup]`/`[sub]` BBCode tags** — they render as literal text
(`x[sup]n[/sup]`). So multi-character exponents keep the **readable caret form**
`x^(n+1)` (numeric exponents remain Unicode superscripts from task 264, which work).
Verified in-app: `df(x^(n+1),x)` shows `x^n·(n + 1)`, cleanly. True raised scripts
need a newer Godot, a custom `RichTextEffect`, or the LaTeX→SVG path (Phase 2).

## Verification

- **Unit tests** (`--test126`): **149 / 149 pass, exit 0** — 6 new for `to_bbcode`:
  2×2 and 3-col matrices → `[table]`, a matrix with expression cells (nested commas
  safe), literal-bracket escaping, multi-char exponent kept as caret, and plain
  results passing through unchanged.
- **In-app** (`--demo-264`, `app_screenshot_task265.png`): the matrix product renders
  as a stacked grid; the symbolic-exponent result shows the clean caret (no literal
  BBCode tags leaking through).

## Still remaining (per task 263)

- **MR-F1 finish** — bundle JuliaMono/STIX (+ OFL) for machines without Cambria Math
  (blocked here on obtaining the font files).
- **MR-S3** — true `[sup]`/`[sub]`: a custom `RichTextEffect` or the SVG path.
- **MR-S5 / Q1 (Phase 2)** — structured LaTeX/MathML from REDUCE → KaTeX/Typst → SVG,
  cached + worker-rendered.
- **MR-L\* / M\* (Phases 3–4)** — animation, validation, reactivity, export, frontier.

## Files changed
- `app/scripts/math_formatter.gd` — `to_bbcode()` + `_matrices_to_bbcode`,
  `_rows_to_table`, `_split_top_commas`.
- `app/scripts/notebook_view.gd` — result cell `bbcode_enabled = true` + text routed
  through `MathFormatter.to_bbcode(...)`.
- `app/scripts/_test126.gd` — 6 new assertions (now 149/149).
- `app/notebooks_sample/task264_symbols.md` — matrix + exponent demo sections.
