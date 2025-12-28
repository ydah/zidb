const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello, from target!\n", .{});
    std.debug.print("This is line 2.\n", .{});
    std.debug.print("This is line 3.\n", .{});
}
