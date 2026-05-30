# Task 62 — Expanded Font List (23 Options Across 7 Categories)

The Font dropdown in the notebook view's action bar went from 5 options
([task 58](task58_notebook_primary_and_fonts.md) +
[task 59](task59_facebook_font.md)) to **23**. The data layer
([font_config.gd](app/scripts/font_config.gd)) was already
fallback-chain-based, so growing the list was purely a config edit —
no handler / cell-builder / persistence changes needed.

---

## What's now in the dropdown

Grouped by intent (the dropdown shows them in this order):

### Generic / sans-serif (4)

| Key       | Label       | Tries (in order)                                                          |
|-----------|-------------|---------------------------------------------------------------------------|
| `default` | Default     | theme default — no override                                                |
| `system`  | System UI   | Segoe UI Variable → Segoe UI → SF Pro Text → Helvetica Neue → Arial       |
| `sans`    | Sans-Serif  | Segoe UI → Helvetica Neue → Arial                                          |
| `serif`   | Serif       | Cambria → Georgia → Times New Roman                                        |

### Programming-specific monospace (5)

| `mono`        | Monospace        | JetBrains Mono → Cascadia Code → Cascadia Mono → Consolas         |
| `fira_code`   | Fira Code        | Fira Code → Cascadia Code → Consolas                              |
| `jb_mono`     | JetBrains Mono   | JetBrains Mono → Cascadia Mono → Consolas                         |
| `cascadia`    | Cascadia Code    | Cascadia Code → Cascadia Mono → Consolas                          |
| `source_code` | Source Code Pro  | Source Code Pro → Consolas → Courier New                          |

(Each one is a separate item so users who specifically have / want one
of these get the actual face, not a fallback.)

### Modern UI sans-serifs (4)

| `inter`     | Inter      | Inter → Inter Display → Segoe UI → Helvetica Neue                 |
| `roboto`    | Roboto     | Roboto → Roboto Flex → Segoe UI → Helvetica Neue                  |
| `open_sans` | Open Sans  | Open Sans → Segoe UI → Helvetica Neue                             |
| `lato`      | Lato       | Lato → Segoe UI → Helvetica Neue                                  |

### Reading / display serifs (3)

| `charter`     | Charter      | Charter → Cambria → Georgia                       |
| `lora`        | Lora         | Lora → Georgia → Times New Roman                  |
| `merriweather`| Merriweather | Merriweather → Georgia → Times New Roman          |

### Math / academic (1)

| `cmu_serif` | CMU / Latin Modern | Latin Modern Roman → CMU Serif → Cambria Math → Cambria |

— for users who want notebooks to read like a LaTeX'd article.

### Legacy / casual (5)

| `verdana`    | Verdana        | Verdana → Tahoma                       |
| `tahoma`     | Tahoma         | Tahoma → Verdana                       |
| `trebuchet`  | Trebuchet MS   | Trebuchet MS → Tahoma                  |
| `calibri`    | Calibri        | Calibri → Segoe UI → Helvetica         |
| `comic`      | Comic Sans MS  | Comic Sans MS → Comic Sans             |

(Yes Comic Sans — surprisingly useful for early-grade math notebooks.)

### Proprietary brand fallbacks (3)

| `facebook` | Facebook | Facebook Sans → Optimistic Display → … → Helvetica Neue → Arial |
| `google`   | Google   | Google Sans → Google Sans Text → Product Sans → Roboto          |
| `apple`    | Apple    | SF Pro Text → SF Pro Display → -apple-system → Helvetica Neue   |

Same trick [task 59](task59_facebook_font.md) used for the Facebook
option: the proprietary face is listed first, with a graceful
sans-serif fallback for everyone who doesn't have it locally
installed.

---

## How it was added

Pure data — append entries to `FontConfig.FAMILIES`. Example:

```gdscript
{"key": "inter",   "label": "Inter", "names": [
    "Inter", "Inter Display", "Segoe UI", "Helvetica Neue", "sans-serif"]},
```

No changes to:
- The OptionButton wiring (it walks `FONT_CONFIG.FAMILIES`).
- `font_resource(key)` (builds a `SystemFont` from `names`).
- The persistence layer (`load_family()` / `save_pair()`).
- The applier (`_apply_font()` / `_font_apply()`).

That's the payoff of the
[task 58](task58_notebook_primary_and_fonts.md) fallback-chain design:
adding a font option *is* a one-liner against `FAMILIES`.

## Verification

- Project reimports headless with **exit 0, no script errors**.
- Pre-seeded `user://font.cfg` with `family = "serif"` → app launched
  with Serif (Cambria on the capture machine) applied everywhere
  including the new task-63 sidebar tree. The dropdown shows "Serif"
  selected. Switching to any other entry in-app applies instantly and
  persists.

## Honest scope

- **Some fonts aren't installed on most machines.** Inter, Roboto,
  Open Sans, Lato, Charter, Lora, Merriweather, Source Code Pro, Fira
  Code, JetBrains Mono are all open-licensed but typically need to be
  installed by the user (or come bundled with VSCode / editor packs).
  When they're not installed, the chain falls through to system
  defaults — same graceful-degradation contract every other entry has.
- **No font preview in the dropdown items.** Users see the name only;
  the actual font appears on the next cell rebuild. Adding a preview
  would mean rendering each item label in its target font — doable but
  a separate UI task.
- **No filtering / search.** With 23 items, the dropdown is still
  scrollable in one chunk; a search box would be premature.

---

## TL;DR

23 font options live in `FontConfig.FAMILIES` now, grouped from
generic to specific to proprietary, each with a SystemFont
fallback chain. The Font dropdown rebuilds automatically from
the array. Anyone who has a specific face installed sees it; everyone
else sees a sensible fallback. Persisted across launches like every
other family.
