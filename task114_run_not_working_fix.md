# Task 114 — Run Buttons / Run Notebook Not Working

## Symptom

> "Run button in cells does not work. Run notebook also does not work."

Clicking a cell's **▶ Run**, the toolbar **Run All**, or pressing F5 did
nothing — no result, the app seemingly frozen for runs.

## Root cause — REDUCE ran out of heap ("insufficient freestore")

The engine is launched as `reduce.exe -w`. The default `-w` heap is **too small
for the loaded packages**: under memory pressure REDUCE aborts with

```
+++ Fatal error insufficient freestore to run this package
```

Because that error **aborts the command**, the result **sentinel** that the app
waits for is never emitted — so the evaluation **hangs forever** (no
`result_ready`). In the notebook runner that means the block never completes,
so `_run_active` stays **`true`** permanently. From then on **every** later run
— cell ▶ Run *and* Run notebook — early-returns at `if _run_active: "Already
running"`. One hung evaluation kills all subsequent runs: exactly the reported
symptom. (The calculator showed the same thing — every history row stuck on "…".)

This was intermittent: it worked in tasks 95–105 when free memory was ample,
then failed once the machine was under pressure.

## The fix

### 1. Give REDUCE a real heap — [math_engine.gd](app/autoload/math_engine.gd)
```gdscript
var info := OS.execute_with_pipe(exe, ["-w", "-K", "1000m"])
```
`-K 1000m` sets a 1 GB heap ceiling (CSL only grows into it as needed). Verified
directly: with the default heap, `(x+1)^2` already fails with *insufficient
freestore*; with `-K 500m`+ it succeeds, **and** the heavy
`int(exp(-x^2), x) → (√π·erf(x))/2` integral evaluates fine. 1000m gives
comfortable headroom for the package set and hard computations.

### 2. Safety net — per-block timeout, [notebook_view.gd](app/scripts/notebook_view.gd)
Even with the heap fix, a genuinely runaway computation shouldn't be able to
wedge the whole run system forever. `_watch_block_timeout()` aborts a block whose
result hasn't arrived in 20 s: it resets `_run_active`/queues, shows a clear
"⚠ Run timed out — the engine was restarted" message, and restarts the engine —
so the app stays usable instead of silently dead.

## Verification (deterministic harness that waits for the engine *and* the run)

- **Before the heap fix:** force-running a notebook stuck at `Running 1/4…` for
  20 s; `_run_active` stayed `true` (then the timeout recovered it). The
  calculator returned no results ("…").
- **After the heap fix:**
  - A normal notebook (algebra) force-ran in **<1 s** → "Done — 5 block(s)
    updated"; a deliberately-corrupted result was corrected to
    `x⁵ + 5·x⁴ + 10·x³ + 10·x² + 5·x + 1`.
  - The previously-hanging **erf** notebook ran in **<1 s** → corrected to
    `(√π·erf(x))/2`, "Done — 4 block(s) updated".
  - The calculator computes again: `solve({x+y=3,x-y=1}) = {{x=2,y=1}}`,
    `limit(sin(x)/x,x,0) = 1`, `binomial(10,3) = 120`
    (`app_screenshot_task114.png`).

So cell ▶ Run and Run notebook both work again, including heavy integrals.

## Files changed
- `app/autoload/math_engine.gd` — launch REDUCE with `-K 1000m`.
- `app/scripts/notebook_view.gd` — `_watch_block_timeout()` safety net.
- `app/scripts/main.gd` — the demo runner now waits for the engine to be ready
  before force-running (a fixed delay could fire before REDUCE had booted).

## Note
The temporary `_runtest.gd` harness used to pin this down was removed after
verification.
