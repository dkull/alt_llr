const std = @import("std");
const stderr = std.debug.warn;

const c = @import("c.zig");
const gmp = c.gmp;
const gw = c.gw;

pub fn gmp_to_gw(in: gmp.mpz_t, out: gw.gwnum, out_ctx: *gw.gwhandle) void {
    const word_size: usize = 4;
    // FIXME: max stack size is a thing
    const buf_size: usize = 1000000;
    var buf: [buf_size]u32 = undefined;
    var count: usize = 0;
    const void_ = gmp.mpz_export(&buf, &count, -1, word_size, 0, 0, &in);
    if (count < 0) {
        stderr("gmp_to_gw copy error {}\n", .{count});
    }
    gw.binarytogw(out_ctx, &buf, @intCast(u32, count), out);
}
