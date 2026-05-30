# Task 15 — Evolving Toward a Zettlr-Style App, and Why

A design doc (not implementation): how would the **Symbolic Math Workbench**
shift to a workflow like **Zettlr**'s Markdown-notebook / Zettelkasten model,
and what concrete advantages that brings.

The current app (tasks 1–14) is a single-document calculator: the history
panel is in-memory, results live for one session, and there's no concept of
"a notebook" or a library of saved work. Zettlr's strength is exactly that —
a workspace of plain-Markdown files you can link, tag, search, and export.
Bringing that pattern to a CAS-backed workbench is a high-value direction.

---

## What Zettlr does that's worth copying

| Zettlr concept              | What it gives the user                                                  |
|-----------------------------|-------------------------------------------------------------------------|
| **Workspace folder**        | Open a directory; every `.md` file in it becomes a note in the sidebar  |
| **Sidebar file browser**    | Persistent navigation; rename / drag / move notes between subfolders    |
| **Plain-Markdown storage**  | Notes are just text files — version-controllable, editable elsewhere    |
| **Wikilinks `[[Note]]`**    | Zettelkasten linking — connect ideas without flat hierarchies           |
| **Tags `#topic`**            | Cross-cutting categorisation; tag-browser shows all notes per tag      |
| **Global search**           | Find any past work by content, tag, or link                             |
| **Live Markdown preview**   | Edit and read in one pane; math via KaTeX                               |
| **Pandoc export**           | One-click to PDF, HTML, DOCX, LaTeX                                     |
| **Citation support**        | BibTeX integration, `@citekey` syntax, bibliography on export           |
| **Distraction-free mode**   | Hide chrome, focus on writing                                           |
| **Dark / light themes**     | Easy on the eyes, consistent across the app                             |

---

## Mapping it onto the Symbolic Math Workbench

A "math zettlr" would treat every problem-solving session as a **notebook
file** that mixes Markdown prose with executable CAS blocks. The current
[history panel](app/scripts/main.gd) becomes a *view of one file* in a
larger workspace.

### 1. File format — Markdown with executable blocks

Plain `.md`, with the CAS blocks fenced and tagged:

````markdown
# Forced harmonic oscillator

The equation is $y'' + y = \sin x$.

```cas
odesolve(df(y,x,2) + y = sin(x), y, x);
```

```cas-result
{y = (2·arbconst(2)·sin(x) + 2·arbconst(1)·cos(x) − cos(x)·x) / 2}
```

```cas-plot x∈[-10,10]
sin(x) + a*cos(x)
```

#oscillator #classical-mechanics

See also [[Free oscillator]], [[Driven damped oscillator]].
````

- ` ```cas ` = source. The engine runs it; results are written back into a
  paired ` ```cas-result ` block so the file is self-contained even when
  the engine isn't running.
- ` ```cas-plot ` = renders a plot from sampled values, same pipeline as the
  task-7 plot panel.
- `[[Note]]` is a wikilink to another `.md` in the workspace.
- `#tag` is a hashtag; the tag browser indexes them.

> **Engineering note:** the persistent `MathEngine` autoload from task 6 is
> exactly the right substrate. Re-running a notebook = walking the file's
> `cas` blocks in order through the *same* long-lived session, so variable
> bindings (`f := …`) persist between blocks the way a user expects.

### 2. UI changes (incremental, on top of the current app)

The existing layout already has the right anatomy; Zettlr-ification reshapes
it rather than replacing it.

```
+---------------------------------------------------------------+
|  View   File   Algebra  Calculus  …  Help                     |  menu bar
+-----------+--------------------------------------+------------+
|  Sidebar  |  Editor / preview                    |  Plot pane |
|  (file    |   # heading                          |            |
|  tree)    |   prose…                             |            |
|           |   ```cas ... ```                     |            |
|           |   ```cas-result ... ```              |            |
|           |   prose…                             |            |
|           |                                      |            |
|           +--------------------------------------+            |
|           |  Status: Engine ready   Run notebook | Reset      |
+-----------+--------------------------------------+------------+
```

Concretely, swap the in-memory `_history_box` for a `CodeEdit` /
`TextEdit` whose source is the open `.md` file, add a left `Tree` populated
from the workspace folder, and keep the plot pane on the right.

### 3. Concrete subsystems to add

