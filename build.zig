const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("altllr_zig", "alt_llr.zig");
    exe.setBuildMode(mode);
    //exe.addCSourceFile("gwhandle_create.c", &[_][]const u8{"-std=c99"});

    exe.addIncludeDir("./Prime95/gwnum/");

    //const gwnum_lib = b.addStaticLibrary("./Prime95/gwnum/gwnum.a", null);

    exe.linkSystemLibrary("c");

    const run_cmd = exe.run();
    const run_step = b.step("run", "Run the thing");

    run_step.dependOn(&run_cmd.step);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
