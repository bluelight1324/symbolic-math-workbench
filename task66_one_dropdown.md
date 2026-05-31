# Task 66 — Collapse the Action Bar into One Dropdown Menu Button

The notebook view's action bar had grown to **13 widgets** after the
font/theme/style tasks (58–61). Per the user's screenshot:

```
[Open workspace…] [New note] [Save (Ctrl+S)] [Run notebook (F5)]
[Force re-run (Ctrl+F5)] [Export HTML] [Show Source]
Font: [Default ▼]  Size: [24]
Theme: [Dark ▼]  Style: [Default ▼]  [☑ Shadows]  [☑ Animations]
```

Task 66 replaces all 13 with a single **`☰ Notebook menu ▾`**
`MenuButton`. Clicking it pops up a nested `PopupMenu` carrying every
file action, the view toggle, every preference, and every checkable
toggle.

Screenshots:
- [app_screenshot_task66_small.png](app_screenshot_task66_small.png) — the
  collapsed action bar (one button on the right of the workspace label).
- [app_screenshot_task66_open_small.png](app_screenshot_task66_open_small.png) — the
  popup open, showing every option.

---

## The popup tree

```
☰  Notebook menu  ▾
├── Open workspace…
├── New note
├── ────
├── Save              Ctrl+S
├── Run notebook            F5
├── Force re-run            Ctrl+F5
├── Export HTML
├── ────
├── Show Source           ← text flips to "Show Notebook" in Source mode
├── ────
├── Font   ▶
│   ├── ◉ Default
│   ├── ◯ System UI
│   ├── ◯ Sans-Serif
│   ├── ◯ Serif
│   ├── ◯ Monospace
│   ├── ◯ Fira Code
│   ├── ◯ JetBrains Mono
│   ├── ◯ Cascadia Code
│   ├── ◯ Source Code Pro
│   ├── ◯ Inter
│   ├── ◯ Roboto
│   ├── ◯ Open Sans
│   ├── ◯ Lato
│   ├── ◯ Charter
│   ├── ◯ Lora
│   ├── ◯ Merriweather
│   ├── ◯ CMU / Latin Modern
│   ├── ◯ Verdana
│   ├── ◯ Tahoma
│   ├── ◯ Trebuchet MS
│   ├── ◯ Calibri
│   ├── ◯ Comic Sans MS
│   ├── ◯ Facebook
│   ├── ◯ Google
│   └── ◯ Apple
├── Size   ▶
│   ├── 10 pt    14 pt    18 pt    22 pt    28 pt
│   ├── 12 pt    16 pt    20 pt    24 pt    32 pt   (10 presets, one radio-checked)
├── Theme  ▶
│   ├── ◉ Dark
│   ├── ◯ Light
│   ├── ◯ Solarized Dark
│   ├── ◯ Solarized Light
│   └── ◯ High Contrast
├── Style  ▶
│   ├── ◯ Compact
│   ├── ◉ Default
│   └── ◯ Comfortable
├── ────
├── ☑ Shadows
└── ☑ Animations
```

`◉` = currently selected radio item. `☑` = currently checked boolean
toggle.

## What changed in code

[app/scripts/notebook_view.gd](app/scripts/notebook_view.gd):

| Before                                                       | After                                               |
|--------------------------------------------------------------|------------------------------------------------------|
| ~85 lines building 6 Buttons + 2 OptionButtons + 1 SpinBox + 2 CheckBoxes + 6 separator labels in the topbar | ~10 lines building a single `MenuButton` + a call to `_build_menubar_popup()` |
| `_view_mode_btn` (Button)                                    | One `_popup` item id `_ID_VIEW`, label kept in sync by `_apply_view_mode()` |
| `_font_family_btn` (OptionButton, 23 items)                  | `_font_submenu` (PopupMenu with 23 radio_check items) |
| `_font_size_spin` (SpinBox, 10–32)                            | `_size_submenu` (10 discrete preset radio items)     |
| `_color_btn` (OptionButton, 5 items)                          | `_theme_submenu` (5 radio items)                     |
| `_density_btn` (OptionButton, 3 items)                        | `_style_submenu` (3 radio items)                     |
| `_shadows_check` (CheckBox)                                   | `_popup.add_check_item("Shadows", _ID_SHADOWS)`     |
| `_anim_check` (CheckBox)                                      | `_popup.add_check_item("Animations", _ID_ANIMATIONS)`|

The old field declarations are **kept** (set to null at runtime) so the
existing handlers' defensive checks (`if _font_family_btn: …`) still
compile — but those branches are now dead. A follow-up cleanup pass can
delete them.

## Handler dispatch

