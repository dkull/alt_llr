const std = @import("std");
const log = std.debug.warn;

const c = @import("c.zig");
const gmp = c.gmp;
const gw = c.gw;

const glue = @import("glue.zig");

/// caller owns the result
pub fn calculate_N(k: u32, n: u32) gmp.mpz_t {
    var N: gmp.mpz_t = undefined;
    gmp.mpz_init(&N);
    // set N to Riesel number base at first
    gmp.mpz_set_ui(&N, 2);
    // raise b^n
    gmp.mpz_pow_ui(&N, &N, n);
    // multiply with k
    gmp.mpz_mul_ui(&N, &N, k);
    // and subtract the 1
    gmp.mpz_sub_ui(&N, &N, 1);
    return N;
}

pub fn find_V1(N: gmp.mpz_t) u32 {
    var minus: gmp.mpz_t = undefined;
    var plus: gmp.mpz_t = undefined;
    gmp.mpz_init(&minus);
    gmp.mpz_init(&plus);

    var V1: u32 = 1;
    while (V1 < 1000) {
        gmp.mpz_set_ui(&minus, V1 - 2);
        gmp.mpz_set_ui(&plus, V1 + 2);
        const minus_val = gmp.mpz_jacobi(&minus, &N);
        const plus_val = gmp.mpz_jacobi(&plus, &N);
        if (minus_val == 1 and plus_val == -1) {
            gmp.mpz_clear(&minus);
            gmp.mpz_clear(&plus);
            return V1;
        }
        V1 += 1;
    }
    unreachable;
}

/// currently used as the fastest solution even for large k's
/// total ripoff from Jean Penne's LLR64 Llr.c
/// FIXME: use gwnum here? would be totally free of GMP
pub fn do_fastest_lucas_sequence(k: u32, _P: u32, Q: u32, N: gmp.mpz_t) gmp.mpz_t {
    var k_tmp: gmp.mpz_t = undefined;
    gmp.mpz_init(&k_tmp);
    gmp.mpz_set_ui(&k_tmp, k);
    const k_bitlen: usize = gmp.mpz_sizeinbase(&k_tmp, 2);

    var x: gmp.mpz_t = undefined;
    var y: gmp.mpz_t = undefined;
    var one: gmp.mpz_t = undefined;

    //  init gmps
    gmp.mpz_init(&x);
    gmp.mpz_init(&y);
    gmp.mpz_init(&one);
    gmp.mpz_set_ui(&one, 1);

    // setup
    gmp.mpz_set_ui(&y, _P);
    gmp.mpz_set_ui(&x, _P);

    gmp.mpz_mul(&y, &y, &y);
    gmp.mpz_sub_ui(&y, &y, 2);
    gmp.mpz_powm(&y, &y, &one, &N);

    var i: u32 = @intCast(u32, @intCast(i32, k_bitlen) - 2);
    if (k <= 2) {
        // FIXME: understand why the value of i does not matter
        i = 0;
    }
    var one2: i32 = 1;
    while (i > 0) {
        // FIXME: dirty hack for 1<<i
        var mask: u32 = 1;
        var j: u32 = 0;
        while (j < i) {
            mask *= 2;
            j += 1;
        }
        const bit_is_set = (k & mask) != 0;
        if (bit_is_set) {
            // x = (x*y) - v1 mod N
            gmp.mpz_mul(&x, &x, &y);
            gmp.mpz_sub_ui(&x, &x, _P);
            gmp.mpz_powm(&x, &x, &one, &N);

            // y = (y * y) - 2 mod N
            gmp.mpz_mul(&y, &y, &y);
            gmp.mpz_sub_ui(&y, &y, 2);
            gmp.mpz_powm(&y, &y, &one, &N);
        } else {
            // y = (x*y) - v1 mod N
            gmp.mpz_mul(&y, &x, &y);
            gmp.mpz_sub_ui(&y, &y, _P);
            gmp.mpz_powm(&y, &y, &one, &N);

            // x = (x * x) - 2 mod N
            gmp.mpz_mul(&x, &x, &x);
            gmp.mpz_sub_ui(&x, &x, 2);
            gmp.mpz_powm(&x, &x, &one, &N);
        }
        // if k == 1
        if (i == 0) {
            break;
        }
        i -= 1;
    }
    // finish up: x *= y; x -= P; x %= N
    gmp.mpz_mul(&x, &x, &y);
    gmp.mpz_sub_ui(&x, &x, _P);
    gmp.mpz_powm(&x, &x, &one, &N);
    return x;
}

