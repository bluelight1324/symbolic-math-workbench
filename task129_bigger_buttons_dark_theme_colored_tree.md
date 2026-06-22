# Task 129 — Bigger Buttons, Courier-New Default, MATLAB Dark Theme, Colored File Names

Four UI changes, all implemented and verified in the running app.

## 1. Bigger top buttons (but not too big)

[icon_menubar.gd](app/scripts/icon_menubar.gd) — bumped the top category/action
buttons by ~20 %:

| | was | now |
|---|---|---|
| button size | 72 × 64 | **88 × 78** |
| icon glyph | 28 pt | **34 pt** |
| label | 12 pt | **14 pt** |

Big enough to read/click comfortably, still fitting the full row across the bar.

## 2. MATLAB Courier New as the standard startup font

This was already the default and is confirmed: `FontConfig.DEFAULT_FAMILY =
"matlab"` → the "MATLAB (Courier New)" family (`Courier New`, falling back to
`Verdana`), and the saved `font.cfg` on disk reads `family="matlab"`. The
calculator chrome (`main.gd` theme) also hardcodes the `matlab` font. So every
surface starts in Courier New — verified: all text in the app renders in Courier
New monospace at startup. No change was needed; documented here for completeness.

## 3. MATLAB Dark theme

Added a **MATLAB Dark** colour scheme — the MATLAB desktop in its dark mode:

- [color_config.gd](app/scripts/color_config.gd) — new `matlab_dark` scheme:
  charcoal desktop (`#262626`), near-black editor/command panels (`#1E1E1E`),
  the signature MATLAB blue/orange accents **brightened** so they read on dark,
  light-grey text (`#E6E6E6`). Added to `ordered_keys()` so it appears in the
  **Theme** submenu right after MATLAB.
- [looks_config.gd](app/scripts/looks_config.gd) — a one-click **MATLAB Dark**
  Look bundle (dark scheme + compact density + Courier New + flat finish),
  alongside the existing MATLAB Look.

Verified: switching to it gives a dark charcoal UI with light text, blue-bordered
source cells and orange-bordered result cells (`app_screenshot_task129_dark.png`).

## 4. Colored file names in the left pane

[notebook_view.gd](app/scripts/notebook_view.gd) — the file tree now colours each
entry:

- **Folders** (incl. the workspace root) get a gold tint.
- **Notebooks** (`.md`) each get a **stable colour hashed from the filename**
  (`item.set_custom_color`), cycling a 6-hue palette (blue, orange, green,
  purple, teal, rose). The hues are saturated enough to read on **both** the
  light and dark MATLAB backgrounds.

Verified: the "Current Folder" pane shows each notebook in its own colour on both
the light (`app_screenshot_task129_light.png`) and dark
(`app_screenshot_task129_dark.png`) themes.

## Verification summary

Launched the app (no script/parse errors) in both themes:
- Top buttons visibly larger; all text in Courier New.
- Light: colored file names on the white "Current Folder" pane.
- Dark: full MATLAB-dark palette with the colored file names still readable.

## Files changed
- `app/scripts/icon_menubar.gd` — larger button + glyph sizes.
- `app/scripts/color_config.gd` — `matlab_dark` scheme + ordering.
- `app/scripts/looks_config.gd` — `matlab_dark` Look bundle + ordering.
- `app/scripts/notebook_view.gd` — per-item tree colours (palette + gold folders).
