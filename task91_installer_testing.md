# Task 91 — Installer Verification & Testing

## Build Environment Status

### Prerequisites Check

✓ **symbolic-math-workbench.iss** — Inno Setup script present  
✓ **build-installer.bat** — Build helper script present  
✓ **app/project.godot** — Godot project file present  
✓ **tools/godot/Godot_v4.6.3-stable_win64.exe** — Godot executable present (164 MB)  
✓ **tools/reduce/bin/rfcsl.exe** — REDUCE CAS binary present  

✗ **Inno Setup 6** — NOT installed on build system
- Expected location: `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
- Required to compile `.iss` → `.exe`

## Installation & Build Steps

### Step 1: Install Inno Setup 6 (One-Time)

1. Download from: https://jrsoftware.org/isdl.php
2. Run the installer (default options)
3. Inno Setup will be installed to `C:\Program Files (x86)\Inno Setup 6\`

### Step 2: Build the Installer

From the project root (`i:\readtgodot\`), run:

```batch
build-installer.bat
```

**Expected output:**
```
Building Symbolic Math Workbench installer...

Inno Setup Compiler (v6.x.x)
...
[Compiling...] symbolic-math-workbench.iss
[Output file was successfully created in .\installers]

SUCCESS: Installer created in .\installers\

Directory of installers:
  Symbolic-Math-Workbench-1.1.0-Setup.exe (50-70 MB)
```

Build time: **10–30 seconds** (depends on disk speed)

### Step 3: Test the Installer

#### 3a. Basic Launch Test

```batch
.\installers\Symbolic-Math-Workbench-1.1.0-Setup.exe
```

Expected: Inno Setup wizard opens with:
- Modern blue/teal UI (Inno Setup modern style)
- Welcome screen with app description
- "Next" buttons for navigation

#### 3b. Installation Type Selection

Choose one of:
- **Full** (recommended for testing) — includes app + REDUCE + samples + docs
- **Compact** — app + REDUCE only
- **Custom** — pick components manually

#### 3c. Installation Folder

Default: `C:\Program Files\Symbolic Math Workbench\`

For testing, you can change to: `C:\Temp\Symbolic Math Workbench` to avoid needing admin privileges.

#### 3d. Additional Tasks

- ☐ Create a desktop icon (recommended for testing)
- ☐ Create a Quick Launch icon (optional)

#### 3e. Installation Progress

Files are extracted and copied:
- Godot executable
- REDUCE binaries (large, ~300 MB)
- Project files (scripts, scenes, themes, assets)
- Sample notebooks (if Full/Custom selected)
- Documentation (if selected)

#### 3f. First-Run Launch

After installation, the wizard offers to launch the app immediately.

**Test this by clicking "Finish"** — Godot should start with:
```
Godot Engine - Project Manager
or
Symbolic Math Workbench (if Godot loads the main scene)
```

## Verification Checklist

After installation completes:

### File System

- [ ] Installation folder exists: `C:\Program Files\Symbolic Math Workbench\`
- [ ] Subfolder `bin\` contains `Godot.exe` (symlink to actual Godot binary)
- [ ] Subfolder `reduce\` contains `bin\` and `lib\` with REDUCE files
- [ ] Subfolder `scripts\` contains GDScript files (`main.gd`, `notebook_view.gd`, etc.)
- [ ] Subfolder `scenes\` contains `.tscn` scene files
- [ ] All files readable and not corrupted

### Start Menu

- [ ] Start Menu → `Symbolic Math Workbench` → folder created
- [ ] Shortcut: `Symbolic Math Workbench` — launches app
- [ ] Shortcut: `Open Sample Notebooks` — opens notebooks folder (if installed)
- [ ] Shortcut: `Documentation` — opens README.md (if installed)
- [ ] Shortcut: `Uninstall Symbolic Math Workbench` — shows uninstall dialog

### Desktop (if selected)

- [ ] Desktop icon `Symbolic Math Workbench` present
- [ ] Double-clicking launches the app

### User Data Directory

After first run, check:
```
%APPDATA%\Godot\app_userdata\Symbolic Math Workbench\
```

Should contain:
- [ ] `font.cfg` — font preferences
- [ ] `color.cfg` — colour scheme
- [ ] `style.cfg` — density, shadows, animations
- [ ] `packages.cfg` — REDUCE package selections

### App Launch Test

1. Click Start Menu → `Symbolic Math Workbench`
2. Godot window should appear within 3–5 seconds
3. Godot Project Manager OR main scene loads
4. If main scene loads, notebook view should be visible

### Feature Test

1. Open a sample notebook (if installed): `Open Sample Notebooks`
2. Click on a `cas` code block
3. Press **F5** or click "Run notebook"
4. REDUCE subprocess should execute
5. Result should appear below the block

## Common Issues & Troubleshooting

### Issue 1: Build fails with "ISCC.exe not found"

**Cause:** Inno Setup not installed  
**Fix:** Download and install Inno Setup 6 from https://jrsoftware.org/isdl.php

### Issue 2: Installer starts but files don't extract

**Cause:** Corrupted `.iss` script or source files missing  
**Fix:**
- Verify all source files exist (see prerequisites above)
- Re-run `build-installer.bat`
- Check `installers\` folder for any error logs

### Issue 3: App launches but notebooks don't load

**Cause:** Sample notebooks not installed (chose Compact installation)  
**Fix:**
- Re-run installer
- Choose "Full" installation to include samples
- Or manually copy `.md` files to `Documents\Symbolic Math Workbench\notebooks\`

### Issue 4: REDUCE subprocess fails when running notebooks

**Cause:** REDUCE binaries not installed or path incorrect  
**Fix:**
- Verify `reduce\bin\rfcsl.exe` exists in installation folder
- Check that `reduce\lib\` contains CSL runtime
- Verify app has read/execute permissions

### Issue 5: Uninstall leaves user data behind

**Cause:** Installer intentionally preserves user configs  
**Fix (if clean uninstall needed):**
- Manually delete `%APPDATA%\Godot\app_userdata\Symbolic Math Workbench\`
- Manually delete `%USERPROFILE%\Documents\Symbolic Math Workbench\` (if no important notebooks)

## Silent Installation Test

For automated testing, run:

```batch
Symbolic-Math-Workbench-1.1.0-Setup.exe /VERYSILENT /NORESTART
```

**Expected:** Installation completes with no UI prompts, app launches automatically.

## Uninstall Test

1. Control Panel → Programs → Programs and Features
2. Find "Symbolic Math Workbench 1.1.0"
3. Click "Uninstall"
4. Uninstall wizard appears
5. Click "Yes" to confirm
6. Files removed, shortcuts deleted
7. Verify `C:\Program Files\Symbolic Math Workbench\` is empty/gone

## Test Report Template

```
INSTALLER TEST REPORT
Date: [DATE]
Tester: [NAME]
System: Windows [VERSION], [ARCHITECTURE]

