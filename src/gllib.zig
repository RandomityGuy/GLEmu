//! Root module of the OpenGL 1.1 emulation engine.

pub const gl = @import("gl/gl.zig");
pub const compat = @import("gl/compat.zig");
pub const wgl = @import("gl/wgl.zig");
pub const host = @import("gl/host.zig");
pub const errors = @import("gl/error.zig");
pub const modern = @import("gl/modern.zig");
pub const exports = @import("gl/exports.zig");

pub const emu = struct {
    pub const state = @import("emu/state.zig");
    pub const math = @import("emu/math.zig");
    pub const shaders = @import("emu/shaders.zig");
};

// Force the compiler to analyse every public declaration of the API and export the commands
comptime {
    exports.exportAll();
}
