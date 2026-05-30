# Task 61 — Beautify the Interface (Density, Shadows, Animations)

Where [task 60](task60_color_schemes.md) gave the notebook view a
colour-scheme dropdown, task 61 ships the *other* knobs of visual
polish: a **density preset** (Compact / Default / Comfortable), a
**Shadows** toggle, and an **Animations** toggle. All three persist via
a new `StyleConfig` at `user://style.cfg` and apply instantly when
flipped.

Combined with task 60, the same notebook can now look like a
chalk-on-blackboard chunk (Dark + Compact, no shadows) or a Notion-style
clean reading surface (Light + Comfortable + shadows + animations) — same
content, just dressed differently.

See the matched-content screenshots in
[app_screenshot_task60_dark_small.png](app_screenshot_task60_dark_small.png)
(Dark / Default) and
[app_screenshot_task60_light_small.png](app_screenshot_task60_light_small.png)
(Light / Comfortable).

---

## The three controls

The action bar gained three new widgets after the
[task 60](task60_color_schemes.md) Theme dropdown:

```
… Theme: [Dark ▼]    Style: [Default ▼]   [☑] Shadows   [☑] Animations
                                  task 61 ── ─────────  ─────────────
```

| Control       | Widget      | Effect                                                            |
|---------------|-------------|-------------------------------------------------------------------|
| **Style**     | `OptionButton` (Compact / Default / Comfortable) | Cell spacing, padding, corner radius, border width, chip size all scale together |
| **Shadows**   | `CheckBox`  | Subtle drop shadow under every source / result cell               |
| **Animations**| `CheckBox`  | Fade-in on the Source ↔ Notebook view toggle (via `Tween`)        |

All three changes write to `user://style.cfg` immediately. A
freshly-launched app reads the file in `_ready()` and selects the
dropdown / checkboxes accordingly — same pattern as the font + colour
configs.

## The density preset

[app/scripts/style_config.gd](app/scripts/style_config.gd) packages five
visual constants per preset, so picking "Compact" or "Comfortable" is one
click rather than fiddling with five sliders:

```gdscript
const DENSITIES := {
    "compact": {
        "label": "Compact", "cell_separation": 6, "cell_padding": 6,
        "corner_radius": 4, "border_width": 2, "chip_size": 12, "chip_offset": 1,
    },
    "default": {
        "label": "Default", "cell_separation": 12, "cell_padding": 8,
        "corner_radius": 6, "border_width": 3, "chip_size": 13, "chip_offset": 2,
    },
    "comfortable": {
        "label": "Comfortable", "cell_separation": 20, "cell_padding": 14,
        "corner_radius": 10, "border_width": 4, "chip_size": 14, "chip_offset": 4,
    },
}
```

Cell builders read every numeric constant from `_density[…]`:

```gdscript
sb.set_corner_radius_all(int(_density["corner_radius"]))
sb.set_content_margin_all(int(_density["cell_padding"]))
sb.border_width_left = int(_density["border_width"])
…
src_kind_lbl.add_theme_font_size_override("font_size", int(_density["chip_size"]))
```

The `_rendered_box`'s separation between cells uses
`_density["cell_separation"]`. Picking a new preset calls
`_apply_visual_style()` which:
1. Updates the root background colour (whichever active colour scheme).
2. Updates `_rendered_box`'s separation constant.
3. Rebuilds every cell so the new StyleBoxFlats take effect.

## The Shadows toggle

The shadow comes from Godot's `StyleBoxFlat.shadow_*` properties:

```gdscript
if _shadows_on:
    sb.shadow_color = Color(0, 0, 0, 0.35)
    sb.shadow_size = 6
    sb.shadow_offset = Vector2(0, 2)
```

Off → no shadow_color / size set → cells render with the border-only
outline. Toggling it rewrites every cell's StyleBoxFlat on the next
rebuild.

## The Animations toggle (Source ↔ Notebook fade)

`_apply_view_mode()` (which fires on the **Show Source** / **Show
Notebook** button) now optionally fades the incoming view in:

```gdscript
if _animations_on:
    outgoing.visible = false
    incoming.visible = true
    incoming.modulate = Color(1, 1, 1, 0)
    var tween := create_tween()
    tween.tween_property(incoming, "modulate", Color(1, 1, 1, 1), 0.18)
else:
    _editor.visible = not _is_notebook_view
    _rendered_scroll.visible = _is_notebook_view
    _editor.modulate = Color(1, 1, 1, 1)
    _rendered_scroll.modulate = Color(1, 1, 1, 1)
```

180 ms is a deliberate "you noticed it but don't sit through it" length.
Disabling the toggle reverts to instant view swaps and resets `modulate`
to opaque white so the previous animation doesn't leave a half-faded
state behind.

## Persistence

[app/scripts/style_config.gd](app/scripts/style_config.gd):

```gdscript
const PATH := "user://style.cfg"

static func save(density: String, shadows: bool, animations: bool) -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("user", "density", density)
    cfg.set_value("user", "shadows", shadows)
    cfg.set_value("user", "animations", animations)
    cfg.save(PATH)
```

Every change to the dropdown or either checkbox calls `save()` with all
three current values, so the file is always a complete snapshot of the
user's choices.

## Verification

- Project re-imports headless with **exit 0, no script errors**.
- **Default startup** (default Dark + Default style + shadows on +
  animations on): see
  [app_screenshot_task60_dark_small.png](app_screenshot_task60_dark_small.png) —
  the action bar's last three controls (`Style: [Default ▼]`,
  `☑ Shadows`, `☑ Animations`) are visible at the top right; the cells
  have subtle drop shadows; spacing matches the previous "default" look.
- **Pre-seeded `user://style.cfg`** with `density = "comfortable"`,
  `shadows = true`, `animations = true` plus `user://color.cfg` with
  `key = "light"` → the relaunched app picks all four up correctly:
  [app_screenshot_task60_light_small.png](app_screenshot_task60_light_small.png)
  shows wider cell padding (14 px vs 8 px), larger corner radius
  (10 px vs 6 px), thicker left borders (4 px vs 3 px), and visibly
  taller separation between cells — exactly the Comfortable preset.
- Toggling animations off and clicking **Show Source** swaps views
  instantly; toggling back on adds the fade.

## Honest scope

- **Density affects the notebook cells only.** The action bar above the
  cells, the sidebar tree, and the toolbar use the app's global theme
  from [task 9](task9_larger_and_rebrand.md). Extending density
  globally would mean swapping the root `Theme` and is left for a
  follow-up.
- **Shadow is one preset.** No softness / size / offset sliders.
  Adding them is one more spinbox per knob; the StyleBoxFlat already
  carries all three properties.
- **Animation duration is fixed at 180 ms.** If the user wants
  longer / shorter, that becomes the next setting. The fade is a
  `Tween` on `modulate.a`, not a layout animation — cells don't
  expand/contract; they just blend in.
- **No animation on density / scheme changes themselves.** A
  Comfortable → Compact transition rebuilds cells instantly. A real
  cross-fade would require keeping both old and new cells in the tree
  during the tween — straightforward but not done yet.

---

## TL;DR

`StyleConfig` packages three visual knobs (density preset, shadows,
animations) behind one OptionButton + two CheckBoxes in the notebook
action bar. Every change persists; every change applies via the same
`_apply_visual_style()` / `_rebuild_rendered_cells()` path. Combined
with [task 60](task60_color_schemes.md), the notebook view now has a
proper visual customisation surface — five themes × three densities ×
two toggles = 60 distinct looks, all one click away.
