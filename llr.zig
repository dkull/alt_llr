const std = @import("std");
const log = std.debug.warn;
const stdout = &std.io.getStdOut().outStream().stream;
const assert = @import("std").debug.assert;
const fmt = @import("std").fmt;

const c = @import("c.zig");
const gw = c.gw;
const gmp = c.gmp;

const glue = @import("glue.zig");
const u_zero = @import("u_zero.zig");
const test_data = @import("test_data.zig");
const helper = @import("helper.zig");

pub fn get_residue(ctx: *gw.gwhandle, u: gw.gwnum, output: *[32]u8) !void {
    var gdata = ctx.gdata;
    // FIXME: this 0 needs to be size of giants buffer
    var g: gw.giant = gw.popg(&gdata, 0);
    const success = gw.gwtogiant(ctx, u, g);
    //log("bitlen {}\n", .{gw.bitlen(g)});
    const succ = try fmt.bufPrint(output, "{X:0>8}{X:0>8}", .{ g.*.n[1], g.*.n[0] });
}

pub fn full_llr_run(k: u32, b: u32, n: u32, c_: i32, threads_: u8) !bool {
    // calculate N for Jacobi
    var N: gmp.mpz_t = u_zero.calculate_N(k, n);
    const n_digits = gmp.mpz_sizeinbase(&N, 10);

    log("LLR testing: {}*{}^{}{} [{} digits] on {} threads\n", .{ k, b, n, c_, n_digits, threads_ });

    // calculate U0
    try stdout.print("step #1 find U0 ...\n", .{});
    var u0_gmp: gmp.mpz_t = undefined;
    try u_zero.find_u0(k, n, N, &u0_gmp);

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
    try stdout.print("FFT size {}KB\n", .{fft_size});
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
    var errored = false;
    var near_fft = false;
    const i_penultimate: u32 = n - 1;
    // this subtracts 2 after every squaring
    gw.gwsetaddin(&ctx, -2);
    while (i < i_penultimate) : (i += 1) {
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

        // gwstartnextfft may ruin the results if run under
        // incorrect conditions. -31 and -30 seem to work (copied from LLR64)
        if (i >= 30 and i < @intCast(i32, i_penultimate - 31)) {
            gw.gwstartnextfft(&ctx, 1);
        } else {
            gw.gwstartnextfft(&ctx, 0);
        }
        if (i >= 30 and i < @intCast(i32, i_penultimate - 30)) {
            gw.gwsquare2(&ctx, u, u);
        } else {
            gw.gwsquare2_carefully(&ctx, u, u);
        }

        // check if near fft limit
        if (gw.gwnear_fft_limit(&ctx, 0.5) != 0) {
            ctx.NORMNUM = 1;
            if (!near_fft) {
                log("WARNING: near FFT limit @ {}\n", .{i});
                near_fft = true;
            }
        }

        // error_check
        if (near_fft) {
            if (gw.gw_test_illegal_sumout(&ctx) != 0) {
                errored = true;
                log("ERROR: illegal sumout @ {}\n", .{i});
            }
            if (gw.gw_test_mismatched_sums(&ctx) != 0) {
                errored = true;
                log("ERROR: mismatched sums @ {}\n", .{i});
            }
            if (gw.gw_get_maxerr(&ctx) >= 0.40) {
                errored = true;
                log("ERROR: maxerr > 0.4 @ {} = {}\n", .{ i, gw.gw_get_maxerr(&ctx) });
            }
        }
    }
    // math logging condition
    if (n >= 10000) {
        try stdout.print("X\n", .{});
    }

    const llr_took = std.time.milliTimestamp() - llr_start;
    try stdout.print("LLR took {}ms\n", .{llr_took});

    const maybe = if (errored) "maybe " else "";
    const residue_zero = gw.gwiszero(&ctx, u) == 1;
    if (residue_zero) {
        log("#> {}*{}^{}{} [{} digits] IS {}PRIME\n", .{ k, b, n, c_, n_digits, maybe });
    } else {
        var residue: [32]u8 = undefined;
        try get_residue(&ctx, u, &residue);
        log("#> {}*{}^{}{} [{} digits] is {}not prime. LLR Res64: {}\n", .{ k, b, n, c_, n_digits, maybe, residue });
    }
    return residue_zero;
}
