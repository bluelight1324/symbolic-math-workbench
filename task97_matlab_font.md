# Task 97 — Use MATLAB's Font Throughout the App

## Goal

> "Change the font throughout the app to the same one used by MATLAB if
> available, else use Verdana."

## Which font does MATLAB use?

Queried the live MATLAB session directly (MATLAB MCP) instead of guessing:

```matlab
get(groot,'FixedWidthFontName')                          % → Courier New
settings.matlab.fonts.editor.code.Name.ActiveValue       % → Monospaced
settings.matlab.fonts.codefont.Name.ActiveValue          % → Monospaced
```

MATLAB's editor/command-window font is the logical font **"Monospaced"**, which
on Windows resolves to **Courier New** — confirmed by `FixedWidthFontName`
returning `Courier New`. Courier New is a standard Windows font, so it's
**available**; per the task, Verdana is the fallback only if it weren't.

## Changes

A single new font family drives the whole app, so the choice lives in one place.

### 1. New "matlab" font family — [font_config.gd](app/scripts/font_config.gd)
```gdscript
{"key": "matlab", "label": "MATLAB (Courier New)",
 "names": ["Courier New", "Verdana"]},
```
`font_resource("matlab")` builds a `SystemFont` whose `font_names` try Courier
New first and fall back to Verdana — exactly the task's rule. (`SystemFont`
keeps OS glyph-fallback on, so any glyph Courier New lacks is still drawn.)

### 2. Make it the default — [font_config.gd](app/scripts/font_config.gd)
`DEFAULT_FAMILY` changed `"default"` → **`"matlab"`**, so the notebook view
(which applies `font_resource(DEFAULT_FAMILY)` to the editor, file tree, labels
and every rendered cell) uses Courier New on a fresh start.

### 3. MATLAB Look points at it — [looks_config.gd](app/scripts/looks_config.gd)
The bundled **MATLAB** Look's `font_family` changed `"mono"` → **`"matlab"`**,
so the look applied automatically on first launch carries the real MATLAB font.

### 4. Calculator chrome too — [main.gd](app/scripts/main.gd)
`_make_theme()` now sets the app `Theme`'s `default_font` to
`FontConfig.font_resource("matlab")`. That propagates Courier New to every
control the calculator/chrome uses (buttons, input field, labels, history,
Command Window, popups, the top toolbar's text labels) — completing "throughout
the app".

## Why the toolbar icons still work

The top toolbar's category glyphs (𝒂, 𝑦′, ∫, ∑, △, ▦, ↗, ▶ …) are
mathematical-alphanumeric / symbol code points that **Courier New does not
contain**. Because `SystemFont` leaves `allow_system_fallback` on, Godot draws
those missing glyphs from an OS fallback font while normal text uses Courier
New. Verified visually: every icon still renders, and the labels beneath them
are now Courier New.

## Verification

Launched from a cleared config (fresh-install) so the new default + MATLAB Look
apply. No script errors.

- `app_screenshot_task97.png`: the workspace path, "Current Folder" / "Editor"
  title bars, file tree, the "Algebra examples" heading, cell source, and
  results all render in **Courier New** (the classic MATLAB command-window
  look). The toolbar icon glyphs render correctly via fallback; their labels
  are Courier New. The math result `x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1`
  renders correctly, superscripts and `·` included.

## Files changed
- `app/scripts/font_config.gd` — new `matlab` family; `DEFAULT_FAMILY` → `matlab`.
- `app/scripts/looks_config.gd` — MATLAB Look `font_family` → `matlab`.
- `app/scripts/main.gd` — theme `default_font` set to the MATLAB font.

## Notes
- Returning users who previously picked a font keep their choice (task-58
  persistence); Courier New is the new default applied on a fresh start.
- The Monospace ("mono") family is unchanged and still available in the Font
  menu for anyone who prefers Consolas/JetBrains Mono.
