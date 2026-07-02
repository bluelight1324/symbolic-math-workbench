# Task 254 — Rebuild the App and the Installer

## Request

> "Rebuild the app and the installer."

Rebuilt mathdot so the installer ships **all** the work since the last build (the
plotting suite added in tasks 133–253: `cas-anim`, `cas-field`, `cas-implicit`,
`cas-domain`, 2-D multi-series, PNG export, threaded sampling, the `complex_eval.gd`
evaluator, etc.). Version bumped **1.2.2 → 1.3.0**.

## How this app is "built"

mathdot does **not** export to a single `.exe`. The installer (`mathdot.iss`,
Inno Setup) bundles the **Godot project source** (`project.godot`, `scripts/`,
`scenes/`, `autoload/`, `icon.svg`) plus the **shipped `.godot` cache**, and the
bundled **Godot 4.6.3 runtime** launches it with `Godot.exe --path {app} --run`.
REDUCE (`tools/reduce`) is bundled alongside.

So "rebuild the app" means **regenerate the `.godot` script-class / import cache**,
and "rebuild the installer" means **re-run Inno Setup**.

## 1. Rebuild the app — regenerate the `.godot` cache (critical)

The shipped `.godot` cache holds `global_script_class_cache.cfg` (the registry of
every `class_name`) and the import caches. Per the task-102 note in `mathdot.iss`, a
**stale cache ships a blank gray screen** — `class_name` types fail to resolve at
runtime. A project *run* does **not** refresh this cache; only the editor does.

- **Before:** the cache had **no `ComplexEval`** (the new task-251 complex-number
  evaluator) — i.e. it was stale.
- **Command:** `Godot_v4.6.3-stable_win64.exe --headless --path app --import`
  (starts the editor headless, scans the filesystem, loads global class names,
  reimports, quits).
- **After:** `global_script_class_cache.cfg` now **contains `ComplexEval`**, and the
  import cache reflects every current script. Verified the rebuilt app still runs
  clean: `--test126` → **123 / 123 pass, exit 0**.

## 2. Rebuild the installer — Inno Setup

- **Version:** bumped `MyAppVersion` `1.2.2 → 1.3.0` in `mathdot.iss` (substantial
  new feature set; a same-version rebuild would have produced a second, different
  "1.2.2" — a versioning anti-pattern).
- **Command:** `./build-installer.ps1 -IsccPath ".../Inno Setup 6/ISCC.exe"` —
  validated the required files (`mathdot.iss`, `app/project.godot`, the Godot
  runtime, `tools/reduce/bin/rfcsl.exe`), then compiled `mathdot.iss` (lzma2 solid
  compression).
- **Result:** `installers/mathdot-1.3.0-Setup.exe` — **104.3 MB**, valid PE
  (`MZ` header), build exit code 0. The previous `mathdot-1.2.2-Setup.exe` is kept
  alongside.

## Verification

| Check | Result |
|---|---|
| `.godot` cache contains new `class_name ComplexEval` | ✓ (was missing → now present) |
| Rebuilt app unit tests (`--test126`) | ✓ 123 / 123, exit 0 |
| Installer compiled | ✓ `SUCCESS`, exit 0 |
| Installer is a valid executable | ✓ `MZ` PE header, 104.3 MB |

## Files changed
- `mathdot.iss` — version `1.2.2 → 1.3.0`.
- `app/.godot/*` — regenerated script-class / import cache (now includes the new
  scripts; ships in the installer).
- `installers/mathdot-1.3.0-Setup.exe` — **new** rebuilt installer.

## Notes
- The build requires Inno Setup 6 (found at
  `…\AppData\Local\Programs\Inno Setup 6\ISCC.exe`) — see
  `INSTALLER_BUILD_INSTRUCTIONS.md`.
- A full install smoke-test would write to `Program Files`; not performed here to
  avoid modifying the system. The installer is byte-valid and built from the
  cache-verified app.
