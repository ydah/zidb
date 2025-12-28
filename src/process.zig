const std = @import("std");
const linux = std.os.linux;

pub const WaitStatus = struct {
    exited: bool,
    stopped: bool,
    exit_code: u8,
    stop_signal: u8,
};

pub fn launchProcess(program: []const u8) !std.posix.pid_t {
    const pid = try std.posix.fork();

    if (pid == 0) {
        // Child process
        executeTarget(program);
    }

    // Parent process: return child's PID
    return pid;
}

fn executeTarget(program: []const u8) noreturn {
    const result = linux.ptrace(linux.PTRACE.TRACEME, 0, 0, 0, 0);
    if (result != 0) {
        std.debug.print("PTRACE_TRACEME failed\n", .{});
        std.posix.exit(1);
    }

    const argv = [_:null]?[*:0]const u8{null};
    const envp = [_:null]?[*:0]const u8{null};

    var path_buf: [std.fs.max_path_bytes:0]u8 = undefined;
    @memcpy(path_buf[0..program.len], program);
    path_buf[program.len] = 0;

    const err = std.posix.execveZ(&path_buf, &argv, &envp);
    std.debug.print("execve failed: {}\n", .{err});
    std.posix.exit(1);
}

pub fn waitForProcess(pid: std.posix.pid_t) WaitStatus {
    const result = std.posix.waitpid(pid, 0);
    const status = result.status;

    return .{
        .exited = std.posix.W.IFEXITED(status),
        .stopped = std.posix.W.IFSTOPPED(status),
        .exit_code = if (std.posix.W.IFEXITED(status)) std.posix.W.EXITSTATUS(status) else 0,
        .stop_signal = if (std.posix.W.IFSTOPPED(status)) @intCast(std.posix.W.STOPSIG(status)) else 0,
    };
}

pub fn continueProcess(pid: std.posix.pid_t) void {
    _ = linux.ptrace(linux.PTRACE.CONT, pid, 0, 0, 0);
}
