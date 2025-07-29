const std = @import("std");
const utils = @import("utils.zig");

const ArrayList = std.ArrayList(u8);
const Allocator = std.mem.Allocator;
const r: u8 = 1;
const k: u8 = 2;

pub fn main() anyerror!void {
    const ruleSet = try utils.RuleSet("150").init();
    const res = try ruleSet.nextState(0, 0, 0);
    std.debug.print("{c}", .{res});
}
