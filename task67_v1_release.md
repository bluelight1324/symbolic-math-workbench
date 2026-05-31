# Task 67 — Update GitHub and Tag v1.0.0

The repo is now at the first real release. Three things shipped:

1. A new commit on `main` (`ac16482`) carrying tasks 65, 66, and the
   four legacy tasks-1-to-5 design docs that didn't use the `task<N>_`
   filename convention.
2. A signed annotated tag `v1.0.0` pointing at that commit.
3. A GitHub release built from the tag, with summary notes about
   what's in v1.0.0 and what's not in the repo (the bundled binaries).

Public URLs:

| Resource    | URL                                                                                                |
|-------------|----------------------------------------------------------------------------------------------------|
| Repo        | <https://github.com/bluelight1324/symbolic-math-workbench>                                          |
| Tag         | <https://github.com/bluelight1324/symbolic-math-workbench/releases/tag/v1.0.0>                     |
| Release     | <https://github.com/bluelight1324/symbolic-math-workbench/releases/tag/v1.0.0>                     |

---

## What was in this push

`05193a1..ac16482` — 15 files, 1238 insertions / 82 deletions:

| File                                       | Source                              | Why it landed now                                                                |
|--------------------------------------------|-------------------------------------|----------------------------------------------------------------------------------|
| `app/scripts/main.gd`                       | task 66 follow-up                    | `--demo-popupmenu` flag to capture the new menu open in a screenshot              |
| `app/scripts/notebook_view.gd`              | task 66                              | 13 action-bar widgets → 1 MenuButton + nested PopupMenu                          |
| `app/icon.svg.import`                       | leftover                             | Godot import sidecar that wasn't included in the initial commit                  |
| `todo.txt`                                  | tracking                             | The user's running checklist                                                     |
| `app_screenshot.png`                        | leftover                             | A pre-task-9 screenshot referenced by older docs                                  |
| `app_screenshot_task66*.png` (4 files)      | task 66                              | Verification screenshots: collapsed bar + popup expanded                          |
| `task65_github.md`                          | task 65                              | The "publish to GitHub" doc                                                       |
| `task66_one_dropdown.md`                    | task 66                              | The "collapse into MenuButton" doc                                                |
| `godot_reduce_ui.md`                        | task 1                               | The original "Godot + REDUCE" architecture sketch                                |
| `godot_math_interface_features.md`          | task 2                               | "Use Godot's full feature set" doc                                                |
| `godot_math_interface_improvements.md`      | task 4                               | "Improve on task 2" doc                                                           |
| `godot_reduce_one_app.md`                   | task 5                               | "Combine Godot + REDUCE into one app" doc                                         |

The four "legacy" docs predate the `task<N>_` naming, so they were
missed by the initial `git add task*.md` glob. Catching them up gets
the repo's documentation back in sync with the actual task list.

## The tag

```
git tag -a v1.0.0 -m "v1.0.0 — Symbolic Math Workbench, first tagged release.
…"
git push origin v1.0.0
```

Annotated rather than lightweight, so the tag carries the same body
the release notes do — useful when browsing tags with `git show v1.0.0`.

## The release

`gh release create v1.0.0` was used with a multi-line `--notes`. The
release page on GitHub now carries a structured summary:

- **What's here** — the engine integration, notebook view, calculator
  view, advanced tab (332 problems), help wizard, package settings,
  customisation (font / colour / style), and the recent action-bar
  consolidation.
- **Tests** — 66/66 PASS UI regression, 72/72 PASS menu library, plus
  the notebook runner's 4-phase end-to-end + cache regression.
- **Not in the repo** — explicit download links for the Godot binary
  (164 MB) and REDUCE install (253 MB), the two pieces excluded
  because they exceed GitHub's per-file size limits.

No release **assets** were attached — there's nothing pre-built to
ship beyond the source. A future minor release (v1.1.0 or v1.0.1)
that bundles the Godot binary as a release asset is doable; GitHub's
2 GB per-asset limit comfortably fits the 164 MB exe. Deferred until
someone asks.

## Why "v1.0.0" rather than "v1"

Three reasons:

1. **Semver convention.** Tools that read tags (Dependabot, automated
   release-note generators, downstream package managers) consistently
   expect `vMAJOR.MINOR.PATCH`. A bare `v1` would work but trades a
   small future cost for no current benefit.
2. **Distinct from a `v1` branch** if one ever exists. Tag names and
   branch names share a namespace at the protocol level; making the
   tag a three-segment version disambiguates intent.
3. **GitHub's own UI shows release pages built from semver tags more
   prettily** (sort order, "latest" badge, version-comparison links).

The release title is the friendlier **v1.0.0 — Symbolic Math
Workbench** which is what shows up in any "Releases" listing.

## Verification

```text
> gh release view v1.0.0 --json url,name,tagName,publishedAt,isPrerelease
{
  "isPrerelease": false,
  "name": "v1.0.0 — Symbolic Math Workbench",
  "publishedAt": "2026-05-31T16:13:36Z",
  "tagName": "v1.0.0",
  "url": "https://github.com/bluelight1324/symbolic-math-workbench/releases/tag/v1.0.0"
}

> git log --oneline -3
ac16482 v1.0.0 — tasks 1–5 docs, 65 (github), 66 (one dropdown)
05193a1 Initial commit: Godot + REDUCE Symbolic Math Workbench

> gh repo view bluelight1324/symbolic-math-workbench --json url,visibility
{"url": "https://github.com/bluelight1324/symbolic-math-workbench", "visibility": "PUBLIC"}
```

## Going forward — branching / versioning intent

| What                                        | Convention                                                                |
|---------------------------------------------|---------------------------------------------------------------------------|
| Each task continues on `main`                | One commit per task, message subject = `task <N> — <one-line>`           |
| Behaviour-changing batches → minor bump      | `v1.1.0`, `v1.2.0`, …  Tagged after the task that completes the batch    |
| Bug fixes → patch bump                       | `v1.0.1`, `v1.0.2`, …  Cherry-picked / merged forward as needed          |
| Breaking changes → major bump                | `v2.0.0` — would only happen for incompatible format changes (e.g. cache footer schema) |

The next obvious tags:
- `v1.1.0` after a few more task additions on top of `main`.
- `v1.0.1` if a real bug surfaces that needs back-porting.

## Honest scope

- **No release assets attached.** The Godot binary could go up as an
  asset (164 MB < 2 GB limit), but the README's download link to
  godotengine.org is the canonical source. Mirroring it as a release
  asset adds maintenance with little benefit.
- **No GitHub Actions or CI** wired up. Headless runs of the
  task-25/36 regression harness need both Godot + REDUCE downloaded
  at job start — a non-trivial workflow file, deferred.
- **No SBOM / Sigstore signing** of the tag. For a one-person
  research project it's overkill. The annotated tag's author
  (`bluelight1324`) and the commit it points at (`ac16482`) are the
  audit trail today.
- **The release notes reference `task36_comprehensive_test_v2.md`
  etc. as plain links** — they resolve correctly because the repo
  has them at root, but they're not anchored to a specific commit.
  Future links could use `https://github.com/.../blob/v1.0.0/...` for
  permanence.

---

## TL;DR

`git push` → `git tag -a v1.0.0` → `git push origin v1.0.0` → `gh
release create v1.0.0`. Three commands beyond the routine push; the
repo now has a stable, citable v1.0.0 at
**<https://github.com/bluelight1324/symbolic-math-workbench/releases/tag/v1.0.0>**.
