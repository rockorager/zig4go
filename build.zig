const std = @import("std");

pub fn addExecutable(b: *std.Build, options: BuildStep.Options) *BuildStep {
    return BuildStep.create(b, options);
}

/// Runs `go build` with relevant flags
pub const BuildStep = struct {
    step: std.Build.Step,
    generated_bin: ?*std.Build.GeneratedFile,
    opts: Options,

    pub const Options = struct {
        name: []const u8,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
        package_path: std.Build.LazyPath,
        cgo_enabled: bool = true,
    };

    /// Create a GoBuildStep
    pub fn create(b: *std.Build, options: Options) *BuildStep {
        const self = b.allocator.create(BuildStep) catch unreachable;
        self.* = .{
            .opts = options,
            .generated_bin = null,
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "go build",
                .owner = b,
                .makeFn = BuildStep.make,
            }),
        };
        return self;
    }

    pub fn make(step: *std.Build.Step, progress: std.Progress.Node) !void {
        const self: *BuildStep = @fieldParentPtr("step", step);
        const b = step.owner;
        var go_args = std.ArrayList([]const u8).init(b.allocator);
        defer go_args.deinit();

        try go_args.append("go");
        try go_args.append("build");

        const output_file = try b.cache_root.join(b.allocator, &.{ "go", self.opts.name });
        try go_args.appendSlice(&.{ "-o", output_file });

        switch (self.opts.optimize) {
            .ReleaseSafe => try go_args.appendSlice(&.{ "-tags", "ReleaseSafe" }),
            .ReleaseFast => try go_args.appendSlice(&.{ "-tags", "ReleaseFast" }),
            .ReleaseSmall => try go_args.appendSlice(&.{ "-tags", "ReleaseFast" }),
            .Debug => try go_args.appendSlice(&.{ "-tags", "Debug" }),
        }

        var env = try std.process.getEnvMap(b.allocator);

        // CGO
        if (self.opts.cgo_enabled) {
            try env.put("CGO_ENABLED", "1");
            // Set zig as the CGO compiler
            const target = self.opts.target;
            const cc = b.fmt(
                "zig cc -target {s}-{s}",
                .{ @tagName(target.result.cpu.arch), @tagName(target.result.os.tag) },
            );
            try env.put("CC", cc);
            const cxx = b.fmt(
                "zig c++ -target {s}-{s}",
                .{ @tagName(target.result.cpu.arch), @tagName(target.result.os.tag) },
            );
            try env.put("CXX", cxx);

            // Tell the linker we are statically linking
            go_args.appendSlice(&.{ "--ldflags", "-linkmode=external -extldflags=-static" }) catch @panic("OOM");
        } else {
            try env.put("CGO_ENABLED", "0");
        }

        // Output file always needs to be added last
        try go_args.append(self.opts.package_path.getPath(b));

        const cmd = std.mem.join(b.allocator, " ", go_args.items) catch @panic("OOM");
        const node = progress.start(cmd, 1);
        defer node.end();

        // run the command
        try self.evalChildProcess(go_args.items, &env);

        if (self.generated_bin == null) {
            const generated_bin = b.allocator.create(std.Build.GeneratedFile) catch unreachable;
            generated_bin.* = .{ .step = step };
            self.generated_bin = generated_bin;
        }
        self.generated_bin.?.path = output_file;
    }

    /// Return the LazyPath of the generated binary
    pub fn getEmittedBin(self: *BuildStep) std.Build.LazyPath {
        if (self.generated_bin) |generated_bin|
            return .{ .generated = .{ .file = generated_bin } };

        const b = self.step.owner;
        const generated_bin = b.allocator.create(std.Build.GeneratedFile) catch unreachable;
        generated_bin.* = .{ .step = &self.step };
        self.generated_bin = generated_bin;
        return .{ .generated = .{ .file = generated_bin } };
    }

    /// Add a run step which depends on the GoBuildStep
    pub fn addRunStep(self: *BuildStep) *std.Build.Step.Run {
        const b = self.step.owner;
        const run_step = std.Build.Step.Run.create(b, b.fmt("run {s}", .{self.opts.name}));
        run_step.step.dependOn(&self.step);
        const bin_file = self.getEmittedBin();
        const arg: std.Build.Step.Run.PrefixedLazyPath = .{ .prefix = "", .lazy_path = bin_file };
        run_step.argv.append(b.allocator, .{ .lazy_path = arg }) catch unreachable;
        return run_step;
    }

    // Add an install step which depends on the GoBuildStep
    pub fn addInstallStep(self: *BuildStep) void {
        const b = self.step.owner;
        const bin_file = self.getEmittedBin();
        const install_step = b.addInstallBinFile(bin_file, self.opts.name);
        install_step.step.dependOn(&self.step);
        b.getInstallStep().dependOn(&install_step.step);
    }

    fn evalChildProcess(self: *BuildStep, argv: []const []const u8, env: *const std.process.EnvMap) !void {
        const s = &self.step;
        const arena = s.owner.allocator;

        try std.Build.Step.handleChildProcUnsupported(s, null, argv);
        try std.Build.Step.handleVerbose(s.owner, null, argv);

        const result = std.process.Child.run(.{
            .allocator = arena,
            .argv = argv,
            .env_map = env,
        }) catch |err| return s.fail("unable to spawn {s}: {s}", .{ argv[0], @errorName(err) });

        if (result.stderr.len > 0) {
            try s.result_error_msgs.append(arena, result.stderr);
        }

        try std.Build.Step.handleChildProcessTerm(s, result.term, null, argv);
    }
};
