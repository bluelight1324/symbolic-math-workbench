# Task 255 — Fix: font changes only once, subsequent changes fail

## Request

> "Clicking the font option and selecting a font changes the font, but subsequent
> attempts to change the font fail. Check, fix and do 1 doc."

## Diagnosis

The font is chosen from **Notebook menu → Font ▸**, a `PopupMenu` submenu of
radio-check items. Selecting one fires the submenu's `id_pressed` signal, handled
by `_on_menu_id_pressed`, which:

1. applied the font (`_on_font_family_changed` → `_apply_font`), and then
2. called **`_sync_menu_checks()` synchronously** — which, via `_check_only`, runs
   `set_item_checked(...)` over **the very submenu that is mid-emit**.

The apply path (`_on_font_family_changed`, `_apply_font`, `_resolve_bold_font`) is
idempotent and correct — it works identically on every call. The fault is step 2:
**mutating a `PopupMenu`'s item state from inside its own `id_pressed` handler.**
Godot's `PopupMenu.activate_item` is still running when `set_item_checked` re-shapes
the items, which desyncs the menu's internal hover/active tracking. The result is
exactly the reported symptom — the **first** selection works, but the menu is left
in a corrupted state so **every subsequent** submenu selection stops firing.

The same anti-pattern affected the Size / Theme / Style / Shadows / Animations /
Looks items (all call `_sync_menu_checks()` from inside the handler), so the bug was
latent across the whole menu, not just fonts.

## Fix

Move the check-mark sync **out of the click handler** — compute it fresh whenever
the menu is about to open, and never during a selection:

- **`_popup.about_to_popup.connect(_sync_menu_checks)`** — the radio/check marks are
  now recomputed from current state (`_font_family`, `_font_size`, `_color_key`, …)
  every time the menu opens, outside any signal emission.
- Every in-handler `_sync_menu_checks()` (font, size, theme, style, shadows,
  animations, and `_apply_look`) changed to **`_sync_menu_checks.call_deferred()`**,
  so even those run at idle — after the `PopupMenu` finishes its click — never
  mid-signal.

Net effect: nothing mutates the menu while it is processing a click, so the menu
state stays valid and **font changes work every time**. (Also strictly better
design: the marks are always correct on open, regardless of how state last changed.)

## Verification

- **Compiles / regressions:** `--test126` → **123 / 123 pass, exit 0**.
- **Menu integrity:** launched the app and opened **and closed the Notebook menu
  three times** in a row — no script errors; `about_to_popup → _sync_menu_checks`
  fires cleanly on every open.
- Note: the exact submenu-*hover* repro could not be driven by cursor automation
  (teleported cursors don't generate Godot's hover events), so the fix targets the
  diagnosed root cause — the only state-corrupting step in an otherwise idempotent
  path — rather than a scripted UI replay.

## Files changed
- `app/scripts/notebook_view.gd` — `_build_menubar_popup` adds the
  `about_to_popup → _sync_menu_checks` connection; `_on_menu_id_pressed` and
  `_apply_look` now call `_sync_menu_checks.call_deferred()` instead of calling it
  synchronously inside the menu's signal handler.
