const std = @import("std");
const rand = std.crypto.random;
const cli = @import("arg.zig");
var gpa = std.heap.GeneralPurposeAllocator(.{}).init;

const rl = @import("raylib");
const Color = rl.Color;
const utils = @import("utils.zig");
const CONFIG = @import("config.zig");
const Grid = @import("Grid.zig").Grid(u8);

const ArrayList = std.ArrayList(u8);
const Allocator = std.mem.Allocator;
const RuleSet = utils.RuleSet();
const Options = @import("arg.zig").Options;

pub const Automata = struct {
    allocator: Allocator,
    ruleSet: ?RuleSet,
    grid: ?Grid,
    currentBuffer: ?ArrayList,
    nextBuffer: ?ArrayList,

    gridRows: u32,
    gridCols: u32,

    cellSize: u32,
    cellGap: u32,
    cellColor: Color,
    delay: u64,

    const Self = @This();

    pub fn init(allocator: Allocator, options: Options) !Self {
        var self = Self{
            .allocator = allocator,
            .ruleSet = null,

            .grid = null,
            .currentBuffer = null,
            .nextBuffer = null,
            .gridRows = options.gridRows,
            .gridCols = options.gridCols,

            .cellSize = options.cellSize,
            .cellGap = options.cellGap,
            .cellColor = options.cellColor,

            .delay = options.delay,
        };
        try self.initCurrentBuffer(options.i);
        try self.initNextBuffer();
        try self.initRuleSet(options.r, options.rule);
        try self.initGrid();
        if (self.ready()) return self;
        return error.NotReady;
    }

    pub fn deinit(self: *Self) void {
        self.grid.?.deinit();
        self.currentBuffer.?.deinit();
        self.nextBuffer.?.deinit();
    }

    /// initialize current buffer
    fn initCurrentBuffer(self: *Self, random: bool) !void {
        self.currentBuffer = try ArrayList.initCapacity(self.allocator, self.gridCols);
        // if ranmom inital state is true set initalBuffer to random values else set middle item to 1
        if (random) {
            try self.seedInitalBuffer();
        } else {
            try self.seedIntialBUfferToZero();
            self.currentBuffer.?.items[self.gridCols / 2] = 1; // set middle item to 1;
        }
    }

    /// initialize next buffers
    fn initNextBuffer(self: *Self) !void {
        var next_buffer = try ArrayList.initCapacity(self.allocator, self.gridCols);
        next_buffer.expandToCapacity(); // expand the capacity
        self.nextBuffer = next_buffer;
    }

    /// initialize  RuleSet
    fn initRuleSet(self: *Self, random: bool, rule: ?[]const u8) !void {
        if (random) {
            self.ruleSet = try RuleSet.initRandom();
        } else self.ruleSet = try RuleSet.init(rule.?);
    }

    /// initialize the grid and populate the first row of the grid with the current buffer
    fn initGrid(self: *Self) !void {
        var grid = try Grid.init(self.allocator, self.gridRows, self.gridCols);
        try grid.appendRow(self.currentBuffer.?.items, 0);
        self.grid = grid;
    }

    pub fn ready(self: *Self) bool {
        if (self.ruleSet != null and self.grid != null and self.currentBuffer != null and self.nextBuffer != null) return true;
        return false;
    }

    /// fill initial buffer with either 0 or 1
    pub fn seedInitalBuffer(self: *Self) !void {
        const len = self.currentBuffer.?.capacity;
        for (0..len) |_| {
            const random_bool: bool = rand.boolean();
            try self.currentBuffer.?.append(@intFromBool(random_bool));
        }
        self.currentBuffer.?.items[0] = 0;
        self.currentBuffer.?.items[len - 1] = 0;
    }

    /// fill initial buffer with zero
    pub fn seedIntialBUfferToZero(self: *Self) !void {
        if (self.currentBuffer == null) return;
        const len = self.currentBuffer.?.capacity;
        for (0..len) |_| try self.currentBuffer.?.append(@intCast(0));
    }
};
