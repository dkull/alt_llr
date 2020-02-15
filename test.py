import llr

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
