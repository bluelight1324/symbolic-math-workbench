# Task 102 — Fix the Blank Screen After Install

## Problem

The mathdot installer (task 101) installed perfectly, but launching the app
showed only the title bar **`mathdot (DEBUG)`** above a **blank gray window** —
no toolbar, no notebook (see the user's screenshot).

## Root cause — missing `.godot` script-class cache

The project is written with GDScript **`class_name`** types — 14 of them
(`NotebookView`, `IconMenuBar`, `ColorConfig`, `FontConfig`, `LooksConfig`,
`StyleConfig`, `MathFormatter`, `NotebookRunner`, `PackageConfig`,
`ProblemLibrary`, `AdvancedLibrary`, `AdvancedView`, `HelpWizard`,
`PackageSettings`). `main.gd` and the `MathEngine` autoload reference these
types directly.

Godot resolves those names at load time from
**`.godot/global_script_class_cache.cfg`**. The installer **excluded the whole
`.godot` folder** ("to force regeneration on first run") — but a project **run**
(as opposed to an editor session) does **not** regenerate that cache. So on the
installed copy the cache was absent and every `class_name` reference failed to
compile.

Reproduced by running a copy of the app with `.godot` removed:

```
SCRIPT ERROR: Parse Error: Identifier "PackageConfig" not declared ...  (math_engine.gd:74)
ERROR: Failed to instantiate an autoload, script 'res://autoload/math_engine.gd' ...
SCRIPT ERROR: Parse Error: Could not find type "NotebookView"   (main.gd:49)
SCRIPT ERROR: Parse Error: Could not find type "IconMenuBar"    (main.gd:52)
... (HelpWizard, AdvancedView, PackageSettings, ...)
```

With the `MathEngine` autoload and the whole main scene failing to compile,
nothing renders → blank gray window. (The earlier `INSTALLER_BLANK_SCREEN_FIX.md`
blamed a missing `--run` flag; that was a misdiagnosis — `mathdot.iss` already
passes `--run`, and the real cause is the missing class cache.)

## Fix — ship the `.godot` cache (minus the editor subfolder)

[mathdot.iss](mathdot.iss): instead of excluding `.godot`, **install it** so the
class/import/uid caches travel with the app. The only part skipped is the
machine-specific `.godot/editor/` subfolder (it holds absolute dev paths and is
not needed to run):

```iss
Source: "{#SourceDir}\.godot\*"; DestDir: "{app}\.godot"; Excludes: "editor\*"; \
  Components: app; Flags: ignoreversion recursesubdirs createallsubdirs
```

The `[InstallDelete]` rule that nuked `{app}\.godot` was replaced with one that
only clears the (never-shipped) `.godot\editor` on upgrade, leaving the shipped
cache intact.

The shipped cache files (`global_script_class_cache.cfg`, `uid_cache.bin`,
`imported/`, `shader_cache/`, `scene_groups_cache.cfg`) all use portable
`res://` references, so they work in any install location.

## Verification

1. Reproduced the blank screen by running the app with `.godot` removed →
   the `class_name` / autoload parse errors above.
2. Confirmed adding the `.godot` cache back (minus `editor/`) → **zero**
   class/autoload/script errors.
3. Rebuilt the installer (`mathdot-1.2.0-Setup.exe`), silently installed it to a
   fresh folder, and launched the installed `bin\Godot.exe --path <dir> --run`:
   the app now renders the **full UI** — toolbar (Notebook … Run All), Current
   Folder sidebar, and the algebra notebook with cells and results
   (`app_screenshot_task102.png`). No blank screen.
4. Confirmed the shipped `.godot\editor` folder is empty (no machine-specific
   paths leaked) and the install created no stray shortcuts.

## Files changed
- `mathdot.iss` — ship `.godot` (minus `editor/`); adjusted `[InstallDelete]`.
- `installers/mathdot-1.2.0-Setup.exe` — rebuilt with the fix (gitignored).

## Note
On the dev machine the installed app's auto-opened workspace still resolves to
the `i:/mathdot/app/notebooks_sample` dev-fallback path (it exists here). On a
clean machine that path won't exist, so the app opens with no workspace but the
**UI renders correctly** — which is the blank-screen fix. (Bundled samples
install to `Documents\mathdot\notebooks`; wiring the installed app to open that
folder by default is a separate enhancement, not part of this fix.)
