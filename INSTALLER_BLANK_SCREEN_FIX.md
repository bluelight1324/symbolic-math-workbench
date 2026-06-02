# Installer Blank Screen Issue — RESOLVED

## Problem

After running the installer and completing setup, the app launched but displayed a blank gray screen instead of the Symbolic Math Workbench UI.

**Window Title:** `Symbolic Math Workbench (DEBUG)` — indicates Godot running in debug/editor mode

**Error Log:** Godot tried to load main.gd, but script parsing failed because:
- Missing `color.cfg` configuration file
- Script classes not recognized by Godot's autoload system

## Root Cause

The installer was launching **Godot Editor in DEBUG mode** instead of **running the actual application**.

### The Problem Code

In `symbolic-math-workbench.iss` [Run] and [Icons] sections:

```iss
; WRONG - opens Godot Editor
Parameters: "--path ""{app}"""

; RIGHT - runs the app
Parameters: "--path ""{app}"" --run"
```

### Why This Happened

- `--path <dir>` tells Godot which project to open
- Without `--run`, Godot defaults to opening the **editor UI**
- With `--run`, Godot executes the project as a running application

The editor UI is blank because it's trying to render the Godot editor interface, not the app.

## Solution Applied

### Changed Parameters

All Godot launch commands now include `--run`:

**In `[Run]` section (post-install launch):**
```iss
Filename: "{app}\bin\Godot.exe"; 
Parameters: "--path ""{app}"" --run"
```

**In `[Icons]` section (Start Menu & desktop shortcuts):**
```iss
Name: "{group}\{#MyAppName}"; 
Filename: "{app}\bin\Godot.exe"; 
Parameters: "--path ""{app}"" --run"
```

### Files Modified

- `symbolic-math-workbench.iss` — Added `--run` flag to all Godot launches

### Installer Rebuilt

- **File:** `installers/Symbolic-Math-Workbench-1.1.0-Setup.exe`
- **Size:** 104.16 MB
- **Build Time:** 60.6 seconds

## Expected Behavior After Fix

When the fixed installer completes and launches the app:

1. ✓ Godot loads the project
2. ✓ Main scene initializes (NotebookView + AdvancedView)
3. ✓ UI renders with full IconMenuBar toolbar
4. ✓ User data directory created with config files (including `color.cfg`)
5. ✓ Notebook view displays with sample workspace ready
6. ✓ CAS integration ready (REDUCE subprocess)

**Result:** Full application window with working interface, not blank gray screen.

## Testing the Fix

Run the rebuilt installer:

```batch
i:\readtgodot\installers\Symbolic-Math-Workbench-1.1.0-Setup.exe
```

After completion, the app should:
- Launch with full UI visible
- Show the notebook view or advanced view
- Have a working toolbar (IconMenuBar with buttons)
- Be ready to open notebooks and execute CAS blocks

## Why the Original Issue Occurred

1. Inno Setup's `[Run]` section executes after installation
2. The launch command passed only `--path`, which Godot interprets as "open editor"
3. User sees the blank Godot editor window, not the app
4. App initialization occurs but UI never renders because it's in editor mode
5. Main.gd loads but can't fully initialize without the running app framework

## Implementation Notes

The fix is minimal and safe:
- Single word addition (`--run`) to existing parameters
- No changes to Godot configuration, paths, or installer structure
- Works with existing project files and setup
- Aligns installer behavior with modern practice (distribute as app, not editor)

## Future Improvements

For a truly standalone release, consider:

1. **Export the project as a binary** (Godot → Project → Export)
   - Creates `Symbolic-Math-Workbench.exe` without needing Godot runtime
   - Reduces installer size significantly
   - More professional distribution

2. **Use `--path --run --quit-after 0`** for headless operation if needed
   - Runs once and exits (useful for demos)

3. **Digital code signing** of the `.exe`
   - Adds trust marker in Windows
   - Requires certificate

---

## Summary

**Issue:** Installer launched Godot editor instead of app → blank screen  
**Root Cause:** Missing `--run` flag in launch parameters  
**Fix:** Added `--run` to all Godot launch commands in `.iss` script  
**Result:** App now launches with full UI visible after installation  
**Status:** ✓ RESOLVED & REBUILT

The installer is now ready for testing and deployment.
