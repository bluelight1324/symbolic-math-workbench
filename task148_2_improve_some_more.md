# Task 148.2 — Improving on the Plotting Plan, Some More

Task 148.1 made the plot *know its maths, be manipulable, publication/web/VR-ready,
and principled.* This tier is the frontier beyond that: the plot becomes a **live
computation that learns, explains itself, engages new senses, tells a story, and
is scientifically reproducible.** Each item is genuinely new versus 148.1.

## A. The plot *is* the computation — live GPU PDE solving

148/148.1 still **sample a precomputed** function. The leap: solve the PDE
**live on the GPU** and let the surface *be* the running simulation.

- A **compute-shader solver** (finite-difference / spectral) steps u(t,x) each
  frame into a `Texture`/storage buffer; a vertex shader reads it as the height.
  The curved-spacetime wave or the nonlinear-PDE evolution from tasks 133/135
  *runs and moves* on screen — press play, scrub time, change a coefficient and
  watch it re-evolve. The notebooks are *about* PDEs; this makes them dynamical.
- Initial/boundary conditions and coefficients come straight from the REDUCE
  cells, so the symbolic setup drives the live numeric simulation.

## B. Learned representations — infinite-resolution surfaces

- Fit a tiny **neural field** (a SIREN / small MLP, trained in a compute shader)
  to the CAS samples. It gives a smooth, **infinitely-zoomable** surface and
  **super-resolves** a coarse 32×32 CAS grid to screen resolution — sharper than
  any fixed mesh, and cheap to evaluate per-pixel.
- The same network yields analytic-quality normals and lets you zoom forever
  without re-meshing.

## C. AI-assisted visualization (the LLM/ML layer)

- **Auto-explanation.** A model reads the spec + sampled features and annotates:
  "saddle at the origin, poles along x = ±1, growth ~ r⁴." Turns a figure into a
  caption and spoken description.
- **Natural-language → plot.** "Show the gradient field coloured by magnitude,
  top-down" compiles to a plot spec (the declarative grammar from 148.1) — no
  syntax to learn.
- **ML-guided adaptive sampling.** A predictor places samples where error will be
  highest, beating the curvature heuristic of 148.1.

## D. New senses & accessibility

- **Sonification.** Map height/curvature to pitch/timbre and scrub along a curve
  or surface ridge — *hear* the singularity spike (task 135) rise. A genuinely
  new channel, and an accessibility win.
- **Screen-reader descriptions** generated from the spec (axis A's auto-
  explanation), so plots aren't opaque to non-visual users.
- **Perceptual depth, fully**: motion parallax, ground-shadow contact, and
  stereo/anaglyph — beyond the SSAO/shadows already shipped.
- **Cyclic, CVD-safe colormaps** chosen automatically by data *type* (sequential
  / diverging / **cyclic** for phase/angle) — past 148.1's "perceptual ramp."

## E. Narrative & explorable explanations

- **Scrollytelling.** Bind camera pose + parameters to the notebook scroll
  position: as the reader scrolls past a `cas-anim` block, the surface rotates,
  the coefficient sweeps, the contour highlights — the figure *performs* the
  explanation.
- **Math-anchored annotations.** Auto-placed arrows/labels that point to features
  the CAS identifies (a root, a pole, an inflection) and *follow* them as
  parameters change.

## F. Scientific rigor — reproducibility, uncertainty, richer objects

- **Reproducible plots.** Extend the existing `src-hash` provenance (results
  already carry it) to **plots**: embed the full spec + engine version + grid +
  seed in the `cas-*3d` result, so any figure re-renders bit-identically and is
  auditable.
- **Uncertainty / ensembles.** Error bands (2-D), confidence *volumes* and
  spaghetti/ensemble surfaces (3-D) for data with noise or parameter ranges —
  show what's *known*, not just a single curve.
- **Tensor & higher-rank fields.** Beyond vectors: ellipsoid-glyph and
  hyperstreamline visualisation of the metric/Hessian tensors the GR notebooks
  already compute (tasks 133/146) — visualise `g`, the curvature tensor.
- **Units & dimensional analysis** on axes, so plots are physically meaningful.

## G. Frontier rendering

- **Hardware ray tracing** (Vulkan RT, as Godot gains it) → true reflection/
  refraction for glassy iso-surfaces and caustics.
- **Gaussian-splat fields** — represent a scalar/vector field as splats for soft,
  volumetric, fast rendering.
- **Temporal super-resolution** (DLSS-like compute upscale) and **HDR output** —
  maximal smoothness and dynamic range for the live simulations of axis A.

## Priority — the few that change everything

1. **Live GPU PDE simulation (A)** — the single biggest leap: notebooks about
   PDEs that *run*. Reuses the compute pipeline planned in 148.
2. **Reproducible-plot provenance (F)** — cheap, extends `src-hash`, and makes
   every other feature trustworthy/auditable.
3. **Auto-explanation + NL→plot (C)** and **sonification (D)** — accessibility and
   approachability, riding the declarative spec from 148.1.
4. **Neural-field super-resolution (B)** and **scrollytelling (E)** — polish and
   narrative, once the simulation + spec foundations exist.

## Bottom line

148.1 made the plot *intelligent and principled*. 148.2 makes it **alive**
(GPU-solved, time-evolving), **learned** (neural-field, AI-explained,
NL-authored), **multisensory** (sound, stereo, accessible), **narrative**
(scrollytelling), and **rigorous** (reproducible, uncertainty-aware, tensor-
capable). It turns mathdot's plots from *pictures of mathematics* into *running,
explainable, reproducible instruments* — the ceiling a CAS-in-a-game-engine can
actually reach.

## Files changed
- None — this is the "improve some more" doc ("do 1 doc").
