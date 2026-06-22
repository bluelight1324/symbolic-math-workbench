# Task 108 — New Note: Stray "%s", Not Editable

## Problem

Creating a **New note** produced a broken notebook (see the user's screenshot of
`zzz.md`):

1. **Unwanted symbols on top** — the note opened with a stray `%s` heading.
2. **Not editable** — the new note opened in the read-only rendered view, so the
   user couldn't type into it.

## Root causes

In [notebook_view.gd](app/scripts/notebook_view.gd) `_on_new_note_confirmed()`:

1. The starter template was written **literally**, with its title placeholder
   never substituted:
   ```gdscript
   f.store_string("# %s\n\n...")   # no `% name` — the "%s" was stored verbatim
   ```
   So the heading was the literal `# %s`, which the renderer drew as the stray
   "%s" symbols (made worse by the drop-cap on the first character).
2. After creating the file it called `_open_file_at(path)`, which always opens in
   the **Notebook (rendered)** view — a read-only stack of cells. A brand-new
   note therefore appeared uneditable.

## Fix

```gdscript
# 1) Substitute the note's name as the title.
var title := raw.get_basename()
f.store_string("# %s\n\nWrite some prose, then a `cas` block:\n\n```cas\n(x+1)^2\n```\n" % title)
...
_open_file_at(path)
# 2) Open a new note in editable Source mode (rendered view is read-only).
_is_notebook_view = false
_apply_view_mode()
```

- The heading is now the note's name (e.g. `# zzz`) — no more `%s`.
- The note opens directly in the **Source** editor (the editable `CodeEdit`), so
  the user can start typing immediately. (Existing notes still open in the
  rendered view as before; only *new* notes switch to Source on creation.)

## Verification

Drove the exact new-note code path in the app (creating `demo_new_note`):

- The created file's first line is `# demo_new_note` — the correct title, **no
  `%s`** (confirmed by reading the file back).
- The app shows **"Editor – demo_new_note.md"** in the editable Source view —
  the `CodeEdit` with line numbers (1–8), not the read-only rendered cells — so
  the note is editable on creation (`app_screenshot_task108.png`).

(The temporary flag used to drive this and the throwaway test note were removed
after verifying.)

## Files changed
- `app/scripts/notebook_view.gd` — substitute the title in the new-note template;
  open new notes in editable Source mode.
