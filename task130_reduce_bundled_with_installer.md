# Task 130 — Is REDUCE CAS Installed with the Installer?

## Question

> "Is REDUCE CAS also installed with the installer?"

## Answer: Yes — REDUCE is fully bundled. No separate install is needed.

The installer ships the entire REDUCE CAS alongside the app, and the app launches
it from there. mathdot is self-contained — a user who runs
`mathdot-1.2.x-Setup.exe` gets a working CAS with no extra downloads.

## Evidence

### 1. The installer copies REDUCE into the app folder
[mathdot.iss](mathdot.iss) `[Files]`:

```
; REDUCE CAS binaries (from tools/reduce)
Source: "tools\reduce\bin\*"; DestDir: "{app}\reduce\bin"; Components: app; Flags: ignoreversion recursesubdirs
Source: "tools\reduce\lib\*"; DestDir: "{app}\reduce\lib"; Components: app; Flags: ignoreversion recursesubdirs
```

Both are part of the **`app` component**, which is `Flags: fixed` — i.e. it's
mandatory, not optional, so REDUCE installs in every install type (full /
compact / custom).

### 2. The engine binary lands exactly where the app looks for it
The app resolves the engine **relative to its own executable**
([math_engine.gd](app/autoload/math_engine.gd)):

```gdscript
exe_dir.path_join("reduce/lib/csl/reduce.exe")   # {app}\reduce\lib\csl\reduce.exe
```

The installer's `tools\reduce\lib\*` (recursive) puts `reduce\lib\csl\reduce.exe`
in that exact spot, so the lookup succeeds on an installed machine. (`csl` is the
CSL — Codemist Standard Lisp — runtime REDUCE is built on; the folder also holds
`reduce.img`, the heap image the `-w` / `-K 1000m` launch loads.)

### 3. What's bundled (≈270 MB)
| Path | Size | Contents |
|---|---|---|
| `tools/reduce/lib` → `{app}\reduce\lib` | ~169 MB | the CSL runtime + `reduce.exe`, `reduce.img`, fonts, packages |
| `tools/reduce/bin` → `{app}\reduce\bin` | ~0.5 MB | `rfcsl.exe` / `rfpsl.exe` launchers |

`tools/reduce/lib/csl/reduce.exe` (the binary the app runs) is present in the
source tree and ships verbatim.

### 4. Confirmed working from an actual install
In **task 128**, after silently installing `mathdot-1.2.2-Setup.exe` to a temp
folder and launching it, the **REDUCE engine process started** ("REDUCE engine
running: yes") — proving the bundled CAS not only installs but runs end-to-end
from the installer (the `-K 1000m` heap launch and all).

## Conclusion

REDUCE CAS **is** installed with the installer — it's a mandatory part of the
`app` component (~270 MB), placed at `{app}\reduce\…`, and the app launches
`{app}\reduce\lib\csl\reduce.exe` at runtime. The product is self-contained; the
user installs nothing else.

## Files changed
- None — investigation + documentation only.
