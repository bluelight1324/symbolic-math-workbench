# Installer Build Instructions

The installer scripts are ready, but we need to locate your Inno Setup installation.

## Quick Start

### Option 1: If you know the Inno Setup path

Run the PowerShell build script with the full path:

```powershell
cd i:\readtgodot
.\build-installer.ps1 -IsccPath "C:\path\to\ISCC.exe"
```

Replace `C:\path\to\ISCC.exe` with your actual Inno Setup location.

**Example:**
```powershell
.\build-installer.ps1 -IsccPath "C:\Users\YourName\AppData\Local\Programs\Inno Setup 6\ISCC.exe"
```

### Option 2: Find Inno Setup on your system

Run the discovery script:

```powershell
cd i:\readtgodot
.\find-inno-setup.ps1
```

This will search for ISCC.exe and provide the exact command to build the installer.

### Option 3: Using the batch file

If you know the Inno Setup path, edit `build-installer.bat` and add it to the list of checked paths:

```batch
if exist "YOUR\ACTUAL\PATH\ISCC.exe" (
    goto build_with_your_path
)
```

Then add the corresponding label section.

## Available Build Scripts

### `build-installer.ps1` (Recommended)
Modern PowerShell script with:
- Auto-detection of Inno Setup
- File validation before building
- Color-coded output
- Build success reporting
- Usage: `.\build-installer.ps1` or `.\build-installer.ps1 -IsccPath "path"`

### `build-installer.bat`
Traditional batch script
- Checks multiple standard installation paths
- Usage: `.\build-installer.bat`

### `find-inno-setup.ps1`
Discovery utility
- Searches for ISCC.exe on the system
- Provides ready-to-use build command
- Usage: `.\find-inno-setup.ps1`

## Finding Inno Setup Manually

If the scripts don't find it, check these locations:

**Standard installations:**
- `C:\Program Files\Inno Setup 6\ISCC.exe`
- `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`
- `C:\Program Files\Inno Setup 5\ISCC.exe`
- `C:\Program Files (x86)\Inno Setup 5\ISCC.exe`

**Non-standard locations (search for `ISCC.exe` in):**
- `C:\Users\[YourUsername]\AppData\Local\Programs\`
- `C:\Users\[YourUsername]\AppData\Roaming\`
- Any custom folder you installed it to

**Windows Start Menu:**
- Type "Inno" in Windows search
- Right-click on Inno Setup → Open file location
- Copy the folder path, add `\ISCC.exe`

**Windows Registry:**
```powershell
Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue |
  Where-Object { $_.PSChildName -match "Inno" } |
  ForEach-Object { Get-ItemProperty $_.PSPath | Select-Object InstallLocation }
```

## Once You Have the Path

Run the build command:

```powershell
cd i:\readtgodot
.\build-installer.ps1 -IsccPath "C:\YOUR\ACTUAL\ISCC.exe"
```

**Expected output:**
```
Symbolic Math Workbench Installer Builder
=========================================

Searching for Inno Setup...
✓ Found: C:\YOUR\PATH\ISCC.exe

Checking required files...
  ✓ symbolic-math-workbench.iss
  ✓ app\project.godot
  ✓ tools\godot\Godot_v4.6.3-stable_win64.exe
  ✓ tools\reduce\bin\rfcsl.exe

Building installer...

[Compiling...] symbolic-math-workbench.iss
[Output file was successfully created in .\installers]

SUCCESS!

Installer created:
  ✓ Symbolic-Math-Workbench-1.1.0-Setup.exe (67.45 MB)

You can now distribute the installer or test it by running:
  .\installers\Symbolic-Math-Workbench-1.1.0-Setup.exe
```

## Testing the Installer

Once built, run:

```batch
.\installers\Symbolic-Math-Workbench-1.1.0-Setup.exe
```

Then follow the [test checklist in task91_installer_testing.md](task91_installer_testing.md).

## Troubleshooting

### "Inno Setup not found"

1. Run `.\find-inno-setup.ps1` to search your system
2. If found, note the path and use: `.\build-installer.ps1 -IsccPath "path"`
3. If not found, [install Inno Setup](https://jrsoftware.org/isdl.php) and try again

### "symbolic-math-workbench.iss: No such file"

Make sure you're in the `i:\readtgodot\` directory:
```powershell
cd i:\readtgodot
ls *.iss  # Should show symbolic-math-workbench.iss
```

### Build hangs or fails

- Try `.\find-inno-setup.ps1` first to verify ISCC is accessible
- Check that all required files exist (see "Checking required files" section above)
- Try running with an explicit path: `.\build-installer.ps1 -IsccPath "full\path\to\ISCC.exe"`

## Next Steps

1. **Locate Inno Setup** — Run `.\find-inno-setup.ps1`
2. **Build installer** — Run `.\build-installer.ps1 -IsccPath "path"`
3. **Test** — Run the `.exe` and verify with [test checklist](task91_installer_testing.md)
4. **Release** — Upload to GitHub Releases or distribute

Questions? Check [task90_modern_installer.md](task90_modern_installer.md) for more details about the installer itself.
