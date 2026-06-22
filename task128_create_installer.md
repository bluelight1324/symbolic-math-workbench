# Task 128 — Create the Installer

## Goal

> "Create the installer."

Rebuild the mathdot installer so it ships the task-126 feature set and the
task-127 fixes.

## What's new in this build (over 1.2.1)

- **Task 126** — LaTeX/MathJax input in `cas` blocks (`_latex_to_reduce`), real
  inline **3D surface plots** (`_build_surface3d`), **wikilinks** `[[Note]]`,
  **Clear all outputs**, **workspace search** (Ctrl+Shift+F), **distraction-free**
  mode, and the `features_126.md` demo notebook.
- **Task 127** — two LaTeX-converter bug fixes (brace-superscript guard;
  superscripts converted before fractions) and the `_test126.gd` test harness.

## Build steps (same proven pipeline as task 119)

1. **Regenerated the `.godot` cache** (headless editor,
   `--editor --quit-after 120`) so the shipped script-class cache matches the
   current scripts. Every script compiled clean — no parse errors.
2. **Bumped the version** in [mathdot.iss](mathdot.iss): `1.2.1 → 1.2.2`.
3. **Compiled** with Inno Setup:
   ```
   ISCC mathdot.iss  →  Successful compile (≈76 s)
   ```
   producing `installers\mathdot-1.2.2-Setup.exe` (~104 MB).

## Verification

Silently installed `mathdot-1.2.2-Setup.exe` to a temp folder
(`/VERYSILENT /NOICONS /TASKS=`) and launched it:

| Check | Result |
|---|---|
| Install exit code | 0 |
| `_latex_to_reduce` in shipped `notebook_view.gd` | ✓ |
| `_build_surface3d` (3D plots) shipped | ✓ |
| `_linkify_wikilinks` (wikilinks) shipped | ✓ |
| `.godot\global_script_class_cache.cfg` shipped (no blank screen) | ✓ |
| App launched as **mathdot (DEBUG)** | ✓ (PID assigned, window present) |
| REDUCE engine started | ✓ |

The temporary test install was removed afterward; no stray Start-menu shortcuts
or `Documents\mathdot` litter were left behind.

## Notes
- The `samples` component installs the bundled notebooks (including
  `features_126.md`) to `Documents\mathdot\notebooks` on a full install.
- `installers/` is git-ignored, so the `.exe` is not committed; the committable
  change is the `mathdot.iss` version bump.

## Files changed
- `mathdot.iss` — version `1.2.1 → 1.2.2`.
- `app/.godot/*` — caches regenerated (git-ignored; shipped by the installer).
- `installers/mathdot-1.2.2-Setup.exe` — the rebuilt installer (git-ignored).
