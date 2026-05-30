# Task 32 — Tick-Box Package Settings + Persisted Default-Load

Implements the UI side of the task-31 design: a modal settings dialog
where the user can **tick** which REDUCE packages to load at engine
start, persists the choice between launches, and applies it via a quick
engine restart.

See [app_screenshot_packages.png](app_screenshot_packages.png) for the
running dialog.

---

## What shipped

Three new pieces, plus wiring into the existing main scene:

| File | Role |
|------|------|
| [app/scripts/package_config.gd](app/scripts/package_config.gd) | Pure config: knows the `KNOWN` package list (name / tier / one-line description) and reads/writes `user://packages.cfg` |
| [app/scripts/package_settings.gd](app/scripts/package_settings.gd) | Modal overlay dialog — checkbox list grouped by tier, Cancel / Restore-defaults / Apply buttons |
| [app/autoload/math_engine.gd](app/autoload/math_engine.gd) — new `restart()` | Tear down the child engine, then `_start()` again so the new package set takes effect |

### `package_config.gd` — what gets persisted

```gdscript
const PATH := "user://packages.cfg"

const KNOWN := [
    {"name": "odesolve", "tier": 1, "desc": "ODE solver — `odesolve(...)`"},
    {"name": "taylor",   "tier": 1, "desc": "Taylor series — `taylor(...)`"},
    …
    {"name": "groebner", "tier": 3, "desc": "Gröbner bases for ideal computation"},
    {"name": "redlog",   "tier": 3, "desc": "Quantifier elimination …"},
    {"name": "excalc",   "tier": 3, "desc": "Exterior calculus / differential forms"},
]

const DEFAULT_SELECTED := [
    "odesolve", "taylor", "limits", "defint", "specfn", "sum", "roots",
]
```

`load_selected()` returns the user's ticked list (or `DEFAULT_SELECTED`
on first run); it filters against `KNOWN` so a malformed cfg can't break
engine startup. `to_load_block(names)` builds the `load_package … ;
load_package … ;` string that `_start()` injects after `off nat; off
echo;`.

### `package_settings.gd` — the dialog

Built with the same pattern as the help wizard:

```
+--------- REDUCE packages — loaded at startup ---------+
|                                                       |
|  Tick packages to load on every engine start. Changes |
|  apply to the current session via a quick engine     |
|  restart on [Apply].                                  |
|                                                       |
|  Tier 1  Recommended — small, broadly useful         |
|    ☑ odesolve     ODE solver — odesolve(...)         |
|    ☑ taylor       Taylor series — taylor(...)        |
|    ☑ limits       Symbolic limits — limit(...)        |
|    ☑ defint       Definite integration with bounds   |
|    ☑ specfn       Bessel, Gamma, error fns, etc.     |
|    ☑ sum          Symbolic summation — sum(...)       |
|    ☐ rlfi         LaTeX output via `on latex`         |
|    ☑ roots        Polynomial root finding              |
|                                                       |
|  Tier 2  Useful — modest size, specific domains       |
|    ☐ laplace      Laplace transforms (and inverse)    |
|    ☐ ztrans       Z-transforms                         |
|    ☐ …                                                |
|                                                       |
|  Tier 3  Specialised — larger / niche                 |
|    ☐ groebner     Gröbner bases for ideal computation |
|    ☐ redlog       Quantifier elimination over real/…  |
|    ☐ excalc       Exterior calculus / differential …  |
|                                                       |
|  [Restore defaults]       [Cancel] [Apply (engine restart)] |
+------------------------------------------------------+
```

Implementation: `CenterContainer` → `PanelContainer` → `VBoxContainer`
of `Label` (tier headers) + `HBoxContainer` rows (`CheckBox` + `Label`
description) inside a `ScrollContainer`. Each `CheckBox` is registered
in a `_checks` Dictionary keyed by package name so the Apply handler
can collect the ticked names back into the canonical `KNOWN` order:

```gdscript
func _apply() -> void:
    var selected: Array = []
    for pkg in PackageConfig.KNOWN:   # KNOWN order = canonical load order
        if (_checks[pkg["name"]] as CheckBox).button_pressed:
            selected.append(pkg["name"])
    PackageConfig.save_selected(selected)
    apply_requested.emit(selected)
    close_panel()
```

### `MathEngine.restart()` — the apply hook

Old session is torn down cleanly:

```gdscript
func restart() -> void:
    _running = false
    if _stdio:
        _stdio.store_string("bye;\n")
        _stdio.flush()
    if _pid != -1:
        OS.kill(_pid)
        _pid = -1
    if _reader and _reader.is_started():
        _reader.wait_to_finish()
    _stdio = null
    _pending.clear()
    _next_id = 0
    _ready_ok = false
    _start()   # ← re-reads PackageConfig.load_selected()
```

`_start()` was already loading its package list from
`PackageConfig.to_load_block(PackageConfig.load_selected())`, so a
restart automatically reflects whatever the user just saved.

## Wiring

Three additions to [main.gd](app/scripts/main.gd):

1. `_pkg_settings = PackageSettingsScript.new(); add_child(...)` —
   attached as a child overlay so its full-rect anchors work like the
   help wizard's.
2. `view_menu.add_item("Engine packages…   (F4)", 8)` and matching
   `match` arm calling `_open_package_settings()`.
3. Connect `_pkg_settings.apply_requested` → `_on_packages_applied()`,
   which calls `MathEngine.restart()` and shows status text.
4. `KEY_F4` in `_unhandled_input` opens the dialog directly.

A `--packages` CLI flag was added so the dialog can be opened by a
single command (used to capture the screenshot above).

## Verification

- Project re-imports headless with **exit 0, no script errors**.
- `--packages` launch shows the dialog correctly populated with the
  current `DEFAULT_SELECTED` ticked (the seven tier-1 items minus
  `rlfi`). All 22 packages probed cleanly against the bundled REDUCE
  before the dialog was built, so each checkbox corresponds to a
  package that actually loads.
- Ticking a Tier-3 package, pressing Apply, and watching the status bar
  shows `Restarting engine with new packages…  →  Engine restarted`
  followed by the new operator becoming available (this is how the
  task-33 Gröbner-basis demo was prepared).

## Honest scope

- **Engine restart is "stop & start a child process,"** which on this
  machine takes ~150 ms. On slower hardware the user will notice it; a
  status label tells them what's happening.
- **No per-notebook package selection** yet — that belongs further out
  on the [task 18 roadmap](task18_requirements.md). Today's setting is
  machine-wide (`user://packages.cfg`).
- **`rlfi` is intentionally off by default** — see
  [task 31](task31_default_packages.md) §"Tier 1" for why.
