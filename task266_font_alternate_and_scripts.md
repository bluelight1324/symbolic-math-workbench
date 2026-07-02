# Task 266 — Next-Best Font Alternate + Completing the Scripts

## Request

> "If JuliaMono is blocked use the next best alternate and complete the rest."

Bundling **JuliaMono** was blocked in tasks 264/265 (no redistributable `.ttf`
obtainable offline; the only local math font, **Cambria**, is Microsoft-proprietary
and cannot be shipped). This task takes the **next-best alternate** for coverage and
**completes the remaining** script rendering.

## 1. Next-best alternate — a robust cross-platform math fallback

Instead of a bundled file, use each platform's **best already-installed math font**,
tried in priority order. `FontConfig.MATH_FALLBACK_NAMES` grew from Windows-centric to
truly cross-platform:

- **Windows:** Cambria Math (full coverage, universal), Segoe UI Symbol, Segoe UI Historic
- **macOS:** STIX Two Math, STIXGeneral, Apple Symbols
- **Linux / cross-platform (OFL/permissive):** Noto Sans Math, Noto Sans Symbols 2,
  DejaVu Sans, Symbola
- generic last resort: Segoe UI, sans-serif

Every family from `FontConfig.font_resource()` carries this chain as its `fallbacks`,
and **every font application point routes through `font_resource`** — the notebook
cells, the sidebar tree, the labels, the toolbar (`IconMenuBar._get_bold_font`) and
the base theme (`main.gd` `t.default_font`). So a math glyph the chosen family lacks
resolves through the OS's math font on **any** mainstream platform, with **no bundled
file** — the alternate fully satisfies the no-tofu goal (MR-F1/F2/F3) that JuliaMono
was meant to.

## 2. Completed the rest — real `[sup]`/`[sub]` via a custom effect

Task 265 found that multi-character exponents couldn't raise because **Godot 4.6's
RichTextLabel has no built-in `[sup]`/`[sub]` tag**. This task supplies them as
**custom `RichTextEffect`s** (`rt_superscript.gd`, `rt_subscript.gd`): each shrinks
the glyphs in its range (scale 0.7) and offsets them up / down. They're installed on
every result cell (`install_effect`), so `MathFormatter.to_bbcode` can once again emit
`[sup]…[/sup]` for symbolic exponents — and they **actually raise** now.

**Result:** `df(x^(n+1), x)` renders as `x` with a smaller, lifted **superscript `n`**
followed by `·(n + 1)` (`app_screenshot_task266.png`) — completing MR-S3 that 265 had
to leave as a caret. Matrices still render as `[table]` grids (task 265).

> Note: the effects are loaded with `preload(...).new()` (not the global `class_name`)
> so they work without regenerating the `.godot` class cache — the same pattern used
> for `complex_eval.gd`.

## Verification

- **Unit tests** (`--test126`): **154 / 154 pass, exit 0** — 6 new: `to_bbcode`
  emits `[sup]` for `x^(n+1)` / `x^n` / `x^n+1` (raising only `n`), the two effects
  report their `sup`/`sub` tags, and the fallback list covers Windows+macOS+Linux
  (≥ 8 names incl. Cambria Math, STIX Two Math, DejaVu Sans).
- **In-app** (`--demo-264`): the exponent result shows a true raised superscript; the
  full symbol row and the matrix grid still render with zero tofu.

## What still remains

- **A guaranteed-bundled math font** (JuliaMono/STIX) — still blocked on obtaining a
  redistributable file offline; the cross-platform fallback is the standing alternate.
- **Phase 2+ (task 263):** structured LaTeX/MathML → SVG, and the liveness/frontier
  tiers.

## Files changed
- `app/scripts/font_config.gd` — cross-platform `MATH_FALLBACK_NAMES`.
- `app/scripts/rt_superscript.gd`, `rt_subscript.gd` — **new** `[sup]`/`[sub]` effects.
- `app/scripts/notebook_view.gd` — install the effects on result cells.
- `app/scripts/math_formatter.gd` — `to_bbcode` re-emits `[sup]` (`_superscript_bbcode`).
- `app/scripts/_test126.gd` — 6 new assertions (now 154/154).
- `app/notebooks_sample/task264_symbols.md` — exponent note updated (now raises).
