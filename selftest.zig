const std = @import("std");
const log = std.debug.warn;

const test_data = @import("test_data.zig");
const llr = @import("llr.zig");

pub fn run(max_n: u32) !void {
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
            const is_prime = try llr.full_llr_run(current_k, 2, number, -1, 1);
            const is_not_prime = blk: {
                if (number - 1 != prev_prime) {
                    break :blk try llr.full_llr_run(current_k, 2, number - 1, -1, 1);
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
