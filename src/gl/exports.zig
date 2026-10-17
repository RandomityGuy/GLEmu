//! exports.zig
//! Exports the OpenGL entry points under their historical C names.

const gl = @import("gl.zig");
const compat = @import("compat.zig");
const wgl = @import("wgl.zig");

/// Emits the C symbols of the whole API.
pub fn exportAll() void {
    @setEvalBranchQuota(200000);
    exportPrefixed(gl);
    exportPrefixed(compat);
    exportVerbatim(wgl);
}

fn exportPrefixed(comptime module: type) void {
    for (@typeInfo(module).@"struct".decl_names) |name| {
        const decl = @field(module, name);
        switch (@typeInfo(@TypeOf(decl))) {
            .@"fn" => @export(&decl, .{ .name = "gl" ++ name }),
            else => {},
        }
    }
}

fn exportVerbatim(comptime module: type) void {
    for (@typeInfo(module).@"struct".decl_names) |name| {
        const decl = @field(module, name);
        switch (@typeInfo(@TypeOf(decl))) {
            .@"fn" => @export(&decl, .{ .name = name }),
            else => {},
        }
    }
}
