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

const VERSION = "0.0.1";

pub fn full_llr_run(k_: u32, b: u32, n: u32, c_: i32, threads: u8) !bool {
    // calculate N for Jacobi
    var N: gmp.mpz_t = u_zero.calculate_N(k_, n);
    const n_digits = gmp.mpz_sizeinbase(&N, 10);

    try stdout.print("LLR testing: {}*{}^{}{} [{} digits] on {} threads\n", .{ k_, b, n, c_, n_digits, threads });

    const k = @intToFloat(f64, k_);

    // create gwnum context
    var ctx: gw.gwhandle = undefined;
    gw.gwinit2(&ctx, @sizeOf(gw.gwhandle), gw.GWNUM_VERSION);

    // gwnum magic for speed and (un)safety
    //ctx.safety_margin = -1.0;  // eg. if set to -1 then fails for 1*2^23209-1
    ctx.use_large_pages = 1;
    gw.gwset_square_carefully_count(&ctx, 50);
    ctx.num_threads = threads;
    ctx.will_hyperthread = threads;
    ctx.bench_num_cores = threads;
    ctx.will_error_check = 0;

    // set gwnum modulus to N
    const _na = gw.gwsetup(&ctx, k, b, n, c_);

    // calculate U0
    log("step 1. find U0 ...\n", .{});
    var u0_gmp: gmp.mpz_t = undefined;
    u_zero.find_u0(k_, n, N, &u0_gmp);

    // print the u0 if it's small enough
    if (n_digits <= 8) {
        log("U0: {}\n", .{gmp.mpz_get_ui(&u0_gmp)});
    }

    // move U0 from gmp to gw
    // this has to be the first gwalloc to get large pages
    var u: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(u0_gmp, u, &ctx);

    log("step 2. LLR test ...\n", .{});
    const llr_start = std.time.milliTimestamp();
    // core LLR loop
    var i: usize = 1;
    var next_log_i = i;
    while (i < n - 1) : (i += 1) {
        if (i == next_log_i and k >= 10000) {
            const pct: usize = @intCast(usize, (i * 100 / @intCast(usize, (n - 1))));
            if (pct % 10 != 0) {
                log(".", .{});
            } else {
                log("{}", .{pct / 10});
            }
            // log again on next percent
            next_log_i = ((n / 100) * (pct + 1)) + (n / 200 * 1);
        }
        gw.gwsetaddin(&ctx, -2);
        gw.gwsquare2(&ctx, u, u);
    }
    log("X\n", .{});
    const llr_took = std.time.milliTimestamp() - llr_start;
    log("LLR took {}ms\n", .{llr_took});

    const residue_zero = gw.gwiszero(&ctx, u) == 1;
    if (residue_zero) {
        try stdout.print("#> {}*{}^{}{} [{} digits] IS PRIME\n", .{ k_, b, n, c_, n_digits });
    } else {
        try stdout.print("#> {}*{}^{}{} [{} digits] is not prime\n", .{ k_, b, n, c_, n_digits });
    }
    return residue_zero;
}

pub fn main() !void {
    try stdout.print("=== RPT - Riesel Prime Tester v{} [GWNUM: {} GMP: {}.{}.{}] ===\n", .{ VERSION, gw.GWNUM_VERSION, gmp.__GNU_MP_VERSION, gmp.__GNU_MP_VERSION_MINOR, gmp.__GNU_MP_VERSION_PATCHLEVEL });

    // the only malloc I make is for cmd args
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    // use default k,n or take them from cmd args
    var k: u32 = 0;
    var n: u32 = 0;
    var threads: u8 = 1;
    if (args.len == 3) {
        k = @intCast(u32, try helper.parseU64(args[1], 10));
        n = @intCast(u32, try helper.parseU64(args[2], 10));
    } else if (args.len == 4) {
        k = @intCast(u32, try helper.parseU64(args[1], 10));
        n = @intCast(u32, try helper.parseU64(args[2], 10));
        threads = @intCast(u8, try helper.parseU64(args[3], 10));
    } else {
        // https://primes.utm.edu/primes/page.php?id=85376
        k = 39547695;
        n = 506636;
    }

    // only riesel number support
    const b: u32 = 2;
    const c_: i32 = -1;

    const only_tests: u32 = 0;
    if (only_tests == 0) {
        const is_prime = full_llr_run(k, b, n, c_, threads);
    } else {
        const success = selftest(1000000);
    }
}

pub fn selftest(max_n: u32) !void {
    var current_k: u32 = 0;
    var prev_prime: u32 = 0;

    for (test_data.primes) |prime_line| {
        for (prime_line) |number, i| {
            if (i == 0) {
                current_k = number;
                continue;
            }
            if (number == 0 or number > max_n) {
                continue;
            }
            log("testing k: {} n: {}\n", .{
                current_k,
                number,
            });
            const is_prime = try full_llr_run(current_k, 2, number, -1, 1);
            const is_not_prime = blk: {
                if (number - 1 != prev_prime) {
                    break :blk try full_llr_run(current_k, 2, number - 1, -1, 1);
                } else {
                    break :blk false;
                }
            };

            prev_prime = number;

            if (is_prime != true or is_not_prime != false) {
                log("TEST FAILED {} {}\n", .{ is_prime, is_not_prime });
                return;
            }
        }
        log("TESTS COMPLETED! all good\n", .{});
    }
}
