# Task 35 — Mathematica-Style Inline Cells (Plots Beneath Their Source)

The original task-35 implementation added a single plot strip *below the
editor* — visible-when-needed, but still a separate band: the plot
floated underneath the text editor rather than sitting next to the
`cas-plot` block that produced it. The updated brief said "like
Mathematica," meaning each plot must appear inline with its source, in
document order. Multiple plots from one notebook should all be visible
together, each beneath the right block. That's what v2 ships.

See [app_screenshot_nbcells_small.png](app_screenshot_nbcells_small.png).

---

## The two view modes

The notebook view now has a **View** toggle in the top action bar:

| Mode      | What it shows                                                            |
|-----------|--------------------------------------------------------------------------|
| **Source**| The raw markdown source in a `CodeEdit` (the v1 behaviour, unchanged).   |
| **Notebook** | A scrollable column of *cells* rendered from the parsed AST: prose, source blocks (with their kind tag), result blocks, and **`cas-plot` blocks followed immediately by an inline plot canvas**. Multiple plots stack in document order. |

Both modes share the same underlying source-of-truth `.md` file. The
view button shows the **next** mode you'll switch to ("View: Source ▶"
when you're in Notebook mode, and vice-versa).

A **Run notebook** (F5) or **Force re-run** (Ctrl+F5) **auto-switches to
Notebook mode** when any `cas-plot` block produced samples — so a user
who presses Run on a plot-heavy notebook sees the rendered cells
without having to click the toggle.

## The cell renderer ([notebook_view.gd](app/scripts/notebook_view.gd))

`_rebuild_rendered_cells()` walks the same AST that
`NotebookRunner.parse_blocks` / `pair_blocks` produces, then emits one
Control per logical chunk into a `VBoxContainer` inside a
`ScrollContainer`:

| Cell type            | Widget                                  | Style                                              |
|----------------------|-----------------------------------------|----------------------------------------------------|
| Prose paragraph       | `RichTextLabel` with BBCode             | `#`/`##` rendered as larger bold via `[font_size]` |
| `cas` / `cas-plot` source | `PanelContainer` + label + `RichTextLabel` | Dark panel, blue left-border accent, `▸ kind` chip |
| `cas-result` / `cas-test-result` / `cas-derive-result` | `PanelContainer` + label + `RichTextLabel` | Dark green panel, green left-border, `= result` chip |
| **Inline plot** (for cas-plot blocks with stored samples) | `PlotPanel` (reused from the calculator view) | Full-width, ~220 px tall, plot drawn directly under its source |

The samples that the plot panel draws come from
`_plot_samples_by_line: Dictionary[int, PackedFloat64Array]` — a map
from the source block's start-line in the parsed AST to the float array
returned by `MathFormatter.parse_number_list(output)`. Populated by
`_on_engine_result()` whenever a `KIND_PLOT` block returns successfully:

```gdscript
if src_kind == NotebookRunner.KIND_PLOT and ok:
    var ys := MathFormatter.parse_number_list(output)
    _plot_samples_by_line[int(pair["source"]["start"])] = ys
    _show_plot_strip(pair["source"]["body"].strip_edges(), ys)
    _finish_block_locally(entry, "plotted %d samples" % ys.size(), true)
    return
```

`_emit_block_cell()` checks this map when it's building a `cas-plot`
cell:

```gdscript
if block["kind"] == NotebookRunner.KIND_PLOT \
        and _plot_samples_by_line.has(int(block["start"])):
    var ys := _plot_samples_by_line[int(block["start"])]
    var plot_panel := preload("res://scripts/plot_panel.gd").new()
    plot_panel.custom_minimum_size = Vector2(0, 220)
    _rendered_box.add_child(plot_panel)
    plot_panel.set_samples(X_MIN, X_MAX, ys)
    return
```

So plots appear inline **only after** a real run has produced numeric
samples for them. Before a run, a `cas-plot` cell in Notebook mode
shows just its source (with no plot below) — clicking Run populates the
samples and the next rebuild draws the curve beneath it.

## What's preserved from v1

- The **plot strip below the editor** still exists, used when the user is
  in Source mode and wants a quick visual without flipping to Notebook
  mode. `_show_plot_strip()` and `_hide_plot_strip()` are unchanged.
- The `cas-plot-result` block written back into the markdown stays as
  `plotted 61 samples` — succinct and meaningful for HTML/Pandoc
  export.

## Behaviour by event

| Event                                             | Notebook view                                              | Source view                                |
|---------------------------------------------------|-----------------------------------------------------------|--------------------------------------------|
| Open a file                                       | _plot_samples cleared; mode reset to Source               | Editor loads the file                       |
| Click **View** button                             | Toggle to Source                                          | Toggle to Notebook (rebuild cells)         |
| F5 / Run                                          | (no plots produced) Rebuild rendered cells, stay in view  | (no plots produced) Stay in Source         |
| F5 / Run                                          | (plots produced) Stay in Notebook view                    | (plots produced) Auto-switch to Notebook   |
| Ctrl+F5 / Force re-run                            | Same as F5 above                                          | Same as F5 above                            |
| Edit text                                         | (not available — Notebook view is read-only-ish)          | Standard CodeEdit                           |

## Reproduce manually

1. Launch the app, **F2** to switch to the notebook view.
2. Pick `plotting.md` in the sidebar (it has two `cas-plot` blocks).
3. Press **F5** to run. The view auto-switches to Notebook mode; both
   plots are visible inline, each beneath its source.
4. Click **View: Notebook ▶** to flip back to raw source.

Automated reproduction (used for the screenshot):

```powershell
& 'i:\readtgodot\tools\godot\Godot_v4.6.3-stable_win64.exe' `
    --path 'i:\readtgodot\app' -- --demo-plotnb
```

## What this is not

- **Not editable.** The Notebook view is a renderer, not a structural
  editor. Editing source still happens in the CodeEdit. A real
  cell-by-cell editor (where each source cell is its own editable widget)
  is a bigger refactor and remains out of scope here.
- **Not a Markdown engine.** Prose uses a tiny `#` / `##` heading
  recogniser inside RichTextLabel BBCode. Full Markdown rendering
  (lists, links, inline code, emphasis) is the next obvious follow-up;
  the design hooks are in place but the formatter isn't.
- **Plots don't persist as images.** Each render builds the cells from
  the in-memory `_plot_samples_by_line`. After a fresh app launch and an
  `--demo-plotnb`-style force-run is the way to repopulate them.
  Caching plot PNGs on disk and referencing them via Markdown
  `![](path)` is the follow-up that would also make HTML export carry
  the images.

## Honest scope of the v2 change

- **About 200 lines of new code** in `notebook_view.gd`: two
  scaffolding helpers (`_toggle_view_mode`, `_apply_view_mode`), the
  `_rebuild_rendered_cells` walker, two cell emitters
  (`_emit_prose_cell`, `_emit_block_cell`), and a plot-samples
  dictionary plus its callsite in `_on_engine_result`.
- **No breaking changes** to the existing notebook semantics — same
  cache (task 19), same force-rerun (task 29), same fence-block
  vocabulary, same HTML export. Source view is byte-for-byte the same
  experience.
- **The plot strip from v1 is kept** for source-mode use, but the
  Notebook view never shows it because the inline plots take its place.

That's how the brief "like Mathematica" cashes out: every plot appears
where it belongs in the document, multiple plots are visible together,
and there's no separate plot pane in the corner of the screen.
