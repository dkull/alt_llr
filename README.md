# RPT - Riesel Prime Tester
*Experimental* Lucas-Lehmer-Riesel primality tester.

Note
----
This project is in no way 'production ready', it does not check errors and does not save state. I wouldn't recommend swapping out your LLR64's for this (yet). Although I have noticed that if a CPU is stable with LLR (for a while), it should be okay to run it without error checking...am I right about this?

Also, it is important to note that this software and Jean Penné's software (LLR64 http://jpenne.free.fr/index2.html) do (almost) exactly the same thing, using the same libraries. So there is no performance gains to be had - we both rely on the speed of the GWNum library. LLR is probably faster in many cases (possibly due to using C/GCC or some other magic), even though it uses error checking. But I have noticed that RPT is a smidge faster when using larger k's in threaded mode.

What this project is
--------------------
This is me being interested in how the Lucas-Lehmer-Riesel primality proving works - from end to end. I first ran Jean's LLR software in 2007 and found my first primes that got into the TOP5000(https://primes.utm.edu/primes/lists/all.txt). I stopped for over a decade, but the topic always lingered in my mind. In 2019 I started sieving/testing again and the curiosity got the best of me and I decided to implement most of what LLR64 does with Riesel Primes.

The core LLR loop is actually trivial and can be implemented in no time. Much of the complexity comes from needing to find U0 for k > 1. Eg. for Mersenne primes (k=1) U0==4. For k>1 U0 needs to be calculated, and naive implementations are slow for large k's. I have two different (naive and less-naive) implementations in this project, though they are not currently used. The one used is the same one used in LLR64, which runs in O(log(bitlen(k))) time.

This project will probably also implement the PRP primality testing used in PFGW(https://sourceforge.net/projects/openpfgw/)

What this project is not
------------------------
This is not an attempt to replace LLR64. LLR64 has a lot of years of work behind it, in both features and stability/safety. This project is no match to that. This project does not aim to provide factoring, trivial candidate elimination, resumability, safety, support for different prime formats, etc.

Building
--------
Requires the Zig compiler. And GWNum and GMP in the project directory. 
Both library dependencies need to be built first in their respective ways. They are not complicated to build. The Zig compiler can be downloaded in binary form from https://ziglang.org/download/

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

# find V1 (as 'u')
# this uses Jacobi Symbols 
while (u := 1) : () : (u += 1) {
    if jacobi(u - 2, N) == 1 && jacobi(u + 2, N) == -1 {
        break
    }
}

# fastest method [ O(log(bitlen(k))) ] to find u0 (as u)
# this calculates the value of the Lucas Sequence
x = u
y = (u * u) - 2
k_bitlen = bitlen(k)
while (i := k_bitlen - 2) : (i > 0) : (i -= 1) {
    if k.bits[i] == 1 {
        x = (x*y) - v1 mod N
        y = (y * y) - 2 mod N
    } else {
        y = (x*y) - v1 mod N
        x = (x * x) - 2 mod N
    }
}
x = x * x
x = x - u
x = x mod N

# Lucas-Lehmer-Riesel primality test starting from U0 (as u)
while (i := 1) : (i < n - 1) : (i += 1) {
    (u * u) - 2
}
'prime!' if u == 0
```