/// body method for do_fast_lucas_sequence
/// !!! slow - not used currently
fn fast(_m: u32, _x: u32, N: gmp.mpz_t) gmp.mpz_t {
    // required precision 102765*2^333354[100355 digits] == 1KB*227 (0.44)
    // required precision     81*2^240743[72473 digits] == 130 (0.62)
    // required precision  17295*2^217577[65502 digits] == 1KB*54 (0.31) [fft 16K]
    // required precision 39547695*2^454240[136748 digits] == 1MB*86 (0.43) [fft 48K]
    // required precision 133603707*2^100014[136748 digits] == 350?-425+MB
    const start = std.time.milliTimestamp();

    var one: gmp.mpf_t = undefined;
    gmp.mpf_init(&one);
    gmp.mpf_set_ui(&one, 1);

    var x: gmp.mpf_t = undefined;
    var a: gmp.mpf_t = undefined;
    var inner: gmp.mpf_t = undefined;
    var buf: gmp.mpf_t = undefined;

    // we do not automatigally calculate the required precision, but it seems
    // to be a function of at least 2 numbers. 1 is k, the other is? [haven't got to it yet]
    // this number will be unusably large for k's in the millions
    const super_precision: u32 = 1024;

    // initialize structs
    gmp.mpf_init2(&x, super_precision);
    gmp.mpf_init(&a);
    gmp.mpf_init2(&inner, super_precision);
    gmp.mpf_init(&buf);

    // write some default values
    gmp.mpf_set_ui(&x, @intCast(u64, _x));

    // do the inner calculation first
    // srt((x^2)-4) == sqrt((x+2)(x-2))
    // alt: x - (sqrt(4) / x)  # seems to work on larger numbers, also fails a lot
    gmp.mpf_pow_ui(&inner, &x, 2);
    gmp.mpf_sub_ui(&inner, &inner, 4);
    gmp.mpf_sqrt(&inner, &inner);

    // do deep negative exponentiation
    // 2^-m
    gmp.mpf_set_ui(&a, 2);
    gmp.mpf_div(&a, &one, &a);
    gmp.mpf_pow_ui(&a, &a, _m);

    // do the core calculation
    // ceil [ ((x + inner)^m*a) ]
    // ~= y=[x + sqrt((x^2)-4)] [ y^m / 2^m ]
    // move pow and mul earlier. use mod pow, b/c m is huge and is a power

    gmp.mpf_add(&x, &x, &inner);
    gmp.mpf_set_prec(&x, 63);
    gmp.mpf_pow_ui(&x, &x, _m);
    gmp.mpf_mul(&x, &x, &a);
    gmp.mpf_ceil(&x, &x);

    var result: gmp.mpz_t = undefined;
    gmp.mpz_init(&result);
    gmp.mpz_set_f(&result, &x);

    return result;
}

/// https://vixra.org/pdf/1303.0195v1.pdf
/// i figured it out on my own that the constant 4 in Pb/2(4) is actually the P
/// value we found with the Jacoby symbol. so this is a general u0 finder
/// if you have the Jacoby calculation results
/// currently unused as it requires too much floating precision with large k's
/// and thus get's unbearably slow with k's in the millions
/// caller owns the result
/// !!! slow - not used currently
pub fn do_fast_lucas_sequence(k: u32, _P: u32, Q: u32, N: gmp.mpz_t) gmp.mpz_t {
    // P_generic(b * k // mpz2, P_generic(b // mpz2, mpz(4), debug), debug)
    var P: gmp.mpz_t = undefined;
    gmp.mpz_init(&P);
    gmp.mpz_set_ui(&P, _P);

    // technically it should be b / 2', but b is 2 for us, so just '1'
    const inner = fast(1, _P, N);
    const buf = @intCast(u32, gmp.mpz_get_ui(&inner));
    // technically it should be 'b * k / 2', but b is 2 for us, so just 'k'
    const result = fast(k, buf, N);

    // result is actually a working u0
    return result;
}

