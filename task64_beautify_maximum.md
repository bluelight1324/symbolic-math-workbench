# Task 64 — Beautifying the UI to the Maximum: A Godot Catalogue

Doc only — no implementation. The brief: enumerate the things Godot
offers for *visual polish*, well beyond the colour/density/animation
controls already shipped in
[task 60](task60_color_schemes.md) /
[task 61](task61_beautify.md), so a future build can pick from a known
menu rather than reinventing.

The list is grouped by **what the change makes the app feel like** —
"sharper," "lively," "richer," "more reactive," "more accessible,"
"more themable." Each entry says what Godot widget / system enables it,
roughly how invasive the change is (S/M/L), and what the headline
example would be for *this* app (Symbolic Math Workbench).

Inventory only. Order = same loose ordering an implementer would pick:
biggest visual return for the least work first.

---

## A. Sharper / more refined surfaces

| # | Beautification               | Godot piece                                      | Effort | Headline use in this app                                |
|---|------------------------------|--------------------------------------------------|:------:|---------------------------------------------------------|
| 1 | Variable corner radius per-corner | `StyleBoxFlat.corner_radius_top_left`, etc.       | S | Source cells "speech-bubble" corners — top corners round, bottom flatter to point at the result cell below |
| 2 | Subtle inner shadows / inset highlights | `StyleBoxFlat.expand_margin_*` + extra StyleBoxFlat children behind the panel | S | A 1-px brighter top edge on dark cells for that "extruded" look |
| 3 | Multi-stop gradient fills    | `StyleBoxFlat.bg_color` + a child `ColorRect` with `Gradient` texture | M | Dark theme bg gets a faint top→bottom gradient — more depth, less flatness |
| 4 | Real drop shadows with soft falloff | already used (`shadow_size` / `shadow_color`) — extend to soft/elevated tiers | S | Three "elevation" presets — flat / floating / elevated |
| 5 | Texture-backed borders       | `StyleBoxTexture` instead of `StyleBoxFlat`      | M | Notebook-paper texture under source blocks for the "Mathematica notebook" feel |
| 6 | Subtle background patterns   | `NinePatchRect` + `Color(…, 0.04)` overlay        | S | Faint dot grid behind the editor — visible only in dark mode |
| 7 | Anti-aliased dividers        | `HSeparator` / `VSeparator` + custom StyleBoxLine | S | Hairline rules between sidebar files instead of nothing |

## B. Lively / motion-rich

| # | Beautification                                | Godot piece                                                        | Effort | Headline use                                                              |
|---|-----------------------------------------------|---------------------------------------------------------------------|:------:|---------------------------------------------------------------------------|
| 8 | View-mode crossfade with simultaneous fade-in/fade-out | `Tween` on `modulate.a` for both views                          | S | Already partial (task 61) — extend to true cross-fade rather than out-then-in |
| 9 | Cell-by-cell stagger animation on Run         | `Tween.tween_callback` chained with delays                          | M | After a Force-rerun, results pop in one-by-one with 60 ms stagger          |
| 10| Pulse / glow on focus                         | `Tween` loop on `scale` + `modulate.a`                              | S | Currently-running cas block gets a subtle blue glow until its result arrives |
| 11| Smooth scroll easing                          | `ScrollContainer.scroll_horizontal/vertical` tweened on click       | S | Click a `[[wikilink]]` → smooth-scroll to the target cell rather than jump |
| 12| Drag-and-drop reorder of cells                | `get_drag_data` / `can_drop_data` / `drop_data`                     | L | Drag a `cas` block in the rendered view to reorder it in the markdown source |
| 13| Resize-able panels with snap points           | `SplitContainer.collapsed`, `split_offset` tweened                  | S | Notebook ↔ sidebar split has 200/280/360 px snaps                          |
| 14| Animated icons (rotation, bounce)              | `AnimationPlayer` on each icon button                              | M | Help icon (?) gently rocks back and forth on first ever launch              |
| 15| Loading skeletons / shimmer                    | `Tween` looping a gradient `ShaderMaterial` across placeholder boxes | M | While engine restarts after a package change, source cells shimmer        |
| 16| Particle bursts on success/test pass          | `GPUParticles2D` + a small "confetti" lifetime                      | M | `cas-test` block PASSES → 6-particle green burst over the chip            |

## C. Richer typography

