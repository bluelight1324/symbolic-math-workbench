# Task 131 — Update GitHub

## Goal

> "Update GitHub."

Push the accumulated work (tasks 107–130) — the first push since task 106
(commit `84ce3e8`).

## What was done

One commit on `main`, pushed to
`origin` (`github.com/bluelight1324/symbolic-math-workbench`):

```
84ce3e8..e24c78d  main -> main
e24c78d  tasks 107-130: engine-heap Run fix, editability, LaTeX input, 3D plots, MATLAB dark theme, installer 1.2.2
```

**62 files**: the modified scripts (`notebook_view.gd`, `main.gd`,
`icon_menubar.gd`, `color_config.gd`, `looks_config.gd`, `math_engine.gd`),
`mathdot.iss`, `CLAUDE.md`, the new test harness `_test126.gd`, three new sample
notebooks, task docs 107–130, and the task screenshots.

### Highlights in this push
- **task 114** — REDUCE engine heap fix (`-K 1000m`) so Run works, + per-block
  timeout guard.
- **task 126** — LaTeX→REDUCE input in `cas` blocks, real inline 3D surface
  plots, wikilinks, clear-outputs, workspace search, distraction-free.
- **task 127** — headless test harness (28 assertions) + LaTeX converter fixes.
- **tasks 118 / 129** — bolder fonts, light tooltip, bigger buttons, MATLAB Dark
  theme, colored file names.
- **tasks 119 / 128** — installer rebuilds.

## Housekeeping before the commit
- Restored sample notebooks dirtied by test runs / line-ending churn
  (`algebra.md`, `test.md`, `task72_…md`) to their authored state.
- Removed temp scratch files (`_start.err`, `_t118.err`).
- Left the stray `zzz.md` test note (the `# %s` artifact from task 108 testing)
  **uncommitted** — it's a scratch file, not part of the project.

## Not pushed (by design)
- `installers/*.exe` and `app/.godot/*` are git-ignored (large binaries / machine
  caches), so the installer EXE and the regenerated cache are not in the repo —
  only the `mathdot.iss` version bumps are.

## Verification
`git status -sb` shows `main...origin/main` in sync at `e24c78d`; the working tree
is clean apart from the intentionally-untracked `zzz.md`.

## Per project rules
- Committed locally and pushed **only because explicitly asked** ("update
  github").
- No AI-attribution / "Co-Authored-By" trailer (per the standing rule).

## Files changed
- None (this is the push itself + this doc).
