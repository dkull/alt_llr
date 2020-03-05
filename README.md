# RPT - Riesel Prime Tester
*Experimental* Lucas-Lehmer-Riesel primality tester.

Note
----
This project is in no way 'production ready', it does not check errors and does not save state. I wouldn't recommend swapping out your LLR64's for this (yet). Although I have noticed that if a CPU is stable with LLR (for a while), it should be okay to run it without error checking...am I right about this?

Also, it is important to note that this software and Jean Penné's software (LLR64 http://jpenne.free.fr/index2.html) do (almost) exactly the same thing, using the same libraries. So there is no performance gains to be had - we both rely on the speed of the GWNum library. LLR64 is probably faster in many cases (possibly due to using C/GCC or some other magic), even though it uses error checking. But I have noticed that RPT is a smidge faster when using larger k's in threaded mode.

k and n are currently limited to unsigned 32 bit values (~4.29Bil) for arbitrary reasons. I don't see a need for supporting larger values.
As Riesel states in his paper (Prime Numbers and Computer Methods for Factorization p126 [2012]) this condition must hold: 2^n > 4k for the test to work.
This software does currently not notify you if this condition does not hold.

What this project is
--------------------
This is me being interested in how the Lucas-Lehmer-Riesel primality proving works - from end to end. I first ran Jean's LLR64 software in 2007 and found my first primes that got into the TOP5000 (https://primes.utm.edu/primes/lists/all.txt). I stopped for over a decade, but the topic always lingered in my mind. In 2019 I started sieving/testing again and the curiosity got the best of me and I decided to implement most of what LLR64 does with Riesel Primes.

The core LLR loop is actually trivial and can be implemented in no time. Much of the complexity comes from needing to find U0 for k > 1. Eg. for Mersenne primes (k=1) U0==4. For k>1 U0 needs to be calculated, and naive implementations are slow for large k's. I have three different (naive, less-naive and optimal) implementations in this project. The optimal one is the same one used in LLR64, which runs in O(log(bitlen(k))) time.

This project will probably also implement the PRP primality testing used in PFGW (https://sourceforge.net/projects/openpfgw/)

What this project is not
------------------------
This is not an attempt to replace LLR64. LLR64 has a lot of years of work behind it, in both features and stability/safety. This project is no match to that. This project does not aim to provide factoring, trivial candidate elimination, resumability, safety, support for different prime formats, etc.

Building
--------

Requires the Zig compiler. GWnum(included in Prime95) and GMP need to be directly in the project directory. 
Both GWnum and GMP dependencies need to be built first in their respective ways. They are not complicated to build. The Zig compiler can be downloaded in binary form from https://ziglang.org/download/

I am considering using only GWnum and dropping GMP. But it seems like a safe bet to keep onto GMP for other Riesel Prime proving/PRP methods.

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

# install Zig to $PATH first

make
```

Running
-------
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
Pseudocode of the whole thing
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
    u = (u * u) - 2
}
'prime!' if u == 0
```
