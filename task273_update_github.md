# Task 273 — Update GitHub

## Request

> "Update github and do 1 doc."

An explicit instruction to publish the work accumulated since the last push (commit
`b8770e6`, "tasks 149.2-253.1"). This commits tasks **254–272** and pushes `main` to
`origin` (`github.com/bluelight1324/symbolic-math-workbench`).

## What's in this push (tasks 254 – 272)

**App / installer**
- **254** — rebuilt the app (`.godot` cache regenerated for the new `class_name`s)
  and the installer, bumped **1.2.2 → 1.3.0**.
- **255** — fixed the font-menu bug (changing font worked once then failed): the
  radio-check sync ran inside the menu's own `id_pressed` signal; moved to
  `about_to_popup` + deferred.
- **256** — modernised the dialogs (Open-workspace / New-note / Search) with a
  theme-aware `_apply_dialog_style` (rounded panels, pill buttons, focus rings).

**Math-symbol rendering** (the 257–272 arc)
- **264** — math-font fallback (no more tofu) + a wide Unicode symbol map in
  `MathFormatter.to_display` (`∫ ∑ ∂ √ ≤ ≥ ≠ → ∞`, Greek, signed/parenthesised
  exponents).
- **265** — BBCode 2-D: REDUCE matrices render as `[table]` grids.
- **266** — cross-platform math fallback + custom `RichTextEffect`s giving the
  `[sup]`/`[sub]` tags Godot 4.6 lacks (multi-char exponents really raise).
- **268** — **bundled STIX Two Math** (SIL OFL) and wired it as the primary math
  fallback, shipped via the installer.
- **270** — made **STIX the primary font** for result cells (math reads like a
  textbook; prose/source keep the UI font).
- **272** — a live equation showcase that also caught + fixed a paren-eating bug in
  the superscript formatter.
- **257–263, 267, 269, 271** — the design/requirements/roadmap and thorough-test docs
  behind the above.

**Math problems**
- **159/160** — `mathproblems/` folder + a mathdot-solved nonlinear integro-PDE
  (notebook + plot + doc).

**Tests:** the harness grew from 123 → **183 assertions**.

## What was committed vs. left alone

- **Committed:** the modified/new `app/scripts/*` (incl. `complex_eval.gd`,
  `anim_surface.gd`, `rt_superscript.gd`, `rt_subscript.gd`), the **bundled font**
  `app/fonts/STIXTwoMath-Regular.otf` + `OFL.txt`, the demo notebooks, `mathdot.iss`,
  the `mathproblems/` solutions, the task docs, and the task screenshots.
- **Left untracked** (deliberately): `todo.txt` and `mathdot problems.txt` (the user's
  task/problem lists — never modified or committed by me) and
  `app/notebooks_sample/zzz.md` (scratch).
- **No AI/Anthropic attribution** in the commit (standing rule).

## Result

See the command output for the commit hash and the `origin/main` push confirmation.

## Files
- This doc only; the push itself is a git operation.
