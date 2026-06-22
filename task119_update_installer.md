# Task 119 — Update the Installer

## Goal

> "Update the installer."

Rebuild the mathdot installer so it ships everything done since the last build
(tasks 102–118) — most importantly the **engine heap fix** (task 114) and the
notebook/UI improvements.

## What changed in this build

The previous installer (`mathdot-1.2.0-Setup.exe`) predates tasks 103–118. The
new build bundles the current `app/` — which now includes:

- **Task 114** — `math_engine.gd` launches REDUCE with `-K 1000m` (the heap fix
  that stops evaluations from hanging on "insufficient freestore"). This is the
  most important inclusion — without it, Run silently breaks.
- **Tasks 110/111/115** — the editable-Source workflow and the **✎ Source /
  ▤ Notebook** toggle as a top button.
- **Task 118** — bolder fonts throughout (except buttons); light, readable file
  tree tooltip.
- Tasks 104/105 notebooks, and the rest of the MATLAB-look UI.

## Build steps

1. **Regenerated the `.godot` cache** that the installer ships (task 102): opened
   the project once with the headless editor
   (`Godot --headless --editor --path app --quit-after 120`) so
   `global_script_class_cache.cfg` / `uid_cache.bin` reflect the current scripts.
   No parse errors — every script compiled clean.
2. **Bumped the version** in [mathdot.iss](mathdot.iss): `1.2.0 → 1.2.1`.
3. **Compiled** with Inno Setup:
   ```
   ISCC mathdot.iss   →   Successful compile (≈83 s)
   ```
   producing `installers\mathdot-1.2.1-Setup.exe` (~104 MB).

## Verification

Silently installed `mathdot-1.2.1-Setup.exe` to a temp folder
(`/VERYSILENT /NOICONS /TASKS=`) and launched it:

- The shipped `autoload\math_engine.gd` contains the `-K 1000m` heap fix; the
  bundled `.godot\global_script_class_cache.cfg` is present (no blank screen).
- The installed app launched as **mathdot (DEBUG)**, the **REDUCE engine started**
  (heap fix active), and the UI shows the latest state: the **✎ Source** toggle
  as a top button and **bold** chrome text (`app_screenshot_task119.png`).

The temporary test install was removed afterward (no orphaned shortcuts left).

## Files changed
- `mathdot.iss` — version `1.2.0 → 1.2.1`.
- `app/.godot/*` — caches regenerated (git-ignored; shipped by the installer).
- `installers/mathdot-1.2.1-Setup.exe` — the rebuilt installer (git-ignored, like
  all of `installers/`).
