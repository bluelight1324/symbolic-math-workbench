# Task 122 — Clearing a Notebook's Answers So It Can Run Again

## Question

> "How to clear the notebook of answers so it can be run again?"

When you press **Run** (or **Run All**) a second time, the status bar says

    All blocks cached — nothing to evaluate

and nothing recomputes. This doc explains **why**, and the two ways to make the
notebook evaluate again.

## Why answers don't re-run — the content-addressed cache

Each `cas` block's result is stored in a `cas-result` block tagged with a hash of
the source:

```
```cas-result
<!-- src-hash: 835bcaef764e engine: csl-6547 -->
( - sin(x)³ - 6·sin(x) + 6·x)/9
```
```

On a normal Run, mathdot hashes each `cas` block and compares it to the stored
`src-hash` ([notebook_view.gd:508](app/scripts/notebook_view.gd#L508)). If they
match, the block is a **cache hit** and is skipped. If every block matches, you
get "All blocks cached — nothing to evaluate". This is intentional (it makes
re-running a big notebook cheap — only changed cells recompute).

## Way 1 — Force re-run (the intended way to "run it again")

**Force re-run** bypasses the cache and re-evaluates **every** block, overwriting
all the answers with fresh ones. Three equivalent triggers:

- **Keyboard:** `Ctrl + F5`
  ([main.gd:786](app/scripts/main.gd#L786) — plain `F5` = normal Run, `Ctrl+F5`
  = force).
- **Toolbar:** the **Force re-run** button.
- **Menu:** **Force re-run   Ctrl+F5**
  ([notebook_view.gd:772](app/scripts/notebook_view.gd#L772)).

Internally this is `_on_force_run() → _run_internal(true)`
([notebook_view.gd:484](app/scripts/notebook_view.gd#L484)); the status bar shows
`(cache bypassed)`.

> Use this when the *engine* or environment changed (new package, restarted
> engine) but the source text didn't — the cache thinks nothing changed, so a
> plain Run would skip everything.

## Way 2 — Actually empty the answer blocks

If you want the notebook **clean** (no answers stored at all), edit it in
**Source** view (the ✎ Source top button) and delete the ```` ```cas-result ````
blocks, then Save. The next Run treats every `cas` block as new and recomputes
from scratch.

A lighter touch: changing a `cas` block's text even slightly changes its
`src-hash`, so **just that block** falls out of cache and re-runs on the next
normal Run.

## Quick reference

| Goal | Do this |
|---|---|
| Re-evaluate everything now (keep the blocks) | **Ctrl+F5** / Force re-run button |
| Re-run only one cell | edit that `cas` block, then Run |
| Remove all stored answers | Source view → delete `cas-result` blocks → Save |

## Files changed
- None — this is a how-to for existing functionality.
