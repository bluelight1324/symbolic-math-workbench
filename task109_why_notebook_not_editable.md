# Task 109 — Why Is the Notebook Not Editable?

## Short answer

The notebook view has **two surfaces**, and the one shown by default is a
**read-only preview**. Typing requires switching to the **Source** surface,
which *is* editable. Nothing is broken — it's a view-mode default.

## The two surfaces

[notebook_view.gd](app/scripts/notebook_view.gd) keeps two controls stacked in
the same area, with only one visible at a time (`_apply_view_mode()`):

| Surface | Control | Editable? | What it shows |
|---|---|---|---|
| **Notebook** (rendered) | `_rendered_scroll` → a column of cells | **No** | A Mathematica-style presentation: prose, source blocks, results, and **inline plots**, built from `RichTextLabel` / `Label` cells |
| **Source** | `_editor` (`CodeEdit`) | **Yes** | The raw Markdown of the file, with line numbers |

The rendered cells are **display widgets** (`RichTextLabel`/`Label`) — there is
no text caret to type into. That surface is intentionally a *preview*, not an
editor. The `CodeEdit` (`_editor`) is the real editor and is fully editable
(it has no `editable = false`).

## Why the read-only one is the default

This was a deliberate design choice (tasks 35 v2 / 58): the notebook view is the
**primary display**, so the app opens files showing the nicely-rendered cells
(with results and plots inline) rather than raw Markdown. Concretely,
`_open_file_at()` sets `_is_notebook_view = true`, so **every file you open lands
in the read-only rendered view**:

```gdscript
# _open_file_at(...)
_is_notebook_view = true
_apply_view_mode()        # shows _rendered_scroll (read-only), hides _editor
```

`_apply_view_mode()` then shows `_rendered_scroll` and hides the `CodeEdit`:

```gdscript
var incoming := _rendered_scroll if _is_notebook_view else _editor   # read-only when true
```

So "the notebook is not editable" really means "you're looking at the rendered
preview, not the source editor."

## How to edit it today

Open the **Notebook** menu (top-left toolbar button) and choose **"Show
Source"** (`_ID_VIEW` → `_toggle_view_mode()`). That flips `_is_notebook_view`
to `false`, hides the rendered cells, and shows the editable `CodeEdit`. The
same menu item then reads **"Show Notebook"** to flip back. Edit, then **Save**
(`Ctrl+S`) and **Run** (`F5`) to re-render.

## What task 108 already changed

A **brand-new** note now opens straight into the Source editor (task 108), so
you can type immediately after creating it. **Existing** files still open in the
rendered preview by default — which is the behaviour this doc explains.

## If you want existing notebooks to open editable too

That's a one-line change — have `_open_file_at()` set `_is_notebook_view = false`
(or remember the last-used mode) so files open in Source. It's not applied here
because defaulting to the rendered preview is the established design (tasks
35 v2 / 58); say the word and I'll switch the default or make it a remembered
preference.

## Files
- None changed — this task is an explanation. (The editable surface already
  exists; it's reached via **Show Source**.)
