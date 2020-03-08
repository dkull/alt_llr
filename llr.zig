const std = @import("std");
const log = std.debug.warn;
const stdout = &std.io.getStdOut().outStream().stream;
const assert = @import("std").debug.assert;

const c = @import("c.zig");
const gw = c.gw;
const gmp = c.gmp;

const glue = @import("glue.zig");
const u_zero = @import("u_zero.zig");
const test_data = @import("test_data.zig");
const helper = @import("helper.zig");

pub fn full_llr_run(k: u32, b: u32, n: u32, c_: i32, threads_: u8) !bool {
    // calculate N for Jacobi
    var N: gmp.mpz_t = u_zero.calculate_N(k, n);
    const n_digits = gmp.mpz_sizeinbase(&N, 10);

    log("LLR testing: {}*{}^{}{} [{} digits] on {} threads\n", .{ k, b, n, c_, n_digits, threads_ });

    // calculate U0
    try stdout.print("step #1 find U0 ...\n", .{});
    var u0_gmp: gmp.mpz_t = undefined;
    u_zero.find_u0(k, n, N, &u0_gmp);

    // print the u0 if it's small enough
    if (n_digits <= 8) {
        try stdout.print("U0: {}\n", .{gmp.mpz_get_ui(&u0_gmp)});
    }

    // use given threadcount or determine the fastest one using benchmarking
    const threads: u8 = blk: {
        if (threads_ > 0) {
            break :blk threads_;
        }
        try stdout.print("step #1.5 benchmark threadcount ...\n", .{});
        break :blk helper.benchmark_threads(u0_gmp, k, n);
    };

    // create gwnum context for LLR core loop
    var ctx: gw.gwhandle = undefined;
    helper.create_gwhandle(&ctx, threads, k, n);

    // print and check fft size
    const fft_size = gw.gwfftlen(&ctx) / 1024;
    try stdout.print("FFT size {}KB", .{fft_size});
    //if (threads > 1) {
    //    if (fft_size / threads < MIN_THREAD_FFT_KB) {
    //        try stdout.print(" [WARNING: Possibly too many threads for this FFT size]", .{});
    //    }
    //}
    //try stdout.print("\n", .{});

    // move U0 from gmp to gw
    // this has to be the first gwalloc to get large pages
    // TODO: Verify we got large pages
    var u: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(u0_gmp, u, &ctx);

    try stdout.print("step #2 LLR test ...\n", .{});
    const llr_start = std.time.milliTimestamp();
    // core LLR loop
    var i: usize = 1;
    var next_log_i = i;
    // this subtracts 2 after every squaring
    gw.gwsetaddin(&ctx, -2);
    while (i < n - 1) : (i += 1) {
        if (i == next_log_i and n >= 10000) {
            const pct: usize = @intCast(usize, (i * 100 / @intCast(usize, (n - 1))));
            if (pct % 10 != 0) {
                if (pct % 2 == 0) {
                    try stdout.print(".", .{});
                }
            } else {
                try stdout.print("{}", .{pct / 10});
            }
            // log again on next percent
            next_log_i = ((n / 100) * (pct + 1)) + (n / 200 * 1);
        }
        gw.gwsquare2(&ctx, u, u);
        // provides a speed boost
        gw.gwstartnextfft(&ctx, 1);
    }
    try stdout.print("X\n", .{});
    const llr_took = std.time.milliTimestamp() - llr_start;
    try stdout.print("LLR took {}ms\n", .{llr_took});

    const residue_zero = gw.gwiszero(&ctx, u) == 1;
    if (residue_zero) {
        log("#> {}*{}^{}{} [{} digits] IS PRIME\n", .{ k, b, n, c_, n_digits });
    } else {
        log("#> {}*{}^{}{} [{} digits] is not prime\n", .{ k, b, n, c_, n_digits });
    }
    return residue_zero;
}
