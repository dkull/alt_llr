const std = @import("std");
const log = std.debug.warn;

const gw = @cImport(@cInclude("gwnum.h"));

pub fn main() !void {
    const stdout = &std.io.getStdOut().outStream().stream;

    const k: u32 = 1;
    const b: u32 = 2;
    const n: u32 = 216091;
    const c: i32 = -1;
    // TODO: Hard! Calculate this for all k/b
    var s0: f64 = 4.0;

    var ctx: gw.gwhandle = undefined;
    gw.gwinit2(&ctx, @bitSizeOf(gw.gwhandle) / 8, gw.GWNUM_VERSION);

    // some magic for speed and (un)safety
    ctx.safety_margin = -2.0;
    ctx.use_large_pages = 1;
    gw.gwset_square_carefully_count(&ctx, -1);

    const _na = gw.gwsetup(&ctx, k, b, n, c);

    // init s0
    const s: gw.gwnum = gw.gwalloc(&ctx);
    gw.dbltogw(&ctx, s0, s);

    var i: i32 = 1;
    while (i < n - 1) {
        //if (i % 10000 == 0) {
        //    log("progress {}%\n", .{ (i * 100 / (n - 1)) });
        //} 
        gw.gwsetaddin(&ctx, -2);
        gw.gwsquare2(&ctx, s, s);
        i += 1;
    }

    if (gw.gwiszero(&ctx, s) == 1) {
        try stdout.print("is prime\n", .{});
    } else {
        try stdout.print("is not prime\n", .{});
    }
}

