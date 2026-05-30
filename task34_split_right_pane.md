# Task 34 — Right Pane Split into Code + Result/Plot

The calculator view's right column used to be the plot panel only. Task
34 splits it vertically into two panes:

- **Top — Code.** A read-only `CodeEdit` showing the actual REDUCE
  command sent for the most recent operation. So when you click
  `Solve ODE` on `df(y,x) = y`, the top pane shows
  `odesolve(df(y,x) = y, y, x)` — the exact string handed to the
  engine, not your friendlier-formatted input.
- **Bottom — Result + Plot.** A `Result` line carrying the formatted
  engine output (`{y = e^x·arbconst(1)}` etc.), and underneath, the
  existing plot canvas with its parameter sliders. The plot stays empty
  (no grid, per task 26) until you actually request a plot.

A `VSplitContainer` between them is the user-draggable divider. The
history panel on the left and the layout everywhere else are unchanged.

Screenshot of the new layout (taken with `--demo-ode` so the ODE
sequence runs into the right pane):
[app_screenshot_splitright_small.png](app_screenshot_splitright_small.png).

---

## What changed in code

[main.gd](app/scripts/main.gd) — `_build_ui()`:

```gdscript
var right := VBoxContainer.new()
split.add_child(right)

var right_split := VSplitContainer.new()
right_split.split_offset = 200
right.add_child(right_split)

# --- top: Code pane ---
var code_box := VBoxContainer.new()
right_split.add_child(code_box)
code_box.add_child(Label.new())  # "Code  (engine command for the last operation)"
_code_view = CodeEdit.new()
_code_view.editable = false
_code_view.placeholder_text = "(click an operation — the REDUCE command appears here)"
code_box.add_child(_code_view)

# --- bottom: Result + Plot pane ---
var result_box := VBoxContainer.new()
right_split.add_child(result_box)
result_box.add_child(Label.new())  # "Result"
_result_view = RichTextLabel.new()
result_box.add_child(_result_view)
result_box.add_child(Label.new())  # "Plot  (x ∈ [-10, 10])"
result_box.add_child(_param_box)
result_box.add_child(_plot)
```

Two new fields: `_code_view: CodeEdit`, `_result_view: RichTextLabel`.

Two new tiny helpers handle the writes:

```gdscript
func _show_code(cmd: String) -> void:
    if _code_view:
        _code_view.text = cmd

func _show_result(text: String, is_err: bool) -> void:
    if _result_view == null:
        return
    _result_view.text = text
    _result_view.add_theme_color_override(
        "default_color", COL_ERR if is_err else COL_TEXT)
```

Wired into the three places that dispatch to the engine:

| Where                          | What it writes                                                |
|--------------------------------|---------------------------------------------------------------|
| `_do_op()` for non-plot ops    | `_show_code(cmd)` — the wrapped command (`factorize(...)`, `df(..., x)`, etc.) and clears result to "…" |
| `_request_plot()` for plot ops | `_show_code(cmd)` — the sampler command (`on rounded; for i:=0:200 collect sub(x=..., f); off rounded`) |
| `_on_result_ready()`           | `_show_result(formatted, is_error)` — pretty-printed output, or the cleaned `*****` error, with text-colour switched to the error red on failure |

For plot operations the Result line shows `plotted N samples` so the
user gets a confirmation that something arrived even though the visible
artefact is the plot itself.

## Why a `CodeEdit`, not a `Label`

`CodeEdit` is non-editable here but still gives:

- A monospace font that doesn't run together for long sampler commands.
- Word-wrap toggle and horizontal scrolling for very long commands.
- The same widget the notebook view uses for `cas` source —
  cosmetically consistent with task 19's editor.

`editable = false` keeps the user from accidentally typing into it.

## Behaviour in each scenario

| Click            | Code pane                                                      | Result pane                                  | Plot pane          |
|------------------|----------------------------------------------------------------|----------------------------------------------|---------------------|
| Simplify `(x+1)^2`| `(x+1)^2`                                                       | `x² + 2·x + 1`                                | (unchanged, blank)  |
| Factor `x^6 - 1` | `factorize(x^6 - 1)`                                            | `{{x²+x+1,1}, {x²-x+1,1}, {x+1,1}, {x-1,1}}` | (unchanged)         |
| d/dx `sin(x)*x`   | `df(sin(x)*x, x)`                                               | `cos(x)·x + sin(x)`                          | (unchanged)         |
| ∫ dx `1/(x^2+1)` | `int(1/(x^2+1), x)`                                             | `atan(x)`                                    | (unchanged)         |
| Solve `x^2-4`    | `solve(x^2 - 4, x)`                                             | `{x=2, x=-2}`                                | (unchanged)         |
| Solve ODE `df(y,x)=y` | `odesolve(df(y,x) = y, y, x)`                                | `{y=e^x·arbconst(1)}`                        | (unchanged)         |
| Plot `sin(x) + a·cos(x)` | `on rounded; for i:=0:200 collect sub(x=…, sin(x) + a·cos(x)); off rounded` | `plotted 201 samples`            | curve drawn         |

The history panel on the left also still records each input/result pair
exactly as before — the new right pane is in addition to, not in place of,
the history.

## Why this is genuinely useful

- **Transparency.** Users see exactly what wrapping the operation does
  to their expression. "Solve" + `x^2-4` = `solve(x^2 - 4, x)`. No magic.
- **Debugging.** When a result looks wrong, the Code pane lets you see
  whether the wrapping is the problem or the engine's answer is the
  problem.
- **Copy-pastable engine commands.** Selecting the Code text gives you
  the exact one-liner you can drop into a `cas` block in the notebook
  view, into a `.tst` file in [`workdoc/`](workdoc/), or directly into
  `reduce.exe` outside the app.
- **Bigger result text.** The right pane's `Result` label uses the
  larger result font (22 pt from [task 9](task9_larger_and_rebrand.md)),
  so it's quicker to read than the history row entry which has to
  share space with the input echo.

## Honest scope

- **No syntax highlighting** on the Code pane yet — the operators are
  REDUCE's, not Godot's defaults. Adding a small `SyntaxHighlighter`
  for `df`, `int`, `solve`, `factorize`, `mat`, etc., is a follow-up.
- **Only the latest operation's code/result** is shown in the right
  pane. Click an older history row's input to re-load it into the input
  field; re-running re-populates the right pane. A "show a previous row
  here" affordance would be nice; deferred.
- **Plot does *not* unify with code/result on a single click** — it
  uses the same sampler command path. That's intentional; the Plot
  button's job is the plot, with the sampler shown for honesty.
