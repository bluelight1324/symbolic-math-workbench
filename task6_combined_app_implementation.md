# Task 6 — Implementing the Combined App (Option 1)

This implements the **recommended option #1** from
[godot_reduce_one_app.md](godot_reduce_one_app.md): a single Godot application
that bundles the REDUCE binary and drives **one long-lived REDUCE process** over
a stdin/stdout pipe. The user launches one app; REDUCE runs invisibly as a child
process.

The working project lives in [app/](app/) and uses the REDUCE bundled in
[tools/reduce/](tools/reduce/) (from task 3) and the Godot bundled in
[tools/godot/](tools/godot/).

---

## What was built

```
app/
├─ project.godot                  app config + ReduceSession autoload
├─ icon.svg
├─ autoload/
│   └─ reduce_session.gd           ← the core: persistent piped REDUCE process
├─ scripts/
│   ├─ main.gd                     UI (built in code) + operation wiring
│   ├─ math_formatter.gd           REDUCE text → BBCode, list parsing, validation
│   └─ plot_panel.gd               custom-drawn plot
└─ scenes/
    └─ main.tscn                   root Control running main.gd
```

## The core: `ReduceSession` (option 1 in code)

[app/autoload/reduce_session.gd](app/autoload/reduce_session.gd) is an **autoload
singleton** that owns REDUCE for the app's whole lifetime:

- **Starts one process** with `OS.execute_with_pipe(reduce_exe, ["-w"])` in
  `_ready()` and keeps it alive — no per-click process spawning.
- **Finds the binary relative to the executable**
  (`OS.get_executable_path().get_base_dir()/reduce/lib/csl/reduce.exe`), with a
  dev fallback to `tools/reduce/...`, so the exported bundle is self-contained.
- **Asynchronous, non-blocking:** a worker `Thread` reads REDUCE's output;
  results return to the UI through a `result_ready(id, output, is_error)` signal
  via `call_deferred`. The window never freezes.
- **Reliable request/response correlation via a SENTINEL.** After each command
  the session sends `write "<<<RDONE n>>>";`. The reader treats every line up to
  that sentinel as the result for request `n`. This was chosen over parsing
  REDUCE's interactive `n:` prompts after an empirical test showed the prompts
  don't reliably terminate a read, but the sentinel always does.
- **Clean shutdown:** `_exit_tree()` sends `bye;` and `OS.kill`s the child, so no
  orphan REDUCE process is left behind.
- **Linear output:** sends `off nat; off echo;` at startup so results are
  single-line (`x**2 + 2*x + 1`) and easy to format.

## The UI ([app/scripts/main.gd](app/scripts/main.gd))

Built entirely in GDScript (no fragile scene wiring): an input field, a row of
operation buttons, a scrolling history "notebook", and a keypad. Each button
wraps the expression in the right REDUCE call and routes the async answer back
to its history row by id:

| Button   | REDUCE sent          |
|----------|----------------------|
| Simplify | `expr`               |
| Factor   | `factorize(expr)`    |
| d/dx     | `df(expr, x)`        |
| ∫ dx     | `int(expr, x)`       |
| Solve    | `solve(expr, x)`     |

(Plotting and the task-4 upgrades are documented in
[task7_improvements_implementation.md](task7_improvements_implementation.md).)

---

## Verification — it actually runs

Validated headlessly with the bundled Godot 4.6.3:

1. **Imports & parses cleanly** —
   `Godot --headless --path app --import` → exit 0, no script errors.
2. **Runs without runtime errors** — `--quit-after` run → exit 0; REDUCE child
   launches (no "binary not found").
3. **End-to-end through the real pipe** — a self-test scene drove
   `ReduceSession.evaluate(...)` against the live bundled REDUCE:

   | Sent                         | Got back (by matching id)     |
   |------------------------------|-------------------------------|
   | `(x+1)^2`                    | `x**2 + 2*x + 1`              |
   | `df(sin(x)*x, x)`            | `cos(x)*x + sin(x)`           |
   | sampled `x^2+1` over 0..3    | `{1,2,5,10}`                  |

   All three answers came back asynchronously and were correlated to the right
   request id — proving the persistent session + sentinel + threaded reader work.

> Note: the headless checks confirm the engine, scripts, autoload, pipe, and
> REDUCE integration. The visual UI itself (themed widgets, drawn plot) requires
> a desktop run — `tools\godot\Godot_v4.6.3-stable_win64.exe --path app` — since
> headless mode does no rendering.

---

## Running it

```powershell
# Editor / dev run (uses tools\reduce fallback path):
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' --path 'i:\readtgodot\app'
```

To ship as one bundle: export the project (Windows Desktop) and copy
`tools\reduce\` next to the exported `.exe`, exactly as
[godot_reduce_one_app.md](godot_reduce_one_app.md) describes — the runtime path
resolution then finds REDUCE automatically.
