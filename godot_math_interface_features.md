# Using Godot's Full Feature Set for a Beautiful, Useful Math Interface

This doc maps Godot's engine features onto a polished math application — the
kind of app where a user types/solves math (paired with the REDUCE CAS
back-end from [godot_reduce_ui.md](godot_reduce_ui.md)) and *enjoys* using it.
The point: Godot is not just a layout tool. Its rendering, animation, theming,
input, and 2D-drawing systems let a math UI feel alive instead of like a form.

---

## 1. Layout & containers — the skeleton

Godot's `Control` node tree gives responsive, resolution-independent layout.

- `MarginContainer` / `VBoxContainer` / `HBoxContainer` / `GridContainer` —
  arrange the input bar, button rows, output, and plot without manual pixel
  math.
- `SplitContainer` — draggable divider between the "notebook" (history) and the
  "plot" panel.
- `TabContainer` — separate workspaces: *Algebra*, *Calculus*, *Plot*, *Matrix*.
- **Anchors + size flags** — the UI reflows correctly on desktop, mobile, and
  when the window resizes. Set `size_flags_horizontal = FILL/EXPAND`.
- `ScrollContainer` — the calculation history scrolls like a notebook.

## 2. Theme system — the "beautiful" part

Godot's `Theme` resource is the single biggest lever for looking good.

- Define one `Theme` with consistent colors, fonts, and `StyleBox`es; assign it
  at the root so every control inherits it.
- `StyleBoxFlat` — rounded corners, soft borders, subtle shadows on panels,
  buttons, and the input field. This alone makes it look modern.
- **Custom fonts** — load a clean UI font *and* a monospace/math font for
  expressions (`FontFile`, with `RichTextLabel` BBCode to mix them).
- **Light/Dark mode** — swap two Theme resources at runtime.
- **Theme type variations** — e.g. a "primary" button style (Solve) vs.
  "secondary" (Clear), without separate scenes.

## 3. RichTextLabel — readable math output

- BBCode for formatting: `[color]`, `[font]`, sizing, `[url]` (clickable links),
  `[b]`/`[i]`. Selectable + clickable: `[url]` lets a user click a previous
  result to reuse it as input.
- **Note (verified empirically in Godot 4.6):** `RichTextLabel` does **not**
  parse `[sup]`/`[sub]` tags — they appear literally. For real superscripts use
  **Unicode characters** (`x²`, `x³`, `e⁻¹`) for numeric exponents; for
  non-numeric exponents (`e^x`) fall back to the caret. Push REDUCE's output
  through a small formatter that does this substitution.

## 4. Custom 2D drawing — plots & math rendering

This is where Godot shines for "useful."

- `_draw()` + `draw_line`, `draw_polyline`, `draw_circle`, `draw_string` —
  render function graphs, axes, gridlines, and tick labels yourself with full
  control.
- `Line2D` — smooth, antialiased, width-adjustable curves; one per plotted
  function with distinct colors.
- **Sample from REDUCE**: ask the CAS to evaluate `f(x)` at sampled `x` values
  (exact → numeric), then plot — symbolic correctness, real-time rendering.
- `draw_set_transform` — pan/zoom the plot by transforming the canvas.
- A `SubViewport` — render the plot into a texture for export/snapshots.

## 5. Animation & feel — `Tween` and `AnimationPlayer`

Subtle motion makes it feel premium without being gaudy.

- `create_tween()` — animate a result fading/sliding in when REDUCE answers;
  ease a plotted curve drawing itself left-to-right.
- Button press feedback: quick scale "pop" on click.
- Smooth panel transitions when switching tabs or expanding history.
- `AnimationPlayer` — orchestrate a polished intro / loading state while REDUCE
  computes.

## 6. Input handling — fast, keyboard-friendly

- `LineEdit` / `TextEdit` with `text_submitted` so **Enter** evaluates.
- `InputMap` — keyboard shortcuts: Ctrl+Enter = solve, Up/Down = walk history,
  Ctrl+L = clear.
- A custom **virtual math keypad** (`GridContainer` of buttons: π, √, ^, ∫, d/dx,
  fractions) for touch/mobile — each inserts the right REDUCE token.
- `_gui_input` on the plot for mouse-wheel zoom and drag-pan.

## 7. Signals — clean wiring

- Connect button `pressed`, `text_submitted`, and a custom `result_ready`
  signal (emitted when the worker `Thread` finishes a REDUCE call) so the UI
  updates reactively and the main thread never blocks.

## 8. Threads & responsiveness

- Run REDUCE calls on a `Thread` (or `WorkerThreadPool`); emit a signal with the
  result via `call_deferred`. The spinner animates, the window stays smooth.

## 9. Persistence & polish

- `ConfigFile` or `ResourceSaver` — save history, theme choice, and last session.
- `FileDialog` — export results / plot images (`Image.save_png`).
- `AudioStreamPlayer` — optional soft click on evaluate (toggleable).
- Window settings — title, icon, min size, HiDPI scaling.

---

## Feature → benefit summary

| Godot feature        | Makes the math UI… |
|----------------------|--------------------|
| Containers + anchors | responsive on any screen |
| Theme + StyleBoxFlat | beautiful & consistent   |
| RichTextLabel BBCode | render real exponents/indices |
| `_draw` / `Line2D`   | plot functions interactively |
| Tween / AnimationPlayer | feel smooth & premium |
| InputMap + keypad    | fast keyboard & touch input |
| Signals + Thread     | responsive, never frozen |
| ConfigFile/FileDialog| persistent & exportable |

---

## Suggested screen (single workspace)

```
+------------------------------------------------------------+
|  [Algebra] [Calculus] [Plot] [Matrix]            (tabs)    |
+------------------------------------------------------------+
|  f(x) = [ sin(x) * x                    ]  [Solve] [d/dx]  |  <- LineEdit + buttons
+------------------------------------+-----------------------+
|  History (ScrollContainer)         |   Plot (_draw/Line2D) |
|   (x+1)^2  ->  x^2 + 2x + 1         |        /\             |
|   df(sin x*x) -> cos(x)x + sin(x)   |   ____/  \____        |  <- SplitContainer
|                                    |                       |
+------------------------------------+-----------------------+
|  Keypad:  7 8 9 ^  pi  sqrt  (  )  d/dx  int     (GridCtr) |
+------------------------------------------------------------+
```

---

## Build order

1. Root `Control` + base `Theme` (colors, fonts, `StyleBoxFlat`).
2. Layout skeleton with containers (input bar, split history/plot, keypad).
3. Wire input → REDUCE (on a `Thread`) → `result_ready` signal → RichTextLabel.
4. BBCode formatter for pretty output (superscripts etc.).
5. Plot panel with `_draw`/`Line2D`, sampling values from REDUCE.
6. Add Tweens, shortcuts (`InputMap`), and the math keypad.
7. Light/dark Theme toggle, persistence, export.

The result: a single, responsive, themed, animated math workbench that's both
*beautiful* (theme, motion, typography) and *useful* (real CAS results,
interactive plots, fast input).
```