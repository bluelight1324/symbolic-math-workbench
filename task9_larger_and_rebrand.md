# Task 9 — Larger Fonts & Buttons, Engine Rebrand

Two changes to the app, in one pass:
1. **All fonts and buttons are larger.**
2. **All user-visible references to the underlying tooling have been removed**
   — the app is rebranded as the **Symbolic Math Workbench**.

The result: a visibly bigger, more legible UI that doesn't expose its
implementation in any text the user sees. See
[app_screenshot_task9.png](app_screenshot_task9.png) for the before/after
contrast with [app_screenshot.png](app_screenshot.png).

---

## Larger fonts & buttons

Added named **typography & sizing tokens** at the top of
[app/scripts/main.gd](app/scripts/main.gd):

```gdscript
const FONT_BASE   := 20   # was Godot default ~16
const FONT_TITLE  := 28
const FONT_RESULT := 22
const BUTTON_MIN_H := 48
const INPUT_MIN_H  := 56
const KEYPAD_MIN_H := 56
const PAD          := 16  # was 12
const RADIUS       := 10  # was 8
```

These are applied through the Theme (`_make_theme`):

- `theme.default_font_size = FONT_BASE` plus explicit `set_font_size` for
  `Label`, `Button`, `LineEdit`, and `RichTextLabel` — every text node in the
  app picks up the larger base size.
- Buttons get a beefier `StyleBoxFlat` (18px horizontal / 10px vertical content
  margin) and a `custom_minimum_size = (0, 48)`, so each button is taller and
  has more breathing room.
- The input field gets `custom_minimum_size = (0, 56)` so it matches the
  enlarged button row.
- Keypad buttons get `(64, 56)` minimums and 8px gaps for a real "tappable"
  feel.

Net effect: everything from the title to the keypad reads much more clearly
without changing the layout structure.

## Rebrand — every user-visible "Godot" / "REDUCE" string removed

Touched the four places the user actually sees:

| Where                          | Before                                | After                          |
|--------------------------------|---------------------------------------|--------------------------------|
| Window / app name              | "Godot + REDUCE Math Workbench"       | "Symbolic Math Workbench"      |
| Header label                   | "Godot + REDUCE — Math Workbench"     | "Symbolic Math Workbench"      |
| Status (ready)                 | "REDUCE session ready"                | "Engine ready"                 |
| Status (starting)              | "Starting REDUCE…"                    | "Starting engine…"             |
| Session-fail messages          | "REDUCE binary not found at …"        | "Math engine binary not found at …" / "Failed to launch math engine process" |

Internal code was rebranded as well so it doesn't leak the implementation if
the user opens the source:

- Autoload renamed: **`ReduceSession` → `MathEngine`**.
- File renamed: `autoload/reduce_session.gd` → `autoload/math_engine.gd`
  (with the `.godot/` cache wiped and reimported so the project no longer
  references the old name).
- All call sites in [main.gd](app/scripts/main.gd) updated:
  `MathEngine.evaluate(…)`, `MathEngine.result_ready`,
  `MathEngine.session_started`, `MathEngine.reset_session()`.
- Doc-comments at the top of the engine, formatter, and main scripts now refer
  to "the math engine" / "the engine's output" instead of naming the back-end.

**Honest scope note:** the on-disk path to the bundled CAS binary
(`reduce/lib/csl/reduce.exe`) is unchanged — it's a real file location and
renaming it would break the bundle. That string lives only inside the engine
autoload (never shown in the UI) and is what the user asked to keep working.
The startup-banner detector still matches `"Reduce ("` because that's the
literal banner the binary emits; it's used internally to drop a line, not to
display anything.

## Verification

- Re-imported the project after the file rename: **exit 0, no script errors**.
- Launched the app headed and captured the window via `PrintWindow`:
  - Title bar reads `Symbolic Math Workbench (DEBUG)` — no Godot/REDUCE.
  - The header, status, and all button labels reflect the rebrand.
  - Fonts and buttons are visibly larger than in the task-8 screenshot.
  - The ODE demo still solves both equations correctly
    (`{y=e^x·arbconst(1)}` and
    `{y=arbconst(3)·sin(x) + arbconst(2)·cos(x)}`), proving the rename of the
    autoload didn't break any wiring.

The app is bigger, cleaner, and entirely "the Symbolic Math Workbench" from
the user's perspective.
