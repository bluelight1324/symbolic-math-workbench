# Task 23 — A Visual Menu Bar That Uses Godot, Not Just Text

[Task 11](task11_problem_menu.md) gave the app a category menu bar built
from Godot's stock `MenuBar` + `PopupMenu` widgets — fully functional, but
visually plain text (`View | Algebra | Calculus | …`). Task 23 replaces it
with a richer **`IconMenuBar`** built directly from `Control` /
`StyleBoxFlat` primitives: every category is a tinted icon-glyph button
with a small label underneath, a coloured bottom accent, hover and pressed
states, and a tooltip. Clicking still pops up the same `PopupMenu` of
problems — so behaviour is preserved, but the bar now *looks* like a UI
toolbar, not a string of words.

See [app_screenshot_iconbar.png](app_screenshot_iconbar.png) for the
running result.

---

## What was built

### `IconMenuBar` ([app/scripts/icon_menubar.gd](app/scripts/icon_menubar.gd))

A reusable `class_name IconMenuBar extends HBoxContainer` with one public
method:

```gdscript
func add_category(
    icon: String,        # large Unicode glyph (∫, ∑, △, …)
    label: String,       # small text + tooltip (Calculus, Series, Trig)
    menu: PopupMenu,     # the actual menu shown on click
    accent: Color,       # bottom-border + hover/press tint
) -> Button
```

Each button is layered:
1. `Button` with `focus_mode = FOCUS_NONE` (tabbing through doesn't snag).
2. Inside: a `VBoxContainer` with a `Label` showing the icon glyph at
   28 pt above a tiny 12 pt category label.
3. Three `StyleBoxFlat`s overriding `normal` / `hover` / `pressed` — same
   rounded corners and bottom-accent border, three brightness levels of
   the category's accent colour.
4. The button's child Labels have `mouse_filter = IGNORE` so clicks always
   reach the parent Button.

On click, the bar's `_show_menu()` positions the category's `PopupMenu` at
the button's bottom-left in screen coordinates and calls `popup(Rect2i…)`.

### Wiring it in ([main.gd `_build_menubar()`](app/scripts/main.gd))

`main.gd` now constructs an `IconMenuBar`, adds the View menu, walks
`ProblemLibrary.ALL` with a per-category `{icon, accent}` table, and ends
with the Help menu — exactly the same set of menus as before, but presented
as icon-buttons:

| Category   | Icon | Accent (RGB)                 |
|------------|:----:|-------------------------------|
| View       | `⊞`  | blue        `(0.55, 0.65, 0.95)` |
| Algebra    | `𝒂`  | orange      `(0.95, 0.65, 0.45)` |
| Calculus   | `∫`  | green       `(0.55, 0.85, 0.55)` |
| Equations  | `=`  | light blue  `(0.55, 0.75, 0.95)` |
| ODEs       | `𝑦′` | pink        `(0.95, 0.55, 0.70)` |
| Matrices   | `▦`  | purple      `(0.85, 0.65, 0.95)` |
| Series     | `∑`  | yellow      `(0.95, 0.85, 0.45)` |
| Trig       | `△`  | cyan        `(0.45, 0.85, 0.95)` |
| Numbers    | `#`  | red-brown   `(0.85, 0.55, 0.55)` |
| Plots      | `↗`  | mint        `(0.55, 0.95, 0.75)` |
| Help       | `?`  | red         `(0.95, 0.45, 0.45)` |

Behaviour stays identical to task 11: clicking a button opens that
category's `PopupMenu` of problems; `id_pressed` routes to the existing
`_on_problem_selected(cat_idx, item_idx)`, which feeds the engine.

---

## "Uses Godot", concretely

Per the wording of task 23, the new bar is built from the same Godot
primitives task 21 inventoried — but used more deeply than a stock node:

| Godot piece               | What it does for this bar                                       |
|---------------------------|------------------------------------------------------------------|
| `HBoxContainer`           | Hosts the row of buttons with controlled spacing                 |
| `Button`                  | Each category is one (with tooltip)                              |
| `VBoxContainer` (child)   | Stacks the big icon glyph above the small label                  |
| `Label` × 2 per button    | Independently sized icon glyph (28 pt) + caption (12 pt)         |
| `StyleBoxFlat` × 3 per button | Rounded corners, content margins, accent border, three brightness levels for normal / hover / pressed |
| `add_theme_*_override`    | Font sizes, font colours, and styleboxes applied per-control     |
| `Button.pressed` signal   | Triggers menu popup                                              |
| `PopupMenu.popup(Rect2i)` | Native sub-window opened at the button's screen coords           |
| `Control.mouse_filter`    | `IGNORE` on the inner Labels so the parent Button always gets clicks |
| `Control.focus_mode`      | `FOCUS_NONE` so Tab doesn't drift through the bar                 |

That's eight Godot subsystems collaborating in one widget — `MenuBar` on
its own only uses the popup + signal layer.

---

## Glyph honesty

The first attempt used `∡` (U+2221, ANGLE SYMBOL) for **Trig** and reused
`⊞` for both **View** and **Matrices**. Two problems showed up on the
running app:

- `∡` is **not in the default Godot fallback font**, so it rendered as a
  near-`4` tofu — visible in the first version of
  [app_screenshot_iconbar.png](app_screenshot_iconbar.png).
- Reusing `⊞` for two categories was visually confusing.

Swapped to `△` (U+25B3) for Trig (universally available) and `▦`
(U+25A6) for Matrices (a tiled square — semantically more "matrix"-y and
distinct from View's `⊞`). Both render cleanly in the second screenshot.

This is the kind of thing only a real headed run catches.

---

## How to use it

Nothing new for the user — just click an icon button. The bar lives in
the same place at the top of the calculator view, with the same hotkeys
unchanged:

- **F1** opens the Help wizard.
- **F2** switches to the notebook view.
- **F11** toggles fullscreen.

Each icon button shows its full category name as a Godot tooltip when
hovered.

---

## What didn't change

- `ProblemLibrary.ALL` — same 72 problems across 9 categories.
- `_on_problem_selected(cat_idx, item_idx)` — same routing.
- The `View` and `Help` menus' contents.
- Every keyboard shortcut, every signal connection.
- The headless library test ([_libtest.gd](app/scripts/_libtest.gd)) which
  doesn't touch the bar widget at all.

So the change is purely visual + interaction polish; nothing downstream
breaks.
