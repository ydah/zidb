const std = @import("std");
const process = @import("process.zig");

pub const Debugger = struct {
    program: []const u8,
    pid: ?std.posix.pid_t,
    running: bool,

    const Self = @This();

    pub fn init(program: []const u8) Self {
        return Self{
            .program = program,
            .pid = null,
            .running = true,
        };
    }

    pub fn run(self: *Self) !void {
        var stdin_buf: [4096]u8 = undefined;
        var stdout_buf: [4096]u8 = undefined;
        const stdin_file = std.fs.File.stdin();
        var stdin_reader = stdin_file.reader(&stdin_buf);
        const stdin = &stdin_reader.interface;
        const stdout_file = std.fs.File.stdout();
        var stdout_writer = stdout_file.writer(&stdout_buf);
        const stdout = &stdout_writer.interface;

        while (self.running) {
            try stdout.print("zidb> ", .{});
            try stdout.flush();

            const line = stdin.takeDelimiter('\n') catch |err| switch (err) {
                error.ReadFailed, error.StreamTooLong => {
                    std.debug.print("Error reading input: {}\n", .{err});
                    continue;
                },
            };

            if (line) |input| {
                const trimmed = std.mem.trim(u8, input, " \t\r");
                if (trimmed.len > 0) {
                    self.handleCommand(trimmed);
                }
            } else {
                // End of file
                break;
            }
        }
    }

    fn handleCommand(self: *Self, line: []const u8) void {
        var iter = std.mem.splitScalar(u8, line, ' ');
        const cmd = iter.next() orelse return;

        if (std.mem.eql(u8, cmd, "run") or std.mem.eql(u8, cmd, "r")) {
            self.cmdRun();
        } else if (std.mem.eql(u8, cmd, "continue") or std.mem.eql(u8, cmd, "c")) {
            self.cmdContinue();
        } else if (std.mem.eql(u8, cmd, "quit") or std.mem.eql(u8, cmd, "q")) {
            self.cmdQuit();
        } else if (std.mem.eql(u8, cmd, "help") or std.mem.eql(u8, cmd, "h")) {
            self.cmdHelp();
        } else {
            std.debug.print("Unknown command: {s}\n", .{cmd});
            std.debug.print("Type 'help' for a list of commands.\n", .{});
        }
    }

    fn cmdRun(self: *Self) void {
        if (self.pid != null) {
            std.debug.print("Program is already running.\n", .{});
            return;
        }

        const result = process.launchProcess(self.program);
        if (result) |pid| {
            self.pid = pid;
            std.debug.print("Started process, pid: {}\n", .{pid});

            self.waitForSignal();
        } else |err| {
            std.debug.print("Failed to start process: {}\n", .{err});
        }
    }

    fn cmdContinue(self: *Self) void {
        if (self.pid) |pid| {
            process.continueProcess(pid);
            self.waitForSignal();
        } else {
            std.debug.print("No process is running. Use 'run' first.\n", .{});
        }
    }

    fn cmdQuit(self: *Self) void {
        std.debug.print("Bye!\n", .{});
        self.running = false;
    }

    fn cmdHelp(_: *Self) void {
        std.debug.print("Available commands:\n", .{});
        std.debug.print("  run (r)       - Start the program\n", .{});
        std.debug.print("  continue (c)  - Continue execution\n", .{});
        std.debug.print("  quit (q)      - Exit the debugger\n", .{});
        std.debug.print("  help (h)      - Show this help message\n", .{});
    }

    fn waitForSignal(self: *Self) void {
        if (self.pid) |pid| {
            const status = process.waitForProcess(pid);

            if (status.exited) {
                std.debug.print("Process exited with code: {}\n", .{status.exit_code});
                self.pid = null;
            } else if (status.stopped) {
                std.debug.print("Process stopped by signal: {}\n", .{status.stop_signal});
            }
        }
    }
};
