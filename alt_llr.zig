const std = @import("std");
const log = std.debug.warn;

const gw = @cImport(@cInclude("gwnum.h"));

pub fn main() void {
    const k: u32 = 1;
    const b: u32 = 2;
    const n: u32 = 216091;
    const c: i32 = -1;
    var s0: f64 = 4.0;

    var ctx: gw.gwhandle = undefined;
    gw.gwinit2(&ctx, @bitSizeOf(gw.gwhandle) / 8, gw.GWNUM_VERSION);
    const _na = gw.gwsetup(&ctx, k, b, n, c);

    // init s0
    const s: gw.gwnum = gw.gwalloc(&ctx);
    gw.dbltogw(&ctx, s0, s);

    // init constant 2 for subtraction
    const gwnum_2 = gw.gwalloc(&ctx);
    gw.dbltogw(&ctx, 2.0, gwnum_2);

    var i: u32 = 1;
    while (i < n - 1) {
        //if (i % 10000 == 0) {
        //    log("progress {}%\n", .{ (i * 100 / (n - 1)) });
        //} 
        gw.gwsquare2(&ctx, s, s);
        gw.gwsub3quick(&ctx, s, gwnum_2, s);
        i += 1;
    }
    if (gw.gwiszero(&ctx, s) == 1) {
        log("is prime\n", .{});
    } else {
        log("is not prime\n", .{});
    }
}

