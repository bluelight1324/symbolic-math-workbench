# Task 117 — Why Is There a "%s" on the Page?

## Question

> "Why is there a %s on the page?" (from the `zzz.md` screenshot)

The notebook `zzz.md` renders a heading that looks like **"%s"** at the top
(the drop-cap styling enlarges the first character, so it reads as a big "%"
followed by "s").

## Why

`zzz.md`'s first line is the literal text:

```
# %s
```

That `%s` is an **unsubstituted template placeholder**. When the "New note"
template was created, the title was written as `"# %s\n..."` but the filename
was never substituted into it — so the literal `%s` ended up in the file, and
the notebook renderer shows it as an `# ` heading reading "%s".

## This was already fixed (task 108) — for *new* notes

The root cause is the exact bug fixed in **task 108**
([task108_new_note_fixes.md](task108_new_note_fixes.md)):
`_on_new_note_confirmed()` now substitutes the note's name into the template:

```gdscript
var title := raw.get_basename()
f.store_string("# %s\n\n...```cas\n(x+1)^2\n```\n" % title)
```

So **notes created now** get a proper title (e.g. `# zzz`), with no `%s`.

## So why does `zzz.md` still show it?

Because `zzz.md` is an **existing file** that was created **before** the task-108
fix (it was made while testing the new-note feature). The fix only changes how
*new* notes are written; it doesn't rewrite files that already exist on disk.
`zzz.md` therefore keeps its literal `# %s` first line.

## How to make it go away

Just edit `zzz.md` and change `# %s` to a real title (e.g. `# zzz`) — open it,
toggle to **Source** (the ✎ Source top button), fix the line, Save. Or delete
`zzz.md` (it was only a test note). I left it untouched since it's your file and
this task only asked *why* the `%s` appears.

## Files changed
- None — this is an explanation. (The underlying bug was already fixed in task
  108; `zzz.md` is a pre-fix leftover.)
