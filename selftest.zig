const std = @import("std");
const stderr = std.debug.warn;

const test_data = @embedFile("test_cases.dat");
const llr = @import("llr.zig");
const helper = @import("helper.zig");

// LLR test expects n not to be too small in relation to k
const MIN_N: u32 = 11;

pub fn run(max_n: u32) !void {
    const State = enum(u8) {
        ReadingK,
        ReadingN,
    };

    var current_k: u32 = 0;
    var current_n: u32 = 0;
    var previous_n: u32 = 0;
    var state = State.ReadingK;
    // parse the test data byte-by-byte
    // zig doesn't seem to have much for string processing
    var buf: [9:0]u8 = undefined;
    var buf_ptr: u32 = 0;
    var skip_next: u32 = 0;
    var testcase_ready = false;
    for (test_data) |b| {
        // should end reading number and parse it
        if (skip_next > 0) {
            skip_next -= 1;
            continue;
        }
        if (b == ' ' or b == '\n') {
            const read_nr = @intCast(u32, try helper.parseU64(buf[0..buf_ptr], 10));
            buf_ptr = 0;
            switch (state) {
                State.ReadingK => {
                    //stderr("setting k={}\n", .{read_nr});
                    current_k = read_nr;
                    state = State.ReadingN;
                    skip_next = 2;
                },
                State.ReadingN => {
                    previous_n = current_n;
                    current_n = read_nr;
                    if (b == '\n') {
                        state = State.ReadingK;
                    }
                    if (current_n >= MIN_N and current_n <= max_n) {
                        //stderr("setting n={}\n", .{read_nr});
                        testcase_ready = true;
                    }
                },
            }
        } else {
            buf[buf_ptr] = b;
            buf_ptr += 1;
        }

        if (testcase_ready) {
            testcase_ready = false;
            stderr(". testing positive case k:{} n:{}\n", .{ current_k, current_n });
            const positive_case = try llr.full_llr_run(current_k, 2, current_n, -1, 1);
            stderr(". testing negative case k:{} n:{}\n", .{ current_k, current_n - 1 });
            const negative_case = blk: {
                if (current_n - 1 != previous_n) {
                    break :blk try llr.full_llr_run(current_k, 2, current_n - 1, -1, 1);
                } else {
                    break :blk false;
                }
            };
            if (positive_case != true or negative_case != false) {
                stderr("--TEST FAILED-- {} {}\n", .{ positive_case, negative_case });
                return;
            } else {
                stderr("k:{} n:{} vs. n:{} checks out\n", .{ current_k, current_n, current_n - 1 });
            }
        }
    }
    stderr("TESTS COMPLETED! all good\n", .{});
}
