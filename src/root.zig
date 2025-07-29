//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const ArrayList = std.ArrayList(u8);
const Allocator = std.mem.Allocator;
const testing = std.testing;



// test "basic add functionality" {
//     try testing.expect(add(3, 7) == 10);
// }
