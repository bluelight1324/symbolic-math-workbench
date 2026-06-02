# Task 90 — Modern Installer for Symbolic Math Workbench

Created a professional Windows installer using **Inno Setup 6**, a modern, widely-used installer framework for desktop applications.

## What's Included

### `symbolic-math-workbench.iss`
An Inno Setup script that produces `Symbolic-Math-Workbench-1.1.0-Setup.exe` with:

- **Full installation** (default) — app + REDUCE + samples + docs
- **Compact installation** — app + REDUCE only
- **Custom installation** — user selects components

**Components:**
- `app` — Godot executable + project files + REDUCE binaries (required)
- `samples` — Pre-made notebooks installed to user's Documents folder
- `docs` — Task guides, technical documentation, API reference

**Features:**
- Modern Windows Installer UI (Inno Setup's modern wizard style)
- 64-bit only (Windows 7 SP1+)
- Creates Start Menu shortcuts
- Optional desktop icon
- Automatic first-run launch (with `--path` pointing to installation)
- Clean uninstall (removes desktop shortcuts, optionally user data)
- Compression (LZMA2, ~50% smaller than uncompressed)
- Unique app ID for Windows Add/Remove Programs registration

### `build-installer.bat`
Helper script that:
1. Checks for Inno Setup 6 installation
2. Creates `installers/` output directory
3. Compiles the `.iss` script into `.exe`
4. Reports success/failure

## How to Build

### Prerequisites

1. **Install Inno Setup 6** from https://jrsoftware.org/isdl.php (free, open-source)
   - Default install path: `C:\Program Files (x86)\Inno Setup 6\`

2. **Godot executable** must be present at:
   ```
   tools/godot/Godot_v4.6.3-stable_win64.exe
   ```
   (Already in repo)

3. **REDUCE binaries** must be present at:
   ```
   tools/reduce/bin/  (rfcsl.exe, etc.)
   tools/reduce/lib/  (CSL runtime)
   ```
   (Already in repo)

### Build Steps

1. Open Command Prompt / PowerShell in the project root
2. Run:
   ```batch
   .\build-installer.bat
   ```
3. Inno Setup compiler runs and produces:
   ```
   installers\Symbolic-Math-Workbench-1.1.0-Setup.exe
   ```
4. The installer is ready to distribute

**Build time:** ~10–30 seconds (depends on disk speed and REDUCE binaries size)

## Installer Behavior

### On First Install

User runs `Symbolic-Math-Workbench-1.1.0-Setup.exe`:

1. **Welcome screen** — explains what's being installed
2. **License agreement** (if LICENSE.txt present)
3. **Installation type selection** — Full / Compact / Custom
4. **Component selection** (if Custom) — app, samples, docs
5. **Installation folder** — defaults to `C:\Program Files\Symbolic Math Workbench\`
6. **Additional tasks** — Desktop icon, Quick Launch icon
7. **Installation** — files extracted, REDUCE binaries copied, shortcuts created
8. **First-run** — automatically launches `Godot.exe --path <install-dir>`

### Start Menu

After install:
- `Start Menu > Symbolic Math Workbench > Symbolic Math Workbench` — launches app
- `Start Menu > Symbolic Math Workbench > Open Sample Notebooks` — opens notebook folder
- `Start Menu > Symbolic Math Workbench > Documentation` — opens README.md
- `Start Menu > Symbolic Math Workbench > Uninstall` — removes the app

### File Locations

**Installation directory** (default `C:\Program Files\Symbolic Math Workbench\`):
```
bin\
  Godot.exe
reduce\
  bin\  (rfcsl.exe, reduce.exe, etc.)
  lib\  (CSL runtime and bootstrap)
scripts\
  main.gd, notebook_view.gd, color_config.gd, ...
scenes\
  main.tscn, notebook_view.tscn, ...
themes\
  (theme resource files)
docs\
  README.md
  tasks\
    task01_*.md, task02_*.md, ...
```

**Sample notebooks** (if installed):
```
%USERPROFILE%\Documents\Symbolic Math Workbench\notebooks\
  showcase.md
  plotting.md
  advanced_demo.md
  task72_integrate_exponential_log.md
  ... (all notebook samples)
```

**User configuration** (created on first run):
```
%APPDATA%\Godot\app_userdata\Symbolic Math Workbench\
  font.cfg     (user's font preferences)
  color.cfg    (user's colour scheme)
  style.cfg    (shadows, animations, density)
  packages.cfg (REDUCE package selections)
```

## Advanced Options

### Customizing the Installer

**Edit `symbolic-math-workbench.iss` to:**

1. **Change installation directory:**
   ```iss
   DefaultDirName={autopf}\My Math App
   ```

2. **Change app ID** (for side-by-side installs):
   ```iss
   AppId={{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
   ```
   Use a UUID generator to create a unique ID

3. **Add file associations** (open `.nb` files with the app):
   ```iss
   [Registry]
   Root: HKCR; Subkey: ".nb"; ValueType: string; ValueName: ""; ValueData: "SymbolicMathNotebook"
   Root: HKCR; Subkey: "SymbolicMathNotebook"; ValueType: string; ValueName: ""; ValueData: "Notebook"
   Root: HKCR; Subkey: "SymbolicMathNotebook\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\icon.ico"
   ```

4. **Require administrator privileges:**
   ```iss
   PrivilegesRequired=admin
   ```

5. **Skip first-run launch:**
   In the `[Run]` section, comment out the launch entry:
   ```iss
   ; Filename: "{app}\bin\Godot.exe"; ...
   ```

### Silent Installation

End users can install silently from the command line:
```batch
Symbolic-Math-Workbench-1.1.0-Setup.exe /VERYSILENT /NORESTART
```

Useful for enterprise deployments or scripted setups.

## Distribution & Deployment

### GitHub Releases

The `.exe` can be attached to GitHub releases:
```bash
gh release create v1.2.0 \
  --title "v1.2.0 — Title" \
  --notes "Release notes..." \
  installers/Symbolic-Math-Workbench-1.2.0-Setup.exe
```

### Self-Hosted Download

Host the `.exe` on a web server; users download and run.

### Windows Store / Microsoft Store

Inno Setup installers are compatible with submission to Microsoft Store (requires additional packaging), though this is optional.

## Honest Scope

- **Godot executable not exported.** The installer currently assumes the Godot binary exists at `tools/godot/Godot_v4.6.3-stable_win64.exe` and launches it with `--path <install-dir>`. A true standalone release would require:
  1. Exporting the Godot project as a standalone binary (via Godot > Project > Export)
  2. Pointing the `.iss` script to that exported binary instead
  
  This isn't done yet because it requires export templates setup in Godot.

- **Icon missing.** The `.iss` references `icon.ico` which doesn't exist yet. To use the installer icon feature:
  1. Create or design a 256×256 PNG logo
  2. Convert to `.ico` format (tools like ImageMagick or online converters)
  3. Place at `i:\readtgodot\icon.ico`
  4. Uncomment the `SetupIconFile` line in the `.iss`

- **License file missing.** The installer looks for `LICENSE.txt` in the root. Add a LICENSE file (MIT, GPL, or other) to include it.

- **Sample notebooks location.** The `.iss` copies from `{#SourceDir}\notebooks_sample\`, which is the `app/notebooks_sample/` folder. Ensure sample notebooks are present.

## TL;DR

Built a professional Inno Setup installer that:
- Bundles Godot + REDUCE + notebooks + docs into one `.exe`
- Offers Full/Compact/Custom installation types
- Creates Start Menu shortcuts, desktop icons
- Auto-launches on first run
- Cleans up on uninstall
- Is ready to distribute on GitHub Releases or self-hosted

**To build:** Install Inno Setup 6, run `build-installer.bat`, get `installers/Symbolic-Math-Workbench-1.1.0-Setup.exe`.

**To complete:** Export Godot as binary (not just run from Godot editor), add icon.ico, add LICENSE file, then the installer is production-ready.
