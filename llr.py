import sys
import time
import math
from collections import defaultdict
from sys import exit

import gmpy2
from gmpy2 import mpz, xmpz, mpfr, sqrt, c_mod, add, sub, mul, powmod, round2, round_away, divexact, is_prime
from numpy.polynomial.chebyshev import chebval

# raise the precision so at least our tests pass
gmpy2.get_context().precision=2 ** 10
assert(pow(xmpz(2), xmpz(3)) == 8)
assert(pow(xmpz(7), xmpz(31)) == 157775382034845806615042743)

stats = defaultdict(lambda: 0)

sqrt4 = mpfr(sqrt(4))
mpfr22 = mpfr(2 ** -2)
def P_generic(m, x):
    m = mpz(m)
    x = mpz(x)
    a = mpfr(mpfr(2)**-m)

    inner = pow(x, mpz(2))
    inner -= mpz(4)
    inner = sqrt(inner)
    #inner = x - (sqrt4 / x)  # potential replacement in cases x >= 5

    x += inner
    x **= m
    x *= a
    return xmpz(round_away(x))

# k:5 b:2 n:32
# N = k * 2 ^ 32 - 1 = 21474836479
assert(P_generic(1, xmpz(4)) == 4)
assert(P_generic(5, xmpz(4)) == 724)
assert(P_generic(2, xmpz(724)) == 524174)
assert(P_generic(2, xmpz(524174)) == 274758382274)
assert(P_generic(2, xmpz(17060344526)) == 291055355345818164674)
assert(P_generic(2, xmpz(291055355345818164674)) == 84713219875480482488869261558493781526274)
assert(P_generic(2, xmpz(84713219875480482488869261558493781526274)) == 7176329621671501453076568852489247776568376218009120175741348930545473480952323074)

# Cache some values
def is_riesel_prime(k, n):
    b = 2
    N = mpz((k * (b ** n)) -1)
    precision = b * k * 8
    gmpy2.get_context().precision = precision 
    print("N digits = {} precision {} bits".format(N.num_digits(), precision))

    assert(k % 2 == 1)
    assert(k < 2 ** n)
    assert(b % 2 == 0)
    assert(b % 3 != 0)
    assert(N % 3 != 0)
    # assert(k % 6 == 1 or k % 6 == 5)
    assert(k < b ** n)
    assert(n > 2)

    b = mpz(b)
    k = mpz(k)
    s = s0 = P_generic(b * k // 2, P_generic(b // 2, xmpz(4)))

    if s.num_digits() > 20:
        print("s0: digits ", s.num_digits(10))
    else:
        print("s0: ", s)

    begin = time.time()
    for i in range(1, n - 1):
        s1 = time.time()
        s **= 2
        e1 = time.time()

        s2 = time.time()
        s -= 2
        e2 = time.time()

        s3 = time.time()
        if i % 1 == 0:
            s %= N
        e3 = time.time()

        stats['**'] += e1 - s1
        stats['-'] += e2 - s2
        stats['%'] += e3 - s3

        if i % 10000 == 0:
            print(i, "/", n)

    end = time.time() - begin
    print("core took {:5.5f}ms".format(end * 1000))
    for op, took in stats.items():
        print("op {} took {:5.2f}ms".format(op, took * 1000))
    return s == 0

if __name__ == '__main__':
    start = time.time()
    k = 0 if len(sys.argv) == 1 else int(sys.argv[1])
    n = 0 if len(sys.argv) == 2 else int(sys.argv[2])
    if k == 0 or n == 0:
        print("give two (smallish) numbers as arguments")
        exit(1)
    result = is_riesel_prime(k, n)
    print("{}*2^{}-1 = {}".format(k, n, result))
    end = time.time()

    print("time: {:5.2f}ms".format((end - start) * 1000))

