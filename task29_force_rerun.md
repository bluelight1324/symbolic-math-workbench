# Task 29 — Force Re-run (Bypass the Notebook Cache)

[Task 28](task28_cache_message.md) explained the **"All blocks cached —
nothing to evaluate"** message: the content-addressed cache from
[task 19 P1 #5](task19_p0_p2_implementation.md) is doing its job. It also
noted, as a small follow-up, that there's no one-click way to force a
fresh re-evaluation — you'd have to edit a source block or delete a
result block to invalidate the hash. Task 29 ships that one-click way.

---

## What changed in the UI

[notebook_view.gd](app/scripts/notebook_view.gd) — the notebook view's
top action bar now has a **Force re-run  (Ctrl+F5)** button next to the
existing **Run notebook  (F5)** button:

```
Workspace: …    [Open workspace…] [New note] [Save (Ctrl+S)] [Run notebook (F5)] [Force re-run (Ctrl+F5)] [Export HTML]
```

[main.gd](app/scripts/main.gd) — the existing F5 handler now branches on
`event.ctrl_pressed`:

```gdscript
elif event.keycode == KEY_F5 and _notebook and _notebook.visible:
    if event.ctrl_pressed:
        _notebook._on_force_run()
    else:
        _notebook._on_run()
    get_viewport().set_input_as_handled()
```

## What changed in the runner

The two run paths share a single function so the loop stays in lock-step
with the rest of the dispatcher; they only differ by the cache-check
guard:

```gdscript
func _on_run() -> void:
    _run_internal(false)

## Force re-run — ignore the content-addressed cache and re-evaluate every
## block in the open file.
func _on_force_run() -> void:
    _run_internal(true)

func _run_internal(force: bool) -> void:
    …
    for p in pairs:
        var src: Dictionary = p["source"]
        var src_hash := NotebookRunner.source_hash(src["body"], src["kind"])
        if not force and p["result"] != null:
            var existing_hash := NotebookRunner.extract_src_hash(p["result"]["body"])
            if existing_hash == src_hash:
                cache_hits += 1
                continue
        _run_queue.append({"pair": p, "src_hash": src_hash})
    …
    var note := "" if not force else "  (cache bypassed)"
    if force and cache_hits == 0:
        note = ""    # cosmetic — nothing was actually cached anyway
    _status.text = "Running 1/%d…%s" % [_run_queue.size(), note]
```

The status bar now reads `Running 3/5…  (cache bypassed)` during a Ctrl+F5
run, so the user sees they bypassed the cache, not that the cache
silently failed.

## What did NOT change

- The provenance footer format (`<!-- src-hash: … engine: … -->`) is
  unchanged. Force-rerun writes new result blocks with the **same**
  hashes (since the source didn't change), so subsequent regular Runs
  hit the cache again. Cache resumes normal operation immediately.
- `NotebookRunner.source_hash` / `extract_src_hash` / `format_result_body`
  — pure logic, untouched. The change is purely about *whether* the
  comparison runs, not how the hash is computed.
- Every other run command path (the showcase auto-run, the headless
  test, anyone calling `_on_run()` programmatically) keeps its existing
  caching behaviour. Only the explicit user action — button click or
  Ctrl+F5 — triggers the bypass.

## Verification

A focused regression test parsed `notebooks_sample/algebra.md` (already
fully cached from earlier test runs) and ran both queue-building paths:

```
pairs: 5                                   ← 3 cas + 2 cas-test blocks
normal queue (cache enabled): 0            ← every block hit the cache → skipped
force queue (bypassed):       5            ← bypass enqueued every block
RESULT: PASS
```

Then the project was re-imported headless: **exit 0, no script errors**.
The new button slot fits cleanly into the existing top action bar layout.

## How to use it

In the notebook view (F2 to switch), with a file open:

| Key combo / button   | What it does                                                              |
|----------------------|---------------------------------------------------------------------------|
| **F5** / Run notebook | Normal run — skip every block whose hash matches its cached result.       |
| **Ctrl+F5** / Force re-run | Re-evaluate every block, then rewrite the result blocks with fresh footers (same content hashes — the cache resumes on the next regular Run). |

## When to use which

| Situation                                                | Use         |
|----------------------------------------------------------|-------------|
| You just opened a file and want to see the cached answers re-rendered into the editor | F5 (cheap, often a no-op) |
| You edited one or two source blocks                       | F5 (only the changed blocks evaluate) |
| You suspect an old result is stale despite a matching hash (e.g., you've poked at the bundled REDUCE behind the cache's back) | **Ctrl+F5** |
| You want to time how long the *real* evaluation takes from scratch | **Ctrl+F5** |
| You upgraded the bundled engine and forgot to bump `ENGINE_TAG`     | **Ctrl+F5** (or just bump the tag and use F5) |

---

## TL;DR

`Ctrl+F5` (or the **Force re-run** button) now re-evaluates every block
in the open notebook regardless of the content-addressed cache. The
status bar prints `(cache bypassed)` so the bypass is visible.
Implementation is one shared function with a single `force` flag; the
hash and provenance machinery is unchanged, so subsequent F5 presses
fall back to cached behaviour without further work.

Follow-up flagged in [task 28](task28_cache_message.md) — closed.
