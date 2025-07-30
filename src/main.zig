const std = @import("std");
const rand = std.crypto.random;

const rl = @import("raylib");
const utils = @import("utils.zig");
const CONFIG = @import("config.zig");

const ArrayList = std.ArrayList(u8);
const GridType = std.ArrayList(std.ArrayList(u8));
const Allocator = std.mem.Allocator;
const RuleSet = utils.RuleSet();

var w: f32 = CONFIG.SCREEN_WIDTH;
var h: f32 = CONFIG.SCREEN_HEIGHT;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    const ruleSet = try utils.RuleSet().init("76");
    const res = try ruleSet.nextState(0, 0, 0);
    std.debug.print("{c}\n", .{res});
    std.debug.print("{}", .{ruleSet});
    //--------------------------------------------------------------------------------------
    rl.setConfigFlags(.{ .window_resizable = true, .window_transparent = true });
    rl.initWindow(CONFIG.SCREEN_WIDTH, CONFIG.SCREEN_HEIGHT, CONFIG.TITLE);
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.setTargetFPS(CONFIG.TARGET_FPS); // Set our game to run at 60 frames-per-second

    //--------------------------------------------------------------------------------------
    const Grid = try GridType.initCapacity(allocator, CONFIG.GRID_HEIGHT);
    defer Grid.deinit();

    var current_buffer = try ArrayList.initCapacity(allocator, CONFIG.GRID_WIDTH);
    try seedInitalBuffer(&current_buffer);
    defer current_buffer.deinit();

    var next_buffer = try ArrayList.initCapacity(allocator, CONFIG.GRID_HEIGHT);
    try seedInitalBuffer(&next_buffer);
    defer next_buffer.deinit();

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
        try updateBuffer(&ruleSet, &current_buffer, &next_buffer);
        //----------------------------------------------------------------------------------
        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
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

fn seedInitalBuffer(buffer: *ArrayList) !void {
    for (0..buffer.capacity) |_| {
        const random_bool: bool = rand.boolean();
        try buffer.append(@intFromBool(random_bool));
    }
}

fn updateBuffer(ruleSet: *const RuleSet, cBuf: *ArrayList, nBuf: *ArrayList) !void {
    // set boundary elements to zero
    const len = cBuf.*.items.len;
    cBuf.items[0] = 0;
    cBuf.items[len - 1] = 0;
    for (1..len - 1) |i| {
        const next_cell_value = try ruleSet.nextState(cBuf.items[i - 1], cBuf.items[i], cBuf.items[i + 1]);
        std.debug.print("{d}", .{next_cell_value});
        nBuf.items[i] = next_cell_value;
    }
    cBuf.clearRetainingCapacity();
    try cBuf.appendSlice(nBuf.items);
}
