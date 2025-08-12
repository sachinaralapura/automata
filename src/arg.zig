const std = @import("std");
const Allocator = std.mem.Allocator;
const ArgIterator = std.process.ArgIterator;
const TokenArray = std.ArrayList(Token);
const StringEqual = std.mem.eql;
const rl = @import("raylib");
const Color = rl.Color;
const CONFIG = @import("config.zig");

const ArgError = error{ ParseError, TooManyColorValues, InvalidArgument, IntParseError, RGBValueError };

const Token = union(enum) { LongOption: struct {
    name: []const u8,
    value: []const u8,
}, ShortOption: u8 };

const State = enum {
    Start,
    Dash,
    DoubleDash,
    LongOption,
    LongOptionValue,
    ShortFlag,
    Error,
};

pub const Options = struct {
    /// random inital state
    i: bool,
    /// random rule from 0 to 255
    r: bool,
    /// help
    h: bool,
    /// to make window transparent
    t: bool,
    /// specify the rule from 0 to 255
    rule: []const u8,
    /// cell size 1 to 100
    cellSize: u32,
    /// cell gap  1 to 100
    cellGap: u32,
    /// cell color four value of comma separated value
    cellColor: Color,
    /// grid rows
    gridRows: u32,
    /// grid Columns
    gridCols: u32,
    /// screen color
    screenColor: Color,
    delay: u64,

    const Self = @This();

    fn init() Self {
        return Self{
            .i = false,
            .r = false,
            .h = false,
            .t = false,

            .rule = CONFIG.RULE_STRING,
            .cellSize = CONFIG.CELL_SIZE,
            .cellGap = CONFIG.CELL_GAP,
            .cellColor = CONFIG.CELL_COLOR,
            .gridRows = CONFIG.GRID_ROWS,
            .gridCols = CONFIG.GRID_COLS,
            .screenColor = CONFIG.SCREEN_COLOR,
            .delay = CONFIG.DELAY,
        };
    }

    fn setOption(self: *Self, token: Token) ArgError!bool {
        switch (token) {
            .ShortOption => {
                // Iterate through all the fields of option struct
                inline for (std.meta.fields(Self)) |field| {
                    if (field.name[0] == token.ShortOption and field.type == bool) {
                        @field(self, field.name) = true;
                        return true;
                    }
                }
                std.log.err("invalid option : {c}", .{token.ShortOption});
            },
            .LongOption => {
                // Iterate through all the fields of option struct
                inline for (std.meta.fields(Self)) |field| {
                    const name = token.LongOption.name;
                    const value = token.LongOption.value;
                    if (StringEqual(u8, field.name, name)) {
                        switch (field.type) {
                            []const u8 => @field(self, field.name) = value,
                            u32 => {
                                const valu32: u32 = std.fmt.parseInt(u32, value, 10) catch return ArgError.IntParseError;
                                @field(self, field.name) = valu32;
                            },
                            u64 => {
                                const value64 = std.fmt.parseInt(u64, value, 10) catch return ArgError.IntParseError;
                                @field(self, field.name) = value64 * 1_000_000;
                            },
                            Color => {
                                const color: Color = try toColor(value);
                                @field(self, field.name) = color;
                            },
                            else => {},
                        }
                        return true;
                    }
                }
            },
        }
        return false;
    }
};

pub fn parseArgument(argument: *ArgIterator) ArgError!Options {
    const allocator: Allocator = std.heap.page_allocator;
    var options: Options = Options.init();
    while (argument.*.next()) |arg| {
        const tokens: TokenArray = try Tokenize(allocator, arg);
        defer tokens.deinit();
        for (tokens.items) |token| {
            _ = try options.setOption(token);
        }
    }
    return options;
}

fn Tokenize(allocator: Allocator, argument: []const u8) ArgError!TokenArray {
    var tokens: TokenArray = TokenArray.init(allocator);
    var state: State = .Start;
    var i: usize = 0;
    const n = argument.len;

    var longOptStart: usize = 0;
    var longOptEnd: usize = 0;

    while (i < n) {
        const ch = argument[i];
        label: switch (state) {
            .Start => {
                switch (ch) {
                    '-' => state = .Dash,
                    else => state = .Error,
                }
            },
            .Dash => {
                switch (ch) {
                    '-' => state = .DoubleDash,
                    else => {
                        state = .ShortFlag;
                        continue :label .ShortFlag;
                    },
                }
            },
            .DoubleDash => {
                longOptStart = i;
                state = .LongOption;
            },
            .LongOption => {
                if (ch == '=') {
                    longOptEnd = i;
                    state = .LongOptionValue;
                }
            },
            .LongOptionValue => {
                tokens.append(.{ .LongOption = .{ .name = argument[longOptStart..longOptEnd], .value = argument[longOptEnd + 1 ..] } }) catch return ArgError.ParseError;
                i = n;
            },
            .ShortFlag => {
                tokens.append(.{ .ShortOption = ch }) catch return ArgError.ParseError;
            },
            .Error => {
                return ArgError.InvalidArgument;
            },
        }
        i += 1;
    }
    return tokens;
}

fn toColor(value: []const u8) ArgError!Color {
    var iterator = std.mem.splitScalar(u8, value, ',');
    var components: [4]u8 = undefined;
    var i: usize = 0;
    while (iterator.next()) |val| {
        if (i >= 4) return ArgError.TooManyColorValues;
        const v: u8 = std.fmt.parseInt(u8, val, 10) catch return ArgError.RGBValueError;
        components[i] = v;
        i = i + 1;
    }
    return Color.init(components[0], components[1], components[2], components[3]);
}

// -r -l -i
// -lri
// --option=value
