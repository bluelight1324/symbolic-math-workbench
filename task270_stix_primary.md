# Task 270 — Make STIX Two Math the Primary Math Font

## Request

> "Make STIX the primary font and do 1 doc."

Implements **§1 of [task 269](task269_stix_best_display.md)** — the biggest,
lowest-cost improvement: render the mathematics *itself* in the bundled STIX Two Math
([task 268](task268_bundle_stix.md)), instead of only using STIX as a fallback for
missing symbols.

## The change

Previously the **result cells** rendered in the user's chosen family (Courier New by
default) with STIX filling in only the glyphs Courier lacked — so an expression mixed
two designs and two baselines (Courier variables + STIX symbols).

Now the result-cell `RichTextLabel` gets STIX as its **primary** font:

```gdscript
_font_apply(res_text)                                    # keeps the user's size
res_text.add_theme_font_override("normal_font", FontConfig.math_font())  # STIX primary
```

So **every** glyph of a result — variables, numbers, operators, radicals, matrices,
symbols — comes from one coherent, professionally-designed math face with a single
baseline and consistent metrics. `_font_apply`'s size override is preserved, so the
result font size still tracks the user's setting.

**Scope is deliberately narrow:** only the **result** cells (the actual mathematics)
change. **Prose, the source (`cas`) cells, the editor, and the sidebar tree keep the
user's chosen font** — so the app's overall look is unchanged and only the math reads
like a textbook. (`FontConfig.math_font()` is the bundled STIX with the system math
fonts behind it as a further fallback, so coverage is still total.)

## Verification

- **Unit tests** (`--test126`): **155 / 155 pass, exit 0** — no regressions.
- **In-app** (`--demo-264`, `app_screenshot_task270.png`): result cells now render in
  STIX Two Math — e.g. `( - 1)/(2·√(x)·x)` and the matrix grid `19 22 / 43 50` appear
  in STIX's serif math style, while the surrounding prose and the `cas` source block
  stay in the user's Courier family. Zero tofu; one coherent math face per result.

## What's next (rest of task 269)

STIX is now primary; the remaining display polish from 269 is optional follow-up:
- **§4 render tuning** — MSDF for crisp-at-zoom, `hinting = LIGHT`, antialiasing.
- **§2 math italics** — map variable tokens to the Unicode Mathematical-Italic block
  so STIX draws its designed italics.
- **§3 OpenType features** (`ssty`, `dtls`, `flac`) via `FontVariation`.
- The full MATH-table layout (stretchy delimiters, radicals) remains the SVG-path
  ceiling (task 259).

## Files changed
- `app/scripts/notebook_view.gd` — result cell overrides `normal_font` with
  `FontConfig.math_font()` (STIX) after `_font_apply`.
