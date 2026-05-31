# Task 65 — Publish to GitHub

The whole project is now on GitHub at:

> **<https://github.com/bluelight1324/symbolic-math-workbench>**

Public repo, default branch `main`, initial commit `05193a1` carrying
**277 files / 6.5 MB / 58,695 lines** — every task doc, every script,
every sample notebook, every REDUCE worked-problem `.tst` mirrored
into `workdoc/`, every screenshot.

The bundled Godot + REDUCE binaries are intentionally **excluded** (the
README documents how to fetch them); the repo is the project's
*source* — the things I actually wrote and the things I curated. The
277 MB of third-party binaries that make it runnable stay where their
licences and download pages already provide them.

---

## What the user gets

Cloning the repo + following the README is a complete setup:

```powershell
git clone https://github.com/bluelight1324/symbolic-math-workbench.git
cd symbolic-math-workbench

# Fetch the two binaries the README points at:
#   tools/godot/Godot_v4.6.3-stable_win64.exe   (164 MB)
#   tools/reduce/lib/csl/reduce.exe + packages   (253 MB)
# Then run:
& '.\tools\godot\Godot_v4.6.3-stable_win64.exe' --path '.\app'
```

The app's MathEngine resolves these paths relative to the executable's
parent directory ([math_engine.gd `_engine_exe_path()`](app/autoload/math_engine.gd)),
so the layout above just works.

## What was in the initial commit

| Category                                  | What it covers                                                                                       |
|--------------------------------------------|-------------------------------------------------------------------------------------------------------|
| `app/project.godot`, `app/scenes/`        | Godot project entry point + main scene                                                               |
| `app/autoload/math_engine.gd`              | Persistent REDUCE child + sentinel-correlated reader thread (task 6)                                  |
| `app/scripts/` (16 production + 4 test)    | Every UI script — main, notebook view, advanced view, help wizard, all the config layers, the headless tests |
| `app/notebooks_sample/`                    | 7 sample notebooks: algebra, calculus, ode, plotting, showcase, task37 system, test                  |
| `workdoc/` (152 .tst files, 81 packages)   | Verbatim mirror of REDUCE's worked-problem test suite (task 30)                                       |
| `task*.md` (~50 docs)                      | Per-task design + implementation docs (tasks 6–37, 58–65)                                            |
| `app_screenshot_*.png` (~25 images)         | Verification screenshots referenced by the per-task docs                                              |
| `README.md`                                | Landing page — what the project is, what's not in the repo, how to fetch + run                       |
| `.gitignore`                               | Excludes the 277 MB of binaries, Godot's `.godot/` import cache, HTML export artefacts, marker files |

## What's *not* in the initial commit (and why)

| Excluded path                              | Size       | Reason                                                                                |
|--------------------------------------------|------------|----------------------------------------------------------------------------------------|
| `tools/godot/Godot_v4.6.3-stable_win64.exe`| 164 MB     | Single file over GitHub's 100 MB per-file limit                                       |
| `tools/godot/Godot_v4.6.3-stable_win64_console.exe` | 1 MB | Sibling of the above; same exclusion to keep the `tools/godot/` dir clean             |
| `tools/reduce/`                            | 253 MB     | Whole REDUCE install — exceeds 1 GB repo soft limit when combined with everything else |
| `app/.godot/`                              | varies     | Godot's per-machine import cache. Auto-regenerated on first launch.                   |
| `app/notebooks_sample/*.html`              | small      | HTML exports — produced on demand by **Export HTML** button.                          |
| `app/font.cfg` / `color.cfg` / `style.cfg` / `packages.cfg` | small | User-per-machine settings; live in Godot's `user://` already.                       |
| `*_marker.txt`, `nbtest.log`               | small      | Headless-test progress markers, recreated on each run                                  |

## How the commit was assembled

Three rounds rather than a single `git add .` so I could see exactly
what was being staged:

```powershell
git init
git config user.email "bluelight1324@users.noreply.github.com"
git config user.name "bluelight1324"
git add .gitignore README.md
git add app/project.godot app/icon.svg
git add app/scripts/ app/autoload/ app/scenes/ app/notebooks_sample/
git add workdoc/
git add task*.md todo.txt
git add app_screenshot_*.png
```

Then:

```powershell
git commit -m "Initial commit: Godot + REDUCE Symbolic Math Workbench ..."
git branch -m main
gh repo create bluelight1324/symbolic-math-workbench --public \
    --source=. --remote=origin \
    --description "Godot + REDUCE Symbolic Math Workbench: a desktop CAS app ..." \
    --push
```

`gh` was already authenticated against my account (`bluelight1324`,
via keyring), so the create + push happened in one call.

## Verification

```text
> gh repo view bluelight1324/symbolic-math-workbench --json url,visibility,defaultBranchRef,description
{
  "defaultBranchRef": { "name": "main" },
  "description": "Godot + REDUCE Symbolic Math Workbench: a desktop CAS app …",
  "url": "https://github.com/bluelight1324/symbolic-math-workbench",
  "visibility": "PUBLIC"
}

> git log --oneline -1
05193a1 Initial commit: Godot + REDUCE Symbolic Math Workbench

> git remote -v
origin  https://github.com/bluelight1324/symbolic-math-workbench.git (fetch)
origin  https://github.com/bluelight1324/symbolic-math-workbench.git (push)
```

## What was deliberately *not* done

- **No tags / releases.** The project is at its "v0.x — working" stage;
  cutting a `v0.1.0` tag is a one-step follow-up once the contents
  stabilise.
- **No GitHub Actions workflow.** The headless test harnesses
  ([task 25](task25_comprehensive_ui_test.md) /
  [task 36](task36_comprehensive_test_v2.md)) could run in CI, but
  they need both Godot and REDUCE binaries — neither of which is
  bundled in the repo. A workflow that downloads them at job start
  is a separate task.
- **No CODEOWNERS / CONTRIBUTING / issue templates.** Solo project
  for now.
- **No GitHub Pages preview** of the rendered notebook HTML. The
  `Export HTML` output already produces a styled `.html` file per
  notebook; pointing Pages at a future `docs/` directory of exports
  is a small follow-up.

## Future commit hygiene

Going forward, the per-task workflow becomes:

```powershell
# After finishing each task's edits:
git add app/scripts/<file> task<N>_<name>.md app_screenshot_*.png
git commit -m "task <N> — <one-line summary>"
git push
```

Each task's commit stays focused and traceable. The per-task `.md` doc
serves as the commit's long-form description; the commit message itself
just captures intent.

---

## TL;DR

Local `git init` → `.gitignore` excluding the 277 MB of bundled
binaries → README pointing at where to fetch them → curated
`git add` of source + docs + sample notebooks + screenshots →
`gh repo create --public --push` → live at
**<https://github.com/bluelight1324/symbolic-math-workbench>**.
First commit `05193a1`, 277 files, 6.5 MB.
