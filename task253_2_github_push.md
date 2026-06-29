# Task 253.2 — Push to GitHub

## Request

> "Push to github."

An explicit instruction to publish the accumulated plotting work. This commits the
tasks since the last push (commit `9f1a399`, "tasks 146-149") and pushes `main` to
`origin` (`github.com/bluelight1324/symbolic-math-workbench`).

## What's in this push (tasks 149.2 – 253.1)

**New plot kinds**
- `cas-anim` — animated `z=f(x,y,t)` surfaces (real-time re-sample). *(149.3)*
- `cas-field` — vector fields (MultiMesh arrows, magnitude colour). *(149.3)*
- `cas-implicit` — implicit surfaces `f(x,y,z)=0` via **Surface Nets**. *(149.5)*
- `cas-domain` — complex **domain colouring** via a new complex-number evaluator
  (`complex_eval.gd`). *(251.0)*

**2-D + output + performance**
- **Multiple series + legend** in one `cas-plot` block. *(251.0)*
- **PNG export** ("⤓ PNG") on every plot cell — native-resolution capture. *(252.0)*
- **Threaded sampling** — implicit/domain builds run on a worker thread with a
  placeholder→swap, so the UI never freezes. *(253.0)*
- Nested-parenthesis `^→pow` parser fix (helps every 3-D kind). *(149.5)*

**Docs & tests**
- Plotting audits / benefit catalogues / "what's left" docs. *(149.2, 149.4, 149.6)*
- Per-task docs for every change, and a **123-assertion** test harness plus demo
  and export integration checks (task 253.1 thorough test).

## What was committed vs. left alone

- **Committed**: the five modified `app/scripts/*` files, two new scripts
  (`complex_eval.gd`, `anim_surface.gd`), the demo notebooks
  (`domain_coloring.md`, `multi_series.md`, `implicit_surfaces.md`,
  `dynamic_plots.md`), the task docs, and the task screenshots.
- **Left untracked** (deliberately): `todo.txt` (the user's task list — per the
  standing rule it is never modified or committed by me) and `app/notebooks_sample/zzz.md`
  (a scratch notebook).
- **No AI/Anthropic attribution** in the commit (per the standing rule).

## Result

See the command output for the commit hash and push confirmation.

## Files changed
- This doc only; the push itself is a git operation, not a code change.
