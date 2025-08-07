const std = @import("std");
const stdout = std.io.getStdOut().writer();
const Allocator = std.mem.Allocator;

var gpa = std.heap.GeneralPurposeAllocator(.{}).init;

pub fn Grid(comptime T: type) type {
    return struct {
        const Self = @This();
        data: []T,
        rows: usize,
        cols: usize,
        allocator: Allocator,

        pub fn init(allocator: Allocator, rows: usize, cols: usize) !Self {
            if (rows == 0 or cols == 0) {
                return error.InvalidDimensions;
            }
            const data = try allocator.alloc(T, rows * cols);
            @memset(data, 0);
            return Self{ .data = data, .rows = rows, .cols = cols, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.data);
            self.data = undefined;
            self.rows = 0;
            self.cols = 0;
        }

        fn checkBoundry(self: *const Self, row: usize, col: usize) bool {
            return row >= self.rows or col >= self.cols;
        }

        pub fn get(self: *const Self, row: usize, col: usize) !T {
            if (self.checkBoundry(row, col)) {
                return error.IndexOutOfBound;
            }
            return self.data[row * self.cols + col];
        }

        pub fn set(self: *Self, row: usize, col: usize, value: T) !void {
            if (self.checkBoundry(row, col)) {
                return error.IndexOutOfBound;
            }
            self.data[row * self.cols + col] = value;
        }

        pub fn appendRow(self: *Self, slice: []T, row: usize) !void {
            if (slice.len != self.cols) {
                return error.InvalidLength;
            }
            if (row > self.rows) {
                return error.InvalidRows;
            }
            for (slice, 0..) |ele, i| {
                try self.set(row, i, ele);
            }
        }

        pub fn String(self: *const Self) ![]u8 {
            var buffer = std.ArrayList(u8).init(self.allocator);
            // in case of error deinit buffer
            errdefer buffer.deinit();
            // Add matrix dimensions header
            try std.fmt.format(buffer.writer(), "Grid ({d}x{d}) of type {s}:\n", .{ self.rows, self.cols, @typeName(T) });
            for (0..self.rows) |r| {
                for (0..self.cols) |c| {
                    const value = try self.get(r, c);
                    try std.fmt.format(buffer.writer(), "{} ", .{value});
                }
                // Add a newline after each row
                try buffer.append('\n');
            }
            return try buffer.toOwnedSlice();
        }

        pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
            try std.fmt.format(writer, "Grid ({d}x{d}) of type {s}:\n", .{ self.rows, self.cols, @typeName(T) });
            for (0..self.rows) |r| {
                for (0..self.cols) |c| {
                    const value = try self.get(r, c);
                    try std.fmt.format(writer, "{} ", .{value});
                }
                try writer.writeAll("\n");
            }
        }
    };
}
