# Task 24 — Why the Error in the Screenshot?

The screenshot showed two consecutive **Factor** attempts on the same
expression, `1/(x^9+1)`, with very different result blocks:

| When                                  | Result block                                                                  |
|---------------------------------------|--------------------------------------------------------------------------------|
| First click of **Factor**             | ⚠ `1/(x**9 + 1) invalid as polynomial`                                          |
| Second click — **after Reset session**| ⚠ `clear$` ¶ `latex not defined as switch` ¶ `1/(x**9 + 1) invalid as polynomial` |

Two different things are going on. The first error is a real engine
limitation; the second is a **real bug in our code** that the screenshot
caught. This doc explains both, and ships the fix for the bug.

---

## 1. The "first" error — real REDUCE limitation, not a bug

REDUCE's `factorize(x)` is defined only over **polynomials**. The input
`1/(x^9+1)` is a *rational function* — a polynomial in the denominator,
not a polynomial by itself — so the engine refuses.

```
input :  factorize(1/(x^9 + 1))
output:  ***** 1/(x**9 + 1) invalid as polynomial
```

The app strips the leading `*****` via `MathFormatter.clean_error()` and
shows a friendly ⚠-prefixed red message in the history (which is exactly
what the screenshot shows). To factor the denominator, the user would type
the denominator on its own:

```
input :  factorize(x^9 + 1)
output:  {{x + 1,1}, {x^6 - x^3 + 1,1}, {x^2 - x + 1,1}}
```

Nothing to fix here — REDUCE is doing the right thing, and the UX surfaces
its message cleanly.

---

## 2. The "second" error — real bug in `reset_session()`

This is the interesting one. The screenshot's second result block had
three different errors concatenated into one ⚠ block, but only the third
line is about the user's Factor request. The first two lines —
`clear$` and `latex not defined as switch` — came from clicking **Reset
session**, *not* from the Factor request, and they leaked into the next
user result.

### Root cause

Before the fix, [math_engine.gd `reset_session()`](app/autoload/math_engine.gd)
looked like:

```gdscript
func reset_session() -> void:
    if _stdio:
        _stdio.store_string("clear; off latex; off rounded;\n")
        _stdio.flush()
```

Three commands sent to the engine **with no flush sentinel**. Each
produced output:

| Command       | What it does (in this app's session)                                                                                          |
|---------------|-------------------------------------------------------------------------------------------------------------------------------|
| `clear;`      | Clears all explicit variable bindings. Echoes `clear$`.                                                                       |
| `off latex;`  | **Errors**: `***** latex not defined as switch`. The `latex` switch only exists after `load_package rlfi;`, which this app *never* loads at startup — so the switch genuinely doesn't exist, and turning it off can't succeed. |
| `off rounded;`| Disables `rounded` numeric mode. Silent.                                                                                       |

All that output piles up in the reader thread's `buf`. Reader-side
correlation in this app is sentinel-based — a result is emitted only when
the worker reads a `<<<RDONE n>>>` line. The reset commands had no such
sentinel, so the buf kept growing.

The **next** user request — Factor — sent `factorize(1/(x^9+1));` followed
by its sentinel. When the worker eventually hit that sentinel, it dumped
**everything accumulated so far** as one result: `clear$ \n
***** latex not defined as switch \n ***** 1/(x**9 + 1) invalid as polynomial`.
That single accumulated string is then routed to the Factor history row,
which is why three unrelated lines showed up together with the ⚠.

### Fix

Two changes to
[math_engine.gd](app/autoload/math_engine.gd):

```diff
 func reset_session() -> void:
-    if _stdio:
-        _stdio.store_string("clear; off latex; off rounded;\n")
-        _stdio.flush()
+    if _stdio == null:
+        return
+    # Note: `off latex` is intentionally omitted — the latex switch only
+    # exists after `load_package rlfi`, which the app never loads on
+    # startup, so sending `off latex` would error with
+    # "latex not defined as switch".
+    _stdio.store_string("clear; off rounded;\n")
+    _stdio.store_string('write "%s-2%s";%s' % [SENTINEL_PREFIX, SENTINEL_SUFFIX, "\n"])
+    _stdio.flush()
```

Two effects:

1. **Sentinel flush.** After the reset commands, the engine emits
   `<<<RDONE -2>>>`. The reader treats it as a normal sentinel: it bundles
   the preceding `clear$` (and anything else) into a result for id `-2`,
   then resets its buffer. The `result_ready` signal fires with id `-2`,
   which no UI handler is waiting for, so it's silently dropped (per the
   existing `_pending.has(id)` guard in
   [notebook_view.gd](app/scripts/notebook_view.gd) /
   [main.gd](app/scripts/main.gd) / `_libtest.gd`). The next user request's
   sentinel now matches only its own output. **No more contamination.**
2. **Drop `off latex`.** It was wrong from the start — the latex switch is
   undefined in this app's session, so the command always errored. Removing
   it eliminates the `latex not defined as switch` line at its source.

### Regression test

A throwaway harness drove the exact bug scenario through the live engine:
bind a variable, call `reset_session()`, evaluate something innocuous, then
factor the rational. Output:

```
boot done; engine ready=true
setup result: f := x**2 + 1$
reset flush captured (id=-2); output=clear$           ← the clear$ output isolated into its own result
post-reset result: x**2 + 2*x + 1$
contaminated: false                                    ← no clear$ / latex / ***** in the next user result
factor-rational: err=true | ***** 1/(x**9 + 1) invalid as polynomial
```

- The post-reset evaluation comes back **clean**.
- The legitimate Factor-of-a-rational error is **still** reported correctly.

---

## TL;DR

| Symptom in the screenshot                                                  | Cause                                                                                              | Status                  |
|-----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|-------------------------|
| ⚠ `1/(x**9 + 1) invalid as polynomial`                                       | Real REDUCE limit: `factorize` only takes polynomials, not rationals                                | Working as intended     |
| Extra `clear$` + `latex not defined as switch` lines in the *next* result   | `reset_session()` sent commands without a flush sentinel; their output leaked into the next request | **Fixed** in math_engine.gd |
| `latex not defined as switch` specifically                                   | `off latex` was being sent even though `load_package rlfi` is never loaded in this app's startup    | **Fixed** by removing the bogus command |

Pressing **Reset session** then **Factor** (or any other operation) now
returns a clean result block for the operation alone, just like before.
