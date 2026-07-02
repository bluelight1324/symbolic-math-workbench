# Task 269 — Displaying STIX Two Math in the Best Possible Manner

STIX Two Math is now bundled ([task 268](task268_bundle_stix.md)) — but it's wired as a
*fallback* (symbols only) with default rendering. This doc is the plan to make it
display at its best: as a real math font, with the right typography and Godot render
settings. (A doc; the edits are the follow-up.)

## Where it is now, and the gap

- STIX only fills in glyphs the user's family lacks, so an expression mixes **Courier
  New variables** with **STIX symbols** — two designs, two baselines, inconsistent.
- It renders with Godot's *default* FontFile settings (no MSDF, default hinting), and
  none of STIX's math OpenType features are enabled.

Five levers close the gap: **who uses it, italics, features, render settings, and
size.**

## 1. Use STIX as the PRIMARY font for math cells (not just a fallback)

The single biggest improvement. Keep the user's chosen font for **prose and the
editor**, but render the **result cells** (the actual mathematics) *entirely* in STIX
Two Math:

```gdscript
res_text.add_theme_font_override("normal_font", FontConfig.math_font())
```

Now every glyph of an expression — variables, numbers, operators, symbols — comes from
one coherent, professionally-designed math face with a single baseline and consistent
metrics. That is what makes it read like a textbook rather than a patchwork.

## 2. Real math italics via Unicode Mathematical Alphanumerics

Mathematical convention: single-letter **variables are italic**, **function names
upright** (`sin`, `log`), **numbers upright**. STIX contains purpose-designed glyphs
for this in the Unicode **Mathematical Alphanumeric** blocks. So map lone variable
tokens to the italic block in `MathFormatter`:

- `x` → `𝑥` (U+1D465 MATHEMATICAL ITALIC SMALL X), `A` → `𝐴` (U+1D434), … (skip `i`,
  `e`, `d` if used as constants/operators, and skip multi-letter identifiers like
  `sin`).

STIX renders these as its true math italics — far better than faux-slanting an upright
glyph, and semantically correct. (`[i]…[/i]` BBCode is a cheaper fallback, but the
Unicode block is the right answer with STIX.)

## 3. Enable STIX's math OpenType features (`FontVariation`)

Wrap the font in a `FontVariation` and turn on the features STIX ships for math:

```gdscript
var fv := FontVariation.new()
fv.base_font = FontConfig.math_font()
fv.opentype_features = {
    "ssty": 1,   # Math Script Style — proper smaller glyph forms for super/subscripts
    "dtls": 1,   # Dotless forms (for accents over i/j in math)
    "flac": 1,   # Flattened accents over tall symbols
    "kern": 1, "liga": 1,
}
```

`ssty` in particular pairs with the task-266 superscript effect so raised glyphs use
STIX's *designed* script shapes, not just a shrunk regular glyph.

## 4. Tune the Godot FontFile render settings for STIX

STIX is a fine-stroke CFF/serif face; defaults can make it look thin or fuzzy. Set on
the bundled `FontFile`:

```gdscript
var f := FontConfig.math_font()          # the bundled FontFile
f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY   # (LCD if targeting LCD screens)
f.hinting = TextServer.HINTING_LIGHT                 # CFF math fonts prefer light/none
f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
f.oversampling = 0.0                                  # auto — sharp at the shown size
```

**And for mathdot specifically — MSDF.** Because the notebook **zooms** (plots and
results scale), render STIX from a **multi-channel signed-distance field** so glyphs
stay razor-sharp at any zoom/DPI instead of re-rasterising or blurring:

```gdscript
f.multichannel_signed_distance_field = true
f.msdf_pixel_range = 8
f.msdf_size = 48
```

MSDF is the same crisp-at-any-scale trick the plots want; here it makes zoomed
equations stay clean.

## 5. Size big operators to STIX's display forms

STIX draws `∑ ∫ ∏ ⋀` at multiple optical sizes. Godot won't pick the display variant
automatically (no MATH-table layout), so **bump the font size** of a large operator in
"limits" context (`[font_size=+N]∑[/font_size]`) so it visually dominates its operands
— approximating the display-vs-inline distinction TeX makes.

## 6. Keep metrics coherent (don't mix fonts mid-expression)

Mixing STIX with the UI font inside one expression causes baseline/height mismatch.
Recommendation §1 (all-STIX result cells) already solves this; for any inline math in
prose, wrap the whole run in STIX rather than only its symbols.

## The ceiling (needs the SVG path)

STIX's real superpower — the OpenType **MATH table**: stretchy delimiters that grow
with content, radicals with proper vinculum, nested-script optical sizes, big-operator
limit stacking. Godot doesn't execute that table. To use it fully, render via the
**LaTeX→SVG (KaTeX/Typst)** route from [task 259](task259_improve_math_rendering.md),
which *does* do MATH-table layout and produces true STIX typesetting. Items 1–5 above
are the best that native Godot text can do; the SVG path is the rest.

## Priority

1. **STIX as primary for result cells** (§1) — biggest visible win, ~1 line.
2. **MSDF + render tuning** (§4) — crisp, correct weight at any zoom.
3. **Math italics** (§2) and **OpenType features** (§3) — textbook correctness.
4. **Big-operator sizing** (§5); full MATH-table layout via SVG (the ceiling).

## Files
- This doc only (task 269 asks *how* — no code changed). §1–§5 are the concrete
  follow-up edits to `notebook_view.gd`, `font_config.gd`, and `math_formatter.gd`.
