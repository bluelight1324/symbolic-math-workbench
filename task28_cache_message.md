# Task 28 — Why the "All blocks cached — nothing to evaluate" message?

The screenshot showed the notebook view's status bar reading

> **All blocks cached — nothing to evaluate**

This is **not an error.** It's the **content-addressed cache** from
[task 19 P1 #5](task19_p0_p2_implementation.md) doing its job — every
`cas` block in the open file already has a paired `cas-result` block
whose source hash matches the current source. The runner has nothing
to do, so it tells you instead of silently no-op-ing.

This doc walks through what that means, why it's intentional, and how to
force a fresh run when you actually do want one.

---

## Where the message comes from

[notebook_view.gd `_on_run()`](app/scripts/notebook_view.gd):

```gdscript
for p in pairs:
    var src: Dictionary = p["source"]
    var src_hash := NotebookRunner.source_hash(src["body"], src["kind"])
    # Cache hit? Result block carries the same src-hash → skip evaluation.
    if p["result"] != null:
        var existing_hash := NotebookRunner.extract_src_hash(p["result"]["body"])
        if existing_hash == src_hash:
            continue
    _run_queue.append({"pair": p, "src_hash": src_hash})
if _run_queue.is_empty():
    _status.text = "All blocks cached — nothing to evaluate"
    return
```

If every block hits its cached result, `_run_queue` ends up empty and
that's the status message you see.

## How the cache works

Each `cas` (or `cas-test` / `cas-derive` / `cas-plot`) block has a paired
result block immediately after it:

````markdown
```cas
factorize(x^12 - 1)
```
```cas-result
<!-- src-hash: 926b6349829e engine: csl-6547 -->
{{x⁴ - x² + 1,1},
{x² + x + 1,1},
…
```
````

The provenance line — `<!-- src-hash: <12-hex-chars> engine: csl-6547 -->`
— is the cache key. It's computed by
[notebook_runner.gd `source_hash()`](app/scripts/notebook_runner.gd):

```gdscript
static func source_hash(body: String, kind: String) -> String:
    var canonical := "%s|%s|%s" % [ENGINE_TAG, kind, body.strip_edges()]
    return canonical.sha1_text().substr(0, 12)
```

The hash includes three things:

| Component       | Why                                                                 |
|-----------------|---------------------------------------------------------------------|
| `engine: csl-6547` | If the bundled REDUCE build changes, every block re-runs automatically |
| `kind: cas / cas-test / …`  | A test of `(x+1)^4` shouldn't be confused with a simplify of `(x+1)^4` |
| `body` (trimmed) | The actual user-written source                                       |

When **you press Run**, the runner reads the hash baked into each result
block's footer and compares it to a freshly-computed hash of the block's
current source. **Match → skip; mismatch → re-evaluate.** No mismatches in
your file means no work to do.

## Why this is desirable

The cache is the reason re-running a 50-block notebook with one edited
block takes ~50 ms instead of several seconds. Three concrete benefits:

1. **Reproducible.** The provenance line documents *which* engine
   produced *which* result for *which* source. A future reader (or you,
   next week) can verify a cell hasn't drifted relative to its computed
   answer.
2. **Fast.** Heavy items (`factorial(100)`, an ODE that takes 500 ms, a
   Taylor series at order 20) re-show instantly from disk.
3. **Honest about staleness.** If you bump REDUCE's bundled version,
   every old `engine: csl-6547` footer becomes stale and the next run
   regenerates everything — you can't accidentally show an
   answer-from-three-versions-ago beside fresh prose.

## When you'd see the message

You'll see "All blocks cached — nothing to evaluate" whenever:

- You **re-press Run / F5 without editing the source**. Most common
  case — you just want to glance at the result you already have.
- You **opened a notebook that someone else already ran** (e.g.
  `notebooks_sample/algebra.md` after the task-19 self-test, or
  `showcase.md` after a `--showcase` launch). The on-disk file already
  carries all the matching result blocks.
- You **ran the notebook through the headless test** and then opened it
  in the GUI. Same situation.

## How to force a fresh run

Four reliable ways, in order of "lightest touch":

1. **Edit the source.** Any change to a `cas` block's body changes its
   hash; that block (and only that block) re-runs.

2. **Delete a single result block.** Erase the
   ` ```cas-result … ``` ` block under the `cas` you want to re-run.
   The runner sees a `cas` with no paired result, can't compare hashes,
   and runs it again.

3. **Delete all result blocks.** Quick way to redo the whole file —
   delete every `cas-result`, `cas-test-result`, `cas-derive-result`
   block. Run will rebuild them.

4. **Bump the engine tag.** Edit `ENGINE_TAG` in
   [notebook_runner.gd](app/scripts/notebook_runner.gd) and any old
   `engine: csl-…` footer becomes a hash mismatch. Useful if you've
   actually upgraded REDUCE; otherwise overkill.

There is **no** "Force re-run" button today — the design assumes a stale
hash is enough signal. If the lack of a one-click rerun bites in
practice, it's a small follow-up to add: a status-bar
"Force re-run" button that ignores cache for one invocation.

---

## TL;DR

The message means **the cache says you have nothing to re-evaluate**.
This is the intended behaviour of the content-addressed cache shipped in
[task 19](task19_p0_p2_implementation.md): each `cas-result` block
carries a `<!-- src-hash: … engine: csl-… -->` footer that the runner
compares to a freshly-computed hash of the source on every Run press.
All hashes matched → nothing to do → "All blocks cached — nothing to
evaluate."

To re-run a block: edit its `cas` source, or delete its `cas-result`
block. To re-run the whole notebook: delete every `cas-*-result` block,
or change the source of every block.
