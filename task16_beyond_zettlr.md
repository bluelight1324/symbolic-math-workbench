# Task 16 — Improving on the Zettlr-Style Direction

[Task 15](task15_zettlr_direction.md) proposed turning the Symbolic Math
Workbench into a Zettlr-style Markdown notebook with workspace folders,
wikilinks, tags, and Pandoc export. That alone would already be a huge step
up from the in-memory history we have today.

But Zettlr was designed for **writing**, not for **computing**. Adopting its
model verbatim leaves a lot of value on the table because we have something
Zettlr doesn't: a live, persistent CAS underneath the editor. This doc lists
ten concrete improvements *beyond* the Zettlr design — each one taking a real
weakness of either Zettlr or the task-15 proposal and proposing a specific
fix that the existing stack ([math_engine.gd](app/autoload/math_engine.gd),
[plot_panel.gd](app/scripts/plot_panel.gd),
[problem_library.gd](app/scripts/problem_library.gd), the design-token theme,
the [help_wizard.gd](app/scripts/help_wizard.gd) modal pattern) is already
well placed to support.

The improvements are ordered by *impact-per-effort*, not by ambition.

---

## 1. Reactive cells, not just runnable cells

**Zettlr/task-15 weakness:** a notebook is a static document; the user has to
remember to re-run downstream blocks when an upstream input changes.

**Improvement:** **Observable / Pluto-style reactivity** — when a `cas` block
re-binds a name, every block that *reads* that name automatically re-runs.
This is uniquely tractable for us because the CAS already tracks symbolic
bindings explicitly.

**How:**
- Parse each `cas` block to extract `defines := {symbols assigned}` and
  `reads := {symbols referenced}`.
- Build a per-notebook dependency DAG.
- On a block run / edit, topologically re-run only the downstream slice
  through the shared persistent `MathEngine` session.
- Show a thin colored "stale" bar on the left of any block whose inputs have
  changed since its last result, so the user sees what's out-of-date.

**Why it wins:** Zettlr can never do this — it has no idea what's in its code
blocks. We do, because REDUCE knows.

---

## 2. Real typeset math *inside* the editor, not only on export

**Zettlr/task-15 weakness:** Zettlr renders LaTeX via KaTeX in a preview pane,
but the *editor* shows the LaTeX source. Task 15 punts on inline typesetting
entirely.

**Improvement:** typeset `cas-result` blocks **inline** in the editor, the way
modern notebooks (Jupyter, Observable, Quarto) do.

**How:**
- REDUCE's `rlfi` package already produces real LaTeX
  (verified in [task 4 §1](godot_math_interface_improvements.md):
  `\left(x \left(x+2\right)\right)/\left(x^{2}+2 x+1\right)`).
- Bundle a small LaTeX-to-image renderer next to `reduce/` — either a slim
  Pandoc + `dvipng` pipeline, or a native MathJax/KaTeX node bundle invoked
  via stdio.
- Cache by `sha1(latex_source)` so each formula is rendered once.
- Display the rendered image inline via a `TextureRect` in the editor's
  CodeEdit gutter, or by reading the source character-by-character and
  injecting line offsets.

**Why it wins:** LaTeX-as-text in the editor is what mathematicians actually
*tolerate*, not what they prefer. True inline typesetting is the experience
that turns a notebook into a textbook.

---

## 3. Computation provenance & content-addressed result cache

**Weakness:** rerunning a 100-block notebook is wasteful when only one cell
changed — and there's no audit trail showing which result came from which
input.

**Improvement:** content-address each `cas` block by
`sha1(canonical_source + engine_version + upstream_input_hashes)`. Persist
the cache on disk per workspace. Each `cas-result` block carries its source
hash; on re-run, a block with an unchanged hash is **skipped** and its cached
result is shown.

**How:**
- A `cache/` folder next to the workspace (`.cas-cache/<hash>.txt`).
- Every result includes a small footer the engine writes back to the file:
  `<!-- src-hash: ab12…  engine: csl-6547 -->`. Markdown ignores it; we use
  it as the provenance stamp.
