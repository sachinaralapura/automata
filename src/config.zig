const rl = @import("raylib");

// window
pub const TARGET_FPS: i32 = 120;
pub const SCREEN_WIDTH: i32 = 1920;
pub const SCREEN_HEIGHT: i32 = 1080;
pub const SCREEN_COLOR: rl.Color = .init(0, 0, 0, 255);
pub const TITLE: [:0]const u8 = "Automata";

// cell
pub const CELL_SIZE: u32 = 5;
pub const CELL_GAP: u32 = 1;
pub const CELL_COLOR: rl.Color = rl.Color.init(0, 247, 66, 255);

// grid
pub const GRID_ROWS: u32 = 250;
pub const GRID_COLS: u32 = 390;

// delay
pub const DELAY: u64 = 1_000_0000;

pub const RULE_STRING = "150";
