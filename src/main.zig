const std = @import("std");
const rand = std.crypto.random;

const rl = @import("raylib");
const utils = @import("utils.zig");
const CONFIG = @import("config.zig");
const Grid = @import("Grid.zig").Grid(u8);

const ArrayList = std.ArrayList(u8);
const Allocator = std.mem.Allocator;
const RuleSet = utils.RuleSet();

var w: f32 = CONFIG.SCREEN_WIDTH;
var h: f32 = CONFIG.SCREEN_HEIGHT;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    const ruleSet = try utils.RuleSet().init("99");
    std.debug.print("{}", .{ruleSet});
    //--------------------------------------------------------------------------------------

    rl.setConfigFlags(.{ .window_resizable = true, .window_transparent = true });
    rl.initWindow(CONFIG.SCREEN_WIDTH, CONFIG.SCREEN_HEIGHT, CONFIG.TITLE);
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.setTargetFPS(CONFIG.TARGET_FPS); // Set our game to run at 60 frames-per-second

    //--------------------------------------------------------------------------------------

    var grid = try Grid.init(allocator, CONFIG.GRID_ROWS, CONFIG.GRID_COLS);
    defer grid.deinit();

    var current_buffer = try ArrayList.initCapacity(allocator, CONFIG.GRID_COLS);
    // try seedInitalBuffer(&current_buffer); // populate current Buffer;
    // current_buffer.expandToCapacity();
    try seedIntialBUfferToZero(&current_buffer);
    current_buffer.items[CONFIG.GRID_COLS / 2] = 1;
    defer current_buffer.deinit();

    var next_buffer = try ArrayList.initCapacity(allocator, CONFIG.GRID_COLS);
    next_buffer.expandToCapacity(); // expand the capacity
    defer next_buffer.deinit();

    var row: usize = 0;
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        updateScreenDimension();
        rl.beginDrawing();
        defer rl.endDrawing();
        // draw
        //----------------------------------------------------------------------------------
        rl.clearBackground(CONFIG.SCREEN_COLOR);
        if (row < CONFIG.GRID_ROWS) {
            try updateBuffer(&ruleSet, &current_buffer, &next_buffer);
            try grid.appendRow(next_buffer.items, row);
            std.time.sleep(CONFIG.DELAY);
            row += 1;
        }
        try drawAutomata(&grid);
        //----------------------------------------------------------------------------------
    }
}

fn updateScreenDimension() void {
    if (rl.isWindowResized()) {
        w = @floatFromInt(rl.getScreenWidth());
        h = @floatFromInt(rl.getScreenHeight());
    }
}

fn screenCenter() rl.Vector2 {
    const x: f32 = @divTrunc(w, 2);
    const y: f32 = @divTrunc(h, 2);
    return rl.Vector2.init(x, y);
}

fn drawAutomata(grid: *const Grid) !void {
    for (0..CONFIG.GRID_ROWS) |i| {
        for (0..CONFIG.GRID_COLS) |j| {
            if (try grid.get(i, j) == 1) {
                const posx: i32 = @intCast(j * CONFIG.CELL_SIZE + CONFIG.CELL_GAP);
                const posy: i32 = @intCast(i * CONFIG.CELL_SIZE + CONFIG.CELL_GAP);
                const width: i32 = @intCast(CONFIG.CELL_SIZE);
                const height: i32 = @intCast(CONFIG.CELL_SIZE);
                rl.drawRectangle(posx, posy, width, height, CONFIG.CELL_COLOR);
            }
        }
    }
}

// update the next buffer
fn updateBuffer(ruleSet: *const RuleSet, cBuf: *ArrayList, nBuf: *ArrayList) !void {
    // set boundary elements to zero
    const len = cBuf.capacity;
    nBuf.items[0] = 0;
    nBuf.items[len - 1] = 0;
    for (1..len - 1) |i| {
        const next_cell_value: u8 = try ruleSet.nextState(cBuf.items[i - 1], cBuf.items[i], cBuf.items[i + 1]);
        nBuf.items[i] = next_cell_value;
    }
    cBuf.clearRetainingCapacity();
    try cBuf.appendSlice(nBuf.items);
}

fn seedInitalBuffer(buffer: *ArrayList) !void {
    const len = buffer.capacity;
    for (0..len) |_| {
        const random_bool: bool = rand.boolean();
        try buffer.append(@intFromBool(random_bool));
    }
    buffer.items[0] = 0;
    buffer.items[len - 1] = 0;
}

fn seedIntialBUfferToZero(buffer: *ArrayList) !void {
    const len = buffer.capacity;
    for (0..len) |_| {
        try buffer.append(@intCast(0));
    }
}

fn printRow(buffer: []u8) void {
    for (0..CONFIG.GRID_COLS) |i| {
        std.debug.print("{d} | ", .{buffer[i]});
    }
    std.debug.print("\n", .{});
}
