const std = @import("std");
const log = std.debug.warn;
const stdout = &std.io.getStdOut().outStream().stream;
const assert = @import("std").debug.assert;

const c = @import("c.zig");
const gw = c.gw;
const gmp = c.gmp;

const glue = @import("glue.zig");
const u_zero = @import("u_zero.zig");

const VERSION = "0.0.1";

// required precision 102765*2^333354[100355 digits] == 1KB*227 (0.44)
// required precision     81*2^240743[72473 digits] == 130 (0.62)
// required precision  17295*2^217577[65502 digits] == 1KB*54 (0.31) [fft 16K]
// required precision 39547695*2^454240[136748 digits] == 1MB*86 (0.43) [fft 48K]
// required precision 133603707*2^100014[136748 digits] == 350?-425+MB

pub fn full_llr_run(k_: u32, b: u32, n: u32, c_: i32) !bool {
    try stdout.print("LLR testing: {}*{}^{}{}\n", .{ k_, b, n, c_ });

    const k = @intToFloat(f64, k_);

    // create gwnum context
    var ctx: gw.gwhandle = undefined;
    gw.gwinit2(&ctx, @sizeOf(gw.gwhandle), gw.GWNUM_VERSION);

    // gwnum magic for speed and (un)safety
    //ctx.safety_margin = -1.0;
    ctx.use_large_pages = 1;
    gw.gwset_square_carefully_count(&ctx, -1);

    // tell gwnum in what modulus are we calculating
    const _na = gw.gwsetup(&ctx, k, b, n, c_);

    // calculate u0
    var u0_gmp: gmp.mpz_t = undefined;
    log("find s0...\n", .{});
    var start = std.time.milliTimestamp();
    u_zero.find_rodseth_u0(k_, n, &u0_gmp);
    log("s0 took {}ms\n", .{std.time.milliTimestamp() - start});

    const u_zero_length = gmp.mpz_sizeinbase(&u0_gmp, 10);
    if (u_zero_length < 7) {
        log("u0: {}\n", .{gmp.mpz_get_ui(&u0_gmp)});
    }
    log("found u0 {} digits\n", .{u_zero_length});

    // moved u0 from gmp to gw
    var u: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(u0_gmp, u, &ctx);

    start = std.time.milliTimestamp();
    var i: i32 = 1;
    while (i < n - 1) {
        //if (i % 10000 == 0) {
        //    log("progress {}%\n", .{ (i * 100 / (n - 1)) });
        //}
        gw.gwsetaddin(&ctx, -2);
        gw.gwsquare2(&ctx, u, u);
        i += 1;
    }
    log("llr took {}ms\n", .{std.time.milliTimestamp() - start});

    if (gw.gwiszero(&ctx, u) == 1) {
        try stdout.print("is prime\n", .{});
        return true;
    } else {
        try stdout.print("is not prime\n", .{});
        return false;
    }
}

pub fn main() !void {
    try stdout.print("=== RPT - Riesel Prime Tester v{} [GWNUM: {} GMP: {}.{}.{}] ===\n", .{ VERSION, gw.GWNUM_VERSION, gmp.__GNU_MP_VERSION, gmp.__GNU_MP_VERSION_MINOR, gmp.__GNU_MP_VERSION_MINOR });

    //const k: u32 = 39547695;
    const k: u32 = 133603707;
    const b: u32 = 2;
    //const n: u32 = 454240;
    const n: u32 = 100014;
    const c_: i32 = -1;

    if (true) {
        const success = selftest(1000000);
    } else {
        const is_prime = full_llr_run(k, b, n, c_);
    }
}

const primes = [2][29]u32{
    .{ 1, 3, 3, 5, 7, 13, 17, 19, 31, 61, 89, 107, 127, 521, 607, 1279, 2203, 2281, 3217, 4253, 4423, 9689, 9941, 11213, 19937, 21701, 23209, 44497, 0 },
    .{
        11,
        26,
        50,
        54,
        126,
        134,
        246,
        354,
        362,
        950,
        1310,
        2498,
        6926,
        11826,
        31734,
        67850,
        74726,
        96150,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
    },
};

pub fn selftest(max_n: u32) !void {
    var current_k: u32 = 0;
    for (primes) |prime_line| {
        for (prime_line) |number, i| {
            if (i == 0) {
                current_k = number;
                continue;
            }
            if (number == 0) {
                continue;
            }
            if (number > max_n) {
                continue;
            }
            log("testing k: {} n: {}\n", .{
                current_k,
                number,
            });
            const is_prime = try full_llr_run(current_k, 2, number, -1);
            if (is_prime != true) {
                log("TEST FAILED\n", .{});
                return;
            }
        }
    }
}
