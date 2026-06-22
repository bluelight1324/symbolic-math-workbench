# Another difficult integral

```cas
int(exp(-x^2), x)
```
```cas-result
<!-- src-hash: 144cb7e07646 engine: csl-6547 -->
(sqrt(pi)·erf(x))/2

```

```cas
int(1/(1 + x^6), x)
```
```cas-result
<!-- src-hash: 3312057d2765 engine: csl-6547 -->
( - 2·atan(sqrt(3) - 2·x) + 2·atan(sqrt(3) + 2·x) + 4·atan(x) - sqrt(3)·log( -
sqrt(3)·x + x² + 1) + sqrt(3)·log(sqrt(3)·x + x² + 1))/12

```

```cas
int((x^2 + 1)/(x^4 + 1), x)
```
```cas-result
<!-- src-hash: 07fe826fd503 engine: csl-6547 -->
(sqrt(2)·( - atan((sqrt(2) - 2·x)/sqrt(2)) + atan((sqrt(2) + 2·x)/sqrt(2))))/2

```

```cas
int(x^2*log(x), x)
```
```cas-result
<!-- src-hash: cbf367029cdb engine: csl-6547 -->
(x³·(3·log(x) - 1))/9

```
