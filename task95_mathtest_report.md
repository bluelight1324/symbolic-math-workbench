# Task 95 — Math-Function UI Test Report

**28 passed / 0 failed**  (of 28 total)
✅ Engine ready at start

## Phase A — operation buttons (exact-result checks)
✅ Simplify (x+1)^2  — got== x² + 2·x + 1 want=x^2+2*x+1
✅ Simplify (x+1)^3  — got== x³ + 3·x² + 3·x + 1 want=x^3+3*x^2+3*x+1
✅ Simplify (x^2-1)/(x-1)  — got== x + 1 want=x+1
✅ Factor x^6-1  — got== {{x² + x + 1,1}, | {x² - x + 1,1}, | {x + 1,1}, | {x - 1,1}} want={{x^2+x+1,1},{x^2-x+1,1},{x+1,1},{x-1,1}}
✅ d/dx x^3  — got== 3·x² want=3*x^2
✅ d/dx sin(x)*x  — got== cos(x)·x + sin(x) want=cos(x)*x+sin(x)
✅ d/dx atan(x)  — got== 1/(x² + 1) want=1/(x^2+1)
✅ d/dx tan(x)  — got== tan(x)² + 1 want=tan(x)^2+1
✅ ∫ 1/(x^2+1) dx  — got== atan(x) want=atan(x)
✅ ∫ x^2 dx  — got== x³/3 want=x^3/3
✅ ∫ cos(x) dx  — got== sin(x) want=sin(x)
✅ ∫ 1/x dx  — got== log(x) want=log(x)
✅ ∫ log(x) dx  — got== x·(log(x) - 1) want=x*(log(x)-1)
✅ Solve x^2-5x+6 = 0  — got== {x=3,x=2} want={x=3,x=2}
✅ Solve x^4-1 = 0  — got== {x=i,x= - i,x=1,x=-1} want={x=i,x=-i,x=1,x=-1}
✅ Solve x^2+1 = 0  — got== {x=i,x= - i} want={x=i,x=-i}
✅ Solve ODE y'=y  — got== {y=e^x·arbconst(1)} want=arbconst
✅ Solve ODE y'=y has e^x  — got== {y=e^x·arbconst(1)}

## Phase B — problem library breadth (every item, no error)
✅ Algebra — 12/12 items evaluated  — 12/12 ok
✅ Calculus — 13/13 items evaluated  — 13/13 ok
✅ Equations — 8/8 items evaluated  — 8/8 ok
✅ ODEs — 8/8 items evaluated  — 8/8 ok
✅ Matrices — 6/6 items evaluated  — 6/6 ok
✅ Series — 7/7 items evaluated  — 7/7 ok
✅ Trig — 5/5 items evaluated  — 5/5 ok
✅ Numbers — 6/6 items evaluated  — 6/6 ok
✅ Plots — 7/7 items evaluated  — 7/7 ok

**Library breadth: 72/72 items returned a valid result.**
