# Task 27 — A Better Way to Display the Advanced Problems

The task-26 Advanced view shipped a `TabContainer` of 13 tabs, each holding
a single column of stacked full-width problem buttons. That works, but with
332 items across 13 categories it's visually overwhelming — the user has
to scroll a long single column inside whichever tab they pick.

This doc surveys five better-display options, picks one, ships it, and
shows the before/after.

---

## Five options considered

| # | Layout | Pros | Cons |
|---|--------|------|------|
| A | **Tabs + stacked full-width buttons** (original) | Simple, obvious | Long scroll; only one category visible; can't quickly compare across categories |
| B | **Tabs + multi-column GridContainer** | More items per screen | Still hides categories behind tabs; no search |
| C | **Two-pane (sidebar + grid)** | Category list always visible; click-to-switch; room for search | Slightly more code |
| D | **Tree (categories with collapsible sub-groups)** | Lets us nest sub-patterns like "Expand (x+1)^n for n=2..12" under one header | Navigation cost — user has to expand the right node first |
| E | **Single big list + tag filters** | Fast cross-category search | Loses the structure that categories give |

**Picked: option C — sidebar + searchable 3-column grid**, with a result
panel underneath. Reasons:
- The category list is always visible — switching is one click, not a
  scroll-then-tab-then-click chain.
- Three columns instead of one cut Expansion's view from 32 rows to ~11
  rows — fits without scrolling on a maximised window.
- A **filter LineEdit** lets the user narrow within a category instantly
  (e.g. type "(x+1)" to see only `(x+1)^n` variants).
- The bottom result panel from task 26 is preserved, so picking a problem
  shows the result in place without leaving the view.

---

## What shipped

[app/scripts/advanced_view.gd](app/scripts/advanced_view.gd) is rewritten
around an `HSplitContainer`:

```
+--------------------------------------------------------------------------+
|  Advanced Problems  (332 problems · 13 categories)        [Close (Esc)]  |
+--------------------------------------------------------------------------+
| Expansion (32)   |  Expansion  · 32 items                  [ filter… ][×]|
| Factoring (29)   +--------------------------------------------------------+
| Differentiation  |  Expand (x+1)^2  | Expand (x+1)^3 | Expand (x+1)^4    |
| Higher derivs    |  Expand (x+1)^5  | Expand (x+1)^6 | Expand (x+1)^7    |
| Integration (35) |  Expand (x+1)^8  | Expand (x+1)^9 | Expand (x+1)^10   |
| Limits (20)      |  Expand (x+1)^12 | Expand (x-1)^2 | Expand (x-1)^3    |
| Taylor series    |  …                                                     |
| Trig identities  |                                                        |
| First-order ODEs |                                                        |
| Higher ODEs      |                                                        |
| Matrices         |                                                        |
| Number theory    |                                                        |
| Combinatorics    |                                                        |
+--------------------+--------------------------------------------------------+
| ✓ done   ▶ (x+1)^5     x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1                |
+--------------------------------------------------------------------------+
```

| Element                  | Godot widget                  | Why                                              |
|--------------------------|-------------------------------|---------------------------------------------------|
| Sidebar of categories     | `ItemList`                    | Fast single-click selection; renders counts inline |
| Body split                | `HSplitContainer`             | User-resizable divider                            |
| Search / filter            | `LineEdit` with `text_changed`| Live filter, no Enter needed                      |
| Clear button               | `Button` (`✕`)                | Resets the filter to empty                        |
| Grid of problems           | `GridContainer` (3 cols)      | 3× density vs. single column                      |
| Scroll                     | `ScrollContainer`             | Long lists still scroll                            |
| Result panel               | `PanelContainer` + `RichTextLabel` + `Label` | Shows status + input echo + formatted result |
| Background tint            | `ColorRect`, `StyleBoxFlat`   | Consistent with the rest of the app's theme       |

## Keyboard shortcuts added

| Key       | Action                          |
|-----------|---------------------------------|
| **Esc**   | Close the Advanced view          |
| **/**     | Focus the filter field           |

(F3 still toggles the view from the main window, per task 26.)

## Before / after

- Before: [app_screenshot_advanced.png](app_screenshot_advanced.png) — tabs
  of one-per-row buttons; on a 3440-px-wide monitor each button is the full
  width of the window, so ~16 items visible at most, and switching category
  requires moving up to the tab strip and clicking.
- After: [app_screenshot_advanced_v2.png](app_screenshot_advanced_v2.png) —
  sidebar + 3-column grid + filter box; all 32 expansion items fit without
  scrolling (3 columns × 11 rows), the category list is always one click
  away on the left, and the result panel is still at the bottom.

## What this did NOT change

- The data ([advanced_library.gd](app/scripts/advanced_library.gd)) — same
  332 problems, same 13 categories. Display-only refactor.
- The result-routing through `MathEngine.evaluate` + `result_ready`.
- The wider app — calculator, notebook, help wizard, problem-library
  popups all untouched.
- F3 to toggle, Esc to close, the bundled sample workspace, etc.

## Future improvements (out of scope here)

- **Cross-category search** — currently the filter scopes to one category;
  a global search ("show me every `factorize(...)` problem regardless of
  category") would be a one-`Tree` or one-additional-list-mode upgrade.
- **Inline-rendered math** on the buttons themselves (a small LaTeX→image
  preview per problem) per
  [task 16 §2](task16_beyond_zettlr.md) /
  [task 17 §4](task17_even_further.md) — needs a TeX renderer bundled,
  which is the right time to tackle along with the notebook-view
  improvements.
- **Recently-run / favourites list** stored via `ConfigFile`, so a user's
  go-to problems can resurface on top of the grid.

These are flagged but left for later — the current task's brief was just
"is there a better way to display that," and the answer was yes: a
sidebar + filtered grid. Done.
