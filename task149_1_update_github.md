# Task 149.1 — Update GitHub

## Goal

> "Update GitHub."

Push the work done since the task-145 push (tasks 146–149.0).

## What was done

One commit on `main`, pushed to `origin`
(`github.com/bluelight1324/symbolic-math-workbench`):

```
6b2e98e..9f1a399  main -> main
9f1a399  tasks 146-149: time-ellipsoid & parametric-surface notebooks, Viridis + 3D axes/colour-bar, 2D axis numbers + hover, plot-render fix, plotting design docs
```

**24 files**: the modified scripts (`notebook_view.gd`, `plot_panel.gd`,
`notebook_runner.gd`, `main.gd`, `_test126.gd`), two new sample notebooks
(`time_ellipsoid.md`, `parametric_surfaces.md`), task docs 145–149.0, the task
screenshots, and `todo.txt`.

### Highlights in this push
- **task 146** — the time-ellipsoid (superellipse Laplace–Beltrami) notebook,
  solved raw with REDUCE.
- **task 148.5** — Viridis colormap, 3-D bounding box + tick numbers, 2-D axis
  numbers + hover crosshair, and the **fix** that restored inline 2-D graphics
  (plot samples keyed by src-hash, stable across the run's text rewrite).
- **task 148.6** — 3-D Viridis **colour-bar**, **parametric surfaces**
  (`cas-surface`), a refactored shared `_plot3d_scene` + `_contour_material`, and
  two bug fixes (`%g` label format, `pair_blocks` for `cas-surface`).
- **task 149.0** — test harness extended to **53/53** + integration run.
- **design docs (147–148.7)** — the plotting vision, 2-D/3-D implementation plan,
  four improvement tiers, consolidated requirements, and the Godot-only /
  AI-VR-Neural scoping.

## Housekeeping before the commit
- Removed temp scratch files (`_start.err`, `_t149.err`).
- Left the stray `zzz.md` test note **uncommitted** (a scratch file, as before).
- No sample notebooks were left dirtied by test runs (the cleared/re-run
  notebooks reproduced identical result blocks, so git saw no change).

## Not pushed (by design)
- `installers/*.exe` and `app/.godot/*` remain git-ignored.

## Verification
`git status -sb` shows `main...origin/main` in sync at `9f1a399`; the working tree
is clean apart from the intentionally-untracked `zzz.md`.

## Per project rules
- Pushed **only because explicitly asked** ("update github").
- No AI-attribution / "Co-Authored-By" trailer.

## Files changed
- None (this is the push itself + this doc).
