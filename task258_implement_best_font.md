# Task 258 — How to Implement the Best-Font Math Rendering (blueprint)

Follow-on to [task 257](task257_math_symbol_fonts.md). That doc chose the fonts and
method; this one is the **concrete, file-by-file implementation plan** for mathdot —
exact code, install/build steps, and how to verify. (Per the task it is written as a
blueprint; the edits are ready to apply as a follow-up.)

**Goal:** every math glyph (`∫ ∑ ∂ ∇ √ ≤ ≥ ≠ → ℝ ℂ ℤ` …) renders — never tofu (□) —
in a **math-complete font**, with the user's chosen family kept for prose. Chosen
font: **JuliaMono** (monospace, matches the CAS look) as the math primary/fallback,
with **STIX Two Math** optional for a textbook look and **Noto Sans Math** as the
final gap-filler.

## Step 0 — Acquire + bundle the font (SIL OFL, redistributable)

1. Download `JuliaMono-Regular.ttf` (+ `-Bold`) and `NotoSansMath-Regular.ttf`
   (both **SIL Open Font License** — free to bundle/ship).
2. Put them in **`app/fonts/`** and commit them.
3. Godot imports `.ttf` → a `FontFile` resource automatically (a `*.ttf.import`
   sidecar appears in `.godot/`).

## Step 1 — `font_config.gd`: bundle + build a fallback chain

Load the bundled faces once and expose them; attach them as **fallbacks** so any
glyph the primary font lacks resolves to the math font.

```gdscript
# --- add near the top of FontConfig ---
const MATH_PRIMARY := "res://fonts/JuliaMono-Regular.ttf"     # math-complete, monospace
const MATH_FALLBACK := "res://fonts/NotoSansMath-Regular.ttf" # last-resort symbol gap-filler

static var _math_font: FontFile          # cached
static var _math_fallback: FontFile

static func math_font() -> FontFile:
	if _math_font == null:
		_math_font = load(MATH_PRIMARY)
		_math_fallback = load(MATH_FALLBACK)
		if _math_font and _math_fallback:
			_math_font.fallbacks = [_math_fallback]   # JuliaMono → Noto Sans Math
	return _math_font

# --- in font_resource(): attach the math fallback to every family ---
static func font_resource(family_key: String) -> Font:
	var mf := math_font()
	for f in FAMILIES:
		if f["key"] != family_key:
			continue
		var names: Array = f["names"]
		if names.is_empty():
			return null                      # "Default" → theme font (handled in Step 2)
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray(names)
		if mf:
			sf.fallbacks = [mf]              # user's font → JuliaMono → Noto Math
		return sf
	return null
```

Now whichever family the user picks (Courier New, Inter, …), missing math glyphs
fall through to JuliaMono and then Noto Sans Math — **the tofu disappears app-wide**
with no other change.

## Step 2 — cover the "Default" family and the base theme

The "Default" family returns `null` (use the theme font), and the toolbar/base UI is
themed in `main.gd`. Attach the math fallback there too so those paths are covered:

```gdscript
# main.gd, in the theme setup (near t.default_font = matlab_font)
var mf := FontConfig.math_font()
if matlab_font is SystemFont and mf:
	(matlab_font as SystemFont).fallbacks = [mf]
```

`notebook_view._resolve_bold_font()` already routes through `font_resource()`, so its
result inherits the fallback automatically — no change needed there.

## Step 3 — render *math* cells in the math font (optional, best look)

For the strongest math typography, use the math font as the **primary** for the
result cells (the rendered CAS output) while prose/editor keep the user's font.
In `_font_apply()` / the result-cell path (`res_text`, a `RichTextLabel`):

```gdscript
# for result / rendered-math cells only:
res_text.add_theme_font_override("normal_font", FontConfig.math_font())
```

(Everything else keeps `_font_resource`, i.e. the user's family with the math
fallback.)

## Step 4 — `math_formatter.gd`: widen the Unicode map

Extend `to_display()` so the linear CAS form gets real symbols, not ASCII:

