# Task 98 — Bolder Font on the Top Buttons

## Goal

> "Make the font on the top buttons bolder."

The "top buttons" are the `IconMenuBar` row at the very top of the app
(Notebook, View, Algebra, Calculus, Equations, ODEs, Matrices, Series, Trig,
Numbers, Plots, Help, and the task-96 Run All button). Each button is an icon
glyph above a small text label.

## Change — [icon_menubar.gd](app/scripts/icon_menubar.gd)

Applied **two** complementary effects to both the icon glyph and the text label
of every button (in the shared `_build_button` builder):

1. **Bold-weight font.** A lazily-built `SystemFont` of the app font (Courier
   New, task 97) with `font_weight = 700`, applied via
   `add_theme_font_override("font", …)`. This picks Courier New **Bold** for the
   labels.
2. **Same-colour outline.** `outline_size` of 3 px on the icon glyph and 2 px on
   the label, with `font_outline_color` set to the same near-white as the text.
   An outline thickens *every* glyph's strokes — including the special icon
   glyphs (𝒂, 𝑦′, ∫, ∑, △, ▦, ↗, ▶ …) that come from OS **fallback** fonts,
   where a bold weight on the primary font alone has no effect.

Using both means the labels get a true bold face while the icon glyphs (drawn
from fallback) are still visibly heavier — so the whole button row reads bolder,
not just the text.

```gdscript
const LABEL_FONT_COLOR := Color(0.93, 0.95, 0.97)
const ICON_OUTLINE := 3
const LABEL_OUTLINE := 2

var bold := _get_bold_font()           # Courier New @ weight 700, built once
for c in [icon_lbl, text_lbl]:
    c.add_theme_color_override("font_color", LABEL_FONT_COLOR)
    c.add_theme_color_override("font_outline_color", LABEL_FONT_COLOR)
    if bold:
        c.add_theme_font_override("font", bold)
icon_lbl.add_theme_constant_override("outline_size", ICON_OUTLINE)
text_lbl.add_theme_constant_override("outline_size", LABEL_OUTLINE)
```

Nothing else about the buttons changed — same size, colours, icons, layout, and
behaviour; only the glyph weight.

## Verification

Launched the app (Godot 4.6.3); no script errors. `app_screenshot_task98.png`
(toolbar crop) shows every label — Notebook, View, Algebra, Calculus,
Equations, ODEs, Matrices, Series, Trig, Numbers, Plots, Help, Run All —
rendering in a clearly **heavier/bold** weight versus the thin Courier New of
task 97, and the icon glyphs above them are noticeably thicker too. All 13 icon
glyphs still render correctly.

## Files changed
- `app/scripts/icon_menubar.gd` — bold font + outline on the icon/label of every
  top button (`_build_button`, `_get_bold_font`).
