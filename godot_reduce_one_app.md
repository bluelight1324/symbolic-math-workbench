# Combining Godot and REDUCE into One Application

Tasks 1–4 treated Godot (UI) and REDUCE (CAS) as two cooperating pieces. This
doc answers task 5: **how to ship them as a single application** the user
double-clicks once — no separate REDUCE install, no terminal, no "start the
server first."

The honest constraint up front: REDUCE is a separate native program (a Lisp
image running `reduce.exe`), and Godot cannot *link* it in-process. So "one
application" means **one self-contained bundle** where Godot launches and drives
an embedded REDUCE — not a single binary. The goal is that, to the user, it's
indivisible.

---

## The integration options, ranked

| # | Approach | One bundle? | State persists? | Effort |
|---|----------|-------------|-----------------|--------|
| 1 | **Bundle `reduce.exe`, drive via piped subprocess** | ✅ | ✅ (long-lived process) | Low–Med |
| 2 | One-shot subprocess per evaluation (`OS.execute`) | ✅ | ❌ | Low |
| 3 | Local HTTP/socket wrapper around REDUCE, bundled | ✅ | ✅ | Med |
| 4 | GDExtension calling REDUCE's C entry points | ✅ (tight) | ✅ | High |

**Recommended: #1** — bundle the REDUCE binary inside the Godot export and keep
one long-lived REDUCE process that Godot talks to over stdin/stdout. It's
self-contained, keeps session state (variables, packages, modes), and avoids
per-call startup cost. #4 is the most "single binary" but REDUCE's CSL runtime
makes it heavy; rarely worth it.

---

## Architecture of the combined app

```
   ┌──────────────────────── one bundle (export folder / installer) ─────────┐
   │                                                                          │
   │   MathApp.exe (Godot)                         reduce/  (bundled CAS)     │
   │   ┌───────────────────────────┐               ┌──────────────────────┐  │
   │   │ UI scenes (Control nodes)  │               │ lib/csl/reduce.exe    │  │
   │   │            │               │  stdin/stdout │ + heap image (.img)   │  │
   │   │  ReduceSession (autoload) ─┼──────────────▶│  one long-lived proc  │  │
   │   │            ▲               │◀──────────────│                       │  │
   │   └────────────┼───────────────┘   results     └──────────────────────┘  │
   │      signals (result_ready)                                              │
   └──────────────────────────────────────────────────────────────────────────┘
```

One process tree, one window, one icon. REDUCE is a child process the user never
sees.

---

## The glue: a `ReduceSession` autoload (GDScript)

A single autoload owns the REDUCE child process for the whole app's lifetime.

```gdscript
# reduce_session.gd  (registered as an Autoload singleton)
extends Node

signal result_ready(id: int, output: String)

var _pid: int = -1
var _stdio: FileAccess        # via OS.create_process with pipe (Godot 4.x)
var _queue: Array = []
var _next_id: int = 0

func _ready() -> void:
    # Path is resolved relative to the bundled executable, so it works
    # wherever the app is installed.
    var exe_dir := OS.get_executable_path().get_base_dir()
    var reduce_exe := exe_dir.path_join("reduce/lib/csl/reduce.exe")
    # Start ONE long-lived REDUCE in console mode reading commands on stdin.
    var info := OS.execute_with_pipe(reduce_exe, ["-w"])  # keeps it alive
    _pid = info.get("pid", -1)
    _stdio = info.get("stdio")

func evaluate(code: String) -> int:
    var id := _next_id
    _next_id += 1
    var script := code.strip_edges()
    if not (script.ends_with(";") or script.ends_with("$")):
        script += ";"
    _stdio.store_string(script + "\n")
    # Read on a worker thread until REDUCE prints its "n:" prompt, then:
    #   call_deferred("emit_signal", "result_ready", id, cleaned_output)
    return id   # caller matches the result by id

func reset() -> void:
    # Deliberately clear CAS state without restarting the whole app.
    _stdio.store_string("clear; off latex;\n")

func _exit_tree() -> void:
    if _pid != -1:
        _stdio.store_string("bye;\n")
        OS.kill(_pid)
```

Key points that make it feel like one app:
- **Lifetime tied to Godot:** REDUCE starts in `_ready()`, dies in `_exit_tree()`
  / `OS.kill` — the user never starts or stops it.
- **Path relative to the executable** (`OS.get_executable_path()`), so the
  bundled REDUCE is found no matter where the app is installed.
- **Asynchronous:** reading happens on a worker thread; the UI gets a
  `result_ready` signal and never blocks (ties into task-2 §7–8 and task-4 §2).

---

## Packaging it as one deliverable

1. **Export the Godot project** (Project → Export → Windows Desktop) to a folder,
   e.g. `MathApp/MathApp.exe`.
2. **Place REDUCE beside it** — copy the `reduce/` tree (already in
   [tools/reduce/](tools/reduce/) from task 3) into `MathApp/reduce/`. The CSL
   build is self-contained (it carries its own heap image), so no system install
   is needed.
3. **Resolve the path at runtime** from `OS.get_executable_path()` (above) — not
   a hard-coded `C:\Program Files\...`.
4. **Wrap into one installer** (optional but recommended for "one app" feel):
   - Inno Setup / NSIS / WiX bundles `MathApp.exe` + `reduce/` + icon + Start-menu
     shortcut into a single `setup.exe`.
   - Or ship a single self-extracting / zipped folder the user unzips and runs.
5. **One icon, one name, one window.** Set the app icon and name in Godot export
   settings so the bundled REDUCE is invisible.

```
MathApp/                 <- distribute this whole folder (or installer)
├─ MathApp.exe           <- the only thing the user launches
├─ *.pck                 <- Godot resources
└─ reduce/
   └─ lib/csl/reduce.exe <- child process, never launched by the user
```

---

## Why subprocess, not "true" embedding

- REDUCE's engine is a Lisp system with its own runtime and heap image; it's
  designed to run as its own process. Godot has no in-process CAS API to link
  against.
- The piped-subprocess model is the standard, robust way and is fully
  cross-platform (`reduce` on Linux/macOS, `reduce.exe` on Windows) — only the
  bundled binary differs per platform.
- It cleanly separates concerns: if REDUCE crashes on a pathological input, the
  app can detect the dead pipe and **restart just the child**, not the whole UI.

---

## Verification (against the bundled REDUCE)

The combined-app model relies on one behavior: a single REDUCE process accepting
multiple commands over stdin and **retaining state** between them. Confirmed on
the bundled binary at `tools/reduce/lib/csl/reduce.exe`:

```
input :  a := 5; b := a^2 + 1; df(b*x, x);  bye;
output:  a := 5  /  b := 26  /  26*x
```

`b` correctly used the earlier binding of `a`, and the later `df` used `b` — i.e.
one persistent process is enough to back the whole app. (See run output recorded
when this doc was authored.)

---

## Build order

1. Take the task-1 bridge and refactor it into the `ReduceSession` autoload above.
2. Switch from per-call `OS.execute` to one `execute_with_pipe` process + worker
   thread reader.
3. Export the Godot app to a folder; drop `reduce/` next to the `.exe`; resolve
   the path from `OS.get_executable_path()`.
4. Test the exported folder on a clean machine (no REDUCE installed) — it must
   just work.
5. Wrap in an installer for a true one-double-click experience.
```