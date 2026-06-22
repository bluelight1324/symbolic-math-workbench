# Task 116 — Is the Factorize Result Correct?

## Question

> "Is the factorize result correct?" (from the screenshot)

The notebook cell ran:

```
Factorize(56466)
```

and the engine returned:

```
{{2,1},{3,2},{3137,1}}
```

## Answer: Yes — it is correct.

REDUCE's `factorize` returns a list of **{factor, multiplicity}** pairs, so
`{{2,1},{3,2},{3137,1}}` means:

    56466 = 2¹ · 3² · 3137¹

### Check 1 — the product
    2 · 3² · 3137 = 2 · 9 · 3137 = 18 · 3137 = 56466 ✓

### Check 2 — independent factorization
Verified with two independent tools (REDUCE's MCP build couldn't run it locally
because it lacks the heap fix from task 114, so I cross-checked outside the app):

| Tool | Result |
|---|---|
| Python `sympy.factorint(56466)` | `{2: 1, 3: 2, 3137: 1}` |
| Unix `factor 56466` | `2 3 3 3137` (= 2 · 3² · 3137) |

Both agree with REDUCE.

### Check 3 — 3137 is prime
The factorization lists `3137` with multiplicity 1, i.e. it claims 3137 is
prime. Confirmed: `sympy.isprime(3137) = True`, and `factor 3137` returns just
`3137`. (3137 has no prime divisor up to √3137 ≈ 56, so it is prime.)

## Conclusion

`Factorize(56466) = {{2,1},{3,2},{3137,1}}` is **mathematically correct**:
56466 = 2 · 3² · 3137 with 3137 prime.

It also confirms the task-114 fix is working — the cell actually evaluated and
returned a result (status "Done — 1 block(s) updated"), where before the heap
fix the run would have hung.

## Files changed
- None — this is a verification task.
