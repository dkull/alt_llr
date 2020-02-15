import gmpy2
from gmpy2 import *
import llr
from llr import P_generic

cases = {
    1999: [29, 53, 131, 179, 215, 219, 429, 669, 831, 1131, 1263, 1703, 3029, 5141],
    #2001: [26, 29, 34, 39, 50, 53, 71, 93, 119, 169, 211, 213, 513, 551, 809, 1081, 1106, 1226, 1923, 2071, 2123, 2141, 2811, 3291, 4617, 4857, 5257, 5714, 7153, 7801, 80631]
}

for k, ns in cases.items():
    for n in ns:
        print("testcase >>>", k, n)
        result = llr.is_riesel_prime(k, n)
        assert(result == True)
        result = llr.is_riesel_prime(k, n + 2)
        assert(result == False)

# raise the precision so at least our tests pass
gmpy2.get_context().precision=2 ** 10
assert(pow(xmpz(2), xmpz(3)) == 8)
assert(pow(xmpz(7), xmpz(31)) == 157775382034845806615042743)
# k:5 b:2 n:32
# N = k * 2 ^ 32 - 1 = 21474836479
assert(P_generic(1, xmpz(4)) == 4)
assert(P_generic(5, xmpz(4)) == 724)
assert(P_generic(2, xmpz(724)) == 524174)
assert(P_generic(2, xmpz(524174)) == 274758382274)
assert(P_generic(2, xmpz(17060344526)) == 291055355345818164674)
assert(P_generic(2, xmpz(291055355345818164674)) == 84713219875480482488869261558493781526274)
assert(P_generic(2, xmpz(84713219875480482488869261558493781526274)) == 7176329621671501453076568852489247776568376218009120175741348930545473480952323074)
