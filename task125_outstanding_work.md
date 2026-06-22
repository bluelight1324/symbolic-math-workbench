# Task 125 — What Still Needs to Be Implemented

## Method

I cross-checked three sources: the canonical roadmap
([task18_requirements.md](task18_requirements.md) — 35 requirements across tiers
P0–P6), the in-code status notes and stubs
([notebook_view.gd:14-33](app/scripts/notebook_view.gd#L14)), and the gaps
surfaced by recent tasks (120–124). Below is what's **done** vs. what **still
needs building**, prioritized.

## Already implemented (for context)

- **P0 #1–4** — workspace + file tree, Markdown notebook format, in-app editor,
  block runner. ✅
- **P1 #5, #10, #11** — content-addressed cache + provenance, `cas-test`
  pass/fail, HTML/Pandoc export. ✅
- **#21 runtime theme switching** — multiple color schemes / "looks" via
  `ColorConfig`/`LooksConfig`. ✅ (the recent MATLAB look is one of these)
- Plus the large beautification + UI pass from tasks 94–123 (MATLAB chrome, bold
  fonts, tooltip fix, Source toggle, engine heap fix, installer).

## Needs implementation — prioritized

### Tier A — **finish P2** (the product-defining tier; started but incomplete)

This is the highest-value outstanding work: each item already exists as a
partial/stub, so finishing it is well-scoped.

| # | Feature | Current state | What's missing |
|---|---|---|---|
| 6 | **Reactive cells (dependency DAG)** | only the hash-skip cache | build a per-notebook symbol-dependency DAG and re-run just the downstream slice on an edit ([notebook_view.gd:23](app/scripts/notebook_view.gd#L23)) |
| 7 | **Inline typeset math** | emits a LaTeX line | render that LaTeX to a PNG (via `rlfi`) and show it in the cell ([notebook_view.gd:26](app/scripts/notebook_view.gd#L26)) |
| 8 | **Step-by-step derivations** | fixed factor→expand→simplify | drive `cas-derive` from the engine's own `trace`, with a "▾ show steps" disclosure ([notebook_view.gd:29](app/scripts/notebook_view.gd#L29)) |
| 9 | **3D plots + animations** | `cas-plot3d` returns a placeholder string | a real Godot `Camera3D` mesh-sampling viewport (this is Godot's core strength) ([notebook_view.gd:600](app/scripts/notebook_view.gd#L600)) |

### Tier B — **gaps surfaced by tasks 120–124** (small, high-relevance)

- **LaTeX/MathJax → REDUCE input converter** (tasks 121, 124). Today the user
  hand-translates LaTeX. A `latex2sympy2`/`parse_latex` + small REDUCE printer
  (proven working in [task124](task124_mathjax_to_reduce_converter.md)) would let
  a `cas` block accept LaTeX. ~1 day for a useful subset.
- **"Clear outputs" command** (task 122). Force re-run exists, but there's no
  one-click way to *empty* all `cas-result` blocks. Small menu/toolbar action.

### Tier C — **P3 navigability** (essentially none built yet, except #21)

Confirmed absent in code: wikilinks, search, tags, backlinks, widgets,
distraction-free mode.

- **#12 Wikilinks `[[Note]]`** — parse + click-navigate + autocomplete.
- **#13 Workspace search** — background recursive grep + results panel.
- **#14 Symbolic-aware search & diff** — match notebooks whose *result simplifies
  to* the query; diff via `expr₁−expr₂=0`. (The category moat feature.)
- **#15 Tags `#topic`** + tag browser.
- **#16 Backlinks panel + graph view.**
- **#17 Interactive widgets** (`cas-widget slider …` driving recomputation).
- **#20 Distraction-free mode** (hide sidebar/plot pane).

### Tier D — **P4–P6 longer-term roadmap** (not started; large)

- **P4** — #18 WYSIWYG/projectional math editing, #19 live preview pane,
  #24 manipulable geometric diagrams.
- **P5** — #22 pluggable kernels (`engine: reduce|maxima|sympy`), #23 GDScript
  plugin system, #25 WASM-compiled engine, #26 publish-as-site, #27 mobile/web,
  #28 citations.
- **P6** — #29 local-LLM assist, #30 formal-proof `cas-prove`, #31 curriculum
  mode, #32 CRDT collaboration, #33 federation, #34 stylus, #35 voice.

## Recommended next implementations (concrete short list)

1. **Real 3D plots (#9)** — replace the `cas-plot3d` placeholder with a Godot
   `Camera3D` viewport. Biggest visible win and plays to Godot's strength.
2. **Inline math image rendering (#7)** — `rlfi` LaTeX → PNG in-cell.
3. **LaTeX→REDUCE input** (Tier B) — the converter is already prototyped in
   task 124; wiring it into the `cas` runner is small.
4. **Workspace search + wikilinks (#13, #12)** — makes multi-notebook workspaces
   actually navigable.
5. **"Clear outputs" command** (Tier B) — trivial, closes the task-122 gap.

## Files changed
- None — this is an audit/planning doc (no code change requested).
