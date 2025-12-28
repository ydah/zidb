const std = @import("std");
const Debugger = @import("debugger.zig").Debugger;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <program>\n", .{args[0]});
        return;
    }

    const program = args[1];
    std.debug.print("zidb - Zig Debugger\n", .{});
    std.debug.print("Target program: {s}\n\n", .{program});

    var debugger = Debugger.init(program);
    try debugger.run();
}
