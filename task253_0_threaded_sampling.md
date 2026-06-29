# Task 253.0 — Threaded Sampling (No More UI Freeze)

## Request

> "Do the threaded sampling issue."

The issue flagged since [149.6 §0](task149_6_plots_whats_left.md) (and again in 251.0 /
252.0): the **implicit-surface** (Surface Nets) and **domain-colouring** builds run
their heavy per-point sampling *synchronously* on the main thread when a notebook
renders — tens of thousands of evaluations that **froze the UI for seconds**. This
task moves that work off the main thread.

## What was built

- **Placeholder → background sample → swap.** A heavy plot cell now appears
  **instantly** with a "⏳ rendering…" placeholder. The expensive sampling runs on a
  `WorkerThreadPool` thread; when it finishes, the real visual is built on the main
  thread and swapped into the cell. The UI never blocks — you can scroll and
  interact while a surface or domain image computes.
- **Shared `_async_plot(chip, worker, finish)`** wraps the pattern, reused by both
  implicit surfaces and domain colouring (and available for future heavy plots).
  `worker` does pure CPU work; `finish` turns its result into a Control on the main
  thread.

## Getting threading right (the hard part)

Three real hazards, each fixed:

1. **No RenderingServer off-thread.** Creating a GPU resource on a worker corrupts
   the renderer (it crashed at shutdown). So the worker now returns **pure data** —
   the implicit worker returns a filled `SurfaceTool` and the **`commit()`** (which
   allocates the mesh) happens on the main thread in `_implicit_finish`; the domain
   worker returns a plain `Image` and the `ImageTexture` is created on the main
   thread. No scene nodes are touched off-thread.
2. **Never build during teardown.** Results are applied from **`_process`** (normal
   main-thread frames only) — *not* from a thread `call_deferred`, which could land
   in the shutdown frame and build a `SubViewport` into a half-destroyed tree
   (an access violation). On exit (`NOTIFICATION_EXIT_TREE` / `PREDELETE`) the view
   **joins** any in-flight workers but does **not** apply them.
3. **Survive a re-render.** If the notebook re-renders while a sample is in flight,
   its target cell is freed; `_process` reads the slot **untyped** and guards with
   `is_instance_valid` before touching it, so a stale result is dropped cleanly
   instead of erroring.

Detached use (the headless test harness, no live frame) falls back to a synchronous
build — there's nothing to keep responsive and no safe thread hand-off.

## Verification

- **Unit tests** (`--test126`): **98 / 98 pass, exit 0** — the builders now return an
  async placeholder cell (`PanelContainer`); the worker functions are tested
  directly (`_implicit_surftool` → `SurfaceTool` / null for no-crossing,
  `_domain_image` → `Image`), and `_async_plot` builds a placeholder + applies the
  finish synchronously when detached.
- **Integration:**
  - `--test-export` (a real window) runs `implicit_surfaces.md` — the surface is
    sampled on a worker, swapped in, and exported: `EXPORT_RESULT ok 1088x560`,
    **exit code 0** (the earlier off-thread-commit shutdown crash is gone).
  - `--demo-domain` renders all three portraits via the threaded path with **no
    script errors**; the `z³ − 1` image (`app_screenshot_task2530.png`) shows the
    three roots of unity, phase wheel and magnitude rings, plus its PNG button.

## Still remaining

Sampling no longer freezes the UI. Higher-resolution implicit/domain grids are now
practical (a future bump, since the cost is off the main thread). Remaining plot
items from [149.6](task149_6_plots_whats_left.md): MP4 capture of animated surfaces,
vector SVG/PDF/TikZ export, and the CAS-fusion tier.

## Files changed
- `app/scripts/notebook_view.gd` — `_async_plot` + `_process` apply + exit-join
  `_notification`; `_build_implicit3d` → worker `_implicit_surftool` + main-thread
  `_implicit_finish` (commit on main); `_build_domain2d` → worker `_domain_image` +
  main-thread `_domain_visual`; `_pending_plots` member.
- `app/scripts/_test126.gd` — tests updated for the async builders + worker funcs
  (now 98/98).
