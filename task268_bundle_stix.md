# Task 268 — Bundle the Downloaded Math Font (STIX Two Math)

## Request

> "Both fonts STIX and Julia Mono are in the folder `i:\fonts`. Use that and do 1 doc."

This finishes **MR-F1** — the bundled math font that tasks 264/266 had to defer for
lack of a downloadable file. The user placed the fonts in `i:\fonts`; I bundled the
usable one.

## What was in `i:\fonts`

- **STIX** (`i:\fonts\stixfonts`) — the full stixfonts repo. The usable, modern math
  face is **`archive/STIXv2.0.2/OTF/STIX2Math.otf`** (STIX Two Math, ~789 KB,
  OpenType, **SIL OFL 1.1**, `OFL.txt` at the repo root). ✅ used.
- **JuliaMono** (`i:\fonts\juliamono`) — a **broken / incomplete git clone** (only a
  `.git` skeleton with an unfinished pack; `git log` reports "your current branch
  appears to be broken", and there is **no built `.ttf`**). ❌ unusable, so it was
  skipped. (Re-clone or download a JuliaMono release to add it later — the wiring
  below makes that a one-line change.)

## What was done

1. **Bundled the font.** Copied into the project:
   - `app/fonts/STIXTwoMath-Regular.otf` (the STIX Two Math OpenType file)
   - `app/fonts/OFL.txt` (its SIL Open Font Licence — required when shipping)

2. **Wired it as the primary math fallback** (`FontConfig`). `math_font()` now loads
   the bundled font **at runtime** via `FontFile.load_dynamic_font(res://fonts/…)` —
   which needs **no import-cache regeneration** — and puts it **first**, backed by the
   system math fonts:

   ```
   user's family  →  STIX Two Math (bundled)  →  Cambria/STIX/Noto/DejaVu (system)
   ```

   Because every font point routes through `FontConfig.font_resource()` (cells, tree,
   labels, toolbar, base theme), math symbols now resolve through the **bundled** STIX
   on **any** machine — Linux/mac/Windows-without-Cambria included. If the bundled
   file is ever missing, it degrades gracefully to the system-only chain.

3. **Shipped it in the installer.** `mathdot.iss` `[Files]` now installs
   `app/fonts/*` to `{app}\fonts` (font + licence), so an installed copy carries the
   guaranteed coverage.

## Verification

- **Unit tests** (`--test126`): **155 / 155 pass, exit 0** — updated/added: the
  bundled `STIXTwoMath-Regular.otf` **is present**, `math_font()` resolves non-null,
  and `font_resource("matlab")` carries the math fallback.
- **In-app** (`--demo-264`, `app_screenshot_task268.png`): the full symbol row
  `√ ∫ ∑ ∏ ∂ ∇ ≤ ≥ ≠ ≈ → ⇒ ∞ … ℝ ℂ ℤ` renders with **zero tofu**, now in STIX Two
  Math's distinct serif-math style — and stderr shows **no font-load error**
  (`load_dynamic_font` succeeded).

## Result vs the plan

- **MR-F1 (bundle a math font): DONE** — STIX Two Math (OFL) is bundled, wired, and
  shipped; coverage no longer depends on the OS having Cambria Math.
- JuliaMono (monospace primary) remains optional — its checkout was broken; adding it
  later is a one-line change to `BUNDLED_MATH_FONT` / the fallback list.
- Still remaining: Phase 2+ (structured LaTeX/MathML → SVG, liveness/frontier), per
  task 263.

## Files changed
- **New:** `app/fonts/STIXTwoMath-Regular.otf`, `app/fonts/OFL.txt`.
- `app/scripts/font_config.gd` — `BUNDLED_MATH_FONT`; `math_font()` loads the bundled
  STIX (runtime `load_dynamic_font`) as the primary fallback, system fonts behind it.
- `mathdot.iss` — ship `app/fonts/*`.
- `app/scripts/_test126.gd` — bundled-font-present + resolves assertions (now 155/155).
