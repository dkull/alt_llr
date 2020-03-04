const c = @import("c.zig");
const gw = c.gw;
const gmp = c.gmp;

const std = @import("std");
const log = std.debug.warn;
const stdout = &std.io.getStdOut().outStream().stream;

const glue = @import("glue.zig");
const u_zero = @import("u_zero.zig");

const VERSION = "0.0.1";


// required precision 102765*2^333354[100355 digits] == 1KB*227 (0.44)
// required precision     81*2^240743[72473 digits] == 130 (0.62)
// required precision  17295*2^217577[65502 digits] == 1KB*54 (0.31) [fft 16K]
// required precision 39547695*2^454240[136748 digits] == 1MB*86 (0.43) [fft 48K]

pub fn main() !void {
    try stdout.print("=== RPT - Riesel Prime Tester v{} [GWNUM: {} GMP: {}.{}.{}] ===\n", .{ VERSION, gw.GWNUM_VERSION , gmp.__GNU_MP_VERSION, gmp.__GNU_MP_VERSION_MINOR, gmp.__GNU_MP_VERSION_MINOR });

    const k: u32 = 39547695;
    const b: u32 = 2;
    const n: u32 = 454240;
    const c_: i32 = -1;

    try stdout.print("LLR testing: {}*{}^{}{}\n", .{ k, b, n, c_ });

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
    u_zero.find_rodseth_u0(k, n, &u0_gmp);
    log("s0 took {}ms\n", .{ std.time.milliTimestamp() - start });

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
    log("llr took {}ms\n", .{ std.time.milliTimestamp() - start });

    if (gw.gwiszero(&ctx, u) == 1) {
        try stdout.print("is prime\n", .{});
    } else {
        try stdout.print("is not prime\n", .{});
    }
}

