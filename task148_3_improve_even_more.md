# Task 148.3 — Improving on the Plotting Plan, Even More

Earlier tiers made the plot maximal (148), intelligent (148.1), and alive (148.2).
This tier is the far frontier — **paradigm shifts**, not features: plots that are
*provably correct*, compiled straight to the GPU, composable as objects,
self-discovering, differentiable end-to-end, and fused into one reactive world.
Each axis is genuinely new versus 148.1/148.2.

## A. Provably-correct (validated) plots — never miss a feature

Every plotter so far, including 148.2's neural fields, **samples** — so a thin
spike or a narrow pole between samples can be missed entirely. The leap:
**rigorous, validated rendering.**

- Use **interval arithmetic / Taylor models** to evaluate f over each pixel/cell
  *as a range*, not a point. The mesh then carries a **proven error bound**: "this
  surface is everywhere within ε of the true f." A region that *might* contain a
  root or pole is flagged, not skipped.
- It **cannot miss** a feature, however thin — the opposite of sampling. REDUCE's
  exact derivatives feed the Taylor coefficients.
- Output a machine-checkable **certificate** alongside the figure — connects to
  the roadmap's `cas-prove`. A plot you can *trust*, not just look at.

## B. Symbolic → GPU transpilation — zero-CPU, per-pixel-exact

148/148.2 sample on the CPU (or train a net). Instead, **compile the REDUCE
expression itself into a GPU shader.**

- Transpile the symbolic AST (REDUCE prefix form) directly to **GLSL** and bind it
  as the surface's `ShaderMaterial`/compute kernel. The exact function is then
  evaluated **per-vertex and per-pixel on the GPU** at native speed — no sampling
  grid, no `Expression` interpreter, no neural approximation.
- Infinite zoom with exact values, instant parameter changes, and animation for
  free (the shader re-runs each frame). This is the true performance/quality
  ceiling: the plot *is* the function, running on the GPU.

## C. Plots as first-class composable objects

A plot stops being a terminal output and becomes a **value you can compute with.**

- **Plot algebra**: subtract two solution surfaces, FFT a plotted field and plot
  the result, overlay a geodesic on a metric — all tracked symbolically, so the
  composition is exact, not pixel math.
- **Bidirectional editing**: drag/sculpt the rendered surface → the system solves
  the **inverse problem** (sketch-to-function), proposing the symbolic expression
  whose graph you drew. Drawing becomes a way to *define* maths.

## D. Automated mathematical discovery — the engine explores for you

Beyond rendering what you asked: let the CAS+engine **find what's interesting.**

- Auto-detect and label **critical points, symmetries, asymptotes, conserved
  quantities, and bifurcations**, using REDUCE (`solve` ∇f=0, symmetry tests).
- **Active exploration of parameter space**: the system searches (α, β, …) for
  qualitatively distinct regimes and auto-generates a **bifurcation atlas** /
  phase-portrait gallery — surfacing behaviour you didn't know to look for.

## E. End-to-end differentiable pipeline — inverse design

Make the whole chain — CAS → mesh → renderer — **differentiable**.

- **Fit through the renderer**: given a target image or dataset, gradient-descend
  the symbolic parameters so the *rendered* plot matches it (differentiable
  rendering + autodiff through the expression). Inverse design of functions from
  pictures.
- **On-manifold optimisation, animated**: solve geodesics, minimal surfaces, or
  optimal-transport flows *on* the plotted surface with a GPU solver and watch the
  optimiser converge — the plot hosts its own variational problems.

## F. The whole notebook as one reactive world

Today each plot is an isolated viewport. Fuse them.

- **One shared 3-D scene/coordinate space** for the notebook, with a full
  **dependency-DAG** (roadmap #6): edit a coefficient cell and every dependent
  surface, field, and annotation in the scene **re-evolves live**.
- **Coupled multi-physics co-render**: the metric, the wave propagating on it, and
  its geodesics shown together and interacting — the notebook becomes a single
  consistent simulation, not a stack of pictures.

## G. Semantic, knowledge-linked plots

- Each plot links into the **Zettelkasten** (roadmap #12–16): "this is a Clifford
  torus" → wikilinked to its properties, references, and related notes; queryable
  ("show every notebook whose surface has positive curvature").
- Provenance + citations baked in → **publishable, connected, auditable** figures,
  not orphan images.

## Priority — the ones that are both deepest and buildable

1. **Symbolic → GLSL transpilation (B)** — concrete, huge speed/quality win,
   reuses the existing REDUCE AST; the clearest next build.
2. **Validated/interval plots (A)** — the correctness frontier; pairs with
   `cas-prove` and the reproducibility provenance from 148.2.
3. **Automated discovery (D)** — high wow-factor, leans on `solve`/symmetry the
   CAS already does.
4. **Unified reactive world (F)** — depends on the dependency-DAG; the integrative
   payoff once A–D exist.
5. **Differentiable inverse design (E)** and **plot algebra / sketch-to-function
   (C)** — the research-grade horizon.

## Bottom line

148.2 made plots *alive*. 148.3 makes them **trustworthy** (proven error bounds),
**native** (the symbolic function compiled onto the GPU), **composable** (plots as
values, sketch-to-function), **self-exploring** (auto-discovered features and
bifurcations), **invertible** (fit parameters through the renderer), **unified**
(one reactive world), and **connected** (semantic, citable). The plot stops being
an output of mathematics and becomes an **instrument of it** — which is the most a
CAS welded to a real-time engine can aspire to.

## Files changed
- None — this is the "improve even more" doc ("do 1 doc").
