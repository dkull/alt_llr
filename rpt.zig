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

pub fn full_llr_run(k_: u32, b: u32, n: u32, c_: i32) !bool {
    // calculate N for Jacobi
    var N: gmp.mpz_t = u_zero.calculate_N(k_, n);
    const n_digits = gmp.mpz_sizeinbase(&N, 10);

    try stdout.print("LLR testing: {}*{}^{}{} [{} digits]\n", .{ k_, b, n, c_, n_digits });

    const k = @intToFloat(f64, k_);

    // create gwnum context
    var ctx: gw.gwhandle = undefined;
    gw.gwinit2(&ctx, @sizeOf(gw.gwhandle), gw.GWNUM_VERSION);

    // gwnum magic for speed and (un)safety
    ctx.safety_margin = -1.0;
    ctx.use_large_pages = 1;
    gw.gwset_square_carefully_count(&ctx, -1);
    ctx.num_threads = 4;
    ctx.will_hyperthread = 4;

    // tell gwnum in what modulus are we calculating in
    const _na = gw.gwsetup(&ctx, k, b, n, c_);

    // calculate u0
    log("step 1. find our u0 ...\n", .{});
    var u0_gmp: gmp.mpz_t = undefined;
    var u0_start = std.time.milliTimestamp();
    u_zero.find_rodseth_u0(k_, n, N, &u0_gmp);
    const u0_took = std.time.milliTimestamp() - u0_start;

    // print the u0 if it's small enough
    const u_zero_digits = gmp.mpz_sizeinbase(&u0_gmp, 10);
    if (u_zero_digits <= 9) {
        log("u0: {}\n", .{gmp.mpz_get_ui(&u0_gmp)});
    }
    log("step 1. done - u0 digits {} and took {}ms\n", .{ u_zero_digits, u0_took });

    // move u0 from gmp to gw
    var u: gw.gwnum = gw.gwalloc(&ctx);
    glue.gmp_to_gw(u0_gmp, u, &ctx);

    log("step 2. do llr test ...\n", .{});
    const llr_start = std.time.milliTimestamp();
    // core LLR loop
    var i: u32 = 1;
    while (i < n - 1) {
        if (@mod(i, 50000) == 0) {
            log("{}%.", .{(i * 100 / (n - 1))});
        }
        gw.gwsetaddin(&ctx, -2);
        gw.gwsquare2(&ctx, u, u);
        i += 1;
    }
    log("\n", .{});
    const llr_took = std.time.milliTimestamp() - llr_start;
    log("step 2. done - llr took {}ms\n", .{llr_took});

    gmp.mpz_clear(&N);

    const residue_zero = gw.gwiszero(&ctx, u) == 1;
    if (residue_zero) {
        try stdout.print("#> {}*{}^{}{} [{} digits] IS PRIME\n", .{ k_, b, n, c_, n_digits });
    } else {
        try stdout.print("#> {}*{}^{}{} [{} digits] is not prime\n", .{ k_, b, n, c_, n_digits });
    }
    return residue_zero;
}

pub fn main() !void {
    try stdout.print("=== RPT - Riesel Prime Tester v{} [GWNUM: {} GMP: {}.{}.{}] ===\n", .{ VERSION, gw.GWNUM_VERSION, gmp.__GNU_MP_VERSION, gmp.__GNU_MP_VERSION_MINOR, gmp.__GNU_MP_VERSION_MINOR });
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var k: u32 = 0;
    var n: u32 = 0;
    if (args.len == 3) {
        k = @intCast(u32, try helper.parseU64(args[1], 10));
        n = @intCast(u32, try helper.parseU64(args[2], 10));
    } else {
        // https://primes.utm.edu/primes/page.php?id=85376
        k = 39547695;
        n = 506636;
    }

    //const k: u32 = 13;
    //const n: u32 = 17;
    //const k: u32 = 17295;
    //const n: u32 = 217577;
    //const k: u32 = 39547695;
    //const n: u32 = 454240;
    //const k: u32 = 39547695;
    //const n: u32 = 506636;
    //const k: u32 = 8331405;
    //const n: u32 = 829367;
    //const k: u32 = 133603707;
    //const n: u32 = 100014;

    const b: u32 = 2;
    const c_: i32 = -1;

    const testo = false;
    //const testo = true;
    if (testo) {
        const success = selftest(1000000);
    } else {
        const is_prime = full_llr_run(k, b, n, c_);
    }
}

pub fn selftest(max_n: u32) !void {
    var current_k: u32 = 0;
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
            const is_prime = try full_llr_run(current_k, 2, number, -1);
            const is_not_prime = try full_llr_run(current_k, 2, number - 1, -1);
            if (is_prime != true or is_not_prime != false) {
                log("TEST FAILED {} {}\n", .{ is_prime, is_not_prime });
                return;
            }
        }
    }
}
