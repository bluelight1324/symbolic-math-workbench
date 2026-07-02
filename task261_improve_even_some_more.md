# Task 261 — Improving Math Rendering *Even Some More* (the far frontier)

Fifth in the sequence: 257 (best font) → 258 (implement) →
[259](task259_improve_math_rendering.md) (structured LaTeX/SVG) →
[260](task260_improve_even_more.md) (alive: animated, editable, validated, spatial).
This doc answers **"how will you improve even *some* more?"** — the paradigm-shift
tier, where math notation stops being a *view of* a computation and becomes a
**living computational and knowledge medium**. Increasingly speculative; each item is
tagged for how grounded it is. (A doc; far-future work.)

## Where 260 tops out

260 made a *single* equation **alive** — it animates, edits back to the CAS, is
provably faithful, lives in 3-D. But it's still **one expression, at one scale, in one
notation, alone, on a screen, disconnected from the rest of mathematics.** 261 breaks
those last six walls: **one-scale, one-notation, one-representation, isolated,
untethered, un-provable.**

## 1. Semantic zoom — infinite level-of-detail math ★ grounded

"Google-Maps for equations." Zoom *out* and a page-long derivation collapses to
`∫ = F(b) − F(a)`; zoom *in* and each term unfolds to full detail, then to its
derivation, then to the numbers. Fold/unfold any subexpression; the notation's
**detail level tracks the zoom** continuously. mathdot is a viewport/LOD engine
already (its plots zoom) — the same machinery applied to the expression tree. Breaks
**one-scale.**

## 2. Cross-representation morphing — the Rosetta view ★ grounded, unifies the app

The same object is a **formula, a graph, a numeric table, a geometric figure, and a
running simulation** at once — and you **slide continuously between them** (symbolic
`sin x` ⇄ its curve ⇄ its Taylor table ⇄ the unit-circle animation). mathdot already
*has* the CAS, the plots, and numeric sampling; 261 is the **smooth interpolation
between representations of one concept**, so understanding transfers across forms.
Breaks **one-representation.**

## 3. Reader-adaptive notation — the equation in *your* dialect ★★ tractable

One expression, rendered in the **reader's** conventions: physics vs pure-math vs
engineering notation, Leibniz vs Newton derivatives, `∂` vs comma-subscript, expert
(terse) vs learner (every step named). An AST + a **notation-style layer** (plus a
model for translating conventions) means the *same* CAS object prints differently for
different readers — and can **translate between a paper's notation and yours**. Breaks
**one-notation.**

## 4. Proof-carrying math — rendered *and provably true* ★ moonshot, uniquely valuable

Beyond 260's "faithful render" (the picture matches the CAS): integrate a **proof
assistant** (Lean / Isabelle) so each result carries a **machine-checked proof**, and
the display marks **verified vs conjectural**, the proof itself explorable inline.
Not "the CAS says so" but "here is the checked proof." The ultimate trust ceiling —
possible because everything on screen is already a formal expression. Breaks
**un-provable.**

## 5. Knowledge-graph tethering — every equation linked to all math ★★ high value

Recognize what an expression *is* and **link it into the corpus**: "this is the
Gaussian integral → DLMF §7," "this sequence → OEIS A000108," "this matches a known
theorem → arXiv." Hover to see identities, alternative closed forms, and where the
result appears in the literature. The rendered math becomes a **hyperlinked node in
the web of mathematics**, not an island. Breaks **isolated.**

## 6. Provenance & time-travel derivations ★★ grounded

Every result carries its full **derivation DAG**: hover any term to see *where it came
from and why*, **scrub backward/forward** through the derivation, and **branch**
alternate paths ("what if I don't assume x>0?"). The document remembers its own
reasoning and lets you explore counterfactuals — a debugger for mathematics.

## 7. Collaborative, real-time math ★★ tractable

Multiple people **edit and manipulate the same live equation** across the network
(CRDT-based), with presence and cursors, in the Godot app or its web export. A shared,
reactive math space — pair-proving and classroom co-derivation. Breaks **untethered**
(from other people).

## 8. Multisensory & tangible math ★ novel

Extend beyond the eye: **sonify** structure (hear a symmetry, a discontinuity as a
click), **haptics** (feel a singularity), **3-D print** a surface or knot, refreshable
**Braille (Nemeth)**. Math you can hear, feel, and hold — a genuinely new channel and
a deep accessibility win.

## 9. Self-improving, generative notation ★ moonshot

A model that **invents optimal notation** for novel structures the CAS emits
(compressing a monstrous expression into a readable custom glyph/definition), renders
"in the style of" a chosen textbook, and **learns each user's readability preferences**
over time (RL over layout choices, optionally eye-tracking-informed). Notation that
designs itself for clarity.

## 10. Uncertainty-native notation ★ niche-but-real

Render **distributions, intervals, and probabilistic terms natively** — an equation
with error bars, a random variable shown as its density inline, interval arithmetic
displayed as bands. Notation that shows *what is known* about each quantity, not just
a point value (mirrors the "uncertainty viz" idea from the plot backlog).

## Ranking — the "even some more" worth chasing first

| # | Idea | Wall it breaks | Grounded? |
|---|---|---|---|
| 1 | **Semantic zoom / LOD math** | one-scale | ★ high — reuses mathdot's viewport/LOD |
| 2 | **Cross-representation morphing** | one-representation | ★ high — unifies CAS+plots+numeric it already has |
| 5 | **Knowledge-graph tethering** | isolated | ★★ medium — needs corpus + matcher |
| 6 | **Provenance / time-travel derivations** | (opacity) | ★ high — REDUCE already knows every step |
| 3 | **Reader-adaptive notation** | one-notation | ★★ medium |
| 7 | **Collaborative real-time** | isolated (people) | ★★ medium |
| 4 / 8 / 9 / 10 | proof-carrying · multisensory · generative · uncertainty | un-provable · senses · clarity | moonshot / niche |

## Bottom line

258–259 made math **legible**; 260 made it **alive**; 261 makes it a **medium**: one
structured, validated object that you can **zoom through** at any scale (1), **morph
between** all its forms (2), **read in your own dialect** (3), **trust as proven** (4),
**follow into the whole literature** (5), **rewind and branch** (6), **build with
others** (7), and **hear, feel, and hold** (8). The unifying bet is unchanged and
compounding: because mathdot holds the math as a *machine-checkable, CAS-backed
structure* — not pixels — it can zoom, morph, prove, link, and personalize notation in
ways a static renderer never can. The most tractable next steps that reuse what
mathdot already is: **semantic zoom (1)**, **cross-representation morphing (2)**, and
**provenance/time-travel (6)**.

## Files
- This doc only (task 261 asks "how will you improve even some more" — no code
  changed). Items 1, 2, and 6 are the highest-leverage, most-tractable of this tier.
