const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // exe_mod imports lib_mod
    exe_mod.addImport("automata_lib", lib_mod);

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const zigcli_dep = b.dependency("cli", .{ .target = target });
    const zigcli_mod = zigcli_dep.module("cli");

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    // Define the 'automata' static library
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "automata",
        .root_module = lib_mod,
    });

    // Make the library installable by default
    // When you run `zig build`, this will place libmy_math_lib.a in zig-out/lib
    b.installArtifact(lib);

    // Define the executable
    const exe = b.addExecutable(.{
        .name = "automata",
        .root_module = exe_mod,
    });

    // Link the executable against 'raylib'
    // This tells the linker to include the code from raylib in my-app
    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("cli", zigcli_mod);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
    // ==== ADD THESE LINES TO LINK SYSTEM LIBRARIES ====
    exe.linkSystemLibrary("GL"); // For libGL.so / libGLX.so
    exe.linkSystemLibrary("X11");
    exe.linkSystemLibrary("Xcursor");
    exe.linkSystemLibrary("Xext");
    exe.linkSystemLibrary("Xfixes");
    exe.linkSystemLibrary("Xi");
    exe.linkSystemLibrary("Xinerama");
    exe.linkSystemLibrary("Xrandr");
    exe.linkSystemLibrary("Xrender");
    exe.linkSystemLibrary("EGL"); // For libEGL.so
    exe.linkSystemLibrary("wayland-client");
    exe.linkSystemLibrary("xkbcommon");
    // You might also need:
    exe.linkSystemLibrary("pthread"); // For threading
    exe.linkSystemLibrary("m"); // For math functions
    exe.linkSystemLibrary("dl"); // For dynamic loading
    // ===============================================

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
