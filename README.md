# RPT - Riesel Prime Tester
*Experimental* Lucas-Lehmer-Riesel primality tester.

Notes
-----
This project is not production ready - it does not guarantee error checks and does not save state.

Both Jean Penné's software (LLR64 http://jpenne.free.fr/index2.html) and RPT are based on the same libraries - gwnum and GMP. So there are no dramatic performance gains/losses to be had. Currently RPT matches the speed of LLR64.

k and n are currently limited to unsigned 32 bit values (~4.29Bil) for arbitrary reasons.

As Riesel states in his paper (Prime Numbers and Computer Methods for Factorization p126 [2012]) the following condition must hold for the test to work: 2^n > 4k. This software does currently not notify you if this condition does not hold.

Features
--------
* LLR testing of Riesel prime candidates
* LLR testing matches the speed of LLR64
* Selftest with known primes for LLR
* Fermat PRP testing of Riesel prime candidates (WIP)

What this project is
--------------------
This is me being interested in how the Lucas-Lehmer-Riesel primality proving works - from end to end. I first ran Jean's LLR64 software in 2007 and found my first primes that got into the TOP5000 (https://primes.utm.edu/primes/lists/all.txt). I stopped for over a decade, but the topic always lingered in my mind. In 2019 I started sieving/testing again and the curiosity got the best of me and I decided to implement most of what LLR64 does with Riesel Primes.

The core LLR loop is actually trivial and can be implemented in no time. Much of the complexity comes from needing to find U0 for k > 1. Eg. for Mersenne primes (k=1) U0==4. For k > 1 U0 needs to be calculated, and naive implementations are slow for large k's. I have three different (naive, less-naive and optimal) implementations in this project. The optimal one runs in O(log2(k)) time and is the default.

This project will probably also implement the PRP primality testing used in PFGW (https://sourceforge.net/projects/openpfgw/). This is currently WIP, but should work for most cases.

What this project is not
------------------------
This is not an attempt to replace LLR64. LLR64 has a lot of years of work behind it, in both features and stability/safety. This project does not aim to provide factoring, trivial candidate elimination, resumability, guaranteed safety, support for different prime formats, etc.


Building
--------
Requires the Zig compiler. GWnum(included in Prime95) and GMP need to be directly in the project directory. 
Both GWnum and GMP dependencies need to be built first in their respective ways. They are not complicated to build. The Zig compiler can be downloaded in binary form from https://ziglang.org/download/

```
Zig: tested with 0.5-master (not a stable version)
GWnum: 29.8
GMP: 6.2.0
```

```
wget https://gmplib.org/download/gmp/gmp-6.2.0.tar.lz
tar xlf gmp-6.2.0.tar.lz
cd gmp-6.2.0
./configure
make
cd -

wget https://github.com/shafferjohn/Prime95/archive/v29.8b6.tar.gz
tar xzf v29.8b6.tar.gz
#edit: ./Prime95-29.8b6/gwnum/gwnum.h
#add: #include <stddef.h> to beginning of file
C_INCLUDE_PATH=../../gmp-6.2.0/ make -C Prime95-29.8b6/gwnum/ -f make64
cp Prime95-29.8b6/gwnum/{gwnum.a,libgwnum.a}

# install Zig to $PATH first

make
```

Running
-------
```
Selftest tests known primes k < 300, their n, and counter cases: n-1 [if not known prime]

Options:
$ ./rpt --llr <k> <n> [--threads <t>]
$ ./rpt --fermat <k> <n> [--threads <t>]
$ ./rpt --selftest <max_n>

Simple example:
$ ./rpt --llr 39547695 506636 --threads 4
$ ./rpt --selftest 50000

For optimal threadcount detection:
$ ./rpt --llr 39547695 506636 --threads 0
```

```
./rpt --llr 39547695 506636 --threads 4                                                                                                       130 ↵
=== RPT - Riesel Prime Tester v0.0.4 [GWNUM: 29.8 GMP: 6.2.0] ===
LLR testing: 39547695*2^506636-1 [152521 digits] on 4 threads
step #1 find U0 ...
found V1 [11] using Jacobi Symbols in 0ms
found U0 using Lucas Sequence in 64ms
FFT size 50KB
step #2 LLR test ...
0....1....2....3....4....5....6....7....8....9....X
LLR took 58404ms
#> 39547695*2^506636-1 [152521 digits] IS PRIME

./rpt --llr 39547695 506636 --threads 0
=== RPT - Riesel Prime Tester v0.0.4 [GWNUM: 29.8 GMP: 6.2.0] ===
LLR testing: 39547695*2^506636-1 [152521 digits] on 0 threads
step #1 find U0 ...
found V1 [11] using Jacobi Symbols in 1ms
found U0 using Lucas Sequence in 69ms
step #1.5 benchmark threadcount ...
threads 1 took 158ms for 1000 iterations
threads 2 took 154ms for 1000 iterations
threads 3 took 133ms for 1000 iterations
threads 4 took 152ms for 1000 iterations
threads 5 took 155ms for 1000 iterations
threads 6 took 167ms for 1000 iterations
threads 7 took 175ms for 1000 iterations
threads 8 took 187ms for 1000 iterations
using fastest threadcount 3
FFT size 50KB
step #2 LLR test ...
0....1....2....3....4....5....6....7....8....9....X
LLR took 55818ms
#> 39547695*2^506636-1 [152521 digits] IS PRIME
```
Pseudocode of the LLR test
-----------------------------
```
const k, n, b, c;  # they have to have values
const N = k * b ^ n - 1;

# find V1
# this uses Jacobi Symbols
while (v1 := 1) : () : (v1 += 1) {
    if jacobi(v1 - 2, N) == 1 && jacobi(v1 + 2, N) == -1 {
        break
    }
}

# fastest method [ O(log(bitlen(k))) ] to find u0
# this calculates the value of the Lucas Sequence
x = v1
y = (v1 * v1) - 2
k_bitlen = bitlen(k)
while (i := k_bitlen - 2) : (i > 0) : (i -= 1) {
    if k.bits[i] == 1 {
        x = (x*y) - v1 mod N
        y = (y*y) - 2 mod N
    } else {
        y = (x*y) - v1 mod N
        x = (x*x) - 2 mod N
    }
}
x = x * x
x = x - v1
u = u0 = x mod N

# Lucas-Lehmer-Riesel primality test starting from U0
while (i := 1) : (i < n - 1) : (i += 1) {
    u = (u * u) - 2 mod N
}
'prime!' if u == 0
```

Linked library licenses
-----------------------
The source code of this project contains no third party licensed code.
The linking process links to GMP and gwnum libraries. Both have their own license.

The gwnum library requires that users of the binary to agree to the license in:
https://github.com/shafferjohn/Prime95/blob/master/gwnum/readme.txt
In particular:
```
(2) If this software is used to find Mersenne Prime numbers, then
GIMPS will be considered the discoverer of any prime numbers found
and the prize rules at http://mersenne.org/prize.htm will apply.
```

GMP is incorporated under LGPL v3:
https://www.gnu.org/licenses/lgpl-3.0.en.html
