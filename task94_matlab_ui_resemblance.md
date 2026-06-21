# Task 94 — Make the App Resemble the MATLAB UI

## Goal

> "While keeping the buttons on top all the same, make the app resemble the
> MATLAB UI as much as you can."

Re-skin the whole Symbolic Math Workbench so it reads like the **MATLAB
desktop** — light-grey desktop, white docked panels with grey title bars,
MATLAB blue/orange accents, a monospace command/editor font, and a flat finish
— **without touching the top toolbar buttons** (the `IconMenuBar` row of
Notebook / View / Algebra / Calculus / Equations / ODEs / Matrices / Series /
Trig / Numbers / Plots / Help).

## Why the top buttons were safe to leave alone

The toolbar buttons are built by [icon_menubar.gd](app/scripts/icon_menubar.gd),
where **each button sets its own `StyleBoxFlat` overrides and font colours**
(`add_theme_stylebox_override` for normal/hover/pressed + a fixed near-white
font colour). They do not read the global app `Theme`, so retheming the rest of
the app leaves them pixel-identical. Verified in the screenshots: the teal
title bar and the 12 coloured glyph buttons are unchanged before and after.

## What MATLAB's UI looks like (the cues we matched)

| MATLAB cue | How we reproduced it |
|---|---|
| Light grey desktop (`#F0F0F0`) | `COL_BG` / scheme `bg` set to `#F0F0F0` |
| White content panels | `COL_PANEL` / scheme `src_bg` = white |
| Docked panels with grey **title bars** ("Current Folder", "Editor", "Command Window") | New `_titled_panel()` / `_make_title_bar()` helpers — a grey `#E2E2E2` strip with a 1 px bottom border above a white body |
| MATLAB blue (`#0072BD`) + orange (`#D95319`) accents (the first two default-plot colours) | scheme `src_border`/`src_chip` = blue, `res_border`/`res_chip` = orange; chrome accent `COL_ACCENT` = blue |
| Blue selection highlight (`#CCE4F7`) | `COL_SELECT` on Tree selection, button hover, text selection |
| Monospace command/editor font | MATLAB Look uses font family `mono` (Consolas/Cascadia) |
| Flat, near-square widgets | `RADIUS` dropped 10 → 3; MATLAB Look turns shadows + animations off, density `compact` |
| Near-black text on white | `COL_TEXT` / scheme `text` = `#1A1A1A` |

## Changes

### 1. New "MATLAB" colour scheme — [color_config.gd](app/scripts/color_config.gd)
Added a `matlab` palette (light grey desktop, white command/editor cells, MATLAB
blue source accents, MATLAB orange result accents, near-black text). Added it to
`ordered_keys()` (first) and made it the new **`DEFAULT_KEY`**, so the bundled
default colour scheme is now MATLAB.

### 2. New one-click "MATLAB" Look — [looks_config.gd](app/scripts/looks_config.gd)
Added a `matlab` Look that bundles everything at once:
`color=matlab, density=compact, font_family=mono, font_size=16, shadows=off,
animations=off`. Listed first in `ordered_keys()`, so **Notebook ▸ Looks ⭐ ▸
MATLAB** applies the full desktop look in one click.

### 3. App chrome retheme — [main.gd](app/scripts/main.gd)
- Replaced the dark design tokens with MATLAB-light ones (`COL_BG`,
  `COL_PANEL`, `COL_ACCENT`, `COL_TEXT`, `COL_ERR`) plus new `COL_BORDER`,
  `COL_TITLE_BG`, `COL_TITLE_TEXT`, `COL_SELECT`; `RADIUS` 10 → 3.
- Rewrote `_make_theme()` for the light look: white bordered `LineEdit` with a
  blue focus ring; flat grey MATLAB-toolstrip `Button`s with light-blue hover;
  white `Tree` with a blue selection; light `PopupMenu`; and a white
  `TextEdit`/`CodeEdit` (including the **`read_only`** stylebox — the Command
  Window is read-only and would otherwise stay grey).
- Added `_titled_panel()` — a MATLAB docked-panel card (white body + grey title
  bar). Wrapped the three calculator panes in them: **Command History**
  (was "History"), **Command Window** (was "Code"), and **Result**.
- History rows restyled for a light background (faint-grey fill, MATLAB-blue
  left accent, MATLAB-blue clickable links).

### 4. Notebook chrome follows the scheme — [notebook_view.gd](app/scripts/notebook_view.gd)
- Wrapped the file tree in a **"Current Folder"** docked panel and the editor in
  an **"Editor – <filename>"** docked panel (title updates on file open), via a
  new `_make_title_bar()` helper.
- New `_apply_chrome_colors()` (called from `_apply_visual_style()`) recolours
  the title bars, sidebar `Tree`, path/status labels, and a new bottom **status
  strip** from the active scheme — so every scheme (not just MATLAB) stays
  cohesive, light or dark.
- **First-launch default:** if no `color.cfg` exists yet, `_ready()` applies the
  `matlab` Look, so a fresh install opens looking exactly like MATLAB. Returning
  users keep whatever they last selected.

## Verification

Ran the app (Godot 4.6.3) from `i:\mathdot\app`; no script errors.

1. **Default notebook view** (`app_screenshot_task94.png`) — light-grey desktop,
   "Current Folder" + "Editor – algebra.md" docked title bars, monospace text,
   blue `▸ cas` / orange `= result` chips. Top buttons unchanged.
2. **Calculator view** (`app_screenshot_task94_calc.png`) — "Command History" +
   "Command Window" docked panels, white command window, light theme.
3. **Engine still works** (`app_screenshot_task94_result.png`, via `--demo-menu`)
   — six library problems evaluated correctly and rendered as dark-on-light
   history entries with MATLAB-blue links:
   `factorize(x^6-1)`, `int(1/(x²+1),x)=atan(x)`,
   `solve({x+y=3,x-y=1})={{x=2,y=1}}`, `limit(sin(x)/x,x,0)=1`,
   `binomial(10,3)=120`, 3×3 determinant.

All changes are pure presentation (colours / styleboxes / layout wrappers);
no engine or notebook logic was touched.

## Files changed
- `app/scripts/color_config.gd`
- `app/scripts/looks_config.gd`
- `app/scripts/main.gd`
- `app/scripts/notebook_view.gd`

## Notes
- The MATLAB look is the new default, but every previous scheme/Look is intact
  and one menu click away (Notebook ▸ Theme / Looks).
- The top toolbar (`icon_menubar.gd`) was deliberately **not** modified, per the
  task constraint.
