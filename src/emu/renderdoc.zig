//! renderdoc.zig
//! Optional integration with RenderDoc.

const std = @import("std");
const builtin = @import("builtin");
const trace = @import("trace.zig");
const host = @import("../gl/host.zig");

const windows = builtin.os.tag == .windows;

const HMODULE = ?*anyopaque;

extern "kernel32" fn GetModuleHandleA(name: [*:0]const u8) callconv(.winapi) HMODULE;
extern "kernel32" fn GetProcAddress(module: HMODULE, name: [*:0]const u8) callconv(.winapi) ?*const anyopaque;
extern "kernel32" fn GetEnvironmentVariableA(name: [*:0]const u8, buffer: [*]u8, size: u32) callconv(.winapi) u32;

const GetApiFn = *const fn (u32, ?*?*const anyopaque) callconv(.winapi) i32;

const idx_mask_overlay_bits: usize = 8;
const idx_get_num_captures: usize = 13;
const idx_get_capture: usize = 14;
const idx_start_frame_capture: usize = 19;
const idx_end_frame_capture: usize = 21;

const MaskOverlayBitsFn = *const fn (u32, u32) callconv(.winapi) void;
const StartFrameCaptureFn = *const fn (?*anyopaque, ?*anyopaque) callconv(.winapi) void;
const EndFrameCaptureFn = *const fn (?*anyopaque, ?*anyopaque) callconv(.winapi) void;
const GetNumCapturesFn = *const fn () callconv(.winapi) u32;
const GetCaptureFn = *const fn (u32, [*]u8, *u32, [*]u8, *u32) callconv(.winapi) u32;

var initialized = false;
var active = false;
var api: ?[*]const ?*const anyopaque = null;
var capture_frame: ?u32 = null;

fn environmentValue(name: [*:0]const u8, buffer: []u8) ?[]const u8 {
    const size: u32 = @intCast(buffer.len);
    const n = GetEnvironmentVariableA(name, buffer.ptr, size);
    if (n == 0 or n >= size) return null;
    return buffer[0..@intCast(n)];
}

fn parseCaptureFrame() ?u32 {
    var buffer: [32]u8 = undefined;
    const value = environmentValue("GLEMU_RDC_CAPTURE", &buffer) orelse return null;
    var number: u32 = 0;
    var digits = false;
    for (value) |c| {
        if (c < '0' or c > '9') return 120;
        number = number * 10 + (c - '0');
        digits = true;
    }
    if (!digits) return 120;
    return @max(number, 1);
}

/// Locates RenderDoc in the process and configures it.
pub fn init() void {
    if (initialized) return;
    initialized = true;
    if (!windows) return;

    var module = GetModuleHandleA("renderdoc.dll");
    if (module == null) module = GetModuleHandleA("renderdocshim64.dll");
    if (module == null) module = GetModuleHandleA("renderdocshim32.dll");
    if (module == null) return;

    const raw = GetProcAddress(module, "RENDERDOC_GetAPI") orelse return;
    const get_api: GetApiFn = @ptrCast(raw);

    var out: ?*const anyopaque = null;
    if (get_api(10102, &out) != 1) return;
    const table: [*]const ?*const anyopaque = @ptrCast(@alignCast(out.?));

    api = table;
    active = true;

    // Clear the mask overlay
    if (table[idx_mask_overlay_bits]) |p| {
        const mask_overlay_bits: MaskOverlayBitsFn = @ptrCast(p);
        mask_overlay_bits(~@as(u32, 1), 0);
    }

    capture_frame = parseCaptureFrame();
    if (capture_frame != null) {
        trace.log("renderdoc: capture requested for frame {d}\n", .{capture_frame.?});
    }
    {
        var b1: [300]u8 = undefined;
        var b2: [300]u8 = undefined;
        trace.log("renderdoc: glDrawArrays host module = {s}\n", .{host.resolvedModuleName("glDrawArrays", &b1)});
        trace.log("renderdoc: wglSwapBuffers host module = {s}\n", .{host.resolvedModuleName("wglSwapBuffers", &b2)});
    }
    trace.flush();
}

/// Called after each buffer swap
pub fn onSwap(swapCount: u32) void {
    if (!initialized) init();
    if (!active) return;
    const table = api orelse return;

    const frame = capture_frame orelse return;
    if (swapCount == frame) {
        if (table[idx_start_frame_capture]) |p| {
            const start: StartFrameCaptureFn = @ptrCast(p);
            trace.log("renderdoc: start capture after swap {d}\n", .{swapCount});
            trace.flush();
            start(null, null);
        }
    } else if (swapCount == frame + 1) {
        if (table[idx_end_frame_capture]) |p| {
            const end: EndFrameCaptureFn = @ptrCast(p);
            trace.log("renderdoc: end capture at swap {d}\n", .{swapCount});
            trace.flush();
            end(null, null);
        }
        reportCaptures(table);
        capture_frame = null;
    }
}

/// Find renderdoc captures
fn reportCaptures(table: [*]const ?*const anyopaque) void {
    const num_fn = table[idx_get_num_captures] orelse return;
    const get_fn = table[idx_get_capture] orelse return;
    const num_captures: GetNumCapturesFn = @ptrCast(num_fn);
    const get_capture: GetCaptureFn = @ptrCast(get_fn);

    const count = num_captures();
    trace.log("renderdoc: {d} capture(s) saved\n", .{count});
    var i: u32 = 0;
    while (i < count and i < 8) : (i += 1) {
        var filename: [260]u8 = undefined;
        var path: [260]u8 = undefined;
        @memset(&filename, 0);
        @memset(&path, 0);
        var path_len: u32 = path.len;
        var file_len: u32 = filename.len;
        _ = get_capture(i, &filename, &path_len, &path, &file_len);
        trace.log("renderdoc: capture {d}: dir={s} file={s}\n", .{
            i,
            std.mem.sliceTo(&path, 0),
            std.mem.sliceTo(&filename, 0),
        });
    }
    trace.flush();
}
