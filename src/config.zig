const rl = @import("raylib");

// window
pub const TARGET_FPS: i32 = 120;
pub const SCREEN_WIDTH: i32 = 1920;
pub const SCREEN_HEIGHT: i32 = 1080;
pub const SCREEN_COLOR: rl.Color = .init(0, 0, 0, 210);
pub const TITLE: [:0]const u8 = "Automata";

// cell
pub const CELL_SIZE: u32 = 10;
pub const CELL_COLOR: rl.Color = .init(100, 100, 100, 100);

// grid
pub const GRID_WIDTH: u32 = 500;
pub const GRID_HEIGHT: u32 = 800;
