# Task 58 — Notebook View as Primary + Font Family/Size That Persist

Three changes, all in the notebook view ([notebook_view.gd](app/scripts/notebook_view.gd)):

1. **Notebook view is now the primary display.** Raw Source is an opt-in
   toggle. The action bar's button now reads **"Show Source"** (the
   action that clicking does) instead of the previous mode-name label.
2. **Font family** can be picked from a dropdown — Default / Monospace /
   Sans-Serif / Serif — using Godot's `SystemFont` to pick the first
   available local font in each family's preference list.
3. **Font size** can be picked from a spinbox (10–32 pt).
4. **Both choices persist** across launches via a new `FontConfig`
   wrapper around a `ConfigFile` at `user://font.cfg`.

See [app_screenshot_task58_small.png](app_screenshot_task58_small.png).

---

## What changed in the action bar

```
[ Open workspace… ] [ New note ] [ Save (Ctrl+S) ] [ Run notebook (F5) ]
[ Force re-run (Ctrl+F5) ] [ Export HTML ]
[ Show Source ]               ← was "View: Notebook ▶" / "View: Source ▶"
[ | ] [ Font: Default ▼ ] [ Size: [18] ]                  ← NEW
```

The View toggle's text always reads what clicking it does:

- In Notebook mode (default): **Show Source**
- In Source mode: **Show Notebook**

## What changed in defaults

| Behaviour                                             | Before                    | After                    |
|-------------------------------------------------------|---------------------------|--------------------------|
| `_is_notebook_view` initial value                     | `false` (Source)          | **`true` (Notebook)**    |
| `_open_file_at` post-open mode                        | reset to Source           | **stays in Notebook**    |
| Default font size                                     | each control hard-coded   | **`FontConfig.DEFAULT_SIZE = 18`** + per-control overrides |
| Default font family                                   | theme default             | **`FontConfig.DEFAULT_FAMILY = "default"`** (theme default) |
| Choice persistence                                    | none                      | **`user://font.cfg`**    |

## How the font controls work

### Data layer ([app/scripts/font_config.gd](app/scripts/font_config.gd))

```gdscript
const FAMILIES := [
    {"key": "default", "label": "Default",   "names": []},
    {"key": "mono",    "label": "Monospace", "names": [
        "JetBrains Mono", "Cascadia Code", "Cascadia Mono",
        "Consolas", "Courier New", "monospace"]},
    {"key": "sans",    "label": "Sans-Serif", "names": [
        "Segoe UI", "Helvetica Neue", "Helvetica",
        "Arial", "sans-serif"]},
    {"key": "serif",   "label": "Serif", "names": [
        "Cambria", "Georgia", "Times New Roman", "serif"]},
]
```

`font_resource(key)` returns either `null` (use the theme default) or a
`SystemFont` whose `font_names` is the family's preference list —
Godot picks the first one actually installed on the user's machine.

`load_size()` / `load_family()` / `save_pair(size, family)` are the
three ConfigFile-backed entry points; load returns the
`DEFAULT_SIZE / DEFAULT_FAMILY` constants when the file doesn't exist
or is malformed.

### UI layer ([notebook_view.gd](app/scripts/notebook_view.gd))

```gdscript
_font_family_btn = OptionButton.new()
for f in FontConfig.FAMILIES:
    _font_family_btn.add_item(f["label"])
_font_family_btn.item_selected.connect(_on_font_family_changed)

_font_size_spin = SpinBox.new()
_font_size_spin.min_value = 10
_font_size_spin.max_value = 32
_font_size_spin.step = 1
_font_size_spin.value_changed.connect(_on_font_size_changed)
```

On change, the handler persists the new value and calls `_apply_font()`
which:
1. Sets `_editor`'s `font_size` and (if the family != default) overrides
   its `font`.
2. If Notebook view is currently visible, calls `_rebuild_rendered_cells`
   so all cell labels pick up the new size/family.

Each cell builder calls `_font_apply(label, bump)` per Label /
RichTextLabel it creates:

```gdscript
func _font_apply(ctrl: Control, bump: int = 0) -> void:
    var size := _font_size + bump
    if ctrl is RichTextLabel:
        ctrl.add_theme_font_size_override("normal_font_size", size)
        if _font_resource:
            ctrl.add_theme_font_override("normal_font", _font_resource)
    elif ctrl is Label:
        ctrl.add_theme_font_size_override("font_size", size)
        if _font_resource:
            ctrl.add_theme_font_override("font", _font_resource)
```

### Startup wiring

```gdscript
func _ready() -> void:
    …
    _font_size = FontConfig.load_size()
    _font_family = FontConfig.load_family()
    _font_resource = FontConfig.font_resource(_font_family)
    if _font_size_spin:
        _font_size_spin.value = _font_size
    if _font_family_btn:
        _font_family_btn.select(FontConfig.family_index(_font_family))
    _apply_font()
    _apply_view_mode()    # reflect the new "Show Source" / "Show Notebook" label
```

So a user who picked Size 22 / Sans-Serif yesterday gets exactly that
again on the next launch — no setting to remember, no re-pick.

## What didn't change

- **Calculator view** untouched. Font controls only live in the
  notebook view since that's the user's primary reading surface.
- **Cache + force re-run** behave identically; the rendered cells just
  re-skin existing source/result blocks.
- **Inline plot** rendering for `cas-plot` blocks (task 35 v2) still
  appears beneath the source block in Notebook view.
- **The toolbar on top-left** (the icon menu bar) untouched — the
  notebook still sits below it at `offset_top = 102` per the previous
  layout change.

## Honest bug found and fixed in the same pass

While building, I noticed the rendered Notebook view was emitting *two*
cells per `cas` block — one paired with its `cas-result` (correct), and
one for the `cas-result` block standing alone (a leftover from the
walker treating every block as a candidate cell). Fix: filter
`cas-*-result` kinds out of the walker's main `block_starts.has(i)`
branch since they're consumed by their paired source. Single line:

```gdscript
if String(b["kind"]).ends_with("-result"):
    i = int(b["end"]) + 1
    continue
```

The pre-fix screenshot showed every `cas-result` block appearing twice
(once green-bordered, once as its own source-style box). The post-fix
screenshot has it once each — clean.

## Honest scope

- **Per-control font overrides** rather than a global theme swap. The
  editor + every rendered cell gets the override; other views
  (calculator, advanced, help wizard, package settings) keep their
  existing fonts. Extending the font preference globally would be a
  one-Theme-tweak follow-up.
- **No font preview** in the dropdown. The label is `Default` /
  `Monospace` / etc.; the SystemFont resolves at render time. The
  user sees the actual font on the next cell rebuild — one click away.
- **Heading sizes** in prose cells are still hard-coded relative
  (`+4`, `+8`) — they scale with the base size correctly but the
  ratio is fixed. Customising the heading ratios would be a separate
  setting.

## Verification

- Project re-imports headless with **exit 0, no script errors**.
- Default-launch screenshot
  ([app_screenshot_task58_small.png](app_screenshot_task58_small.png))
  shows: toolbar at top unchanged, notebook view as default with the
  Algebra prose / source / result cells rendered, action bar's "Show
  Source" + "Font: Default" + "Size: 18" controls visible at top
  right, sidebar listing the workspace files.
- Manually changing Size from 18 → 24 in the spinbox immediately
  rebuilds the cells at the larger size; reopening the app reads
  Size 24 back from `user://font.cfg`.
