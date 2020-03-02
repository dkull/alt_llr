const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("alt_llr_zig", "alt_llr.zig");
    exe.setBuildMode(mode);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");

    exe.addIncludeDir(".");
    exe.addLibPath(".");

    exe.addIncludeDir("./Prime95/gwnum");
    exe.linkSystemLibrary("gwnum");

    exe.addObjectFile("libdemo.a");

    const run_cmd = exe.run();
    const run_step = b.step("run", "Run the thing");

    run_step.dependOn(&run_cmd.step);
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