/// caller owns the result
/// !!! slow - not used currently
pub fn do_iterative_lucas_sequence(k: u32, P: u32, Q: u32, N: gmp.mpz_t) gmp.mpz_t {
    // Vk(P,1) mod N ==
    //  xn = P * Xn-1 - Q * xn-2
    var luc_min2: gmp.mpz_t = undefined;
    var luc_min1: gmp.mpz_t = undefined;
    gmp.mpz_init(&luc_min2);
    gmp.mpz_init(&luc_min1);
    gmp.mpz_set_ui(&luc_min2, 2); // 2
    gmp.mpz_set_ui(&luc_min1, P); // P

    var buf: gmp.mpz_t = undefined;
    gmp.mpz_init(&buf);
    gmp.mpz_set_ui(&buf, 0);

    var temp_k: u34 = k;
    while (temp_k > 2) {
        const new = temp_k / 2;
        var new_partner = new;
        if (temp_k % 2 != 0) {
            new_partner += 1;
        }
        temp_k = new;
    }

    var i: u32 = 2;
    while (i <= k) {
        // use luc_min2 as temporary buffer
        gmp.mpz_mul_ui(&luc_min2, &luc_min2, Q);
        gmp.mpz_mul_ui(&buf, &luc_min1, P);
        gmp.mpz_sub(&buf, &buf, &luc_min2);
        // luc_min2 is now correct
        gmp.mpz_swap(&luc_min1, &luc_min2);
        // luc_min1 is now correct
        gmp.mpz_swap(&buf, &luc_min1);
        i += 1;
    }

    // move the result to buf (for clarity)
    if (k == 0) {
        // these assumes no loop iterations were done
        gmp.mpz_swap(&buf, &luc_min2);
    } else {
        gmp.mpz_swap(&buf, &luc_min1);
    }
    gmp.mpz_clear(&luc_min1);
    gmp.mpz_clear(&luc_min2);
    return buf;
}

pub fn find_u0(k: u32, n: u32, N: gmp.mpz_t, u_zero_out: *gmp.mpz_t) void {
    var V1: u32 = undefined;
    if (k % 3 != 0) {
        log("SHORTCUT: using V1=4 because [k % 3 != 0]\n", .{});
        V1 = 4;
    } else {
        // do the Jacobi to find V1
        const start_jacobi = std.time.milliTimestamp();
        V1 = find_V1(N);
        const jacobi_took = std.time.milliTimestamp() - start_jacobi;
        log("found V1: {} using Jacobi Symbols in {}ms\n", .{ V1, jacobi_took });
    }

    const start_lucas = std.time.milliTimestamp();

    // version 1 - slow
    // calculate and store lucas sequence - slow
    // does all the sequence steps in a loop
    //u_zero_out.* = do_iterative_lucas_sequence(k, V1, 1, N);

    // version 2 - slow
    // fast lucas sequence process does deep negative powers of k
    // and requires high precision - limiting with large k's
    //u_zero_out.* = do_fast_lucas_sequence(k, V1, 1, N);

    // version 3 - fast
    // is O(log(len(k)))
    u_zero_out.* = do_fastest_lucas_sequence(k, V1, 1, N);

    const lucas_took = std.time.milliTimestamp() - start_lucas;
    log("calculated Lucas Sequence in {}ms\n", .{lucas_took});

    // do the mod just in case it's not done
    gmp.mpz_mod(u_zero_out, u_zero_out, &N);
}