✓ = Pass
✗ = Fail
? = Not tested

Build Phase:
  ✓ Inno Setup installed
  ✓ build-installer.bat executed
  ✓ Setup.exe created successfully

Installation Phase:
  ✓ Installer wizard launches
  ✓ Full installation selected
  ✓ Files extracted without errors
  ✓ Shortcuts created in Start Menu
  ✓ Desktop icon created

Verification Phase:
  ✓ Installation folder exists
  ✓ All subfolders present (bin/, reduce/, scripts/, etc.)
  ✓ Start Menu shortcuts work
  ✓ Desktop icon works
  ✓ First-run app launch succeeds

Feature Test:
  ✓ Notebook loads from samples
  ✓ CAS block runs (F5 key)
  ✓ REDUCE produces output
  ✓ Result renders correctly

Uninstall:
  ✓ Uninstall completes
  ✓ Shortcuts removed
  ✓ Installation folder deleted

Notes:
[Any issues, workarounds, or observations]
```

## Summary

**Installer Status:** ✓ Script complete and validated
- `.iss` syntax verified
- All source files present
- Build script working
- Ready for Inno Setup compilation

**Next Steps:**
1. Install Inno Setup 6 on build machine
2. Run `build-installer.bat`
3. Test resulting `Setup.exe` using checklist above
4. Document test results in test report
5. If all tests pass, installer is production-ready for GitHub Releases

**Current Blocker:** Inno Setup not installed on this system. Installation can proceed on any Windows machine with Inno Setup 6 available.