| # | Beautification                                | Godot piece                                                         | Effort | Headline use                                                          |
|---|-----------------------------------------------|----------------------------------------------------------------------|:------:|-----------------------------------------------------------------------|
| 17| Variable-font axes (weight, slant)            | `FontVariation.variation_coordinates`                                | S | Inter Variable → user picks weight 400/500/600 separately            |
| 18| OpenType stylistic alternates (tabular nums)  | `FontVariation.opentype_features`                                    | M | `cas-result` numerical columns use tabular figures (`tnum`)           |
| 19| BBCode-rendered superscripts / subscripts via Unicode + RichTextLabel `[font]` | `RichTextLabel` + Theme | S | Already used; extend to `[code]…[/code]` for inline cas snippets in prose |
| 20| Drop caps                                     | First-letter override in prose RichTextLabel via `[font_size]`       | S | First paragraph of each notebook gets a 32-pt drop-cap initial         |
| 21| Hanging punctuation (CSS-like)                | Custom `RichTextLabel` subclass with margin tricks                   | L | Quotes hang into the gutter for a cleaner left edge                    |
| 22| Smart-quote / em-dash / ellipsis substitution | Pre-render text filter                                              | S | `--` becomes `—` in prose; `...` becomes `…`                            |

## D. Reactive / hover-aware

| # | Beautification                                 | Godot piece                                                  | Effort | Headline use                                            |
|---|------------------------------------------------|---------------------------------------------------------------|:------:|---------------------------------------------------------|
| 23| Hover state for every clickable cell            | `mouse_entered` / `mouse_exited` signals + StyleBoxFlat swap | S | Source cell brightens its left-accent border on hover    |
| 24| Tooltip with rich content (image, code preview)| `RichTextLabel` + custom `_make_tooltip_for_text`            | M | Hover a wikilink → tooltip shows the target cell preview |
| 25| Cursor changes per-zone                        | `mouse_default_cursor_shape`                                 | S | Hover the cell's left border → resize cursor             |
| 26| Click-and-drag selection of cells              | `BoxSelection` Control overlay                                | M | Click-drag in the rendered view → select a range to export |
| 27| Right-click context menus                      | `PopupMenu`                                                   | S | Right-click a source cell → Run / Copy / Delete           |
| 28| Inline previews on link hover                   | `Tween`-faded `Panel` with content                            | M | `[[task37]]` hover → tiny preview panel                   |

## E. Themable / customisable

| # | Beautification                                | Godot piece                                                 | Effort | Headline use                                                  |
|---|-----------------------------------------------|--------------------------------------------------------------|:------:|---------------------------------------------------------------|
| 29| Theme variations (semantic button roles)       | `Theme.add_type_variation` → `primary` / `danger` / `ghost` | S | Reset session → ghost button; Force re-run → primary; Delete cell → danger |
| 30| User-editable colour palette (not just preset) | `ColorPicker` + ConfigFile                                  | M | "Custom theme" entry under [task 60](task60_color_schemes.md) opens picker |
| 31| Importable user themes (.tres files)           | `ResourceLoader.load` on a user-bundled `Theme` resource    | M | Drop `mytheme.tres` next to the app, restart → it appears in the dropdown |
| 32| Per-notebook colour override (front-matter)    | YAML front-matter parsed by `NotebookRunner`                | M | A notebook can say `theme: solarized-dark` in its YAML and override globally |
| 33| Style presets per workspace                     | One ConfigFile per workspace folder                         | M | Open a "lectures" workspace → Comfortable density auto-applied                 |
| 34| Live-reload of edited theme                    | `FileAccess` polling + signal                                | M | Edit `theme.tres` outside the app → reload on focus                            |

## F. Accessibility / inclusive

| # | Beautification                                  | Godot piece                                              | Effort | Headline use                                                   |
|---|-------------------------------------------------|-----------------------------------------------------------|:------:|----------------------------------------------------------------|
| 35| OS-honoured scaling (HiDPI)                      | `display/window/dpi/allow_hidpi = true`                  | S | Project setting; already implicitly on. Verify it scales every cell |
| 36| Larger hit-targets / spacing toggle              | `Theme.constant_overrides` swap                          | S | "Touch-friendly" mode for tablets — all buttons 48 px tall      |
| 37| Reduced-motion mode                              | Skip every Tween based on `StyleConfig.animations_on`    | S | Already partial — extend to skip hover/pulse animations too     |
| 38| Colour-blind-safe palette (a 6th theme)          | New `ColorConfig` entry with deuteranopia-safe colours   | S | Replace red/green with blue/orange for `cas-result`/`cas-error` |
| 39| Screen-reader-friendly labels                    | `Control.tooltip_text` consistency + accessible names    | S | Every chip / button gets a real tooltip                        |
| 40| Font weight in addition to size                  | `FontVariation` with `wght` axis                          | M | Bold / Semibold / Regular spinbox alongside size               |

## G. Iconography / decoration

