const std = @import("std");
const log = std.debug.warn;

const c = @import("c.zig");
const gmp = c.gmp;
const gw = c.gw;

const glue = @import("glue.zig");

const JacobiError = error {
    BadArguments   
};

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

pub fn find_P(N: gmp.mpz_t) u32 {
    var jacobi_input_minus: gmp.mpz_t = undefined;
    var jacobi_input_plus: gmp.mpz_t = undefined;
    gmp.mpz_init(&jacobi_input_minus);
    gmp.mpz_init(&jacobi_input_plus);
    
    var P: u32 = 5;
    while (P < 1000) {
        gmp.mpz_set_ui(&jacobi_input_minus, P - 2);
        gmp.mpz_set_ui(&jacobi_input_plus, P + 2);
        const jacobi_minus = gmp.mpz_jacobi(&jacobi_input_minus, &N);
        const jacobi_plus = gmp.mpz_jacobi(&jacobi_input_plus, &N);
        if (jacobi_minus == 1 and jacobi_plus == -1) {
            gmp.mpz_clear(&jacobi_input_minus);
            gmp.mpz_clear(&jacobi_input_plus);
            return P;
        }
        P += 1;
    }
    unreachable;
}

fn fast(_m: u32, _x: gmp.mpz_t) gmp.mpz_t {

    var one: gmp.mpf_t = undefined;
    gmp.mpf_init(&one);
    gmp.mpf_set_ui(&one, 1);

    var m: gmp.mpz_t = undefined;
    var x: gmp.mpz_t = undefined;
    var inner: gmp.mpz_t = undefined;

    var a: gmp.mpf_t = undefined;
    var float: gmp.mpf_t = undefined;
    var release: gmp.mpf_t = undefined;

    gmp.mpz_init(&m);
    gmp.mpz_init(&x);
    gmp.mpz_init(&inner);

    gmp.mpf_init(&a);
    // precision sets need to be exactly around float and release
    gmp.mpf_set_default_prec(1024*1024*87);
    gmp.mpf_init(&float);
    gmp.mpf_init(&release);
    gmp.mpf_set_default_prec(64);

    gmp.mpz_set_ui(&m, _m);
    gmp.mpz_set(&x, &_x);
    gmp.mpf_set_ui(&a, 2);

    gmp.mpf_div(&a, &one, &a);
    gmp.mpf_pow_ui(&a, &a, _m);
    
    gmp.mpz_pow_ui(&inner, &x, 2);
    gmp.mpz_sub_ui(&inner, &inner, 4);

    gmp.mpf_set_z(&float, &inner);
    gmp.mpf_sqrt(&float, &float);
    log("m {}\n", .{_m});

    gmp.mpf_set_z(&release, &x);
    gmp.mpf_add(&release, &release, &float);

    gmp.mpf_pow_ui(&release, &release, _m);
    gmp.mpf_mul(&release, &release, &a);

    gmp.mpf_ceil(&release, &release);

    // can be no earlier than here
    gmp.mpf_set_prec_raw(&float, 1024);
    gmp.mpf_set_prec_raw(&release, 1024);

    gmp.mpz_set_f(&x, &release);
    return x;
}

/// https://vixra.org/pdf/1303.0195v1.pdf
/// i figured it out on my own that the constant 4 in Pb/2(4) is actually the P
/// value we found with the Jacoby symbol. so this is a general u0 finder
/// if you have the Jacoby calculation results
/// caller owns the result
pub fn do_fast_lucas_sequence(k: u32, _P: u32, Q: u32, N: gmp.mpz_t) gmp.mpz_t {
    // P_generic(b * k // mpz2, P_generic(b // mpz2, mpz(4), debug), debug) 
    
    var P: gmp.mpz_t = undefined;
    gmp.mpz_init(&P);
    gmp.mpz_set_ui(&P, _P);

    // technically it should be b / 2', but b is 2 for us, so just '1'
    const inner = fast(1, P);
    // technically it should be 'b * k / 2', but b is 2 for us, so just 'k'
    const result = fast(k, inner);

    // result is actually a working u0
    return result;
}

/// caller owns the result
pub fn do_lucas_sequence(k: u32, P: u32, Q: u32, N: gmp.mpz_t) gmp.mpz_t {
    // TODO: use gwnum in here
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
        log("> {} -> {} {} ? {}\n", .{ temp_k, new, new_partner, new == new_partner });
        temp_k = new;
    }
    log("=========\n", .{});

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
        if (i < 32) {
            log("i:{} > {}\n", .{i, gmp.mpz_get_ui(&luc_min1)});
        }
        i += 1;
        if (i % 500 == 0) {
            gmp.mpz_mod(&luc_min2, &luc_min2, &N);
            gmp.mpz_mod(&luc_min1, &luc_min1, &N);
        }
        if (i % 1000000 == 0) {
            log("{} - {}%\n", .{ i, 100 * i / k });
        }
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

fn test_lucas() void {
    // notes i, i'
    // i' * j' == (i+j)' + (j-i)'
    // k=23 => 23//2 == (11,12). 11//2 == (5,6), 5//2 == (2,3)
    var N: gmp.mpz_t = calculate_N(100, 1000);
    var k: u32 = 0;
    var P: u32 = 7;
    while (k < 36) { 
        const foo: gmp.mpz_t = do_lucas_sequence(k, P, 1, N);
        log("> {} {}\n", .{ k, gmp.mpz_get_ui(&foo) });
        k += 1;
    }
}

pub fn find_rodseth_u0(k: u32, n: u32, u_zero_out: *gmp.mpz_t) void {
    // calculate N for Jacobi
    var N: gmp.mpz_t = calculate_N(k, n);
    log("N is {} digits\n", .{gmp.mpz_sizeinbase(&N, 10)});

    //test_lucas(); 

    var P: u32 = undefined;
    if (k % 3 != 0) {
        log("SHORTCUT: using P=4 because [k % 3 != 0]\n", .{});
        P = 4; 
    } else {
        // do the Jacobi to find P
        P = find_P(N);
        log("found P {} that satisfied the Jacobi symbols\n", .{ P });
    }

    // calculate and store lucas sequence
    //u_zero_out.* = do_lucas_sequence(k, P, 1, N);
    // fast lucas sequence process does deep negative powers of k
    //gmp.mpf_set_default_prec(k*2+(1024));
    u_zero_out.* = do_fast_lucas_sequence(k, P, 1, N);
    //gmp.mpf_set_default_prec(64);

    gmp.mpz_mod(u_zero_out, u_zero_out, &N);

    gmp.mpz_clear(&N);
}
