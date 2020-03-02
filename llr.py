import sys
import time
import math
from collections import defaultdict
from sys import exit

import gmpy2
from gmpy2 import mpz, xmpz, mpfr, sqrt, c_mod, add, sub, mul, powmod, round2, round_away, divexact, is_prime
from numpy.polynomial.chebyshev import chebval

stats = defaultdict(lambda: 0)

sqrt4 = mpfr(sqrt(4))
mpfr22 = mpfr(2 ** -2)
def P_generic(m, _x, debug=False):
    """
        Used for finding s0, this is a generic implementation because m might be any value
        and optimizations aren't needed anyway since this is called once per number.

        Algorithm found in: https://vixra.org/pdf/1303.0195v1.pdf

        Test data can ve verified using:
        # for checking s0 for k=2001 b=2
        https://www.wolframalpha.com/input/?i=2+*+chebyshevT%282*2001%2F2%2C+chebyshevT%282%2F2%2C+2%29%29
    """
    m = mpz(m)
    x = mpz(_x)
    a = mpfr(mpfr(2)**-m)

    inner = pow(x, mpz(2))
    inner -= mpz(4)
    inner = sqrt(inner)
    #inner = x - (sqrt4 / x)  # potential replacement in cases x >= 5

    x += inner
    x **= m
    x *= a
    result = xmpz(round_away(x))

    #if debug:
    #    print("P: {} {} => {}".format(m, _x, x))

    return result


# Cache some values
def is_riesel_prime(k, n, debug=False):
    b = 2
    precision = b * n * 8
    gmpy2.get_context().precision = precision

    b = mpz(b)
    N = mpz((k * (b ** n)) - 1)
    if debug:
        print("N digits = {} precision {} bits".format(N.num_digits(), precision))
        if N.num_digits() < 20:
            print("N = ", N)

    assert(k % 2 == 1)
    assert(k < 2 ** n)
    assert(b % 2 == 0)
    assert(b % 3 != 0)
    assert(N % 3 != 0)
    assert(k % 6 in (1, 5))
    assert(k < b ** n)
    assert(n > 2)

    mpz2 = mpz(2)

    k = mpz(k)
    # s0
    begin = time.time()
    s = P_generic(b * k // mpz2, P_generic(b // mpz2, mpz(4), debug), debug)
    s %= N

    # WRITE TO FILE
    foob = int(s)
    byte_count = int(foob.bit_length()/8) + 1
    while byte_count % 4 != 0:
        byte_count += 1
    out = foob.to_bytes(byte_count, byteorder='little')
    f = open("{}.s0".format(int(k)), "wb")
    #f.write(int(k).to_bytes(4, byteorder='big'))
    f.write(out)
    f.close()
    # WRITE TO FILE END

    diff = time.time() - begin
    if debug:
        print("s0: calculated in {:3.4f}s".format(diff))

    # reduce precision, we do not need it in mainloop
    precision = 100

    if debug:
        if s.num_digits() > 20:
            print("s0: {} digits last 10 digits: ...{}".format(s.num_digits(10), str(s)[-10:]))
        else:
            print("s0: ", s)

    begin = time.time()
    for i in range(1, n - 1):
        #s1 = time.time()
        s **= mpz2 
        #e1 = time.time()

        #s2 = time.time()
        s -= mpz2
        #e2 = time.time()

        #s3 = time.time()
        s %= N
        #e3 = time.time()
        #if debug:
        #    print("s", i, " => ", s)

        #stats['**'] += e1 - s1
        #stats['-'] += e2 - s2
        #stats['%'] += e3 - s3

        if debug:
            if i % 10000 == 0:
                print(i, "/", n)

    end = time.time() - begin
    if debug:
        print("core took {:5.5f}ms".format(end * 1000))
        for op, took in stats.items():
            print("op {} took {:5.2f}ms".format(op, took * 1000))
    return s == 0

# sanity check
assert(is_riesel_prime(1999, 5141))

if __name__ == '__main__':
    start = time.time()
    k = 0 if len(sys.argv) == 1 else int(sys.argv[1])
    n = 0 if len(sys.argv) == 2 else int(sys.argv[2])
    if k == 0 or n == 0:
        print("give two (smallish) numbers as arguments")
        exit(1)
    result = is_riesel_prime(k, n, debug=True)
    print("{}*2^{}-1 = {}".format(k, n, result))
    end = time.time()

    print("time: {:5.2f}ms".format((end - start) * 1000))

