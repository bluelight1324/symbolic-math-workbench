# Task 99 — Integrate Plotting Into the Notebook

## Goal

> "Integrate plotting in the notebook itself, instead of a separate plotter
> window."

## Before

`cas-plot` blocks were drawn in **two** places:

1. **Inline** in the rendered notebook, beneath the source block (task 35 v2), and
2. a **separate "plot strip"** — a plotter pane pinned to the bottom of the
   notebook view with its own caption and a **"Hide plot"** button (task 35 v1).

The bottom strip was the redundant "separate plotter": a pane outside the
notebook's cell flow that popped up whenever a plot ran. It was also a dark,
unthemed panel that clashed with the MATLAB light look (task 94).

## After

Plotting is now **purely inline** in the notebook cell stack — there is no
separate plot pane. Each plot is rendered as a **framed result cell** directly
beneath the `cas-plot` block that produced it, styled and coloured to match the
active notebook theme.

### Changes

**[notebook_view.gd](app/scripts/notebook_view.gd)**
- Removed the separate plot strip entirely: the `_plot_strip` / `_plot_caption`
  / `_plot_panel` members, their construction in `_build_ui`, the
  `_show_plot_strip()` / `_hide_plot_strip()` functions, and every call to them
  (`_on_engine_result`, `_open_file_at`, `_apply_view_mode`).
- Rebuilt the inline plot in `_emit_block_cell` as a proper notebook cell: a
  `PanelContainer` using the scheme's result-cell box, a `= plot  <expr>
  (N samples · x ∈ […])` caption chip in the result-accent colour, and the
  plot panel beneath it (raised to 260 px tall). The plot's colours are set
  from the active scheme (light background, MATLAB-blue curve) so it reads as
  part of the notebook.

**[plot_panel.gd](app/scripts/plot_panel.gd)**
- Added `set_theme_colors(bg, axis, grid, curve)` so the inline plot can adopt
  the notebook's scheme instead of being a fixed dark panel.

### Run paths covered

Plots appear inline regardless of how a `cas-plot` cell is run:
- **Run All** / **Run notebook** — `_finish_run` switches to the rendered
  notebook view and rebuilds cells, drawing each plot inline.
- **Per-cell ▶ Run** (task 96) — same pipeline via `_run_one`.
- **From source mode** — running a plot auto-switches to the notebook view, so
  the plot shows inline there (nothing is left in a separate pane).

## Verification

Ran the app with the plotting notebook (`--demo-plotnb`); no script errors.
`app_screenshot_task99.png`: the `▸ cas-plot  sin(x) + sin(2*x)/2` cell is
immediately followed by a framed result cell — orange
`= plot  sin(x) + sin(2*x)/2  (61 samples · x ∈ [-10, 10])` caption above the
curve, drawn on a **light background with a MATLAB-blue curve** that matches the
theme. No separate bottom plot strip appears anywhere.

## Files changed
- `app/scripts/notebook_view.gd` — removed the separate plot strip; inline plot
  is now a themed framed cell.
- `app/scripts/plot_panel.gd` — `set_theme_colors()` for scheme-matched inline
  plots.
