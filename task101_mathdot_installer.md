# Task 101 — Create a "mathdot" Installer

## Goal

> "Create an installer for the mathdot app and call the app mathdot."

Rebrand the app from **Symbolic Math Workbench** to **mathdot** and build a
Windows installer for it.

## Rebrand

- **App display name** — [app/project.godot](app/project.godot)
  `config/name` changed `"Symbolic Math Workbench"` → **`"mathdot"`**. This is
  what the runtime uses for the window title, so the installed app's window now
  reads **mathdot**.
- **Installer** — new [mathdot.iss](mathdot.iss) (Inno Setup), branded as
  mathdot throughout: `MyAppName = "mathdot"`, a fresh `AppId` (its own product,
  separate from the old Symbolic Math Workbench), install dir
  `Program Files\mathdot`, Start-menu group **mathdot**, desktop shortcut
  **mathdot**, sample notebooks under `Documents\mathdot\notebooks`, and output
  `installers\mathdot-1.2.0-Setup.exe`. Version set to **1.2.0** to mark the
  rebranded, MATLAB-look release (tasks 93–99).
- **Build script** — [build-installer.ps1](build-installer.ps1) updated to
  compile `mathdot.iss`, and its ISCC search list now includes the user-local
  install path (`%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe`), which is where
  Inno Setup was actually installed on this machine.

## What the installer ships

Same proven payload as the task-90/91 installer, just rebranded:
- The Godot project (`scripts`, `scenes`, `autoload`, `project.godot`, `icon.svg`).
- The **REDUCE** CAS binaries (`reduce\bin`, `reduce\lib`).
- The **Godot** runtime as `bin\Godot.exe`.
- Optional sample notebooks and documentation components.
- The stale `.godot` cache is excluded so Godot regenerates it on first launch
  in the install location.

Shortcuts launch `bin\Godot.exe --path "{app}" --run`.

## Build

Inno Setup 6 was already present (user-local install at
`%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe`). Built with:

```
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" mathdot.iss
```

→ **Successful compile (~77 s)**, producing
`installers\mathdot-1.2.0-Setup.exe` (~104 MB). The only output were
non-fatal warnings (deprecated `x64` architecture id, an `OnlyBelowVersion`
note, and the standard admin-install + userdocs advisory) — all carried over
from the original proven script.

## Verification

1. **Built** — `mathdot-1.2.0-Setup.exe` (104 MB) produced, exit code 0.
2. **Installs** — ran a silent install (`/VERYSILENT /DIR=<temp> /COMPONENTS=app`,
   exit 0). The install tree is correct: `bin\Godot.exe`, `reduce\lib\csl\reduce.exe`,
   `scripts`, `scenes`, `autoload`, and `project.godot` with `config/name="mathdot"`.
3. **Runs as mathdot** — launched the installed `bin\Godot.exe --path <dir> --run`;
   the window title is **`mathdot (DEBUG)`** (`app_screenshot_task101.png`). The
   app is now called mathdot.

The temporary test installation was removed after verification.

## Note on the "(DEBUG)" tag

The window title shows `mathdot (DEBUG)`. The app **name** is `mathdot`; the
`(DEBUG)` suffix is Godot's runtime indicator, automatically appended because
this packaging runs the *project* through the Godot runtime binary (the same
approach used by the task-90/91 installer) rather than an exported release
build. Removing the tag would require switching to a full Godot **release
export** — a larger change to the packaging pipeline, out of scope for this
task.

## Files

- `app/project.godot` — app name → `mathdot`.
- `mathdot.iss` — new rebranded Inno Setup script (added).
- `build-installer.ps1` — points at `mathdot.iss`; user-local ISCC path added.
- `installers/mathdot-1.2.0-Setup.exe` — the built installer (gitignored, like
  all of `installers/`; not committed).
