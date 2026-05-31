# Improving the Godot Math Interface (Upgrades to Task 2)

Task 2 ([godot_math_interface_features.md](godot_math_interface_features.md))
described a solid math workbench: themed layout, BBCode output, `_draw` plots,
tweens, a keypad, threaded REDUCE calls. This doc says **how to make it better** —
each section names a weakness in the task-2 design and the concrete upgrade.

---

## 1. Real math typesetting (beyond plain text)

**Task 2 limit:** plain RichTextLabel output (even with Unicode superscripts
like `x²`) can't render fractions, radicals, integrals, matrices, or stacked
limits properly. (Godot 4.6's RichTextLabel doesn't parse `[sup]`/`[sub]`
either — verified empirically — so even those fake superscripts have to come
from Unicode characters.)

**Upgrade:**
- Render true math layout. Two practical routes:
  - **TeX → image/SVG:** have REDUCE emit LaTeX via its formula interface
    (`load_package rlfi; on latex;`), render it to an image, and show it in a
    `TextureRect`.
  - **A glyph layout engine** drawn via `_draw()`/`RID` canvas items: build
    fraction bars, √ extenders, and big operators from primitives so they scale
    crisply and stay theme-colored.
- Cache rendered expressions by their source string so re-displaying history is
  instant.

> REDUCE *does* produce TeX. Quick check below confirms the back-end can feed a
> real typesetter, removing the BBCode ceiling.

## 2. A persistent REDUCE session (not one process per click)

**Task 2 limit:** spawning `reduce.exe` per evaluation throws away all state —
variable bindings, `let` rules, loaded packages, and mode switches (`on rounded`)
vanish between clicks, and process startup adds latency.

**Upgrade:**
- Keep **one long-lived REDUCE process** via `OS.create_process()` + pipes (or a
  thin local socket wrapper). Send commands, read until the `n:` prompt, keep
  the session warm.
- Benefits: users can define `f := x^2+1;` then evaluate `df(f,x);`; packages
  load once; numeric mode persists; latency drops to the compute time only.
- Add a **"Reset session"** button to clear state deliberately.

## 3. Robust parsing & error UX

**Task 2 limit:** it sends raw user text and shows whatever REDUCE prints —
including `***** ... invalid` errors as raw noise.

**Upgrade:**
- Detect REDUCE error lines (`*****`) and render them as a friendly inline error
  with the offending token highlighted, not dumped verbatim.
- **Pre-validate** before sending: balanced parens, a trailing `;`, allowed
  identifiers. Underline mismatches live in the `LineEdit`.
- Add a **timeout + cancel**: if a solve runs long, let the user cancel the
  worker `Thread` instead of freezing the notebook.

## 4. Interactive, not static, math

**Task 2 limit:** plots and results are computed once and shown.

**Upgrade — the biggest "useful" win:**
- **Parameter sliders:** detect free symbols (`a`, `k`) in the expression, spawn
  `HSlider`s, and re-evaluate/re-plot live as the user drags — see how a curve
  morphs with its parameters.
- **Draggable points / cursors** on the plot that read off `f(x)` values
  (sampled from REDUCE) at the cursor.
- **Animated sweeps:** a `Tween` drives a parameter across a range to animate a
  family of curves.
- **Click-to-manipulate:** click a term in the typeset result to factor/expand
  just that subexpression (send a targeted REDUCE call).

## 5. Plotting quality & performance

**Task 2 limit:** CPU `_draw`/`Line2D` with per-frame sampling gets slow for
many curves or live dragging, and looks jagged when zoomed.

**Upgrade:**
- Move evaluation off the hot path: sample once into a `PackedVector2Array`,
  redraw cheaply; only re-sample when the function or view actually changes.
- For heavy/zoomable plots use a **fragment shader** (`ShaderMaterial` on a
  `ColorRect`) to render implicit curves / heatmaps on the GPU.
- Add **adaptive sampling** (more points where curvature is high) and detect
  asymptotes/discontinuities so vertical jumps aren't drawn as solid lines.

## 6. Notebook power features

**Task 2 limit:** history is a read-only scrolling list.

**Upgrade:**
- **Editable, re-runnable cells** (like Jupyter): edit a past input and re-run;
  downstream cells using a persistent session recompute.
- **Undo/redo** stack for the notebook and input.
- **Reference previous results** by `%` or `Out[3]` style tokens.
- **Export the whole notebook** to Markdown / LaTeX / PDF, not just one image.

## 7. Design system, not ad-hoc theming

**Task 2 limit:** "use StyleBoxFlat + two themes" is a good start but unstructured.

**Upgrade:**
- Define **design tokens**: a spacing scale (4/8/12/16), a type scale, a named
  color palette, and consistent corner radii — stored as constants and applied
  through Theme type variations.
- **Theme variations** for semantic roles (primary/secondary/danger buttons,
  result vs. error text) instead of per-node overrides.
- Respect **OS light/dark** and accent color where available; smooth the toggle
  with a `Tween` on modulate.

## 8. Accessibility & internationalization

**Task 2 gap:** not addressed at all.

**Upgrade:**
- **Scalable UI**: honor a font-size setting / HiDPI; never hard-code pixel text
  sizes.
- **Keyboard-complete**: every action reachable without a mouse (extends the
  task-2 `InputMap`); visible focus rings.
- **High-contrast theme** option; colorblind-safe plot palette.
- `tr()` + translation files so labels and the keypad localize.

## 9. Quality engineering

**Task 2 gap:** no testing/structure guidance.

**Upgrade:**
- **GUT** unit tests for the BBCode/TeX formatter and the REDUCE-output parser
  (pure functions, easy to test).
- Separate **layers**: `ReduceSession` (process I/O), `MathFormatter`
  (text→display), and UI scenes — so logic is testable without the UI.
- **Autoload singleton** for the session + settings.
- Profile with the built-in debugger; keep per-frame allocations out of `_draw`.

---

## Priority order (most impact first)

| # | Upgrade                         | Why it matters                  |
|---|---------------------------------|---------------------------------|
| 1 | Persistent REDUCE session (§2)  | unlocks variables/state, faster |
| 2 | Interactive sliders/cursors (§4)| turns a viewer into a tool      |
| 3 | Real typesetting (§1)           | looks like real math            |
| 4 | Error UX + validation (§3)      | usable by non-experts           |
| 5 | Plot perf + adaptive sampling(§5)| smooth at scale                |
| 6 | Notebook re-run/export (§6)     | real workflow value             |
| 7 | Design tokens, a11y, tests(§7-9)| polish & robustness             |

---

## Verifying the back-end can support these

The two biggest upgrades (persistent state in §2, real typesetting in §1) depend
on REDUCE features — both confirmed working against the local install:

- **State within a session** — `f := x^2 + 1; df(f, x);` → `2*x` (the binding
  `f` is remembered and used by the next statement, which is exactly what a
  persistent session preserves across clicks).
- **TeX output** — `load_package rlfi; on latex; df(x^2/(x+1), x);` emits real
  LaTeX:
  `\left(x \left(x+2\right)\right)/\left(x^{2}+2 x+1\right)`
  — feed this straight into a TeX renderer for true typesetting.

  Note: the package is **`rlfi`** (the REDUCE LaTeX Formula Interface). There is
  no plain `latex` package in this build — `load_package latex;` fails, so use
  `rlfi`.
