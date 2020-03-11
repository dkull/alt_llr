const mem = @import("std").mem;
const std = @import("std");
const stderr = std.debug.warn;

const helper = @import("helper.zig");

pub const RunMode = enum {
    Help,
    LLR,
    Selftest,
};

pub const ParsedArgs = struct {
    mode: RunMode,
    k: u32,
    n: u32,
    threads: u8,

    pub fn parse(args: [][]u8) !ParsedArgs {
        // use default k,n or take them from cmd args
        var mode: RunMode = RunMode.Help;
        var k: u32 = 0;
        var n: u32 = 0;
        var threads: u8 = 1;

        for (args) |arg, i| {
            if (arg.len == 5 and mem.eql(u8, arg[0..5], "--llr"[0..5])) {
                mode = RunMode.LLR;
                k = @intCast(u32, try helper.parseU64(args[i + 1], 10));
                n = @intCast(u32, try helper.parseU64(args[i + 2], 10));
            }
            if (arg.len == 10 and mem.eql(u8, arg[0..10], "--selftest"[0..10])) {
                mode = RunMode.Selftest;
                n = @intCast(u32, try helper.parseU64(args[i + 1], 10));
            }
            if (arg.len == 9 and mem.eql(u8, arg[0..9], "--threads"[0..9])) {
                threads = @intCast(u8, try helper.parseU64(args[i + 1], 10));
            }
        }

        return ParsedArgs{
            .mode = mode,
            .k = k,
            .n = n,
            .threads = threads,
        };
    }
};
