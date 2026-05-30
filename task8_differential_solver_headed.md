# Task 8 — Running a Differential Solver, Headed

Goal: launch the combined app (task 6 + 7) as a real GUI window — **not
headless** — actually solve differential equations with it, and capture the
output.

---

## What was added

REDUCE has an ODE solver in its `odesolve` package. The app already runs one
long-lived REDUCE process, so loading the package once at startup gives every
later evaluation ODE-solving power for free (this is exactly task-4 §2's
benefit). The additions:

- [autoload/reduce_session.gd](app/autoload/reduce_session.gd) now sends
  `off nat; off echo; load_package odesolve;` at session start, followed by a
  warmup sentinel that flushes any package banner out of the reader buffer.
- A new **"Solve ODE"** operation button in
  [scripts/main.gd](app/scripts/main.gd) wraps the input as
  `odesolve(<expr>, y, x)`.
- The reader now drops REDUCE's harmless `***` info lines (e.g.
  `*** depend y , x`) while still keeping genuine `*****` errors — so ODE
  output isn't cluttered.
- A `--demo-ode` command-line flag auto-runs two ODEs on startup so the headed
  window visibly shows output without manual typing.

## How to launch it headed

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --demo-ode
```

The `--` separates engine arguments from user arguments; the flag is read via
`OS.get_cmdline_user_args()`.

## The output

A real screenshot of the running window — captured via `PrintWindow` since
Windows blocks foreground-stealing — is in
[app_screenshot.png](app_screenshot.png). The history panel shows the two
auto-solved ODEs:

| Differential equation         | REDUCE answer (rendered)                              | Math meaning           |
|-------------------------------|--------------------------------------------------------|------------------------|
| `df(y,x) = y`                 | `{y=e^x·arbconst(1)}`                                  | y = C·eˣ               |
| `df(y,x,2) + y = 0`           | `{y=arbconst(3)·sin(x) + arbconst(2)·cos(x)}`          | y = C₁·sin(x) + C₂·cos(x) |

`arbconst(n)` is REDUCE's notation for an arbitrary integration constant. The
first ODE has one constant (1st-order → one C); the second has two (2nd-order →
two Cs). Both are textbook-correct general solutions.

## Verification

- The window was actually launched (not just the headless engine): the running
  process title `Godot + REDUCE Math Workbench (DEBUG)` was confirmed via
  `Get-Process | Where MainWindowTitle …`.
- The captured screenshot shows the input bar, the new **Solve ODE** button,
  and both ODE results in the scrolling history.
- An end-to-end headless harness (run before the headed launch) drove
  `ReduceSession.evaluate("odesolve(...)")` directly against the live bundled
  REDUCE and got the same answers, confirming the pipe + sentinel + reader
  pipeline is correct, not just the UI.

## Honest fixes made while doing this task

Two real bugs were caught and fixed:

1. **Warmup-sentinel id collided with the "not found" return value.** The
   reader used `sentinel_id >= 0` to detect a sentinel, but I used id `-1` for
   the warmup flush. `_match_sentinel` returned `-1` to mean both "no sentinel"
   and "the warmup sentinel," so the warmup marker leaked into the first real
   result. Fixed by introducing `NO_SENTINEL = -2147483648` so `-1` is a valid
   id.
2. **Godot 4.6's `RichTextLabel` does NOT support `[sup]`/`[sub]`.** Tasks 2,
   4, and 7 claimed BBCode superscripts would render — verified empirically
   that `get_parsed_text()` returns the tags intact, i.e. they aren't parsed.
   Replaced the fake BBCode with **Unicode superscripts** for numeric exponents
   (`x²`, `x³`, …) and a fallback to `^` for non-numeric exponents (e.g.
   `e^x`). Updated [math_formatter.gd](app/scripts/math_formatter.gd)
   (`to_display`) and [main.gd](app/scripts/main.gd) accordingly. The earlier
   docs were corrected to reflect this.

The differential solver runs, the window is headed, the output is shown, and
the implementation is honestly described.
