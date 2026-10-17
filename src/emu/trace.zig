//! trace.zig
//! Opt-in tracing of the emulated entry points, done through the `GLEMU_TRACE`

const std = @import("std");

const HANDLE = ?*anyopaque;

const GENERIC_WRITE: u32 = 0x40000000;
const FILE_SHARE_READ: u32 = 0x00000001;
const CREATE_ALWAYS: u32 = 0x00000002;
const FILE_ATTRIBUTE_NORMAL: u32 = 0x00000080;
const INVALID_HANDLE_VALUE: usize = @bitCast(@as(isize, -1));

extern "kernel32" fn GetEnvironmentVariableA(name: [*:0]const u8, buffer: [*]u8, size: u32) callconv(.winapi) u32;
extern "kernel32" fn CreateFileA(
    name: [*:0]const u8,
    access: u32,
    share: u32,
    security: ?*anyopaque,
    disposition: u32,
    flags: u32,
    template: ?*anyopaque,
) callconv(.winapi) HANDLE;
extern "kernel32" fn WriteFile(
    handle: HANDLE,
    buffer: [*]const u8,
    count: u32,
    written: ?*u32,
    overlapped: ?*anyopaque,
) callconv(.winapi) i32;

const default_budget: usize = 1_000_000;

var initialized = false;
var enabled = false;
var file: HANDLE = null;
var buffer: [64 * 1024]u8 = undefined;
var length: usize = 0;
var budget: usize = default_budget;

fn environmentHas(variable: [*:0]const u8) bool {
    var scratch: [16]u8 = undefined;
    const n = GetEnvironmentVariableA(variable, &scratch, scratch.len);
    return n != 0 and n < scratch.len;
}

fn ensureInitialised() void {
    if (initialized) {
        return;
    }
    initialized = true;
    if (!environmentHas("GLEMU_TRACE")) {
        return;
    }
    const handle = CreateFileA(
        "glemu_trace.log",
        GENERIC_WRITE,
        FILE_SHARE_READ,
        null,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        null,
    );
    if (@intFromPtr(handle) == INVALID_HANDLE_VALUE or handle == null) {
        return;
    }
    file = handle;
    enabled = true;
    write("== GLEmu trace ==\n");
}

/// Writes one formatted line
pub fn log(comptime format: []const u8, args: anytype) void {
    ensureInitialised();
    if (!enabled or budget == 0) {
        return;
    }
    budget -= 1;
    var scratch: [1024]u8 = undefined;
    const text = std.fmt.bufPrint(&scratch, format, args) catch return;
    write(text);
}

/// Logs a bare command name.
pub fn name(comptime text: []const u8) void {
    log(text ++ "\n", .{});
}

/// Whether tracing is currently active.
pub fn active() bool {
    ensureInitialised();
    return enabled;
}

fn write(text: []const u8) void {
    if (text.len == 0) {
        return;
    }
    if (text.len > buffer.len) {
        flush();
        writeRaw(text);
        return;
    }
    if (length + text.len > buffer.len) {
        flush();
    }
    @memcpy(buffer[length .. length + text.len], text);
    length += text.len;
}

fn writeRaw(text: []const u8) void {
    if (file) |handle| {
        var written: u32 = 0;
        _ = WriteFile(handle, text.ptr, @intCast(text.len), &written, null);
    }
}

/// Flushes buffered output.
pub fn flush() void {
    if (length == 0) {
        return;
    }
    writeRaw(buffer[0..length]);
    length = 0;
}
