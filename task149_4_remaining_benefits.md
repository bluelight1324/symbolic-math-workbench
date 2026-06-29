# Task 149.4 — Remaining Plotting Work, and the Benefit of Each Item

A benefit-first catalogue of what's left in the plotting subsystem (after task
149.3 added animated surfaces and vector fields). Each row says **what you'd build
and the concrete payoff** — so the list doubles as a value-ranked backlog. Effort:
**L/M/H**. Status grounded in the [149.2 audit](task149_2_plotting_remaining.md).

## A. New plot kinds (extend *what* you can draw)

| Item | Benefit | Effort |
|---|---|---|
| **`cas-implicit`** `f(x,y,z)=0` | Draw surfaces that **aren't graphs** — spheres, tori, level sets, blobby isosurfaces; the one common surface type still missing. | H (marching cubes / SDF shader) |
| **`cas-domain`** complex `f(z)` | A **whole new class** — colour the plane by `arg f` / `|f|` to *see* complex analysis (poles, zeros, branch cuts) at a glance. | M |
| **`cas-stream`** streamlines | Show *flow* (trajectories) of a vector field, far more readable than arrows for fluid/phase-portrait intuition. | M |

## B. 2-D polish (the everyday plots)

| Item | Benefit | Effort |
|---|---|---|
| **Multiple series + legend** | Compare curves on one axis (f vs f′, exact vs numeric) — the single most-requested 2-D feature. | M |
| **Filled regions / between-curves** | Shade integrals, confidence bands, inequalities — communicates area, not just a line. | L |
| **Log / semilog / polar axes** | Make exponential, power-law and periodic data **legible** (straight lines, natural angles). | M |

## C. Interaction (turn a figure into an instrument)

| Item | Benefit | Effort |
|---|---|---|
| **Probe → exact value** (click a point) | Read the **exact symbolic** f(x,y) and gradient at any point — answers "what is it *here*?" instantly. | M |
| **Draggable parameters** (slider bound to a symbol) | **Explorable explanations** — drag `a` and watch the surface deform live; the CAS keeps it exact. | M |
| **Camera pan / linked views** | Inspect detail off-centre; brush a 2-D region → highlight it on the 3-D surface. | M |

## D. CAS-graphical fusion (the differentiator — nothing else in this category does it)

| Item | Benefit | Effort |
|---|---|---|
| **Analytic normals** (symbolic gradient) | **Perfect shading** with no faceting — the lighting is mathematically exact, not estimated from neighbours. | L |
| **Curvature-aware adaptive sampling** | Publication smoothness at the **same triangle budget** — dense where it bends, sparse where flat. | M |
| **Exact singularity / discontinuity clipping** | **Never draw a fake spike across a pole** — the CAS knows where f is undefined; clip there instead of guessing. | M |
| **Exact level-set contours** (`solve f=c`) | Crisp, analytically-correct contour curves even on steep surfaces — beyond the shader's approximate bands. | M |

## E. Foundations (make everything after cheap and safe)

| Item | Benefit | Effort |
|---|---|---|
| **Declarative plot spec** (grammar of graphics) | Plots become **data** — serialisable, themeable, scriptable, AI-authorable; ends the per-kind builder sprawl. | M |
| **Visual-regression harness** (golden-image diff) | Catch **visual** breakage automatically — today only structure is unit-tested; this makes the rest safe to build. | M |
| **Quality switch** (Draft/Standard/Max) | Cheap by default (task 140), **cinematic on demand** — gates the heavy GPU passes without bloating the common case. | L |
| **Plugin API** `register_plot_kind` | New (and community) plot types **without touching core** — compounding capability. | L |
| **Plot provenance** (embed spec+seed) | Any figure **re-renders bit-identically** and is auditable — reproducible science, not orphan images. | L |

## F. Output & reach (deliverables)

| Item | Benefit | Effort |
|---|---|---|
| **PNG figure + MP4 animation** export | Get the plot **out of the app** — into papers, slides, and clips of the animated surfaces. | L |
| **Vector SVG/PDF + TikZ** export | **Infinitely-crisp** publication figures (and drop-into-LaTeX), not screen grabs. | M |
| **WebGL export** | Embed a **live, rotatable** plot in a web page / shared notebook — reach beyond the desktop. | M |
| **VR / AR** (OpenXR, Godot-native) | **Walk around** a PDE solution or curved-spacetime surface at room scale — intuition you can't get on a screen. | H (+ headset) |
| **Animation authoring** (keyframe timeline) | Turn a parameter sweep into a **narrated clip** — teaching and presentation. | M |
| **Plot styles / templates** | One-click **paper / slide / dark** looks — consistent, fast figure prep. | L |

## G. Automation, performance, accessibility

| Item | Benefit | Effort |
|---|---|---|
| **Auto-frame + data-aware colormap** | The plot **looks right with no fiddling** — fit camera, pick ranges, choose a perceptual/diverging/cyclic map by data type. | M |
| **Async / threaded sampling** | Dense grids and marching-cubes **never freeze the UI**. | M |
| **LOD / culling** | Huge surfaces stay **interactive** while orbiting. | M |
| **Uncertainty / ensemble viz** | Show **what's known** (error bands, confidence volumes), not a single deceptive curve. | M |
| **Sonification + screen-reader** | **Hear** a singularity rise; make plots usable **non-visually** — a new channel and accessibility. | M |

## H. Frontier (the long arc — mostly Godot-native per task 148.7)

| Item | Benefit | Effort |
|---|---|---|
| **Symbolic → GLSL** transpile | The function runs **per-pixel on the GPU** — exact, infinite-zoom, free animation; zero CPU sampling. | H |
| **Validated / interval plots** | A plot with a **proven error bound** that **cannot miss** a thin feature — trustworthy, not just plausible. | H |
| **Live GPU PDE simulation** | The PDE notebooks **run** — press play, scrub time, change a coefficient and watch it re-evolve. | H |
| **Neural-field super-resolution** | A coarse CAS grid becomes a **smooth, infinitely-zoomable** surface with analytic-quality normals. | H |
| **AI explain / NL→plot** (local model) | Plots that **caption themselves** and that you **author in plain language**. | M–H |
| **Differentiable inverse design** | **Fit parameters to a target** by descending gradients *through* the renderer. | H |

## Reading the backlog

- **Best value-per-effort right now:** analytic normals (D, L), filled regions
  (B, L), PNG/MP4 export (F, L), quality switch + provenance (E, L) — small,
  high-payoff.
- **Biggest single capabilities:** `cas-implicit` (A), the declarative spec (E),
  and live GPU PDE simulation (H).
- **The moat:** the **CAS-fusion** group (D) — exact normals/contours/singularities
  and complex domain colouring are things only a CAS-in-an-engine can do.

## Files changed
- None — benefits / backlog doc ("do 1 doc").
