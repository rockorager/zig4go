# zig4go

We all know that zig is a great build system. zig4go makes it easy to build go
projects using zig.

## Usage

zig4go will do a few magic things for you:

1. When using CGO, it will automatically set up a static build using zig cc
2. The release mode is passed as a build tag to go (ie `-tags ReleaseSafe`)

```zig
const std = @import("std");
const go = @import("go");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Set up the build runner
    const go_build = go.addExecutable(b, .{
        .name = "app",
        .target = target,
        .optimize = optimize,
        .package_path = b.path("cmd/app"),
    });

    // Add a run step to our build
    const run_cmd = go_build.addRunStep();
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Install the executable
    go_build.addInstallStep();
}
```

## Contributing

Contributions are welcome. Some ideas:

- Add a nice way to cross compile
- Add more of the go build options
- Make a ReleaseSmall build actually small
- Add an option to download go from official sources
