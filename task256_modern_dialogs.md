# Task 256 — Modernize the Dialogs

## Request

> "Modernize the open workspace dialogs and other dialogs throughout the app."

## What the dialogs were

Every dialog in the app was a **default, unstyled Godot Window** — flat grey panel,
square system buttons, plain inputs — clashing with mathdot's themed, rounded,
MATLAB-style UI. There are three:

- **Open workspace** — a `FileDialog` (directory picker).
- **New note** — an `AcceptDialog` with a filename `LineEdit`.
- **Search workspace** — an `AcceptDialog` with a search `LineEdit` + results `ItemList`.

## What changed

A single reusable styler, **`_apply_dialog_style(win: Window)`**, gives any dialog
the app's modern look from the **currently-active colour scheme** (so it tracks the
user's theme), and it's applied **each time** a dialog opens:

- **Rounded, shadowed panel** in the scheme's background colour with a subtle
  border — the dialog body and the embedded window frame/title.
- **Pill buttons** in the scheme accent (`res_chip`) with hover/pressed states and
  white text — OK / Cancel / the FileDialog's navigation buttons.
- **Rounded inputs** (`LineEdit`) on the editor-panel background with a 2 px
  **accent focus ring**, themed placeholder + caret.
- **Rounded lists** (`ItemList` for search results, `Tree` for the file list) with
  an accent **selection** highlight and scheme text colours.
- The **app font** and scheme **title colour / size** on the window.

Because it themes by Godot control *type* (`AcceptDialog`, `FileDialog`, `Window`,
`Button`, `LineEdit`, `ItemList`, `Tree`), one call styles a whole dialog —
including the complex `FileDialog` — with no per-widget wiring, and re-applying on
open means the dialogs always match the live theme.

## Verification

- **Unit tests** (`--test126`): **128 / 128 pass, exit 0** — 5 new asserting that
  `_apply_dialog_style` installs a `Theme` with the panel, embedded window frame,
  pill `Button`, and focus-ring `LineEdit` styleboxes.
- **In-app:** opened the **Open workspace** dialog
  (`app_screenshot_task256_opendialog.png`) — it renders in the active (light) theme
  with accent-coloured rounded navigation buttons (↑ / refresh / drive dropdown), a
  rounded path field, and styled Favorites/Recent panels, instead of the old flat
  grey dialog. The New-note and Search dialogs share the same styler (covered by the
  `AcceptDialog` unit assertions).

## Files changed
- `app/scripts/notebook_view.gd` — new `_apply_dialog_style(win)`; called before
  each `popup_*()` in `_on_open_workspace`, `_on_new_note`, and `_on_search_workspace`.
- `app/scripts/_test126.gd` — 5 new dialog-style assertions (now 128/128); the test
  colour-scheme gained the `bg` / `src_border` / `src_chip` keys the styler reads.
