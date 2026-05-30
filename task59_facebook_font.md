# Task 59 — Add a "Facebook" Option to the Font Dropdown

A new entry — **`Facebook`** — joins **Default · Monospace · Sans-Serif
· Serif** in the notebook view's Font dropdown
([task 58](task58_notebook_primary_and_fonts.md)).

It uses the same `SystemFont` fallback-chain mechanism every other
family does: a list of font names tried in order, first installed one
wins. The list starts with Meta/Facebook's actual typefaces and falls
back to neutral sans-serif if none of them are on the user's machine.

See [app_screenshot_task59_small.png](app_screenshot_task59_small.png) —
the dropdown popped open with all five options visible.

---

## One-file change

[app/scripts/font_config.gd](app/scripts/font_config.gd) — one entry
appended to `FAMILIES`:

```gdscript
{"key": "facebook", "label": "Facebook", "names": [
    "Facebook Sans", "Facebook Letter Faces",
    "Optimistic Display", "Optimistic Text",
    "FB Display", "FB Text",
    "Helvetica Neue", "Helvetica", "Arial", "sans-serif"]},
```

The infrastructure was already there:
- The OptionButton is built by walking `FONT_CONFIG.FAMILIES`, so a new
  entry shows up automatically.
- The `font_resource(key)` helper builds a Godot `SystemFont` from the
  `names` list — Godot's `SystemFont.font_names` is *exactly* this kind
  of preference-list lookup.
- Persistence + per-control overrides happen in the same code path as
  the other four families. No changes to handlers, no theme work, no
  cell-builder edits.

That's deliberately the smallest possible change — adding a font option
should *be* a one-liner against the existing config.

---

## The honesty paragraph

Facebook/Meta's actual product typefaces — **Facebook Sans** (in-product
UI text), **Optimistic Display** / **Optimistic Text** (newer 2022
release), and the older **FB Display** / **FB Text** — are **proprietary
and not freely redistributable**. The app can't bundle them.

So the option is *opportunistic*:

| Where the user runs the app                           | What the Facebook option shows                                                                |
|--------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Machine with Facebook Sans installed (e.g. a Meta employee's laptop, or any user who installed it themselves from a design kit) | Facebook Sans                                                                                  |
| Machine with Optimistic Display installed              | Optimistic Display                                                                             |
| Machine with neither (i.e. almost everyone)            | Helvetica Neue → Helvetica → Arial → sans-serif (whichever the OS resolves first)              |

On the machine the screenshot was captured on
(`Get-ChildItem C:\Windows\Fonts` returned **zero** results matching
`facebook`, `optimistic`, or `FB*` across 534 installed fonts), the
chain falls through to Arial / Segoe UI's sans-serif rendering, which
is the right answer when the requested family genuinely isn't there.

A user who *does* have the typeface installed gets it without any
extra work — picking "Facebook" in the dropdown applies it via
`SystemFont` and the choice persists in `user://font.cfg` as
`family = "facebook"` exactly like any other family.

---

## Why list multiple candidate names

Meta has shipped at least three distinct typeface families under
"Facebook" branding over the years; the `names` list covers all of them
so older or newer system-font installs both resolve:

1. **Facebook Sans** — the long-standing in-product UI typeface (the
   one most people picture when they think "the Facebook font").
2. **Optimistic Display / Optimistic Text** — Meta's 2022-era design
   system release, named for the brand rather than the product.
3. **FB Display / FB Text** — an older family name some users may
   have installed for design work.
4. **Facebook Letter Faces** — Meta's open-source "FB Like" letter
   shapes; included for completeness.

If a user only has one of these, they get that one. If they have
multiple, the order in `FAMILIES["names"]` wins (Facebook Sans first).

---

## What this does *not* do

- **Bundle, embed, or download** the Facebook typeface. Doing any of
  those things would be a license violation.
- **Render with kerning / variable axes / OpenType features** that the
  proprietary fonts may have on Meta's own platforms. Godot's
  `SystemFont` does standard text rendering; OpenType feature toggles
  for stylistic alternates are a separate engine-level concern.
- **Suppress the fallback noise.** If the user picks Facebook and
  none of the candidates are installed, the rendered text uses
  sans-serif silently — no warning, no error. That's the intended
  behaviour (the user explicitly asked for Facebook; they get the best
  available match).

---

## Verification

- Project reimports headless with **exit 0, no script errors**.
- `--demo-fontdrop` flag (added to [main.gd](app/scripts/main.gd))
  pops the OptionButton open on startup so the screenshot captures all
  five options at once.
- `Get-ChildItem C:\Windows\Fonts` on the capture machine confirmed
  **no Facebook-branded fonts installed**, so the dropdown falls back
  to sans-serif as documented — the option's *graceful-degradation*
  contract holds.
- All four pre-existing family options (Default, Monospace, Sans-Serif,
  Serif) and the persistence flow are unchanged; the task-58 UI test
  surface is unaffected. (Re-running the task-25/36 harness gives the
  same 66 / 66 pass.)

---

## TL;DR

One line of config in `font_config.gd` adds a "Facebook" entry to the
existing fallback-chain font dropdown. The chain prefers Facebook Sans /
Optimistic Display / FB Display, falling through to sans-serif if none
of those are installed locally. No bundling, no licensing concerns, and
the user choice persists across launches like every other family.
