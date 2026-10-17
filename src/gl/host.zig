//! host.zig
//! Resolution of the *real* system OpenGL driver for the emulation's own use.

const std = @import("std");
const builtin = @import("builtin");

const windows = builtin.os.tag == .windows;

const HMODULE = ?*anyopaque;

const WglGetProcAddressFn = *const fn ([*:0]const u8) callconv(.winapi) ?*const anyopaque;

extern "kernel32" fn GetSystemDirectoryA(buffer: [*]u8, size: u32) callconv(.winapi) u32;
extern "kernel32" fn LoadLibraryA(name: [*:0]const u8) callconv(.winapi) HMODULE;
extern "kernel32" fn GetProcAddress(module: HMODULE, name: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
extern "kernel32" fn GetModuleHandleExA(flags: u32, address: ?*const anyopaque, module: *HMODULE) callconv(.winapi) i32;
extern "kernel32" fn GetModuleFileNameA(module: HMODULE, buffer: [*]u8, size: u32) callconv(.winapi) u32;

var real_module: HMODULE = null;
var real_wgl_get_proc_address: ?WglGetProcAddressFn = null;
var attempted = false;

/// Finds the system's real opengl path
fn systemOpenGLPath(buffer: []u8) ?[:0]const u8 {
    const n = GetSystemDirectoryA(buffer.ptr, @intCast(buffer.len));
    if (n == 0 or n >= buffer.len) {
        return null;
    }
    const suffix = "\\opengl32.dll";
    if (@as(usize, n) + suffix.len >= buffer.len) {
        return null;
    }
    @memcpy(buffer[n .. @as(usize, n) + suffix.len], suffix);
    buffer[@as(usize, n) + suffix.len] = 0;
    return buffer[0 .. @as(usize, n) + suffix.len :0];
}

fn ensureLoaded() void {
    if (attempted) {
        return;
    }
    attempted = true;
    if (!windows) {
        return;
    }

    var path_buffer: [320]u8 = undefined;
    if (systemOpenGLPath(&path_buffer)) |path| {
        real_module = LoadLibraryA(path.ptr);
    }
    if (real_module) |module| {
        if (GetProcAddress(module, "wglGetProcAddress")) |raw| {
            real_wgl_get_proc_address = @ptrCast(raw);
        }
    }
}

/// The real system OpenGL module
pub fn driverModule() HMODULE {
    ensureLoaded();
    return real_module;
}

/// Resolves an entry point against the real driver
pub fn resolve(name: [*:0]const u8) ?*const anyopaque {
    ensureLoaded();
    if (real_wgl_get_proc_address) |get_proc| {
        if (get_proc(name)) |p| {
            return p;
        }
    }
    if (real_module == null) {
        return null;
    }
    return GetProcAddress(real_module, name);
}

pub fn resolvedModuleName(name: [*:0]const u8, buffer: []u8) []const u8 {
    const p = resolve(name) orelse return "null";
    const from_address: u32 = 0x00000004; // GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS
    var module: HMODULE = null;
    if (GetModuleHandleExA(from_address, p, &module) == 0) return "?";
    const n = GetModuleFileNameA(module, buffer.ptr, @intCast(buffer.len));
    if (n == 0) return "?";
    var start: usize = 0;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        if (buffer[i] == '\\' or buffer[i] == '/') start = i + 1;
    }
    return buffer[start..n];
}
