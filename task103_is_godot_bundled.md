# Task 103 — Is Godot Installed Along With the App?

## Short answer

**Yes.** The Godot runtime is bundled inside the mathdot installer and installed
alongside the app. The end user does **not** need to install Godot separately —
the installer is self-contained.

## How it's bundled

[mathdot.iss](mathdot.iss) ships the Godot binary as part of the `app`
component and installs it as `bin\Godot.exe`:

```iss
; Godot runtime (from tools/godot) — installed as bin\Godot.exe
Source: "tools\godot\Godot_v4.6.3-stable_win64.exe"; DestDir: "{app}\bin"; \
  DestName: "Godot.exe"; Components: app; Flags: ignoreversion
```

Every shortcut and the post-install launch point at that bundled binary:

```iss
Filename: "{app}\bin\Godot.exe"; Parameters: "--path ""{app}"" --run"
```

So after install, the layout is:

```
C:\Program Files\mathdot\
  bin\Godot.exe          <- the bundled Godot runtime (165 MB)
  scripts\  scenes\  autoload\  project.godot  .godot\
  reduce\                <- the bundled REDUCE CAS engine
```

The installer therefore bundles **two** runtimes the app needs — **Godot**
(`bin\Godot.exe`) and **REDUCE** (`reduce\...`) — neither requires a separate
download or install.

## Why Godot is bundled (rather than required as a prerequisite)

mathdot is shipped as a **raw Godot project** (`scripts/`, `scenes/`,
`autoload/`, `project.godot`, plus the `.godot` cache), **not** as an exported
standalone executable — there is no `mathdot.exe` / `.pck` export in `app/`.
A raw project can't run on its own; it needs a Godot engine to execute it.

Two ways to satisfy that:

1. **Require the user to install Godot themselves** — fragile (wrong version,
   not on PATH, extra setup step) and a poor end-user experience.
2. **Bundle the Godot runtime in the installer** ← what mathdot does.

Bundling makes the install self-contained and version-correct: the app always
runs against the exact engine it was built for (Godot 4.6.3-stable). The
shortcut runs `bin\Godot.exe --path "{app}" --run`, i.e. the bundled engine
runs the bundled project in place.

## Consequences of this choice

- **Installer size** — the Godot binary is ~165 MB uncompressed, which is why
  the installer is ~104 MB compressed (and why `tools/` is git-ignored and not
  on GitHub; the README documents fetching it to build locally).
- **The "(DEBUG)" window title** — because the *editor* build of Godot is used
  as the runtime (running a project through it), the window shows
  `mathdot (DEBUG)`. It's a runtime indicator, not a separate program.

## The alternative: a proper Godot export (not currently used)

Godot's **Project ▸ Export** can produce a standalone `mathdot.exe` (+ a `.pck`
data file) using export templates. That would:

- drop the full editor binary (smaller download),
- remove the `(DEBUG)` tag, and
- give a single-purpose executable.

It's the more "professional" packaging, but it requires installing Godot export
templates and an export step. The current pipeline deliberately bundles the
engine binary instead — simpler to build, and it's what produced the working
installer in tasks 90/91/101/102. Switching to a true export is a worthwhile
future enhancement (already flagged in the installer notes), but is out of scope
for this question.

## Conclusion

Godot **is** installed with the app — bundled as `bin\Godot.exe` inside the
mathdot installer — so users get a fully self-contained install (Godot + REDUCE
+ the project) with nothing extra to download.

## Files
- `mathdot.iss` — corrected a stale comment about `.godot` (doc-only; the Godot
  bundling line was already correct).
