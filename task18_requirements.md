# Task 18 — Consolidated Requirements (Tasks 15–17), Ordered by Importance

This document collects every distinct proposal from
[task 15 — Zettlr direction](task15_zettlr_direction.md),
[task 16 — Beyond Zettlr](task16_beyond_zettlr.md),
and [task 17 — Even Further](task17_even_further.md), removes duplicates,
ranks them by importance, and groups them into shippable tiers.

It's a **requirements doc**, not a design doc: each entry says *what* must
exist for the proposal to be considered done, with just enough rationale to
explain its rank. Detailed designs live in tasks 15–17.

---

## 1. Vision (one paragraph)

Turn the **Symbolic Math Workbench** (tasks 1–14) from an in-memory
calculator into a **file-backed, reactive, symbolically-aware research
notebook**: workspace folders of plain Markdown with executable `cas` blocks;
results that re-run automatically when their inputs change; inline real-math
typesetting; step-by-step derivations; native 3D plots; and a path to
publish, collaborate on, and verify the math you produce.

## 2. Ranking criteria

Each requirement was scored on five axes; the ranking below is by their
weighted sum.

1. **Blocking foundation** — if missing, nothing downstream works.
2. **User impact** — directly-visible value to the end user.
3. **Differentiation** — uniquely enabled by the persistent-CAS-in-Godot stack.
4. **Tractability** — buildable on the architecture shipped in tasks 1–14.
5. **Compounding** — unblocks or amplifies other requirements.

## 3. Master list, ordered by importance

The "Src" column points to the originating task. The "Dep" column lists
prerequisite requirement IDs. Effort is L (≤1 sprint), M (1–3 sprints),
or H (>3 sprints).