- A "Clear cache" command for sanity.

**Why it wins:** speeds up `factorial(100)` and slow ODE blocks dramatically,
and lets reviewers verify "this result really did come from this source on a
given engine version" — important for science use cases Zettlr never touched.

---

## 4. Interactive widgets in blocks

**Weakness:** task 15's `cas-plot` already has parameter sliders, but only
for the plot panel. The notebook itself is read/run-only.

**Improvement:** **first-class widgets** declared in Markdown that drive
recomputation:

```` markdown
```cas-widget slider a -5..5 step=0.1 default=1
```

```cas
df(sin(a*x), x);
```
````

The `a` slider lives inline in the notebook between paragraphs. Dragging it
re-runs all downstream `cas` blocks via the reactivity engine (#1).

**How:** wire a `HSlider`/`SpinBox`/`OptionButton` per declaration into the
in-editor layout; bind the widget's value to the engine's symbol via
`sub(a=<val>, …)` in every dependent block.

**Why it wins:** turns a notebook into an explorable explanation in the spirit
of Bret Victor / Distill / Observable, which Zettlr cannot do.

---

## 5. Symbolic-aware diff and search

**Weakness:** plain-text grep can't tell that `sin(x)^2 + cos(x)^2` and `1`
are the same answer; nor can `diff` tell that `(x+1)^2` and `x^2 + 2x + 1`
are the same input.

**Improvement:**
- **Search:** when the user searches `cos(2x)`, also match notebooks whose
  cached `cas-result` *simplifies* to it (run the search query through
  `trigsimp` / `factorize` / engine equivalence and compare with the cached
  results' canonical forms).
- **Diff (between two notebook versions):** for each changed block, send both
  sides as `is_equiv := (expr1 - expr2 = 0)` through the engine; mark
  semantically-equivalent edits in green, real changes in red.

**How:** an indexer thread writes a `.cas-index` of canonical forms; the
search/diff UIs query the engine for equivalence checks.

**Why it wins:** turns the notebook from "files I edit" into "a knowledge
base I can query symbolically." Genuinely novel.

---

## 6. Pluggable kernels, declared per notebook

**Weakness:** task 15 hard-codes REDUCE.

**Improvement:** notebooks declare their engine in frontmatter; the app
launches the right one.

```yaml
---
title: Forced harmonic oscillator
engine: reduce-csl   # or: maxima, sympy, pari, sage
---
```

**How:**
- Generalise the autoload to `EngineManager`: spawn the requested child
  process, wire it through the same sentinel/reader pipeline we already
  built in [math_engine.gd](app/autoload/math_engine.gd).
- Different engines have different prompts; each gets a tiny adapter
  module declaring its sentinel-emitting command (REDUCE: `write "…"`;
  Maxima: `print("…")`; SymPy: `print(repr(…))`).

**Why it wins:** the architecture from task 6 already correlates async
results to requests *abstractly* — there's no REDUCE-specific code in
`_reader_loop` other than the banner string and the `***` filter. Going
multi-kernel is mostly adapters.

---

## 7. Backlinks panel + graph view

**Weakness:** Zettlr has wikilinks but no backlinks panel; the connectedness
of the notebook is implicit.

**Improvement:** an Obsidian-style **Backlinks** sidebar showing "notes that
link to *this* note," and a **Graph view** rendering the wikilink + tag DAG
as a force-directed graph using Godot's `Line2D` + `_draw()` (we already use
this for plotting — same primitives, different layout algorithm).

**Why it wins:** the graph view is where Zettlkasten "clicks" — seeing the
shape of your knowledge. Godot's renderer makes this surprisingly cheap.

---

## 8. Embedded tests (` ```cas-test `)

**Weakness:** there's no way to *assert* that a notebook still computes the
same answer after you change a definition.

**Improvement:** a new fence kind:

````markdown
```cas-test
assert: simplify(df(sin(x), x) - cos(x)) = 0
```
````

On save (or in CI), the test runner pipes the assertion through the engine,
collects pass/fail, and writes a results badge into the file footer. The
reactivity engine (#1) re-runs only the affected tests on edit.

**Why it wins:** turns notebooks into reliable artefacts — they can't silently
drift into being wrong. Zettlr has nothing analogous because it has nothing
to test against.

---

## 9. Mobile / web targets

**Weakness:** Zettlr is desktop-only Electron. Task 15 inherits that.

**Improvement:** Godot exports natively to **Android, iOS, and HTML5**. The
web target uniquely opens up "share a notebook by URL" — readers see the
prose + cached results without installing anything.

**How:** the engine must run server-side for the web target (a thin HTTP
wrapper around `reduce.exe` running on the publisher's machine). For mobile,
bundle a recompiled engine binary per platform. The Godot UI ports without
changes thanks to the `Control` + `Theme` setup.

**Why it wins:** the niche Zettlr can never reach.

---

## 10. Local LLM-assisted derivation and explanation

**Weakness:** modern math tools have AI assistants; we don't.

**Improvement:** an optional "Explain this step" / "Suggest next" sidebar
pane driven by a local small LLM (e.g., a 3B-7B model via `llama.cpp`
running as a child process the same way REDUCE does). The prompt is built
from the surrounding notebook prose + the current `cas` block + any
upstream definitions.

**How:** the sentinel-based child-process protocol from
[math_engine.gd](app/autoload/math_engine.gd) generalises — the LLM is just
another long-lived child with a `<<<RDONE n>>>`-equivalent end marker.
Gate behind a setting because it's heavyweight; default off.

**Why it wins:** sits naturally on the same architecture without giving up
on the CAS-correct foundation. Lets the LLM *suggest* steps, while the CAS
*verifies* them — a much better division of labour than asking the LLM to
do math itself.

---

## Summary table

| # | Improvement                              | Beats Zettlr at        | Effort  | Risk   |
|---|------------------------------------------|------------------------|---------|--------|
| 1 | Reactive cells                            | Reproducibility / UX  | Medium  | Low    |
| 2 | Inline typeset math in editor             | Math readability      | Medium  | Medium |
| 3 | Content-addressed result cache + provenance | Speed / auditability | Small   | Low    |
| 4 | Interactive widgets in cells              | Exploration UX        | Medium  | Low    |
| 5 | Symbolic-aware search & diff              | Knowledge retrieval   | Larger  | Medium |
| 6 | Pluggable kernels                         | Reach                 | Small   | Low    |
| 7 | Backlinks + graph view                    | Knowledge navigation  | Small   | Low    |
| 8 | Embedded tests (cas-test)                 | Reliability           | Small   | Low    |
| 9 | Mobile / web targets                      | Distribution          | Larger  | Medium |
| 10| Local LLM assist                          | Authoring speed       | Larger  | Medium |

---

## What I'd ship first, and why

If only three of these were built on top of the task-15 baseline, **#3, #1,
and #8** — in that order — would yield the most user value per line of code:

1. **Cache + provenance** is small and pays for itself immediately on the
   next ODE-heavy notebook.
2. **Reactivity** then makes the cache *visible* — cells go stale or stay
   green and the user sees what needs re-running.
3. **Embedded tests** turns the now-reliable cache into something a user can
   *depend* on across edits.

Items #2, #4, #7 are the next tier and turn the app from "Zettlr with math"
into "Observable + Zettelkasten + CAS" — a genuinely novel product, not just
a port. #5 (symbolic-aware diff/search) is the standout differentiator if we
want a *moat*: nothing else in this space does it.

The thread running through every improvement is the same: we have a live
symbolic-math engine and a persistent session at the foundation. Every step
beyond Zettlr is something the engine enables and Zettlr literally can't.
That's the angle to lean into.
