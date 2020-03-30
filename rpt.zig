const std = @import("std");
const stderr = std.debug.warn;
const stdout = &std.io.getStdOut().outStream();
const assert = @import("std").debug.assert;

const c = @import("c.zig");
const c_stdlib = c.c_stdlib;
const gw = c.gw;
const gmp = c.gmp;

const glue = @import("glue.zig");
const u_zero = @import("u_zero.zig");
const helper = @import("helper.zig");
const llr = @import("llr.zig");
const fermat = @import("fermat.zig");
const selftest = @import("selftest.zig");
const argparser = @import("argparser.zig");

const VERSION = "0.1.0";

pub fn main() !void {
    // let's be really nice
    const err = c_stdlib.setpriority(c_stdlib.PRIO_PROCESS, 0, 19);

    try stdout.print("=== RPT - Riesel Prime Tester v{} [GWNUM: {} GMP: {}.{}.{}] ===\n", .{ VERSION, gw.GWNUM_VERSION, gmp.__GNU_MP_VERSION, gmp.__GNU_MP_VERSION_MINOR, gmp.__GNU_MP_VERSION_PATCHLEVEL });

    // the only malloc I make is for cmd args
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    // parse the few args we take
    const parsed_args: argparser.ParsedArgs = try argparser.ParsedArgs.parse(args);
    const mode = parsed_args.mode;

    switch (mode) {
        argparser.RunMode.LLR => {
            const threads = parsed_args.threads;
            const k = parsed_args.k;
            const n = parsed_args.n;
            const b: u32 = 2;
            const c_: i32 = -1;
            const is_prime = try llr.full_llr_run(k, b, n, c_, threads);
        },
        argparser.RunMode.Fermat => {
            const threads = parsed_args.threads;
            const k = parsed_args.k;
            const n = parsed_args.n;
            const b: u32 = 2;
            const c_: i32 = -1;
            const is_prime = try fermat.full_fermat_run(k, b, n, c_, threads);
        },
        argparser.RunMode.Selftest => {
            const n = parsed_args.n;
            const success = selftest.run(n);
        },
        argparser.RunMode.Help => {
            try stdout.print("./rpt --llr <k> <n> [--threads <t>]\n", .{});
            try stdout.print("./rpt --selftest [--threads <t>]\n", .{});
        },
    }
}
