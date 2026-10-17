//! build.zig

const std = @import("std");

/// Links the entry points
fn linkPlatform(module: *std.Build.Module, target: std.Build.ResolvedTarget) void {
    switch (target.result.os.tag) {
        .windows => {
            module.linkSystemLibrary("kernel32", .{});
        },
        .linux => {
            module.linkSystemLibrary("GL", .{});
            module.linkSystemLibrary("dl", .{});
        },
        .macos => {
            module.linkFramework("OpenGL", .{});
        },
        else => {},
    }
}

pub fn build(b: *std.Build) void {
    // build 32 bit
    const x86 = b.option(bool, "x86", "Build 32-bit (x86-windows) binaries") orelse false;
    const target = if (x86)
        b.resolveTargetQuery(.{ .cpu_arch = .x86, .os_tag = .windows, .abi = .gnu })
    else
        b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // static library
    const static_module = b.createModule(.{
        .root_source_file = b.path("src/gllib.zig"),
        .target = target,
        .optimize = optimize,
    });
    linkPlatform(static_module, target);
    const lib = b.addLibrary(.{
        .name = "gllib",
        .root_module = static_module,
        .linkage = .static,
    });
    b.installArtifact(lib);

    // opengl32.dll
    const dll_module = b.createModule(.{
        .root_source_file = b.path("src/gllib.zig"),
        .target = target,
        .optimize = optimize,
    });
    linkPlatform(dll_module, target);
    const dll = b.addLibrary(.{
        .name = "opengl32",
        .root_module = dll_module,
        .linkage = .dynamic,
        // re-export them using their proper names
        .win32_module_definition = if (target.result.os.tag == .windows and
            target.result.cpu.arch == .x86)
            b.path("src/gl/opengl32.def")
        else
            null,
    });
    b.installArtifact(dll);

    // some unit tests
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    linkPlatform(test_module, target);

    const tests = b.addTest(.{ .root_module = test_module });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run the headless unit tests");
    test_step.dependOn(&run_tests.step);

    const check_step = b.step("check", "Check Project");
    check_step.dependOn(&lib.step);
}
