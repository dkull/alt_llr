pub const gw = @cImport({
    @cInclude("gwnum.h");
});
pub const gmp = @cImport({
    @cInclude("gmp.h");
});
pub const c_stdlib = @cImport({
    @cInclude("sys/resource.h");
    @cInclude("unistd.h");
});
