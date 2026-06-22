# Task 106 — Push to GitHub

## Goal

> "Push to GitHub."

Commit the work from tasks 101–105 and push it to
`origin` → `github.com/bluelight1324/symbolic-math-workbench.git`, branch `main`.

## What was pushed

A single commit covering tasks 101–105:

| Task | Summary | Key files |
|---|---|---|
| 101 | Rebrand to **mathdot** + build an installer | `app/project.godot` (app name → mathdot), `mathdot.iss` (new), `build-installer.ps1` |
| 102 | Fix the post-install **blank screen** (ship the `.godot` script-class cache) | `mathdot.iss` |
| 103 | Doc: **is Godot bundled?** (yes — installed as `bin\Godot.exe`) | `mathdot.iss` (comment) |
| 104 | Notebook solving a **Volterra integral equation** (→ ODE → `odesolve` → verify) | `app/notebooks_sample/integral_equation.md`, `app/scripts/main.gd` |
| 105 | Notebook of **difficult integrals the engine solves unaided** (incl. `erf`) | `app/notebooks_sample/difficult_integral.md`, `app/scripts/main.gd` |

Also included: the per-task docs (`task101…task106*.md`), the two new sample
notebooks, and the tasks 101/102/104/105 screenshots, plus `todo.txt`.

## Deliberately excluded

- **`installers/`** — the 104 MB `mathdot-1.2.0-Setup.exe`. GitHub rejects
  files > 100 MB, so it stays git-ignored (added in task 100, like `tools/`).
- **Sample notebooks dirtied by test runs** — `ode.md`,
  `task72_integrate_exponential_log.md` (and a line-ending-only change to
  `calculus.md`) were restored to their committed state; the results they picked
  up while testing aren't part of this work.
- Stray pre-existing artefacts unrelated to these tasks
  (`app_screenshot_task72_*.png`, `task176_*.png`, `task72_integral.red`,
  `app_screenshot_running_correct.png`) were left untracked.

## Result

Commit created on `main` and pushed to `origin` (no AI-assistance trailers or
credits, per project policy).
