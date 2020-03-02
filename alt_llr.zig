const std = @import("std");
const log = std.debug.warn;

const c = @import("c.zig");

pub fn main() void {
    //var thing: c.MyStruct = undefined;
    //c.init_struct(&thing);
    //log("> {}\n", .{thing.a});

    //var gwdata = c.create_gwhandle();
    var gwdata: c.gwhandle = undefined;
    c.gwinit(gwdata);
    const _na = c.gwsetup(gwdata, 10, 2, 640, -1);

    const x = c.gwalloc(gwdata);
    c.dbltogw(gwdata, 2.0, x);
    //c.gwsetnormroutine(gwdata, 0, 1, 0);
    c.gwsquare(gwdata, x);
}
