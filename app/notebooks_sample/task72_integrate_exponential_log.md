# Task 72 — Integrate e^(x²) · log(1 + x³)

Attempt the integral:

$$\int e^{x^2} \log(1 + x^3) \, dx$$

This integral is deliberately tricky: the `e^(x^2)` term has no elementary antiderivative (the error function), and `log(1 + x^3)` couples the integrand in a way that REDUCE's symbolic solver must navigate. Let's see what the engine returns.

```cas
int(exp(x^2)*log(1 + x^3), x)
```

The result will either be a closed form (unlikely) or the integral wrapped back in `int(...)` (symbolic, indicating non-elementary).