```gdscript
const _SUB := {"0":"₀","1":"₁","2":"₂","3":"₃","4":"₄","5":"₅","6":"₆","7":"₇","8":"₈","9":"₉"}
const _OPS := {
	"<=":"≤", ">=":"≥", "/=":"≠", "!=":"≠", "->":"→", "=>":"⇒",
	"infinity":"∞", "inf":"∞", "*":"·", "-":"−",
}
const _WORDS := {          # apply on word boundaries only
	"int":"∫", "sum":"∑", "prod":"∏", "sqrt":"√", "partial":"∂", "nabla":"∇",
	"alpha":"α","beta":"β","gamma":"γ","delta":"δ","theta":"θ","lambda":"λ",
	"mu":"μ","pi":"π","sigma":"σ","phi":"φ","omega":"ω","Omega":"Ω","Delta":"Δ",
}
```

- Keep the existing `^digits → ¹²³` pass; **add** `^(-digits)` and `^(…)` handling,
  and a **subscript** pass `_digit → ₀₁₂` using `_SUB`.
- Replace two-char operators (`_OPS`) before the single-char `*`/`-` passes.
- Replace `_WORDS` only when the token is a whole identifier (regex `\b`), so `sqrt`
  → `√` but `sqrt_x` is untouched.

Each of these is a small, testable string transform — no engine round-trip.

## Step 5 — turn on BBCode for light 2-D (scripts, matrices, fractions)

The result `RichTextLabel` currently sets `bbcode_enabled = false`. Enable it and
emit structure where the CAS output has it:

```gdscript
res_text.bbcode_enabled = true
# scripts:            x[sup]2[/sup] , a[sub]ij[/sub]
# fraction (stacked): [table=1][cell]num[/cell][cell]─────[/cell][cell]den[/cell][/table]
# matrix:             [table=cols] … [cell]e[/cell] … [/table]
```

Godot 4's `RichTextLabel` supports `[sup]`/`[sub]`/`[table]`/`[cell]`/`[font_size]`,
so `∑`/`∫` can be enlarged with `[font_size=…]` and matrices laid out with a table —
no external engine. (Escape any literal `[` in expressions first.)

## Step 6 — ship the font in the installer + rebuild

- **`mathdot.iss`** — add the fonts to `[Files]` so they install:
  ```
  Source: "{#SourceDir}\fonts\*"; DestDir: "{app}\fonts"; Components: app; Flags: ignoreversion recursesubdirs
  ```
- Regenerate the `.godot` cache (`Godot … --path app --import`) so the new
  `*.ttf.import` entries ship, then rebuild the installer — exactly the flow from
  [task 254](task254_rebuild.md).

## Verification plan

- **Unit tests** (`_test126.gd`):
  - `FontConfig.math_font()` returns a `FontFile` with a non-empty `fallbacks`.
  - `FontConfig.font_resource("matlab")` returns a `SystemFont` whose `fallbacks`
    contains the math font.
  - `MathFormatter.to_display("int(f,x)")` contains `∫`; `"a<=b"` → `≤`; `"x_1"` → `x₁`;
    `"x^(-2)"` → `x⁻²`.
- **Visual:** open a notebook whose results contain `∫ ∑ ∂ ∇ ≤ ℝ` and confirm **no □
  tofu** in any user-selectable family; check a matrix/fraction renders stacked with
  BBCode on.
- **Build:** `--test126` green, then rebuild app + installer (task 254 flow) and
  confirm the fonts land under `{app}\fonts`.

## Risks / notes

- **TextServer must be Advanced** (the default in Godot's editor + export templates)
  for correct shaping/fallback — verify the bundled runtime isn't a stripped build.
- **Monospace vs textbook:** JuliaMono keeps the fixed-width CAS feel; swap the
  primary to **STIX Two Math** in `MATH_PRIMARY` for a proportional textbook look
  (same wiring).
- **License:** JuliaMono / Noto / STIX are all SIL OFL — include their `OFL.txt` in
  `app/fonts/` and the docs component.
- **Scope:** Steps 1–2 (bundle + fallback) are the 80/20 win and are low-risk; Steps
  3–5 (math-primary result cells, wider symbol map, BBCode 2-D) are incremental polish.

## Files
- This doc only. The blueprint touches `app/fonts/*` (new), `font_config.gd`,
  `main.gd`, `notebook_view.gd`, `math_formatter.gd`, `mathdot.iss`, and `_test126.gd`
  when implemented.
