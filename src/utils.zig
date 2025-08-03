const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList(u8);
const Allocator = std.mem.Allocator;
const rl = @import("raylib");

pub fn RuleSet() type {
    return struct {
        const Self = @This();
        ruleStringBin: [8]u8,

        pub fn init(ruleString: []const u8) !Self {
            const temp = try decToBin(ruleString);
            std.debug.print("{s}\n", .{temp});
            return Self{
                .ruleStringBin = try decToBin(ruleString),
            };
        }

        fn combineBits(self: Self, c0: bool, c1: bool, c2: bool) u8 {
            _ = self;
            return (@as(u8, @intFromBool(c0)) << 2) |
                (@as(u8, @intFromBool(c1)) << 1) |
                @as(u8, @intFromBool(c2));
        }

        pub fn nextState(self: Self, c0: u8, c1: u8, c2: u8) !u8 {
            if (c0 > 1 or c1 > 1 or c2 > 1) return error.InvalidInput;
            const index = self.combineBits(c0 != 0, c1 != 0, c2 != 0);
            return self.ruleStringBin[self.ruleStringBin.len - index - 1] - '0';
        }

        pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try writer.writeAll("-----------------------------\n");
            try writer.writeAll("⏐ c0 ⏐ c1 ⏐ c2 ⏐ next state ⏐\n");
            try writer.writeAll("-----------------------------\n");
            for (0..8) |it| {
                const i = 7 - it;
                const c0: u8 = @intFromBool(i & 1 != 0);
                const c1: u8 = @intFromBool(i & 2 != 0);
                const c2: u8 = @intFromBool(i & 4 != 0);
                const next_state = try self.nextState(c2, c1, c0);
                try std.fmt.format(writer, "⏐ {d}  ⏐ {d}  ⏐ {d}  ⏐     {d}      ⏐\n", .{ c2, c1, c0, next_state });
            }
            try writer.writeAll("-----------------------------\n");
        }
    };
}

// convert "xxx" in decimal to "xxxxxxxx" in binary
pub fn decToBin(input: []const u8) ![8]u8 {
    const range: usize = 8;
    const n = input.len;
    if (n == 0 or n > 3) return error.Invalidlength;
    const num = blk: {
        const parse_result = std.fmt.parseInt(u16, input, 10) catch return error.ParseError;
        break :blk parse_result;
    };
    var temp: [8]u8 = undefined;
    for (0..range) |i| {
        const one: usize = 1;
        const mask = one << @intCast(range - i - 1);
        const bit = num & mask;
        if (bit != 0) {
            temp[i] = '1';
        } else {
            temp[i] = '0';
        }
    }
    return temp;
}

test "Rule string convertion from decimal to binary" {
    const testStruct = struct {
        input: []const u8,
        output: []const u8,
    };
    // const pp = "11111111";
    const testCases: []const testStruct = &[_]testStruct{
        .{ .input = "255", .output = "11111111" },
        .{ .input = "64", .output = "01000000" },
        .{ .input = "42", .output = "00101010" },
        .{ .input = "0", .output = "00000000" },
        .{ .input = "15", .output = "00001111" },
        .{ .input = "1", .output = "00000001" },
        .{ .input = "0", .output = "00000000" },
    };

    for (testCases, 0..) |case, i| {
        // Print information for better debugging on failure
        const actual_output = try decToBin(case.input);
        std.debug.print("Test Case {d}: Input='{s}', Expected Output='{s}' , Actual output='{s}'\n", .{ i, case.input, case.output, actual_output });

        // If the test fails before this, the allocator will detect a leak.
        try testing.expect(std.mem.eql(u8, actual_output[0..], case.output));
    }
}

test "combineBits logic" {
    // c0 c1 c2 -> Decimal
    // 0  0  0 -> 0
    const ruleSet = try RuleSet().init("64");
    try testing.expect(ruleSet.combineBits(false, false, false) == 0);
    // 0  0  1 -> 1
    try testing.expect(ruleSet.combineBits(false, false, true) == 1);
    // 0  1  0 -> 2
    try testing.expect(ruleSet.combineBits(false, true, false) == 2);
    // 0  1  1 -> 3
    try testing.expect(ruleSet.combineBits(false, true, true) == 3);
    // 1  0  0 -> 4
    try testing.expect(ruleSet.combineBits(true, false, false) == 4);
    // 1  0  1 -> 5
    try testing.expect(ruleSet.combineBits(true, false, true) == 5);
    // 1  1  0 -> 6
    try testing.expect(ruleSet.combineBits(true, true, false) == 6);
    // 1  1  1 -> 7
    try testing.expect(ruleSet.combineBits(true, true, true) == 7);
}
