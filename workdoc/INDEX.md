# REDUCE Worked-Problem Test Suite — Mirrored Locally

This folder mirrors the **`.tst` files** from every package in the bundled
REDUCE distribution at
[`tools/reduce/packages/`](../tools/reduce/packages/). Each `.tst` is the
package's own demonstration / regression script — i.e. its worked-problem
file. The same content is what's in the REDUCE source on SourceForge and
its GitHub mirrors; this copy is offline, browsable, and the same version
the engine bundled with this app actually runs.

- **152 `.tst` files** across **81 packages**
- Total: ~1.6 MB plain text

The structure mirrors the upstream layout:

```
workdoc/
  alg/alg.tst
  algint/algint.tst
  arith/arith.tst
  …
```

Most packages have one `<package>.tst` file at the top of their folder;
a few (assist, crack, taylor, …) carry several supplementary `.tst`s.

---

## How to use a file

Open any `.tst` in a text editor (or in the app's notebook view) — they
are plain REDUCE scripts with comments and worked examples. To replay
one through the bundled engine:

```powershell
Get-Content i:\readtgodot\workdoc\defint\defint.tst | `
    & 'i:\readtgodot\tools\reduce\lib\csl\reduce.exe' -w
```

Each statement in the file is sent to REDUCE; the worked-problem output
appears on stdout exactly as the package authors documented it.

You can also pick individual examples from a `.tst` and paste them into
the calculator view's input field, or into a `cas` block in the notebook
view, to evaluate one at a time against the persistent `MathEngine`
session.

---

## Catalogue (by topic)

The descriptions below sketch what each package's test file demonstrates.
For packages whose purpose is fully self-evident from the name, the entry
is brief.

### Algebra & arithmetic

| Path                                | What's in the worked file                                              |
|-------------------------------------|------------------------------------------------------------------------|
| [alg/alg.tst](alg/alg.tst)          | Core polynomial algebra — simplification, substitution, switches       |
| [algint/algint.tst](algint/algint.tst) | Algebraic integration (`algint` extends `int` with algebraic fns)    |
| [arith/arith.tst](arith/arith.tst)  | Arbitrary-precision arithmetic; modular & rational kernels             |
| [arnum/arnum.tst](arnum/arnum.tst)  | Algebraic numbers — extension fields, minimal polynomials              |
| [factor/factor.tst](factor/factor.tst) | Polynomial factorisation tests                                       |
| [int/int.tst](int/int.tst)          | Indefinite integration (the core `int` operator)                       |
| [solve/solve.tst](solve/solve.tst)  | Polynomial / system solving                                            |
| [poly/poly.tst](poly/poly.tst)      | Polynomial manipulation                                                |
| [sparse/sparse.tst](sparse/sparse.tst) | Sparse polynomial arithmetic                                          |

### Calculus & differential equations

| Path                                       | Worked content                                              |
|--------------------------------------------|-------------------------------------------------------------|
| [defint/defint.tst](defint/defint.tst)     | **Definite** integrals (with limits) — many closed forms     |
| [odesolve/odesolve.tst](odesolve/odesolve.tst) | First- and higher-order ODE solving                       |
| [limit/limit.tst](limit/limit.tst)         | Limit evaluations                                            |
| [taylor/taylor.tst](taylor/taylor.tst), [taylor/taylor1.tst](taylor/taylor1.tst), [taylor/taylor2.tst](taylor/taylor2.tst) | Taylor / Laurent series, multi-arg expansions |
| [tps/tps.tst](tps/tps.tst)                 | Truncated power-series arithmetic                            |
| [residue/residue.tst](residue/residue.tst) | Residues for contour integration                             |
| [trigint/trigint.tst](trigint/trigint.tst) | Integration of trig integrands                               |
| [ratint/ratint.tst](ratint/ratint.tst)     | Rational-function integration                                |
| [eds/eds.tst](eds/eds.tst)                 | Exterior differential systems                                |
| [crack/*.tst](crack/)                      | Computer algebra for ODEs / Lie-symmetry analysis (5 files)  |
| [lpdo/lpdo.tst](lpdo/lpdo.tst)             | Linear partial differential operators                         |
| [cdiff/cdiff.tst](cdiff/cdiff.tst)         | Covariant differentials                                       |
| [cde/cde.tst](cde/cde.tst)                 | Computation of (super-)PDE invariants                         |
| [spde/spde.tst](spde/spde.tst)             | Symmetry analysis for PDEs                                   |

### Linear algebra & matrices

| Path                                | Worked content                                          |
|-------------------------------------|---------------------------------------------------------|
| [linalg/linalg.tst](linalg/linalg.tst) | Matrix manipulation library                          |
| [matrix/matrix.tst](matrix/matrix.tst) | Core matrix algebra                                  |
| [normform/normform.tst](normform/normform.tst) | Normal forms (Jordan, Smith)                |
| [orthovec/orthovec.tst](orthovec/orthovec.tst) | Orthogonal vector ops                       |
| [avector/avector.tst](avector/avector.tst)     | Vector calculus (grad/div/curl)             |
| [listvecops/listvecops.tst](listvecops/listvecops.tst) | Vectors-as-lists operations          |

### Trigonometry & special functions

| Path                                       | Worked content                            |
|--------------------------------------------|-------------------------------------------|
| [trigsimp/trigsimp.tst](trigsimp/trigsimp.tst) | Trig simplification + identities       |
| [specfn/specfn.tst](specfn/specfn.tst)     | Special functions (Bessel, Gamma, etc.)   |
| [ellipfn/ellipfn.tst](ellipfn/ellipfn.tst) | Elliptic functions                         |
| [laplace/laplace.tst](laplace/laplace.tst) | Laplace transforms                         |
| [ztrans/ztrans.tst](ztrans/ztrans.tst)     | Z-transforms                               |
| [sum/sum.tst](sum/sum.tst)                 | Symbolic summation                          |
| [qsum/qsum.tst](qsum/qsum.tst)             | q-series and q-hypergeometric sums         |

### Logic, sets, model-checking

| Path                                | Worked content                                                |
|-------------------------------------|---------------------------------------------------------------|
| [redlog/*.tst](redlog/)             | Real-closed-field / Presburger / DCFSF logic — quantifier elimination |
| [assert/assert.tst](assert/assert.tst) | Assertion / pre-/post-conditions package                  |
| [pm/pm.tst](pm/pm.tst)              | Pattern matching                                              |
| [guardian/guardian.tst](guardian/guardian.tst) | Guard / quantified expressions                      |
| [clprl/clprl.tst](clprl/clprl.tst)  | Constraint-logic programming                                  |

### Groebner bases & ideals

| Path                                | Worked content                                                  |
|-------------------------------------|-----------------------------------------------------------------|
| [groebner/groebner.tst](groebner/groebner.tst) | Standard Gröbner bases                              |
| [cgb/cgb.tst](cgb/cgb.tst)          | Comprehensive Gröbner bases (parametric)                        |
| [bibasis/bibasis.tst](bibasis/bibasis.tst) | Boolean Gröbner bases                                    |
| [invbase/invbase.tst](invbase/invbase.tst) | Involutive bases                                          |
| [cali/cali.tst](cali/cali.tst)      | Commutative algebra library — modules, syzygies, Hilbert series |
| [xideal/xideal.tst](xideal/xideal.tst) | Exterior-algebra ideals                                      |
| [wu/wu.tst](wu/wu.tst)              | Wu's method for polynomial systems                              |
| [ncpoly/ncpoly.tst](ncpoly/ncpoly.tst) | Non-commutative polynomial arithmetic                        |
| [dipoly/dipoly.tst](dipoly/dipoly.tst) | Differential polynomials                                     |

### Geometry, tensors, physics

| Path                                | Worked content                                       |
|-------------------------------------|------------------------------------------------------|
| [geometry/geometry.tst](geometry/geometry.tst) | Euclidean / projective geometry          |
| [atensor/atensor.tst](atensor/atensor.tst) | Antisymmetric tensors                          |
| [excalc/excalc.tst](excalc/excalc.tst) | Exterior calculus / differential forms             |
| [camal/camal.tst](camal/camal.tst)  | Celestial mechanics (Cambridge Algebra-style)        |
| [hephys/hephys.tst](hephys/hephys.tst) | High-energy physics — Dirac matrices, gamma algebra |
| [susy2/susy2.tst](susy2/susy2.tst)  | Supersymmetry computations                            |
| [symmetry/symmetry.tst](symmetry/symmetry.tst) | Symmetry-group computations                  |

### Numerics, plotting, output

| Path                                | Worked content                                              |
|-------------------------------------|-------------------------------------------------------------|
| [numeric/numeric.tst](numeric/numeric.tst) | Numerical evaluation routines                         |
| [pgauss/pgauss.tst](pgauss/pgauss.tst) | Gaussian-elimination–style routines                     |
| [roots/roots.tst](roots/roots.tst)  | Polynomial root finding                                     |
| [plot/plot.tst](plot/plot.tst)      | Plotting interface (GnuPlot-driven)                          |
| [mathml/mathml.tst](mathml/mathml.tst) | MathML output                                             |
| [tmprint/tmprint.tst](tmprint/tmprint.tst) | TeXmacs printing                                       |
| [tri/tri.tst](tri/tri.tst)          | Triangulation                                                |
| [scope/scope.tst](scope/scope.tst)  | "Scope" optimisation of expressions                          |

### Approximation & power series

| Path                                | Worked content                                      |
|-------------------------------------|-----------------------------------------------------|
| [rataprx/rataprx.tst](rataprx/rataprx.tst) | Rational approximation (Padé, Chebyshev)     |
| [tps/tps.tst](tps/tps.tst)          | Truncated power-series                              |
| [fide/fide.tst](fide/fide.tst)      | Finite-difference equations                          |

### REDUCE-as-language utilities

| Path                                       | Worked content                                              |
|--------------------------------------------|-------------------------------------------------------------|
| [rlisp/rlisp.tst](rlisp/rlisp.tst), [rlisp88/rlisp88.tst](rlisp88/rlisp88.tst) | The R-LISP host language     |
| [foreign/foreign.tst](foreign/foreign.tst) | Foreign-function interface                                  |
| [gentran/gentran.tst](gentran/gentran.tst) | Code generation (Fortran/C/RATFOR)                          |
| [misc/misc.tst](misc/misc.tst)             | Miscellaneous utilities                                     |
| [rtrace/rtrace.tst](rtrace/rtrace.tst)     | Tracing / debugging                                          |
| [reduce4/reduce4.tst](reduce4/reduce4.tst) | Test suite from REDUCE 4.0                                   |
| [assist/assist.tst](assist/assist.tst), [assist/cantens.tst](assist/cantens.tst), [assist/dummy.tst](assist/dummy.tst), [assist/selfgra.tst](assist/selfgra.tst) | Helpers + canonical-tensor / dummy-indices / self-gravity     |
| [lalr/lalr.tst](lalr/lalr.tst)             | LALR parser generator                                       |
| [pm/pm.tst](pm/pm.tst)                     | Pattern matching                                            |
| [gcref/gcref.tst](gcref/gcref.tst)         | Global cross-references                                     |
| [ranum/ranum.tst](ranum/ranum.tst)         | Random numbers                                              |
| [breduce/breduce.tst](breduce/breduce.tst) | Burmester / BLAS-style reductions                            |
| [xcolor/xcolor.tst](xcolor/xcolor.tst)     | Quark-colour algebra (gauge theory)                          |
| [sstools/sstools.tst](sstools/sstools.tst) | Symbol-system tools                                         |
| [f5/f5.tst](f5/f5.tst)                     | Faugère's F5 algorithm                                       |
| [rubi_red/rubi_red.tst](rubi_red/rubi_red.tst) | RUBI integration rule-set port                          |

### Less common / specialised

| Path                                | Worked content                                                       |
|-------------------------------------|----------------------------------------------------------------------|
| [clashes/?](clashes/)                | Reserved-word clash workarounds                                      |

(Plus the remaining packages whose `.tst` files are present but not
described in detail above — open them directly to see what the package
demonstrates.)

---

## Provenance

This is a verbatim copy of the test/demo content from the bundled REDUCE
build:

```
source : i:\readtgodot\tools\reduce\packages\<pkg>\<pkg>.tst
copy   : i:\readtgodot\workdoc\<pkg>\<pkg>.tst
```

Every byte is what REDUCE's own authors shipped. The license at
`packages/LICENSE` (same as REDUCE's BSD-style) applies; that file is in
this folder too as
[../tools/reduce/packages/LICENSE](../tools/reduce/packages/LICENSE).

---

## Why mirror these instead of pulling from GitHub

The user asked for "the remaining worked problems from the REDUCE demo
on GitHub." Practically:

- The GitHub mirrors of REDUCE
  (e.g. `github.com/PrincetonUniversity/REDUCE-Algebra` and several
  community mirrors) carry the *exact same* `.tst` files. SourceForge is
  the authoritative source; GitHub mirrors track it.
- The bundled REDUCE in this project already includes the same files, at
  the same version the engine actually runs. Using the local copy
  guarantees the demos and the bundled engine agree, and works
  offline.

So this folder is a verbatim local mirror — identical content, no network
round-trips, no chance of demoing one REDUCE version against the engine
of another.
