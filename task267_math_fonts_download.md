# Task 267 — Math Fonts Available for Download

A reference of math-capable fonts that can be **downloaded and bundled** with mathdot
(to finish MR-F1 from tasks 264/266, where the bundle was blocked only because I
couldn't fetch a file offline). The key column is **licence** — an **OFL / permissive**
font is safe to ship inside the app (include its licence file); a **proprietary** one
(e.g. Cambria Math) is *not*.

## Recommended downloads for mathdot

| Purpose | Font | Licence | Get it from |
|---|---|---|---|
| **Primary — monospace CAS identity** | **JuliaMono** | SIL OFL 1.1 | `github.com/cormullion/juliamono` (releases) |
| **Primary — textbook / journal look** | **STIX Two Math** | SIL OFL 1.1 | `github.com/stipub/stixfonts` · `stixfonts.org` |
| **Universal fallback (gap-filler)** | **Noto Sans Math** (+ **Noto Sans Symbols 2**) | SIL OFL 1.1 | `fonts.google.com/noto` · `github.com/notofonts` |

Drop the `.ttf`/`.otf` into `app/fonts/`, ship the `OFL.txt`, and wire it per the
[258](task258_implement_best_font.md)/[266](task266_font_alternate_and_scripts.md)
plan (bundled `FontFile` → fallback chain, replacing the system-font fallback).

## A. OpenType MATH fonts (full coverage + designed for math)

These carry the OpenType **MATH** table (the LaTeX/journal grade). Godot renders their
*glyphs* beautifully; it doesn't run the MATH-table layout, so use them for glyphs +
your own 2-D markup (see [259](task259_improve_math_rendering.md)).

| Font | Licence (bundle?) | Download | Notes |
|---|---|---|---|
| **STIX Two Math** | OFL ✓ | `github.com/stipub/stixfonts` | The de-facto journal math font; huge coverage. |
| **Latin Modern Math** | GUST Font Licence (LPPL-like) ✓ | CTAN `ctan.org/pkg/lm-math` | Computer Modern (classic LaTeX) in OpenType. |
| **XITS Math** | OFL ✓ | `github.com/alif-type/xits` | STIX predecessor; Times-like. |
| **Asana Math** | OFL ✓ | CTAN `ctan.org/pkg/asana-math` | Palatino-like. |
| **TeX Gyre Math** (Termes / Pagella / Bonum / Schola / DejaVu) | GUST Font Licence ✓ | CTAN `ctan.org/pkg/tex-gyre-math` | Times/Palatino/Bookman/Century/DejaVu math variants. |
| **Fira Math** | OFL ✓ | `github.com/firamath/firamath` | Modern sans math (matches Fira Sans). |
| **Libertinus Math** | OFL ✓ | `github.com/alerque/libertinus` | From Linux Libertine; elegant serif. |
| **Garamond-Math / Erewhon-Math / Concrete / Euler** | OFL ✓ | CTAN | Specialty serif math faces. |
| **Cambria Math** | **Proprietary ✗** | Windows / MS Office only | Excellent, but *cannot* be bundled — it's the current runtime fallback on Windows, not a shippable file. |

## B. Monospace fonts with strong math/Unicode coverage (best for mathdot's look)

No MATH table, but wide symbol coverage in a fixed-width design that matches the CAS
aesthetic — ideal as the **primary** or a coverage fallback.

| Font | Licence (bundle?) | Download | Notes |
|---|---|---|---|
| **JuliaMono** | OFL ✓ | `github.com/cormullion/juliamono` | ~10 000 glyphs; built for scientific computing. **Top pick for mathdot.** |
| **DejaVu Sans Mono** | Bitstream Vera + public-domain (permissive) ✓ | `dejavu-fonts.github.io` | Very broad coverage; ubiquitous. |
| **Cascadia Code** | OFL ✓ | `github.com/microsoft/cascadia-code` | MS terminal font; ligatures + good symbols. |
| **Fira Code** | OFL ✓ | `github.com/tonsky/FiraCode` | Programming ligatures; decent coverage. |
| **JetBrains Mono** | OFL ✓ | `jetbrains.com/lp/mono` | Clean, readable; moderate symbol set. |
| **Iosevka** | OFL ✓ | `github.com/be5invis/Iosevka` | Highly configurable; large coverage builds. |
| **GNU Unifont** | GPLv2+ with font-embedding exception ✓ | `unifoundry.com/unifont` | Covers **every** Unicode BMP glyph (bitmap look) — the ultimate no-tofu fallback. |

## C. Symbol / gap-filler fonts (fallback links only)

Best as the *last* entry in a fallback chain so nothing ever renders as tofu.

| Font | Licence (bundle?) | Download | Notes |
|---|---|---|---|
| **Noto Sans Math** | OFL ✓ | `fonts.google.com` / `github.com/notofonts` | Symbols/operators; no MATH layout. |
| **Noto Sans Symbols 2** | OFL ✓ | same | Broad symbol block coverage. |
| **STIX Two Text** | OFL ✓ | `github.com/stipub/stixfonts` | Body-text companion to STIX Two Math. |
| **GNU FreeFont** (FreeSerif/Sans/Mono) | GPLv3 + font exception ✓ | `gnu.org/software/freefont` | Wide math coverage; freely redistributable. |
| **Symbola** | Free but licence changed (recent versions restrict commercial embedding) — **use with care** | `dn-works.com` | Enormous symbol coverage; prefer Noto/FreeFont to avoid the ambiguity. |

## Licensing cheat-sheet (for bundling)

- **SIL OFL 1.1** (JuliaMono, STIX, XITS, Asana, Fira Math, Libertinus, Noto, Cascadia,
  Fira Code, JetBrains Mono, Iosevka) — **bundle freely**; ship the `OFL.txt`; don't
  sell the font by itself.
- **GUST Font Licence** (Latin Modern, TeX Gyre) — LPPL-style; **bundle freely**.
- **Bitstream Vera / public-domain** (DejaVu) — **bundle freely**.
- **GPL + font exception** (Unifont, FreeFont) — **bundle freely** (the exception means
  documents/apps embedding it aren't GPL-encumbered); ship the licence.
- **Proprietary** (Cambria Math, Segoe, Apple system fonts) — **do not bundle**; only
  rely on them as a *runtime system fallback* (as task 266 does).

## Recommendation

For mathdot specifically: download **JuliaMono** (OFL) as the bundled primary math
font — it keeps the monospace CAS feel and covers essentially all math Unicode — with
**Noto Sans Math** (OFL) as the final fallback. For a proportional textbook variant,
swap in **STIX Two Math** (OFL). All three are one download each, freely shippable, and
drop straight into the task-266 fallback wiring.

## Files
- This doc only (task 267 asks *which* fonts are downloadable — no code changed).
