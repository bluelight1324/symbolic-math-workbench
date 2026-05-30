# Task 60 — Colour-Scheme Picker (Five Bundled Palettes, Persisted)

The notebook view's action bar now carries a **Theme** dropdown with
five bundled palettes — **Dark · Light · Solarized Dark · Solarized
Light · High Contrast**. Picking one re-skins the notebook background +
every cell (source / result / prose) instantly and writes the choice to
`user://color.cfg`, so it sticks across launches.

Built on Godot's `OptionButton` + `StyleBoxFlat` + `ConfigFile` — the
same triple [task 58](task58_notebook_primary_and_fonts.md) used for
font persistence.

See [app_screenshot_task60_dark_small.png](app_screenshot_task60_dark_small.png)
(default Dark) and
[app_screenshot_task60_light_small.png](app_screenshot_task60_light_small.png)
(Light + Comfortable, same content).

---

## The schemes

[app/scripts/color_config.gd](app/scripts/color_config.gd) defines each
scheme as a Dictionary with 9 colour slots that the cell builders need:

| Slot         | What it colours                                                   |
|--------------|--------------------------------------------------------------------|
| `bg`         | The notebook view's root `ColorRect`                              |
| `src_bg`     | `cas` / `cas-test` / `cas-derive` / `cas-plot` source cell fill   |
| `src_border` | Left-accent border of source cells                                 |
| `src_chip`   | `▸ cas` chip-label colour                                         |
| `res_bg`     | `cas-result` cell fill                                            |
| `res_border` | Left-accent border of result cells                                 |
| `res_chip`   | `= result` chip-label colour                                       |
| `text`       | Main label / RichTextLabel `default_color` / `font_color` override |
| `muted`      | Secondary / caption labels                                         |

Five schemes ship:

| Key                | Label             | Notes                                                                 |
|--------------------|-------------------|-----------------------------------------------------------------------|
| `dark` *(default)* | Dark              | The original palette from tasks 19 / 35 — gunmetal bg, blue+green chips |
| `light`            | Light             | Cream-white bg, pale blue source cells, pale green result cells       |
| `solarized_dark`   | Solarized Dark    | Ethan Schoonover's classic dark variant (`#002b36` / `#268bd2` / `#859900`) |
| `solarized_light`  | Solarized Light   | The light counterpart (`#fdf6e3` / `#268bd2` / `#859900`)              |
| `high_contrast`    | High Contrast     | Pure black bg, white text, white source borders, yellow result borders |

## How it persists

```gdscript
const PATH := "user://color.cfg"

static func load_key() -> String:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return DEFAULT_KEY
    var k := String(cfg.get_value("user", "key", DEFAULT_KEY))
    return k if SCHEMES.has(k) else DEFAULT_KEY

static func save_key(key: String) -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("user", "key", key)
    cfg.save(PATH)
```

`load_key()` falls back to `dark` whenever the file is missing or
unknown — a future scheme rename can't soft-brick the app.

## What the UI looks like

The action bar now has a Theme dropdown right after the Font controls:

```
… [ Save ] [ Run notebook ] [ Force re-run ] [ Export HTML ] [ Show Source ]
  Font: [Default ▼]  Size: [18]
  Theme: [Dark ▼]                  ← NEW
  Style: …                          ← task 61
```

OptionButton items come straight from `ColorConfig.ordered_keys()` →
`scheme(k)["label"]`. The `item_selected` signal writes the new key
through `ColorConfig.save_key()` and calls `_apply_visual_style()` which
re-colours the root `ColorRect` and rebuilds every cell so all
`StyleBoxFlat` colours pick up the new scheme.

## Where the colours are read

[notebook_view.gd](app/scripts/notebook_view.gd) — the cell emitter
`_emit_block_cell` and the helper `_make_cell_box` now read every
colour from `_color_scheme` instead of the previous hardcoded values:

```gdscript
src_panel.add_theme_stylebox_override("panel",
    _make_cell_box(_color_scheme["src_bg"], _color_scheme["src_border"]))
…
src_kind_lbl.add_theme_color_override("font_color", _color_scheme["src_chip"])
src_text.add_theme_color_override("default_color", _color_scheme["text"])
```

And prose cells:

```gdscript
lbl.add_theme_color_override("default_color", _color_scheme["text"])
```

The root background:

```gdscript
_root_bg.color = _color_scheme["bg"]
```

That's the entire colour surface for the notebook view.

## Verification

- Project reimports headless with **exit 0, no script errors**.
- Default Dark startup
  ([app_screenshot_task60_dark_small.png](app_screenshot_task60_dark_small.png))
  shows the same Dark palette tasks 19 / 35 v2 already used.
- Pre-seeded `user://color.cfg` with `key = "light"` and re-launched →
  Light scheme loaded and applied
  ([app_screenshot_task60_light_small.png](app_screenshot_task60_light_small.png))
  — confirms persistence works.

## Honest scope

- **The colour scheme covers the notebook view only.** The toolbar at
  the top (IconMenuBar), the calculator's right pane, the help wizard,
  package settings, and the advanced view still use their original
  app-wide theme from [task 9](task9_larger_and_rebrand.md) /
  [task 23](task23_visual_menubar.md). Extending the scheme globally
  would require swapping the app's root `Theme` resource at runtime
  (one tweak, separate follow-up).
- **No custom colour pick.** Users get the five bundled palettes;
  there's no `ColorPicker` for free-form choice. Adding one is the
  next step if any user actually asks; the persistence layer already
  supports arbitrary values via the same ConfigFile.
- **Inline plot canvas** (the curve drawn from `cas-plot` samples per
  [task 35 v2](task35_inline_plot.md)) still uses its own hardcoded
  bg / axis / curve colours. Theming the plot is a one-Theme-aware
  refactor on [plot_panel.gd](app/scripts/plot_panel.gd); deferred.
- **No accessibility audit.** "High Contrast" is intentionally
  aggressive (pure black bg, white text); it's not a WCAG-certified
  scheme, just a sensible name for the most-contrast variant.

---

## TL;DR

`ColorConfig` + an OptionButton + a small Dictionary of colour slots is
all it takes to give the notebook view a switchable, persistent theme.
The cell emitters read from `_color_scheme[…]` instead of hardcoded
values; everything else stayed the same.
