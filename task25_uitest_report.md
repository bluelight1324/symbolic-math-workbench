# Task 25 — Comprehensive UI Test Report

**58 passed / 8 failed**  (of 66 total)

## Phase 1 — UI structure exists
✅ Main has _input
✅ Main has _history_box
✅ Main has _plot
✅ Main has _wizard
✅ Main has _notebook
✅ IconMenuBar present
❌ MenuBar has 11 category buttons  — found 12

## Phase 2 — operation buttons
✅ Simplify (x+1)^2  — text== x² + 2·x + 1
✅ Factor x^6-1  — text== {{x² + x + 1,1}, | {x² - x + 1,1}, | {x + 1,1}, | {x - 1,1}}
✅ d/dx sin(x)*x  — text== cos(x)·x + sin(x)
✅ ∫ 1/(x^2+1) dx  — text== atan(x)
✅ Solve x^2-5x+6 = 0  — text== {x=3,x=2}
✅ Solve ODE y'=y  — text== {y=e^x·arbconst(1)}
✅ Plot sin(x): no engine pending  — engine settled

## Phase 3 — problem-library menu picks
✅ Algebra → Expand (x+1)^5  — text== x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1
✅ Calculus → d/dx sin(x)*cos(x)  — text== cos(x)² - sin(x)²
✅ Equations → Solve x^2 - 5x + 6 = 0  — text== {x=3,x=2}
✅ ODEs → y' = y  — text== {y=e^x·arbconst(2)}
✅ Matrices → Matrix product 2×2 · 2×2  — text== mat((19,22),(43,50))
✅ Series → Taylor exp(x) at 0, order 5  — text== taylor(1 + x + 1/2·x² + 1/6·x³ + 1/24·x⁴ + 1/120·x⁵,x,0,5)
✅ Trig → Simplify sin²+cos² (trigsimp)  — text== 1
✅ Numbers → gcd(60, 84)  — text== 12
✅ Plots: pick item  — (skipped — all plot)

## Phase 4 — Reset session (task-24 regression)
✅ Reset-then-evaluate has no leftover lines  — text== x² + 2·x + 1

## Phase 5 — Help wizard
✅ Wizard starts hidden
✅ Wizard opens
✅ Wizard advanced to step 4  — current=3
✅ Wizard closes

## Phase 6 — Notebook view
✅ Notebook starts hidden (or stable)  — initial visible=true
✅ Notebook toggled visible
✅ Notebook toggled back

## Phase 7 — View menu items
✅ View → Maximize  — did not crash
✅ View → all four size presets ran

## Phase 8 — Keypad token insertion
✅ Keypad inserted 'sqrt('  — text=sqrt(

## Phase 9 — Right pane (task 34: Code + Result)
✅ _code_view exists
✅ _result_view exists
✅ Code pane shows the engine command  — code='(x+1)^3'
✅ Result pane shows the formatted output  — result='x³ + 3·x² + 3·x + 1'
✅ Code pane shows the wrapped command for d/dx  — code='df(sin(x)*x, x)'
✅ Result pane has cos+sin  — result='cos(x)·x + sin(x)'

## Phase 10 — Package settings (tasks 31, 32)
✅ _pkg_settings exists
✅ Settings dialog starts hidden
✅ Settings dialog opens
✅ PackageConfig.KNOWN is populated  — 22 known packages
✅ DEFAULT_SELECTED includes core packages
✅ load_selected() returns a non-empty array  — size=8
✅ Settings dialog closes

## Phase 11 — Advanced view (tasks 26, 27)
✅ _advanced exists
✅ Advanced view starts hidden
✅ Advanced view opens
✅ AdvancedLibrary built >= 200 problems  — count=332
✅ Advanced view closes

## Phase 12 — Default notebook + toolbar room
✅ Notebook opens by default at startup
✅ Notebook reserves room for toolbar (offset_top=102)  — offset_top=102
✅ Toolbar (IconMenuBar) still present
✅ Toolbar position.y is above the notebook's top  — toolbar_y=16 notebook_top=102

## Phase 13 — Source ↔ Notebook view toggle (task 35 v2)
❌ _view_mode_btn exists
✅ Source editor exists
✅ Rendered scroll exists
❌ Starts in Source mode (editor visible)
❌ Starts in Source mode (rendered hidden)
❌ After toggle: editor hidden
❌ After toggle: rendered visible
✅ Rendered cells were emitted  — 14 cells
❌ Back to Source mode: editor visible
❌ Back to Source mode: rendered hidden
