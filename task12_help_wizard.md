# Task 12 — Help Wizard

Added an in-app, multi-step Help wizard that walks the user through every
operation the workbench supports, with a "Try it" button on each relevant step
that actually runs the example live against the engine. See
[app_screenshot_wizard.png](app_screenshot_wizard.png) for the running wizard.

---

## What the wizard is

A modal overlay (not a separate OS window) that dims the rest of the UI and
shows a single step at a time. Built as
[app/scripts/help_wizard.gd](app/scripts/help_wizard.gd) — a reusable
`HelpWizard` Control whose steps are supplied by the caller.

```
+-------------------------------------------------+
|  Step N of M                              [×]   |
|                                                 |
|  <Title — 26 pt>                                |
|                                                 |
|  <Body, RichTextLabel BBCode, scrollable>      |
|                                                 |
|  [▶ Try it]              [← Back] [Next →] [Close]
+-------------------------------------------------+
```

Each step is a `Dictionary` with `title`, `body`, and an optional `try: Callable`
that is invoked by the Try-it button.

## The tour — 13 steps

Defined by `_help_steps()` in [main.gd](app/scripts/main.gd). The steps cover
literally every operation in the app:

| # | Step                              | Try-it action                                      |
|---|-----------------------------------|----------------------------------------------------|
| 1 | Welcome                           | (none — overview only)                             |
| 2 | The input field                   | sets input to `(x+1)^2` and grabs focus            |
| 3 | Simplify & Factor                 | runs `(x+1)^2` → `x² + 2x + 1`                    |
| 4 | Differentiate (d/dx)              | `df(sin(x)*x, x)` → `cos(x)·x + sin(x)`            |
| 5 | Integrate (∫ dx)                  | `int(1/(x²+1), x)` → `atan(x)`                     |
| 6 | Solve — algebraic                 | `solve(x²−5x+6, x)` → `{x=3, x=2}`                |
| 7 | Solve ODE — differential          | `odesolve(df(y,x) = y, y, x)` → `y = eˣ·C`        |
| 8 | Plot + parameter sliders          | plots `sin(x) + a·cos(x)`; explains the `a` slider |
| 9 | Menu library — 72 preset problems | clicks Algebra → "Factor x⁶ − 1" via the menu API |
|10 | Keypad & shortcuts                | inserts `sqrt(` at the caret                       |
|11 | View menu & resizing              | (instructional, no try)                            |
|12 | History & Reset session           | (instructional, no try)                            |
|13 | All set! — closing                | (instructional)                                    |

Every Try-it callable is a real, working Callable into `_do_op(...)`,
`_on_problem_selected(...)`, or `_insert_token(...)` — exactly the same code
paths used when the user clicks the corresponding button or menu item. The
wizard is **not** showing fake screenshots of features; it drives the real app.

## How to open the wizard

Three ways:

| Method                  | Where                                                 |
|-------------------------|-------------------------------------------------------|
| **F1** anywhere         | Handled in `_unhandled_input` ([main.gd](app/scripts/main.gd)) |
| **Help → Open Tour**    | Last menu in the menu bar (added in `_build_menubar`) |
| `--tour` startup flag   | Auto-opens on launch, useful for screenshotting       |

Inside the wizard:
- **← / →** arrow keys (or **PageUp / PageDown**) navigate.
- **Esc** closes the wizard. (Main's Esc handler is guarded so it doesn't
  steal the key while the wizard is up.)
- **× / Close** buttons dismiss.

## How the wizard integrates without fighting the rest of the UI

- It's a `Control` overlay, not a `Window`, so it stays inside the main window
  (no separate native window).
- `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` ensures it actually
  fills the maximized window. (I shipped a first cut using `set_anchors_preset`
  which only changed anchors without resetting offsets, so the panel rendered
  pinned at top-left with no dim backdrop. Verified via the captured
  screenshot, then fixed — see "Honest correction" below.)
- The dim backdrop is a full-rect `ColorRect` with `mouse_filter = STOP`, so
  clicks behind the wizard are blocked.
- The wizard panel is wrapped in a `CenterContainer`, so it centres regardless
  of window size (Compact, Default, Large, Full HD, Maximized, Fullscreen).
- The wizard's `_unhandled_input` only handles keys when `visible == true`,
  so it doesn't steal events when closed.
- Main's `_unhandled_input` returns early on Esc when the wizard is visible,
  so Esc cleanly closes the wizard instead of also toggling fullscreen.

## Verification

- Project imports headless after the edits with **exit 0, no script errors**.
- Headed launch with `-- --tour --capture <path>` produced
  [app_screenshot_wizard.png](app_screenshot_wizard.png), which shows:
  - The maximized app window (3440×1334 on this monitor).
  - The wizard centred in the window, with dim backdrop visible behind it.
  - The new **Help** menu present as the last entry in the menu bar (`View |
    Algebra | Calculus | Equations | ODEs | Matrices | Series | Trig |
    Numbers | Plots | Help`).
  - Step 1 of 13 — "Welcome" — with the body BBCode rendered (`Next →` /
    `← Back` bold, the bullet list, etc.) and the Try-it button correctly
    hidden (this step has no try Callable).
  - Action row: `← Back` (disabled on step 1), `Next →` (focused), `Close`.

## How to run

```powershell
# Normal launch — open the wizard via F1 or Help → Open Tour.
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' --path 'i:\readtgodot\app'

# Auto-open the wizard at startup.
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --tour
```

## Honest correction made while shipping this

The first wizard build rendered correctly (text, buttons, BBCode all worked)
but the overlay didn't stretch to fill the window — it sat at the top-left
with no dim backdrop visible behind the rest of the UI. Root cause:
`Control.set_anchors_preset(PRESET_FULL_RECT)` was called but the Control's
offsets were not reset, so it kept its zero default size. Calling
`set_anchors_and_offsets_preset(PRESET_FULL_RECT)` instead — both for the
wizard root and the dim backdrop — fixed it cleanly. The post-fix screenshot
shows the wizard centred with a proper dim backdrop, and is what shipped.
