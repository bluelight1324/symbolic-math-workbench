# Task 123 — Blank First Row in the File Tree (and Click Does Nothing)

## Report

> "After installing, the left-hand tree shows a blank in the first row, and a
> mouse click causes it to be blank."

In the file-tree sidebar the top row under the workspace folder was **empty** (no
filename), and clicking it did nothing useful — it just sat there blank.

## Cause — a non-`.md` file became a text-less, metadata-less row

The workspace folder contained a stray non-notebook file, **`algebra.html`** (an
HTML export). It sorts first alphabetically (`.html` < `.md`), so it landed in the
top row.

The bug was in `_populate_tree()`
([notebook_view.gd:368](app/scripts/notebook_view.gd#L368)). It created the tree
row **before** checking the file type:

```gdscript
for name in entries:
    var item := _sidebar_tree.create_item(parent)   # row created unconditionally
    if DirAccess.dir_exists_absolute(full):
        item.set_text(0, name + "/")  ; item.set_metadata(...)
    elif name.ends_with(".md"):
        item.set_text(0, name)        ; item.set_metadata(...)
    # else: row exists but has NO text and NO metadata  → blank row
```

For `algebra.html` neither branch ran, so the row got **no text** (blank) and
**no metadata**. And because clicking relies on the row's metadata
(`_on_tree_item_activated` reads `meta["kind"] == "file"`,
[notebook_view.gd:380](app/scripts/notebook_view.gd#L380)), clicking the blank row
found no metadata and **did nothing** — exactly the "mouse click causes it to be
blank" symptom.

This showed up "after installing" because the installer copies the whole
`notebooks_sample` folder — including `algebra.html` — to the user's notebooks
folder.

## Fix — only create a row for a directory or a `.md` notebook

[notebook_view.gd `_populate_tree()`](app/scripts/notebook_view.gd#L368) now
creates the `TreeItem` **inside** each matching branch, so non-notebook files are
skipped entirely:

```gdscript
for name in entries:
    var full := dir_path.path_join(name)
    if DirAccess.dir_exists_absolute(full):
        var item := _sidebar_tree.create_item(parent)
        item.set_text(0, name + "/"); item.set_metadata(0, {"kind":"dir", "path":full})
        _populate_tree(full, item)
    elif name.ends_with(".md"):
        var item := _sidebar_tree.create_item(parent)
        item.set_text(0, name);       item.set_metadata(0, {"kind":"file","path":full})
    # any other file (e.g. algebra.html) → no row at all
```

Now every visible row is a real, openable notebook, so there is no blank row and
nothing blank to click. The tree is also robust to *any* stray non-`.md` file in
the workspace, not just this one.

## Verification

Launched the app (no script errors). `app_screenshot_task123.png` shows the tree
now reading **notebooks_sample/ → algebra.md → calculus.md → …** with **no blank
row** (`algebra.html` is gone from the list), and `algebra.md` auto-loads in the
editor.

## Notes
- `algebra.html` is an untracked stray export; it's left on disk but the tree no
  longer shows it. (Deleting it is optional and not required by the fix.)

## Files changed
- `app/scripts/notebook_view.gd` — `_populate_tree()` creates a row only for
  directories and `.md` files.
