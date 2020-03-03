const std = @import("std");
const log = std.debug.warn;

const c = @import("c.zig");
const gmp = c.gmp;
const gw = c.gw;

pub fn gmp_to_gw(in: gmp.mpz_t, out: gw.gwnum, out_ctx: *gw.gwhandle) void {
    const word_size: usize = 4;
    const buf_size: usize = 200000;
    var buf: [buf_size]u32 = undefined; 
    var count: usize = 0;
    const written_count_or_error = gmp.mpz_export(&buf, &count, -1, word_size, 0, 0, &in);
    gw.binarytogw(out_ctx, &buf, @intCast(u32, count), out);
}
