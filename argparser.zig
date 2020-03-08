const helper = @import("helper.zig");

pub const ParsedArgs = struct {
    k: u32,
    n: u32,
    threads: u8,

    pub fn parse(args: [][]u8) !ParsedArgs {
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

        return ParsedArgs{
            .k = k,
            .n = n,
            .threads = threads,
        };
    }
};