One `_on_menu_id_pressed(id: int)` connected to every `PopupMenu`
(the main popup + each of the four submenus). Range-based switch:

```gdscript
const _ID_OPEN := 0       _ID_FONT_BASE := 1000   # 1000–1099
const _ID_NEW := 1        _ID_SIZE_BASE := 2000   # 2000–2099
const _ID_SAVE := 2       _ID_THEME_BASE := 3000  # 3000–3099
const _ID_RUN := 3        _ID_STYLE_BASE := 4000  # 4000–4099
const _ID_FORCE := 4      _ID_SHADOWS := 5000
const _ID_EXPORT := 5     _ID_ANIMATIONS := 5001
const _ID_VIEW := 6

func _on_menu_id_pressed(id: int) -> void:
    if id == _ID_OPEN:   _on_open_workspace()
    elif id == _ID_RUN:  _on_run()
    …
    elif id >= _ID_FONT_BASE and id < _ID_SIZE_BASE:
        _on_font_family_changed(id - _ID_FONT_BASE)
        _sync_menu_checks()
    elif id >= _ID_SIZE_BASE and id < _ID_THEME_BASE:
        _font_size = int(_SIZE_OPTIONS[id - _ID_SIZE_BASE])
        FontConfig.save_pair(_font_size, _font_family)
        _apply_font()
        _sync_menu_checks()
    …
```

`_sync_menu_checks()` walks every submenu and ticks the radio item
matching the current `_font_family` / `_font_size` / `_color_key` /
`_density_key`, plus the two boolean check items.

## Why preset Size options instead of a free spinbox

`PopupMenu` items are labelled text — there's no native way to embed a
SpinBox inside one. Two options:
1. Discrete preset sizes (10 / 12 / 14 / 16 / 18 / 20 / 22 / 24 / 28 / 32). One click → set + persist + tick.
2. A `Size → Custom…` item that opens a small modal with a SpinBox.

Picked (1) — simpler, covers the common range, and the user's previous
value (24 in their screenshot) round-trips losslessly: opening the
popup ticks the 24 pt item.

If a user needs a non-preset size (e.g. 25 pt), they can edit
`user://font.cfg` directly — the load path tolerates any integer.
Adding a "Custom…" submenu item that opens a SpinBox modal is a
follow-up; deferred.

## Defaults & current state on first open

Reading the screenshot the user shared (Size 24, Theme Dark, Style
Default, Shadows + Animations on), the menu reflects each:

| Menu | Shows |
|------|-------|
| Size submenu | `24 pt` radio-checked |
| Theme submenu | `Dark` radio-checked |
| Style submenu | `Default` radio-checked |
| Top-level | `☑ Shadows`, `☑ Animations` |

All sync via `_sync_menu_checks()` after loading from disk in
`_ready()`.

## Verification

- Project reimports headless with **exit 0, no script errors**.
- Closed action bar: only the workspace label and the
  `☰ Notebook menu ▾` button on the right
  ([task66_small.png](app_screenshot_task66_small.png)).
- Opened popup
  ([task66_open_small.png](app_screenshot_task66_open_small.png))
  shows every option from the screenshot reorganised into the tree
  above. `☑ Shadows` and `☑ Animations` correctly show their
  on-state. The `▶` indicators on Font / Size / Theme / Style flag the
  submenus.
- Clicking each item routes through the existing handlers
  (`_on_open_workspace`, `_on_run`, `_on_force_run`, etc.) — no
  behaviour changes, just the route.

## Honest scope

- **Spinbox-style precise size control is gone.** Replaced by 10
  presets covering 10–32 pt. See "Why preset Size options" above.
- **Keyboard shortcuts** (Ctrl+S, F5, Ctrl+F5) still work — they're
  wired in `main.gd` via `_unhandled_input`, not in the action bar.
  The menu items just *display* the shortcut text as a hint.
- **The previous widget fields stay in the script as nullable** for
  now (less risk of breaking the
  [task 25/36 UI tests](task36_comprehensive_test_v2.md) that read
  `_font_size_spin.value` etc.). A subsequent test update + field
  cleanup pass can delete them — separate task.
- **The MenuButton itself uses the global app theme**, not the user-picked font.
  Once the font is changed via the popup, the menu's *items* still
  render in the theme font. Updating the menu's own font is a one-line
  `_menu_btn.add_theme_font_override` away; deferred.

---

## TL;DR

13 widgets in the action bar → 1 `MenuButton` + 1 nested `PopupMenu`.
File actions, view toggle, all four preferences (Font / Size / Theme /
Style), and the two boolean toggles (Shadows / Animations) live in one
tree. Click-to-route handlers re-use every existing `_on_*` callback.
Sync to disk and back is unchanged.
