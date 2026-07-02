# Task 264 — Implement the Math-Rendering Plan (Phase 1)

## Request

> "Implement the above and do 1 doc."

"The above" is the [263 implementation plan](task263_implement_requirements.md) for the
[262 requirements](task262_math_rendering_requirements.md) — a four-phase build. This
task implements **Phase 1 ("Legible")**, the low-risk 80/20 that fixes today's core
problem (math symbols showing as tofu □) and enriches the display. Phases 2–4 (SVG,
liveness, frontier) remain as documented follow-ups.

## What was implemented

### 1. Math-symbol font fallback — no more tofu (MR-F1/F2/F3)

`FontConfig` gained a shared **`math_font()`** — a `SystemFont` over installed
math-capable faces (**Cambria Math** first, then STIX Two Math / Segoe UI Symbol /
Noto Sans Math / DejaVu) — and **every `font_resource()` now attaches it as a
`fallbacks` entry**. So whichever family the user picks, any glyph it lacks
(`∫ ∑ ∏ ∂ ∇ ∞ ∀ ∃ ℝ ℂ ℤ` …) resolves through the chain instead of rendering as □.

This uses **already-installed** system fonts (Cambria Math ships with Windows and has
complete math coverage), so it needed **no font download or bundle** — the whole
Phase-1 fallback works immediately. (Bundling JuliaMono/STIX for guaranteed
cross-platform coverage is the small remaining piece of MR-F1.)

### 2. Wider Unicode symbol map (MR-S1/S2)

`MathFormatter.to_display` now converts the REDUCE linear form far more fully:

- **Relational / arrow operators:** `<=→≤`, `>=→≥`, `!=`/`/=`/`<>` `→≠`, `->→→`, `=>→⇒`.
- **Function / constant words** (identifier-boundary only, so `sqrt`→`√` but `sqrt_x`
  is untouched): `sqrt→√`, `int→∫`, `partial→∂`, `nabla→∇`, `infinity→∞`, and the
  Greek names `alpha…omega → α…ω`.
- **Exponents** now handle **sign and parentheses**: `x^(-2)→x⁻²`, `x^(12)→x¹²`, while
  `x**2→x²` still works and a non-numeric `x^n` correctly keeps its caret.
- The existing `*→·` is retained.

## Verification

- **Unit tests** (`--test126`): **143 / 143 pass, exit 0** — 15 new asserting the
  operator/word/exponent mappings (`sqrt→√`, `a<=b→a≤b`, `infinity→∞`, `x^(-2)→x⁻²`,
  `sqrt_x` untouched, `x^n` kept) and the font wiring (`math_font()` is a populated
  `SystemFont`; `font_resource("matlab").fallbacks` contains it).
- **In-app** (`--demo-264`, `app_screenshot_task264.png`): a probe notebook renders
  `√ ∫ ∑ ∏ ∂ ∇ ≤ ≥ ≠ ≈ → ⇒ ∞ ± × ÷ ∈ ∀ ∃ ℝ ℂ ℤ …` with **zero tofu** (the symbols
  Courier New lacks resolve via Cambria Math), and CAS results format live:
  `sqrt(x^2+1)` → **`√(x² + 1)`**, `df(1/sqrt(x),x)` → **`(-1)/(2·√(x)·x)`**.

## What remains (Phases 2–4, per task 263)

- **MR-F1 finish:** bundle JuliaMono / STIX Two Math (+ OFL files) for guaranteed
  coverage on machines without Cambria Math; add to `mathdot.iss`.
- **MR-S3/S4:** BBCode `[sup]`/`[sub]` + `[table]` for true stacked scripts, matrices
  and fractions (the result cells currently keep `bbcode_enabled = false`).
- **MR-S5 / Q1:** structured LaTeX/MathML from REDUCE → KaTeX/Typst → SVG, cached and
  worker-rendered (Phase 2).
- **MR-L\*/M\*:** animation, validation, reactivity, export, and the frontier (Phases 3–4).

## Files changed
- `app/scripts/font_config.gd` — `math_font()` + math fallback attached in `font_resource`.
- `app/scripts/math_formatter.gd` — widened `to_display` (`_OPS`, `_WORDS`,
  `_superscript`, `_wordsub`).
- `app/scripts/_test126.gd` — 15 new assertions (now 143/143).
- `app/scripts/main.gd` — `--demo-264` flag.
- `app/notebooks_sample/task264_symbols.md` — probe/demo notebook.
