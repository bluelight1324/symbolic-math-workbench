# Task 100 — Update GitHub

## Goal

> "Update GitHub."

Commit the work from tasks 93–99 and push it to the GitHub remote
(`origin` → `github.com/bluelight1324/symbolic-math-workbench.git`, branch
`main`).

## What was pushed

A single commit covering tasks 93–99 (the files are intermingled across several
of these tasks — e.g. `main.gd` and `notebook_view.gd` were each touched by
multiple tasks — so they're committed together with a message enumerating the
tasks rather than split into broken per-task diffs):

| Task | Summary | Key files |
|---|---|---|
| 93 | Root-folder rename audit (`readtgodot` → `mathdot`); fixed broken dev-fallback paths | `math_engine.gd`, `main.gd`, `_libtest/_nbtest/_uitest.gd` |
| 94 | MATLAB-look UI (light theme, docked panels) + MATLAB colour scheme/Look | `color_config.gd`, `looks_config.gd`, `main.gd`, `notebook_view.gd` |
| 95 | Thorough math-function test via the UI (28/28 + 72/72 library) | `_mathtest.gd`, `main.gd` |
| 96 | Doubled startup fonts; **Run All** button; per-cell **▶ Run** | `main.gd`, `icon_menubar.gd`, `notebook_view.gd`, `font/style/looks_config.gd` |
| 97 | App font set to MATLAB's (Courier New, else Verdana) | `font_config.gd`, `looks_config.gd`, `main.gd` |
| 98 | Bolder font on the top buttons | `icon_menubar.gd` |
| 99 | Plotting integrated inline in the notebook (separate plot strip removed) | `notebook_view.gd`, `plot_panel.gd` |

Also included: the per-task docs (`task93…task99*.md`), the test reports
(`task95_mathtest_report.md`, regenerated `task25_uitest_report.md`), the
tasks 93–99 screenshots, and `todo.txt` (the updated task list).

## Deliberately excluded

- **`installers/`** — a 105 MB `Symbolic-Math-Workbench-1.1.0-Setup.exe`.
  GitHub rejects files larger than 100 MB, so it was added to `.gitignore`
  rather than committed (consistent with `tools/` already being ignored for
  size).
- **`app/project.godot`** — reverted to its committed state; the working-copy
  change was pre-existing editor noise (and dropped `window/size/resizable`),
  unrelated to tasks 93–99.
- Stray pre-existing untracked artefacts from other tasks
  (`app_screenshot_task72_*.png`, `task176_*.png`, `task72_integral.red`, …)
  were left untracked — not part of this work.

## Result

Commit created on `main` and pushed to `origin`. (No AI-assistance trailers or
credits, per project policy.)
