# Differential equations

A first-order separable equation:

```cas
odesolve(df(y,x) = y, y, x)
```

A second-order forced oscillator (SHM + drive):

```cas
odesolve(df(y,x,2) + y = sin(x), y, x)
```