| Subsystem               | Likely Godot building block / how to do it                        |
|-------------------------|--------------------------------------------------------------------|
| Workspace folder picker | `FileDialog` with `FILE_MODE_OPEN_DIR`; persist last folder in `ConfigFile` |
| File-tree sidebar       | `Tree` populated by walking the workspace dir; double-click opens  |
| Markdown editor         | `CodeEdit` with custom highlighter for headings, code fences, links |
| Live preview            | A `RichTextLabel` with BBCode produced from Markdown by a small parser, plus inline plot textures |
| Block runner            | Walk the editor's source for fenced `cas` blocks; pipe each through `MathEngine.evaluate`; write the result back into a paired `cas-result` block |
| Wikilink navigation     | Regex `\[\[([^\]]+)\]\]`; map name → file path; click → open file  |
| Tag index               | Scan workspace for `#tag` occurrences; show in a "Tags" view       |
| Global search           | Background `Thread` doing recursive file grep; results in a panel |
| Export                  | Shell out to `pandoc.exe` (bundled like the CAS engine) for PDF / HTML / DOCX; render math via LaTeX (we already verified REDUCE's `rlfi` produces LaTeX in [task-4 §1](godot_math_interface_improvements.md)) |
| Distraction-free mode   | Toggle sidebar + plot pane visibility; widen editor               |
| Themes                  | The design-token Theme from [task 9](task9_larger_and_rebrand.md) already lets us swap a light/dark `Theme` resource at runtime |

### 4. What's already there and helps

This isn't a rewrite — quite a lot of the work is done:

- **Persistent computation engine** with sentinel correlation, async results,
  and packages pre-loaded ([math_engine.gd](app/autoload/math_engine.gd))
  → drop-in block runner.
- **Problem library** (72 items, [problem_library.gd](app/scripts/problem_library.gd))
  → ship as starter notes in the default workspace.
- **Plot pipeline** with parameter sliders and sample-shift singularity fix
  → reuse for `cas-plot` blocks.
- **Theme + design tokens** → light/dark swap is a one-line resource change.
- **Help wizard** ([help_wizard.gd](app/scripts/help_wizard.gd))
  → the same widget can host a "how this notebook format works" tour.

---

## Advantages of going Zettlr-style

### 1. Work *persists* — no more lost sessions
Currently, close the app and the history is gone. With file-backed notebooks,
every computation is a `.md` you can open next month, share with a colleague,
or commit to git. Re-opening reproduces the work exactly because the engine
session is replayable from the file.

### 2. Reproducibility for free
A notebook lists its inputs (the `cas` blocks) and its outputs (`cas-result`).
Anyone with the app can open it and click "Run notebook" to verify the answers
against a fresh `MathEngine` session — the persistent-session property
guarantees the same execution context as the author's.

### 3. Knowledge graph (Zettelkasten)
Math grows by connecting ideas. Wikilinks turn "Forced harmonic oscillator",
"Damped oscillator", "Resonance", and "Fourier series" into a navigable graph.
The classic CAS UI gives you a calculator; Zettelkasten gives you a research
notebook.

### 4. Tagging + search instead of folder-juggling
`#integration`, `#odes`, `#exam-prep` are first-class. A tag browser surfaces
"every integration trick I've collected" without forcing a folder hierarchy.
Global search ("find any note containing `atan`") replaces hunting in scroll
history.

### 5. Pandoc export turns notebooks into deliverables
PDF homework, LaTeX papers, HTML lecture notes — one keystroke, because the
storage is already Markdown. Math is exported as real typeset LaTeX
(produced by `load_package rlfi; on latex` on the REDUCE side — already
verified working in [task 4](godot_math_interface_improvements.md)), not as
BBCode pseudocode. This is the actual unlock for the "real typesetting"
upgrade [task 7](task7_improvements_implementation.md) marked as ⚠ deferred.

### 6. Plain-text storage = the whole toolchain works
`.md` files mean: version control, `grep`, diff/merge, cloud sync, editor
extensions, AI tooling, GitHub Pages, Markdown linters, format converters.
None of that works for an in-app history blob. This is Zettlr's most
underrated win.

### 7. Distraction-free + theming = real day-long use
The current app is great for one-off calculations but visually busy when you
just want to write a derivation. Hiding the sidebar + plot pane and centring
the editor turns the same window into a writing tool. Light theme switching
makes it usable in sunlight; dark theme for late nights.

### 8. Citations and bibliography
For students and researchers, `@knuth1997` → automatic bibliography on export
via Pandoc + BibTeX is huge. Zettlr already proves the UX; we'd be pulling in
mature, well-trodden infrastructure rather than inventing.

### 9. Multi-notebook workflow
Open several `.md`s as tabs. Drag a result from one notebook to cite it in
another via `[[Note#heading]]`. The persistent engine is shared, so a `let`
in one notebook can affect the next — useful for "scratchpad → polished
writeup" workflows.

### 10. A real *advantage* over Zettlr itself
Zettlr renders LaTeX math via KaTeX as **display only**. Our app *computes*
the math: a `cas` block is live, re-evaluable, and parameter-sweepable
([task 7 §4](task7_improvements_implementation.md)). That's the differentiated
value proposition: **Zettlr's authoring model + a real CAS underneath**, not
a static formula viewer.

---

## Honest scope and phased plan

This is intentionally a **roadmap doc**, not implemented work. A pragmatic
phasing if we did do it:

| Phase | Scope                                                                 | Approx effort |
|-------|------------------------------------------------------------------------|---------------|
| 1     | Workspace folder + sidebar `Tree` + open/save `.md` files              | small         |
| 2     | `CodeEdit` editor with fence detection + "Run block" + write-back of `cas-result` | medium |
| 3     | Wikilink parsing + click-to-navigate + tag browser                     | medium        |
| 4     | Global search; recent-files list                                       | small         |
| 5     | Pandoc export (bundle `pandoc.exe`; LaTeX via `rlfi`)                  | medium        |
| 6     | Live preview pane (Markdown → BBCode + inline plot textures)           | larger        |
| 7     | Distraction-free toggle, theme switching, settings dialog              | small         |
| 8     | Citation support (BibTeX picker + auto-bibliography on export)         | medium        |

Each phase keeps the app shippable and useful on its own — phase 1 alone
already turns the workbench from "session-only" into "save and reopen."

The pre-existing pieces from tasks 6–12 (persistent engine, plot pipeline,
problem library, themes, help wizard) carry through unchanged; this proposal
adds *around* them rather than rewriting them.
