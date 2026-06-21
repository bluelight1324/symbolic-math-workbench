# Task 96 — Double Font Size, "Run All" Button, Per-Cell Execution

## Goal

> "Double font size throughout the app on startup. Provide a run all button next
> to the other buttons at the last right. Allow each cell to be executed
> individually."

Three deliverables, one doc.

---

## 1. Double the font size on startup

Doubled every default/base font size the app uses at startup, and scaled the
fixed control heights/widths so the larger glyphs don't clip.

| Where | Constant | Was | Now |
|---|---|---|---|
| Calculator base text | `main.gd FONT_BASE` | 20 | **40** |
| Header title | `main.gd FONT_TITLE` | 28 | **56** |
| Result / code text | `main.gd FONT_RESULT` | 22 | **44** |
| Operation button height | `main.gd BUTTON_MIN_H` | 48 | 76 |
| Input field height | `main.gd INPUT_MIN_H` | 56 | 88 |
| Keypad cell | `main.gd KEYPAD_MIN_H / width` | 56 / 64 | 88 / 104 |
| Panel title-bar labels | `main.gd` / `notebook_view.gd` | 13–14 | 24–26 |
| Notebook default font | `font_config.gd DEFAULT_SIZE` | 18 | **36** |
| MATLAB Look font | `looks_config.gd matlab.font_size` | 16 | **32** |
| Cell kind/result chips | `style_config.gd chip_size` (all 3 densities) | 12–14 | 24–28 |
| Notebook prose headings | `notebook_view.gd _emit_prose_cell` | fixed 22/26/34 | `font_size`-relative (`+6 / +10 / +18`) |

The prose headings were changed from fixed point sizes to **relative** to the
active font size, so headings stay larger than body text after the base
doubled (a fixed 22 pt heading would otherwise be smaller than 32 pt body).

**Scope note:** "throughout the app" was applied to all readable content and
controls. The top icon-toolbar buttons (`icon_menubar.gd`) keep their task-94
fixed dimensions — they're fixed-size glyph buttons whose 28 pt icon already
fills the box, so doubling would clip them; this also preserves the toolbar
look that task 94 deliberately froze. Returning users who previously picked a
font size keep their choice (task-58 persistence); the doubling is the new
*default*, applied on a fresh start.

## 2. "Run All" button at the far right of the toolbar

- Added [`IconMenuBar.add_action(icon, label, callback, accent)`](app/scripts/icon_menubar.gd) —
  a direct-action button styled identically to the category buttons but firing
  a callback instead of popping a menu (factored out the shared button builder
  into `_build_button`).
- In [main.gd](app/scripts/main.gd), after the toolbar is populated, appended a
  green **▶ Run All** button — it lands as the **last (right-most)** button,
  next to Help. It calls `_run_all_notebook()`, which makes the notebook
  visible (if needed) and runs every cell in the open file via the existing
  `NotebookView._on_run()`.

## 3. Execute each cell individually

- Added [`NotebookView._run_one(block_start)`](app/scripts/notebook_view.gd) —
  runs a **single** source block on demand by building a one-entry run queue and
  reusing the exact evaluation pipeline as "Run notebook"
  (`_dispatch_next_block` → `_on_engine_result` → `_finish_block_locally` →
  `_finish_run`), so the cell's paired result is rewritten in place and saved.
- Every rendered source cell (`cas`, `cas-test`, `cas-derive`, `cas-plot`, …)
  now shows a **▶ Run** button next to its kind chip (`_emit_block_cell`). It's
  left-aligned beside the chip so it stays visible regardless of the reading
  column's width.

## Verification

Ran the app (Godot 4.6.3) from a cleared config (fresh-install simulation) so
the doubled startup defaults apply.

1. **Fonts doubled** — `app_screenshot_task96.png`: workspace path, file tree,
   "Algebra examples" heading, cell content, chips and results all render ~2×
   larger. No script errors on load.
2. **Run All button** — green **▶ Run All** appears as the right-most toolbar
   button, after Help.
3. **Per-cell Run** — every cell shows a **▶ Run** button next to its chip
   (`app_screenshot_task96_calc.png` shows several). Clicking the `(x+1)^5`
   cell's Run re-evaluated it through the engine and re-rendered the correct
   result `x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1` (`app_screenshot_task96.png`),
   confirming single-cell execution works end-to-end.

The sample notebooks that picked up results during testing were restored to
their committed state.

## Files changed

- `app/scripts/main.gd` — doubled font/size constants; titled-panel font sizes;
  `Run All` wiring + `_run_all_notebook()`.
- `app/scripts/icon_menubar.gd` — `add_action()` + shared `_build_button()`.
- `app/scripts/notebook_view.gd` — `_run_one()`; per-cell **▶ Run** button;
  scheme-relative prose heading sizes; doubled title-bar font.
- `app/scripts/font_config.gd` — `DEFAULT_SIZE` 18 → 36.
- `app/scripts/looks_config.gd` — MATLAB Look font 16 → 32.
- `app/scripts/style_config.gd` — `chip_size` doubled across all densities.
