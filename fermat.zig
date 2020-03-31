const std = @import("std");
const log = std.debug.warn;
const stdout = &std.io.getStdOut().outStream();
const assert = @import("std").debug.assert;
const fmt = @import("std").fmt;

const c = @import("c.zig");
const gw = c.gw;
const gmp = c.gmp;

const glue = @import("glue.zig");
const helper = @import("helper.zig");
const u_zero = @import("u_zero.zig");

pub fn full_fermat_run(k: u32, b: u32, n: u32, c_: i32, threads_: u8) !bool {
    const PRP_BASE: usize = 2;
    var N: gmp.mpz_t = u_zero.calculate_N(k, n);

    const n_digits = gmp.mpz_sizeinbase(&N, 10);
    log("Fermat-PRP testing: {}*{}^{}{} [{} digits] on {} threads\n", .{ k, b, n, c_, n_digits, threads_ });

    var N_min_1: gmp.mpz_t = undefined;
    gmp.mpz_init_set(&N_min_1, &N);
    gmp.mpz_sub_ui(&N_min_1, &N_min_1, 1);
    const N_min_1_bits = gmp.mpz_sizeinbase(&N_min_1, 2);

    var gmp_one: gmp.mpz_t = undefined;
    gmp.mpz_init_set_ui(&gmp_one, 1);

    var gmp_base: gmp.mpz_t = undefined;
    gmp.mpz_init_set_ui(&gmp_base, PRP_BASE);

    var ctx: gw.gwhandle = undefined;
    helper.create_gwhandle(&ctx, threads_, k, n);

    var buf: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(gmp_one, buf, &ctx);

    var gw_base: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(gmp_base, gw_base, &ctx);

    var i: usize = N_min_1_bits - 1;
    //var testdata = [2]usize{ 0, 0 };
    while (i < 0xFFFFFFFF) : (i -= 1) {
        const bit_set = gmp.mpz_tstbit(&N_min_1, i) == 1;
        const start_next = i > 60 and i < N_min_1_bits - 60;
        if (bit_set) {
            // mult by prp base after squaring
            //gw.gwsetmulbyconst(&ctx, PRP_BASE);
        }
        //if (start_next) {
        //    gw.gwstartnextfft(&ctx, 1);
        //} else {
        //    gw.gwstartnextfft(&ctx, 0);
        //}
        if (start_next or i == 60) {
            gw.gwsquare2(&ctx, buf, buf);
        } else {
            gw.gwsquare2_carefully(&ctx, buf, buf);
        }
        //if (start_next) {
        //    gw.gwstartnextfft(&ctx, 1);
        //} else {
        //    gw.gwstartnextfft(&ctx, 0);
        //}
        if (bit_set) {
            gw.gwsmallmul(&ctx, PRP_BASE, buf);
            //gw.gwsetmulbyconst(&ctx, 0);
        }
        if (start_next) {}
    }
    var gw_one: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(gmp_one, gw_one, &ctx);

    var is_prp = gw.gwequal(&ctx, buf, gw_one);
    if (is_prp == 1) {
        const maybe = "maybe";
        log("#> {}*{}^{}{} [{} digits] IS PROBABLY PRIME\n", .{ k, b, n, c_, n_digits });
    } else {
        log("#> {}*{}^{}{} [{} digits] is not prime ({})\n", .{
            k,
            b,
            n,
            c_,
            n_digits,
            is_prp,
        });
    }
    return is_prp == 1;
}
