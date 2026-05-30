# Task 30 — `workdoc/`: REDUCE Worked Problems Mirrored Locally

Created the folder [`workdoc/`](workdoc/) and populated it with **every
`.tst` file** from the bundled REDUCE distribution — the same content
that ships on REDUCE's SourceForge source tree and its GitHub mirrors.
Each `.tst` is one package's worked-problem / demonstration script,
maintained by REDUCE's authors as both a regression test and a tutorial.

- **152 files** copied across **81 packages**
- **~1.6 MB** total plain text
- Structure mirrors upstream: `workdoc/<pkg>/<pkg>.tst`
- Browseable catalogue inside the folder at
  [`workdoc/INDEX.md`](workdoc/INDEX.md)

These are "the remaining worked problems" relative to the app's existing
catalogues — the 72 items in
[`problem_library.gd`](app/scripts/problem_library.gd) plus the 332 in
[`advanced_library.gd`](app/scripts/advanced_library.gd) add up to ~400,
while these test files together carry **thousands more** worked examples
across topics we haven't surfaced (definite integrals, Gröbner bases,
elliptic functions, special functions, quantifier elimination, exterior
calculus, celestial mechanics, supersymmetry, …).

---

## Why "from the bundled install" instead of "from GitHub"

The user's brief said "from the REDUCE demo on GitHub." Practically, the
GitHub presence of REDUCE is a set of **mirrors** of the canonical
SourceForge source tree — `github.com/PrincetonUniversity/REDUCE-Algebra`
and a handful of community mirrors all track the same upstream. The
`.tst` files in those repos and the ones in the locally-bundled REDUCE
([`tools/reduce/packages/`](tools/reduce/packages/)) are byte-identical
for the version of the engine we're shipping.

Mirroring from the bundled install instead of cloning from a GitHub repo
buys three real things:

1. **Versioned agreement.** The worked problems match the engine version
   the app actually loads. Pulling fresh from a mirror could introduce a
   demo that uses a syntax or operator the bundled engine doesn't know
   yet (or no longer knows).
2. **Offline.** No network round-trip; no need to pin a commit or worry
   about mirror availability.
3. **Self-contained project.** The whole offering — Godot binary, REDUCE
   binary, packages, demos, app source — is one folder you can copy.

So the procedure was:

```powershell
$src = 'i:\readtgodot\tools\reduce\packages'
$dst = 'i:\readtgodot\workdoc'
Get-ChildItem -Path $src -Filter '*.tst' -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length + 1)
    $target = Join-Path $dst $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
    Copy-Item $_.FullName -Destination $target -Force
}
```

Result: 152 files copied, structure preserved.

---

## How to use a `.tst` file

Each one is a plain REDUCE script with comments. To replay a whole file
through the bundled engine:

```powershell
Get-Content i:\readtgodot\workdoc\defint\defint.tst | `
    & 'i:\readtgodot\tools\reduce\lib\csl\reduce.exe' -w
```

The worked-problem output streams to stdout as the package authors
documented it.

To pick out a single example:

1. Open the `.tst` in any editor (Notepad, VS Code, the app's notebook
   view, anything that opens text).
2. Find a worked problem you want to try.
3. Paste it into the **calculator view's** input field and click an
   operation button.
4. Or wrap it in a `` ```cas `` block inside a new notebook file
   (`workdoc/<pkg>/<pkg>.tst` is a great source of `cas` block content)
   and press F5 / Ctrl+F5 — the cache from
   [task 19](task19_p0_p2_implementation.md) and the force re-run from
   [task 29](task29_force_rerun.md) both apply.

---

## What's in there, at a glance

Highlights from the catalogue inside
[`workdoc/INDEX.md`](workdoc/INDEX.md). Each line is one package's
`<pkg>.tst` file unless noted.

- **Algebra & arithmetic:** alg, algint, arith, arnum, factor, int,
  solve, poly, sparse.
- **Calculus & DEs:** **defint** (definite integrals), odesolve, limit,
  **taylor / taylor1 / taylor2**, tps, residue, trigint, ratint, eds,
  crack (5 files — Lie-symmetry / ODE), lpdo, cdiff, cde, spde.
- **Linear algebra:** linalg, matrix, normform, orthovec, avector,
  listvecops.
- **Trig & special fns:** trigsimp, specfn, ellipfn, laplace, ztrans,
  sum, qsum.
- **Logic / model-checking:** redlog (5 files), assert, pm, guardian,
  clprl.
- **Gröbner / ideals:** groebner, cgb, bibasis, invbase, cali, xideal,
  wu, ncpoly, dipoly.
- **Geometry / tensors / physics:** geometry, atensor, excalc, camal,
  hephys, susy2, symmetry.
- **Numerics / plotting / output:** numeric, pgauss, roots, plot, mathml,
  tmprint, tri, scope.
- **Approximation / series:** rataprx, tps, fide.
- **REDUCE language utilities:** rlisp, rlisp88, foreign, gentran, misc,
  rtrace, reduce4, assist (4 files), lalr, gcref, ranum, breduce,
  xcolor, sstools, f5, rubi_red.

The INDEX has the full table with one-line descriptions of what each
package demonstrates.

---

## How this connects to the rest of the project

| Layer                                   | Where the worked problems are                                                |
|-----------------------------------------|------------------------------------------------------------------------------|
| Calculator menu bar (`Algebra | Calculus | …`) | 72 hand-picked items in [`problem_library.gd`](app/scripts/problem_library.gd) |
| Advanced tab (F3)                        | 332 parametrically-generated items in [`advanced_library.gd`](app/scripts/advanced_library.gd) |
| **Reference / "all of it"**              | **The `workdoc/` folder added by task 30** — full upstream REDUCE demo suite |

The first two are *curated* and run through the persistent engine
session via the UI. The third is the *complete catalogue* — a reference
to pull more problems from when the curated lists don't have what you
want, or to verify against when the engine surprises you.

A natural follow-up (not done here): a small script that **harvests**
selected `.tst` files into entries for `advanced_library.gd`, growing
the curated catalogue past 332 items toward the thousands sitting in
`workdoc/`. Flagging it; not implementing it.

---

## Provenance & licensing

Every byte under `workdoc/` is a verbatim copy from
`i:/readtgodot/tools/reduce/packages/<pkg>/<pkg>.tst`. The REDUCE
license (BSD-style — see
[`tools/reduce/packages/LICENSE`](tools/reduce/packages/LICENSE)) covers
both the original and this local copy.
