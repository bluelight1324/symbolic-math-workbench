# Task 264 — math symbols render (no tofu)

These symbols should all appear (not as □ boxes), via the math-font fallback:

√ ∫ ∑ ∏ ∂ ∇ ≤ ≥ ≠ ≈ → ⇒ ∞ ± × ÷ ∈ ∀ ∃ ℝ ℂ ℤ ℕ ℚ α β γ δ θ λ μ π σ φ ω Ω

A CAS result that formats a radical and a superscript:

```cas
sqrt(x^2 + 1)
```
```cas-result
<!-- src-hash: 790b7ea10010 engine: csl-6547 -->
√(x² + 1)

```

A derivative whose result carries a radical:

```cas
df(1/sqrt(x), x)
```
```cas-result
<!-- src-hash: 991e9ebebe31 engine: csl-6547 -->
( - 1)/(2·√(x)·x)

```

## Task 265 — BBCode 2-D

A matrix product renders as a **grid** (not `mat((…),(…))`):

```cas
mat((1,2),(3,4)) * mat((5,6),(7,8))
```
```cas-result
<!-- src-hash: 0c467829ed9f engine: csl-6547 -->
mat((19,22),(43,50))

```

A symbolic (multi-character) exponent now **raises** — a custom RichTextEffect
(task 266) supplies the `[sup]` tag Godot 4.6 lacks, so the `n` is smaller and lifted:

```cas
df(x^(n+1), x)
```
```cas-result
<!-- src-hash: 8391a67d52cb engine: csl-6547 -->
x^n·(n + 1)

```
