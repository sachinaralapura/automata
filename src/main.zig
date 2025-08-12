const std = @import("std");
const rand = std.crypto.random;
const cli = @import("arg.zig");
const Options = @import("arg.zig").Options;

const rl = @import("raylib");
const utils = @import("utils.zig");
const CONFIG = @import("config.zig");
const Grid = @import("Grid.zig").Grid(u8);
const Automata = @import("automata.zig").Automata;
const ArrayList = std.ArrayList(u8);
const Allocator = std.mem.Allocator;
const RuleSet = utils.RuleSet();

var w: f32 = CONFIG.SCREEN_WIDTH;
var h: f32 = CONFIG.SCREEN_HEIGHT;

var config = struct {
    rule: []const u8 = CONFIG.RULE_STRING,
    random_ini: bool = false,
    randon_rule: bool = true,
};

const helpMessage =
    \\Usage: <program_name> [options]
    \\This tool simulates a 1D cellular automaton.
    \\Options:
    \\  -h, Show this help message and exit.
    \\  -r, Use a random rule (0-255). Overrides the --rule option.
    \\  -i, Use a random initial state for the first row.
    \\  -t, Make the window transparent
    \\
    \\  --rule=<number>        Specify the rule number for the automaton, from 0 to 255.
    \\  --cellSize=<size>     The size of each cell in pixels, from 1 to 100.
    \\  --cellGap=<gap>       The gap between cells in pixels, from 1 to 100.
    \\  --cellColor=<r,g,b,a> The color of the active cells, specified as four comma-separated values (0-255). For example: "23,34,45,23".
    \\
    \\  --gridRows=<number>    Specify the number of rows in the grid
    \\  --gridCols=<number>    Specify the number of cols in the grid
    \\  --screenColor=<r,g,b,a> The color of the screen
    \\  --delay=<number>       delay between each row render in ms
;

fn run_automata(automata: *Automata, options: Options) !void {
    //--------------------------------------------------------------------------------------
    rl.setConfigFlags(.{ .window_resizable = true, .window_transparent = options.t });
    rl.initWindow(CONFIG.SCREEN_WIDTH, CONFIG.SCREEN_HEIGHT, CONFIG.TITLE);
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.setTargetFPS(CONFIG.TARGET_FPS); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------
    var row: usize = 1;
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        updateScreenDimension();
        rl.beginDrawing();
        defer rl.endDrawing();
        // draw
        //----------------------------------------------------------------------------------
        rl.clearBackground(options.screenColor);
        if (row < automata.gridRows) {
            try updateBuffer(&automata.ruleSet.?, &automata.currentBuffer.?, &(automata.nextBuffer.?));
            try automata.grid.?.appendRow(automata.nextBuffer.?.items, row);
            std.Thread.sleep(automata.delay);
            row += 1;
        }
        try drawAutomata(&automata.grid.?, automata.*);
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

fn drawAutomata(grid: *const Grid, automata: Automata) !void {
    for (0..grid.rows) |i| {
        for (0..grid.cols) |j| {
            if (try grid.get(i, j) == 1) {
                const posx: i32 = @intCast(j * automata.cellSize + automata.cellGap);
                const posy: i32 = @intCast(i * automata.cellSize + automata.cellGap);
                const width: i32 = @intCast(automata.cellSize);
                const height: i32 = @intCast(automata.cellSize);
                rl.drawRectangle(posx, posy, width, height, automata.cellColor);
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

fn printRow(buffer: []u8) void {
    for (0..CONFIG.GRID_COLS) |i| {
        std.debug.print("{d} | ", .{buffer[i]});
    }
    std.debug.print("\n", .{});
}

pub fn main() anyerror!void {
    var args = std.process.args();
    _ = args.next();
    const options = try cli.parseArgument(&args);
    if (options.h) {
        std.debug.print("{s}", .{helpMessage});
        return;
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    var automata: Automata = try Automata.init(allocator, options);
    defer automata.deinit();
    try run_automata(&automata, options);
}
