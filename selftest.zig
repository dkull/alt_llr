const std = @import("std");
const stderr = std.debug.warn;

const test_data = @embedFile("test_cases.dat");
const llr = @import("llr.zig");
const fermat = @import("fermat.zig");
const helper = @import("helper.zig");

// LLR test expects n not to be too small in relation to k
const MIN_N: u32 = 11;

pub fn run(max_n: u32) !void {
    const State = enum(u8) {
        ReadingK,
        ReadingN,
    };
    stderr("maxn: {}\n", .{max_n});

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

    var positive_tests_run: u32 = 0;
    var negative_tests_run: u32 = 0;
    var negative_fermat_failures: u32 = 0;

    var failures: u32 = 0;
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
            stderr("\n", .{});
            testcase_ready = false;
            positive_tests_run += 1;
            stderr("##### testing positive case k:{} n:{} #####\n", .{ current_k, current_n });
            const positive_case_llr = try llr.full_llr_run(current_k, 2, current_n, -1, 1);
            const positive_case_fermat = try fermat.full_fermat_run(current_k, 2, current_n, -1, 1);
            const positive_case = positive_case_llr and positive_case_fermat;
            stderr("\n##### testing negative case k:{} n:{} [{}-1] #####\n", .{ current_k, current_n - 1, current_n });
            const negative_case_llr = blk: {
                if (current_n - 1 != previous_n) {
                    negative_tests_run += 1;
                    break :blk try llr.full_llr_run(current_k, 2, current_n - 1, -1, 1);
                } else {
                    break :blk false;
                }
            };
            const negative_case_fermat = blk: {
                if (current_n - 1 != previous_n) {
                    break :blk try fermat.full_fermat_run(current_k, 2, current_n - 1, -1, 1);
                } else {
                    break :blk false;
                }
            };
            if (negative_case_fermat) {
                negative_fermat_failures += 1;
            }
            if (positive_case != true or negative_case_llr != false) {
                failures += 1;
                stderr("--TEST FAILED-- {}*2^{}-1 pos case?: {} llr_neg?: {}\n", .{ current_k, current_n, positive_case, negative_case_llr });
                //return;
            } else {
                stderr("##### k:{} n:{} vs. n:{} checks out #####\n", .{ current_k, current_n, current_n - 1 });
            }
        }
    }
    if (failures > 0) {
        stderr("TESTS COMPLETED! {} failures\n", .{failures});
    } else {
        stderr("TESTS COMPLETED! all good\n", .{});
    }
    stderr("total pos: {} neg: {} fermat liars: {} [0 is the best possible result]\n", .{ positive_tests_run, negative_tests_run, negative_fermat_failures });
}
