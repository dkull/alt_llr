# RPT - Riesel Prime Tester
Experimental Lucas-Lehmer-Riesel primality tester.

run:
```
$ ./rpt <k> <n> [threads]
$ ./rpt 39547695 506636 4
```

```
$ ./rpt 39547695 506636 4
=== RPT - Riesel Prime Tester v0.0.1 [GWNUM: 29.8 GMP: 6.2.0] ===
LLR testing: 39547695*2^506636-1 [152521 digits] on 4 threads
step 1. find U0 ...
found V1 [11] using Jacobi Symbols in 0ms
found U0 using Lucas Sequence in 66ms
step 2. llr test ...
9%.19%.29%.39%.49%.59%.69%.78%.88%.98%.
llr took 73827ms
#> 39547695*2^506636-1 [152521 digits] IS PRIME
```