| # | Beautification                                | Godot piece                                                  | Effort | Headline use                                                   |
|---|-----------------------------------------------|---------------------------------------------------------------|:------:|----------------------------------------------------------------|
| 41| Real bundled icons (SVG)                       | `Image.load_svg_from_buffer` or pre-baked PNGs              | M | Replace the `▸` / `=` Unicode chips with vector icons          |
| 42| Inline animated GIF / WebP in prose            | `AnimatedSprite2D`-in-`RichTextLabel`-effect                  | M | A 200-px tall animation showing the unit circle sweeping out   |
| 43| Math-typeset previews (LaTeX → image)          | Bundled `pdflatex` / `dvisvgm` shell-out                     | L | Each `cas-result` block gets a typeset `\mathbb` etc. version  |
| 44| Inline LaTeX-via-MathJax in RichTextLabel       | Web-export only; pre-render to PNG otherwise                | L | Notebook view shows real fractions, square-root extensions etc. |
| 45| Decorative side rail / margin notes column      | Extra `VBoxContainer` parallel to `_rendered_box`            | M | "TODO" / "NOTE" margin notes outside the main column           |

## H. Sound / multimodal (tasteful, off-by-default)

| # | Beautification                                | Godot piece                                                  | Effort | Headline use                                                   |
|---|-----------------------------------------------|---------------------------------------------------------------|:------:|----------------------------------------------------------------|
| 46| Soft click / tick on Run                       | `AudioStreamPlayer` with a 50-ms square-wave                 | S | "Run notebook" → quiet `tick`; off by default                  |
| 47| Confirmation chord on cas-test PASS            | `AudioStreamPlayer` with a chord WAV                         | S | Test passes → soft major chord                                 |
| 48| Voice over for engine status                   | TTS via OS — `OS.tts_speak("Engine ready")`                  | S | Accessibility option — already supported by Godot's TTS APIs   |

## I. Layout sophistication

| # | Beautification                                | Godot piece                                                   | Effort | Headline use                                                   |
|---|-----------------------------------------------|----------------------------------------------------------------|:------:|----------------------------------------------------------------|
| 49| Multi-column rendering (Mathematica-style "side notes") | Two `VBoxContainer` columns inside an `HBoxContainer`        | M | Per-block "explanation" column to the right of each cell        |
| 50| Sticky headers on scroll                       | Custom Control overriding `_unhandled_input` + `_draw`        | M | The current `# section` heading floats at the top of the scroll |
| 51| Smart wrapping / overflow ellipsis              | Custom `Label.text_overrun_behavior = TRIM_ELLIPSIS`           | S | Long file names in sidebar truncate with `…` instead of hiding  |
| 52| Adaptive max-width "reading column"             | `MarginContainer.add_theme_constant_override("margin_left/right", …)` based on viewport width | S | Notebook view caps at 1100 px wide on ultra-wide displays      |
| 53| Picture-in-picture mode (mini player for plots) | `Window` node with `transient = true` + own `PlotPanel`       | M | Pop a plot out of its inline position into a floating window    |

---

## J. Bundling preferences into "looks"

Once individual knobs exist, the *real* polish is to bundle them into
named "looks" — like macOS's "Aqua" or VSCode's "Solarized + Dark+":

| Bundle name      | Pulls in                                                       |
|------------------|-----------------------------------------------------------------|
| **Notebook**     | Light + Comfortable + Serif + shadows + drop-caps              |
| **Lab**          | Solarized Dark + Default + Monospace + grid pattern + animation |
| **Lecture**      | Light + Comfortable + System UI + 22 pt + reading column 1000 px |
| **Mathematica**  | Light + Default + CMU Serif + side notes + LaTeX previews       |
| **Brutalist**    | High-contrast + Compact + Sans + no shadows + no animation      |

Each bundle is one `Resource` file the user picks from a higher-level
"Looks" dropdown above today's individual Theme / Style / Font dropdowns.

---

## What an implementer should pick first

If the goal is "most visible polish for least code," the high-impact
small-effort items (marked S above) are:

1. **#23 hover state for every cell** — single signal pair, one-line styleboox swap. Massive perceived-quality jump.
2. **#10 pulse / glow on focus** — already-built Tween infra. Tells the user "this cell is the one currently running."
3. **#22 smart-quote substitution** — pre-render text filter. Free typography upgrade.
4. **#27 right-click context menu** — `PopupMenu` is one-liner.
5. **#36 touch-friendly toggle** — a Theme constants swap.
6. **#46 / 47 sound on Run / PASS** — `AudioStreamPlayer` + a bundled 50-ms wav. Off by default; nice when on.

Beyond those, the **#41 SVG icons** and **#1–6 surface-finish items**
collectively account for the difference between "Godot UI that
respects taste" and "Godot UI that genuinely looks designed."

The **#J Looks bundles** is the right capstone: once individual knobs
exist, exposing them through one click-and-done preset is what makes
them discoverable. Without it, users adjust three sliders and three
dropdowns and forget they did so a week later.

---

## Honest scope note

This is purely a design catalogue. None of the 50+ items above are
implemented as part of task 64. Anyone working through the list can
pick S items in a single afternoon, M items over a sprint each, L
items as discrete projects. The point is to have a known menu — every
"can Godot do X visually?" question now has an entry to point at.
