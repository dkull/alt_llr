# alt_llr
WIP experimentation with a Lucas-Lehmer-Riesel primality tester.

Requirements: gmpy2

Currently works on smallish k's and n's

The implementation uses no tricks, except
offloading the heavy math to libgmp.

Largest k to work from http://15k.org is 1999, 2001 does not work.

===

Example 1:

```
$ python3 llr.py 301 159
N digits = 51 precision 2408 bits
s0: digits  173
core took 0.23007ms
op ** took 0.035ms
op - took 0.024ms
op % took 0.05ms
301*2^159-1 = True
time: 0.38ms
```

Comparatively llr64 takes 13ms

===

Example 2:
```
$ python3 llr.py 301 32307
N digits = 9729 precision 2408 bits
10000 / 32307
20000 / 32307
30000 / 32307
core took 5569.11278ms
op ** took 1304.56ms
op - took  5.96ms
op % took 4227.08ms
301*2^32307-1 = True
time: 5569.67ms
```

Comparatively llr64 takes 184ms