| #  | Requirement                                       | Src        | Dep        | Effort | Why at this rank                                                                 |
|----|---------------------------------------------------|------------|------------|--------|----------------------------------------------------------------------------------|
| 1  | **Workspace folder + sidebar file browser**       | 15         | —          | L      | Foundation — without file-backed storage, every other proposal is meaningless    |
| 2  | **Plain-Markdown notebook format** (`.md` with fenced `cas` / `cas-result` / `cas-plot` blocks) | 15 | 1 | L | Defines the artifact; everything else operates on this format                    |
| 3  | **In-app Markdown editor with `cas`-fence awareness** (CodeEdit + highlighter) | 15 | 2  | M      | The primary editing surface — without it the notebook format is unusable        |
| 4  | **Block runner** (walk fences, evaluate through the existing `MathEngine`, write `cas-result` back) | 15 | 3 | M | Connects notebooks to the computation engine already shipped                    |
| 5  | **Content-addressed result cache + provenance footer** (`sha1(src + engine_version + upstream)` → skip unchanged blocks; embed `<!-- src-hash: … -->`) | 16 | 4 | L | Tiny code, huge speedup + auditability; unlocks reactivity            |
| 6  | **Reactive cells** (per-notebook DAG; topologically re-run downstream slice on upstream edit) | 16 | 4, 5 | M | Defines the modern-notebook UX; only possible because the CAS tracks symbol bindings explicitly |
| 7  | **Inline typeset math in the editor** (`cas-result` rendered to images via REDUCE `rlfi` → LaTeX → PNG cache) | 16 | 4 | M | Biggest single readability win; verified feasible in task 4                     |
| 8  | **Step-by-step derivations** (`trace`-based folded derivation; "▾ show steps" disclosure) | 17 | 4 | M | The classroom/teaching differentiator; uses the engine's own rewrite rules — no LLM hallucination |
| 9  | **3D plots + parametric curves + vector fields + time-animation** (Godot `Camera3D`, mesh sampling, MP4 export via ffmpeg shell-out) | 17 | — | M | Finally uses Godot's main capability; the engine-choice win cashed in           |
| 10 | **Embedded `cas-test` blocks** with pass/fail badges, optional CI runner | 16 | 4, 6 | L | Turns notebooks into reliable artefacts; tiny code over already-shipped engine  |
| 11 | **Pandoc export** to PDF / HTML / DOCX / LaTeX (math via `rlfi`-emitted LaTeX) | 15 | 4 | M | Turns notebooks into deliverables; widely-trodden third-party tool              |
| 12 | **Wikilinks `[[Note]]`** — parsing, click-to-navigate, autocomplete | 15 | 1, 3 | L | The core Zettelkasten primitive                                                  |
| 13 | **Global workspace search** (background-thread recursive grep, dedicated panel) | 15 | 1 | L | Without it, large workspaces are unusable                                       |
| 14 | **Symbolic-aware search & diff** (search results match notebooks whose *result simplifies to* the query; diff via `expr₁−expr₂=0` engine check) | 16+17 | 5, 13 | M | The moat feature — nothing else in this space does it                            |
| 15 | **Tags `#topic` + tag browser**                   | 15         | 1, 3       | L      | First-class cross-cutting categorisation                                         |
| 16 | **Backlinks panel + graph view** (force-directed, `Line2D` + `_draw`) | 16 | 12, 15 | M | Where Zettelkasten "clicks" — the shape of your knowledge                       |
| 17 | **Interactive widgets in cells** (` ```cas-widget slider a -5..5`; in-editor sliders that drive recomputation) | 16 | 6 | M | Turns notebooks into explorable explanations                                     |
| 18 | **WYSIWYG / projectional math editing** (click & drag terms across `=`; AST-tied hit-test on inline typeset images) | 17 | 7 | H | UX leap that justifies the inline-render investment                              |
| 19 | **Live Markdown preview pane** (BBCode-rendered, inline plot textures) | 15 | 3 | M | Helpful for prose-heavy notebooks; lower priority because the editor itself handles `cas` and math inline (#7) |
| 20 | **Distraction-free mode** (hide sidebar + plot pane, widen editor) | 15 | 3 | L | Cheap toggle, real day-long-use value                                            |
| 21 | **Runtime light / dark theme switching** (swap two `Theme` resources; design tokens already exist) | 15 | — | L | Small change, broad benefit                                                      |
| 22 | **Pluggable kernels** (frontmatter `engine: reduce|maxima|sympy|...`; per-engine sentinel adapter) | 16 | 4 | M | Generalises the existing engine architecture; small code change for big reach   |
| 23 | **Plugin system in GDScript** (`register_block_kind`, `register_renderer`, `plugins/` folder loaded at startup) | 17 | 4 | M | Compounding value via community without touching core                            |
| 24 | **Manipulable geometric diagrams** (drag points; CAS-backed lines/circles equations) | 17 | 4, 9 | M | Geogebra-class capability inside the notebook                                    |
| 25 | **WASM-compiled engine** (REDUCE/CSL or alternative kernel as Godot extension; eliminates IPC) | 17 | 4 | H | Prerequisite for web target (#27); ~1ms per call savings                         |
| 26 | **Publish-as-site** (workspace → static HTML with live cells via WASM kernel) | 17 | 11, 25 | H | Distribution; turns notebooks into reproducible web artefacts                    |
| 27 | **Mobile / web export targets** | 16 | 25 | M | The niche Zettlr cannot reach; Godot exports natively                            |
| 28 | **Citation support** (`@citekey` syntax + bundled BibTeX file + bibliography on export) | 15 | 11 | M | Critical for academic users; well-trodden Pandoc territory                       |
| 29 | **Local LLM assist** ("explain this step", "suggest next"; small local model as long-lived child process, same sentinel pattern) | 16 | 4 | M | Useful, but the CAS-verified version of this is #8; LLM here is supplemental    |
| 30 | **Formal proof `cas-prove` blocks** (CAS canonicalisation + Z3/Lean/Coq backend; ✅/❌/⏱/🤔 footer) | 17 | 4, 22 | H | Genuinely novel; research-grade differentiator; risky integration               |
| 31 | **Curriculum mode** (prerequisites, graded exercises via `cas-test`, hints via LLM, spaced repetition) | 17 | 10, 12, 29 | H | Education vertical; large surface area                                          |
| 32 | **CRDT collaboration** (Yjs/Automerge; offline-first multi-author edits) | 17 | 1, 3 | H | Team product; useful only after single-user UX is solid                          |
| 33 | **Federated knowledge graph** (`[[user/repo#note]]` over Git/HTTPS) | 17 | 12, 26 | H | Requires critical mass to be useful                                              |
| 34 | **Stylus / handwriting input** (touch canvas → on-device math-OCR → CAS) | 17 | 27 | M | Only valuable once mobile target ships                                          |
| 35 | **Voice input + spoken answers** (Whisper + local TTS) | 17 | 4 | M | Accessibility & hands-free; specialised audience                                |

## 4. Tiered roadmap

The same list, regrouped into shippable phases. Each phase ends with a
demonstrably better app.

### P0 — *Make it a notebook* (must-haves; #1–4)

Without these the app is still a calculator. They are the smallest set of
changes that lets a user open a folder, edit a notebook, and run it.

#1 Workspace + sidebar · #2 Markdown format · #3 Editor · #4 Block runner.

### P1 — *Make the notebook trustworthy and fast* (#5, #10, #11)

Cache + provenance, embedded tests, and export. The notebook becomes
reproducible, fast on re-run, and shareable as PDF/LaTeX. Smallest path to
"a thing people will actually use day-to-day."

### P2 — *Make the notebook intelligent and beautiful* (#6, #7, #8, #9)

Reactivity, inline typesetting, step-by-step derivations, and 3D plots.
This is the **product-defining** tier — after P2, the app is qualitatively
different from anything else in the category. If only one tier ever shipped
beyond P0/P1, it should be this one.

### P3 — *Make the notebook navigable and connected* (#12–17, #20, #21)

Wikilinks, tags, search (symbolic and plain), backlinks/graph view, widgets,
distraction-free mode, theme switching. Day-to-day usability for power users.

### P4 — *Make math the editing primitive* (#18, #19, #24)

WYSIWYG/projectional math editing, live preview, geometric diagrams. Goes
from "edit LaTeX, see math" to "manipulate math directly."

### P5 — *Make the app extensible and reaching* (#22, #23, #25, #26, #27, #28)

Pluggable kernels, plugin system, WASM engine, publish-as-site, mobile/web,
citations. Distribution + ecosystem.

### P6 — *Make the app ambitious* (#29, #30, #31, #32, #33, #34, #35)

LLM assist, formal proof, curriculum mode, CRDT collaboration, federation,
stylus/voice. Each is a strong product on its own and requires a substantial
substrate of P0–P4 to be worthwhile.

## 5. Three honest notes

1. **None of this is implemented.** The current codebase is everything shipped
   through task 14 (the help wizard). Tasks 15–17 and this requirements doc
   are all forward-looking design.
2. **Every requirement reuses the architectural choices made in tasks 6–14.**
   The persistent-engine autoload, sentinel-correlated reader, async result
   routing, design-token theme, modular menu/help framework, and the in-app
   screenshot helper are all leveraged by the proposals — none requires
   throwing earlier work away.
3. **Importance is not the same as commitment.** P3–P6 items are ranked
   below P2 because of compounding dependencies and effort, not because
   they're "less worth doing." The symbolic-aware diff (#14) and formal
   proof (#30), in particular, are the strongest *moat* features in the
   whole list — they belong on the roadmap, just not before P2's
   product-defining work is solid.

---

## Appendix — proposal → requirement mapping

| Source                                            | Mapped requirement IDs                                  |
|---------------------------------------------------|---------------------------------------------------------|
| Task 15: workspace folder                         | 1                                                       |
| Task 15: Markdown storage + executable blocks     | 2                                                       |
| Task 15: sidebar file browser                     | 1                                                       |
| Task 15: wikilinks                                | 12                                                      |
| Task 15: tags                                     | 15                                                      |
| Task 15: global search                            | 13                                                      |
| Task 15: live preview                             | 19                                                      |
| Task 15: Pandoc export                            | 11                                                      |
| Task 15: citation support                         | 28                                                      |
| Task 15: distraction-free mode                    | 20                                                      |
| Task 15: light/dark themes                        | 21                                                      |
| Task 16: reactive cells                           | 6                                                       |
| Task 16: inline typeset math                      | 7                                                       |
| Task 16: content-addressed cache + provenance     | 5                                                       |
| Task 16: interactive widgets in cells             | 17                                                      |
| Task 16: symbolic-aware search & diff             | 14                                                      |
| Task 16: pluggable kernels                        | 22                                                      |
| Task 16: backlinks + graph view                   | 16                                                      |
| Task 16: embedded `cas-test`                      | 10                                                      |
| Task 16: mobile/web targets                       | 27                                                      |
| Task 16: local LLM assist                         | 29                                                      |
| Task 17: formal proof blocks                      | 30                                                      |
| Task 17: step-by-step derivations                 | 8                                                       |
| Task 17: equivalence/structural similarity search | merged into 14                                          |
| Task 17: WYSIWYG/projectional math editing        | 18                                                      |
| Task 17: stylus/handwriting                       | 34                                                      |
| Task 17: voice input + spoken answers             | 35                                                      |
| Task 17: 3D plots + animations                    | 9                                                       |
| Task 17: manipulable geometric diagrams           | 24                                                      |
| Task 17: publish-as-site                          | 26                                                      |
| Task 17: federated knowledge graph                | 33                                                      |
| Task 17: curriculum mode                          | 31                                                      |
| Task 17: WASM-compiled engine                     | 25                                                      |
| Task 17: plugin system                            | 23                                                      |
| Task 17: CRDT collaboration                       | 32                                                      |

35 distinct requirements (down from 38 raw proposals after merging the
two symbolic-search variants and the mobile/WASM pair).
