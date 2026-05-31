# Building a Math UI with Godot + REDUCE CAS

## Goal
Use **Godot** (game/UI engine) as the front-end and **REDUCE** (a Computer
Algebra System) as the symbolic-math back-end, so a user can type a math
expression, press a button, and see the simplified / solved / differentiated
result rendered in a clean interface.

Godot is great at interactive UI (buttons, text fields, graphs, touch/mobile,
real-time rendering). REDUCE is great at *symbolic* math (exact algebra,
calculus, equation solving) that Godot's numeric engine can't do. Pairing them
gives a real "math workbench" app.

---

## Architecture

```
+-------------------+        text expr         +------------------+
|   Godot front-end | -----------------------> |  REDUCE process  |
|  (UI / GDScript)  |                          |  (CAS back-end)  |
|                   | <----------------------- |                  |
+-------------------+      simplified result   +------------------+
```

Godot does **not** do the math. It:
1. Collects the user's input (a `LineEdit` / `TextEdit`).
2. Sends the expression as text to REDUCE.
3. Receives REDUCE's text answer.
4. Renders it (a `Label`, `RichTextLabel`, or a plotted curve).

REDUCE runs as a separate process. Two practical ways to talk to it:

- **A. Spawn the CLI** (`redcsl`/`reduce`) from Godot via `OS.execute()` and
  read stdout. Simplest; good for one-shot evaluations.
- **B. Long-running pipe** via `OS.create_process()` + a small wrapper, or a
  thin HTTP wrapper around REDUCE that Godot calls with `HTTPRequest`. Better
  for an interactive session that keeps state between queries.

---

## Why this split works

| Concern              | Handled by | Reason                                  |
|----------------------|-----------|------------------------------------------|
| Buttons, layout, theme | Godot   | Best-in-class scene/UI system            |
| Live plotting        | Godot     | Draw API / `Line2D` for graphs           |
| Symbolic simplify    | REDUCE    | Exact algebra, not floating point        |
| Solve / factor / diff/int | REDUCE | `solve`, `factorize`, `df`, `int`      |
| Mobile / desktop pkg | Godot     | Exports to many platforms                |

---

## Example REDUCE calls the UI exposes

These are the operations to put behind buttons. (Verified against REDUCE.)

| UI button   | REDUCE command sent        | Example result            |
|-------------|----------------------------|---------------------------|
| Simplify    | `(x+1)^2;`                 | `x^2 + 2*x + 1`           |
| Factor      | `factorize(x^2 - 1);`      | `{{x + 1,1},{x - 1,1}}`   |
| Differentiate | `df(sin(x)*x, x);`       | `cos(x)*x + sin(x)`       |
| Integrate   | `int(1/x, x);`             | `log(x)`                  |
| Solve       | `solve(x^2 - 4, x);`       | `{x = 2, x = -2}`         |

---

## Minimal Godot side (GDScript sketch)

```gdscript
extends Control

@onready var input_field: LineEdit = $Input
@onready var result_label: Label = $Result

func _on_simplify_pressed() -> void:
    var expr := input_field.text.strip_edges()
    if not expr.ends_with(";"):
        expr += ";"
    result_label.text = _run_reduce(expr)

func _run_reduce(commands: String) -> String:
    # Pipe the commands into the REDUCE CLI and capture stdout.
    var output: Array = []
    # 'redcsl' is the REDUCE binary; adjust path/args for your install.
    OS.execute("redcsl", ["-w"], output, true, false)
    # For real use, write `commands` to a temp .red file and pass it,
    # or use create_process() to keep an interactive pipe open.
    return _clean(output[0] if output.size() > 0 else "")

func _clean(raw: String) -> String:
    # REDUCE echoes prompts/banner; strip to just the answer line(s).
    return raw.strip_edges()
```

> Note: `OS.execute` is blocking and one-shot. For a responsive UI, run the
> call on a `Thread`, or use the HTTP-wrapper approach (B) so the main thread
> never freezes while REDUCE computes.

---

## Recommended UX

- **Input row:** `LineEdit` + a row of operation buttons (Simplify, Factor,
  d/dx, ∫, Solve).
- **Output:** `RichTextLabel` so you can show results in a larger / math-ish
  font; optionally pretty-print REDUCE output.
- **History:** a scrolling `VBoxContainer` of past input→result pairs (acts
  like a notebook).
- **Plot panel:** when the expression is a function of `x`, ask REDUCE to
  evaluate it at sample points and draw the curve with `Line2D`, combining
  exact symbolic work with Godot's rendering.

---

## Build order (steps)

1. Confirm REDUCE runs from the command line on the target machine.
2. Make a one-shot bridge: GDScript sends a hard-coded `(x+1)^2;` and prints
   the result to verify the pipe works end-to-end.
3. Wrap it: input field → button → `_run_reduce()` → label.
4. Move the call onto a `Thread` (or HTTP wrapper) so the UI stays smooth.
5. Add the operation buttons, each wrapping the expr in the right REDUCE call.
6. Add history + plotting.
7. Export for desktop (REDUCE must be installed/bundled alongside).

---

## Caveats
- REDUCE must be present on the user's system or bundled with the export;
  Godot only orchestrates it.
- Parse/clean REDUCE's text output (it prints a banner and `n:` prompts).
- Validate user input before sending it, to avoid sending broken syntax.
```