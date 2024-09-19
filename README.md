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

## Assert

zig4go also includes a very simple assert package. This package contains two
files: `assert_fast.go` which is used for ReleaseFast builds and `assert.go`
which is used for all other builds. zig4go sets the build mode as a build tag,
which the go compiler uses to conditionally compile one of these files. The
`_fast` version is a no-op function, while the standard version contains
assertion logic. The go compiler optimizes the no-op function away, so (just
like in zig), you can pepper your codebase with assertions and compile them away
with no performance cost in a ReleaseFast build.

## Contributing

Contributions are welcome. Some ideas:

- Add a nice way to cross compile
- Add more of the go build options
- Make a ReleaseSmall build actually small
- Add an option to download go from official sources
