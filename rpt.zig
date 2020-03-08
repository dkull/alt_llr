const std = @import("std");
const log = std.debug.warn;
const stdout = &std.io.getStdOut().outStream().stream;
const assert = @import("std").debug.assert;

const c = @import("c.zig");
const gw = c.gw;
const gmp = c.gmp;

const glue = @import("glue.zig");
const u_zero = @import("u_zero.zig");
const helper = @import("helper.zig");
const llr = @import("llr.zig");
const selftest = @import("selftest.zig");
const argparser = @import("argparser.zig");

const VERSION = "0.0.3";
const MIN_THREAD_FFT_KB = 128;

pub fn main() !void {
    try stdout.print("=== RPT - Riesel Prime Tester v{} [GWNUM: {} GMP: {}.{}.{}] ===\n", .{ VERSION, gw.GWNUM_VERSION, gmp.__GNU_MP_VERSION, gmp.__GNU_MP_VERSION_MINOR, gmp.__GNU_MP_VERSION_PATCHLEVEL });

    // the only malloc I make is for cmd args
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    // parse the few args we take
    const parsed_args: argparser.ParsedArgs = try argparser.ParsedArgs.parse(args);
    const k = parsed_args.k;
    const n = parsed_args.n;
    const threads = parsed_args.threads;

    // only riesel number support
    const b: u32 = 2;
    const c_: i32 = -1;

    const only_tests: u32 = 0;
    if (only_tests == 0) {
        const is_prime = llr.full_llr_run(k, b, n, c_, threads);
    } else {
        const success = selftest.run(1000000);
    }
}
