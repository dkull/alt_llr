const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("rpt_2", "rpt.zig");
    exe.setBuildMode(mode);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");

    exe.addIncludeDir(".");
    exe.addLibPath(".");

    exe.addIncludeDir("./Prime95/gwnum");
    exe.linkSystemLibrary("gwnum");

    exe.addIncludeDir("./gmp-6.2.0");
    exe.linkSystemLibrary("gwnum");

    const run_cmd = exe.run();
    const run_step = b.step("run", "Run the thing");

    run_step.dependOn(&run_cmd.step);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
