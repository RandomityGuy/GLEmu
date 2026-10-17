//! capture.zig
//! One-shot framebuffer capture

const std = @import("std");

const modern = @import("../gl/modern.zig");
const trace = @import("trace.zig");

const HANDLE = ?*anyopaque;

const GENERIC_WRITE: u32 = 0x40000000;
const CREATE_ALWAYS: u32 = 0x00000002;
const FILE_ATTRIBUTE_NORMAL: u32 = 0x00000080;
const INVALID_HANDLE_VALUE: usize = @bitCast(@as(isize, -1));

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
extern "kernel32" fn CloseHandle(handle: HANDLE) callconv(.winapi) i32;

const GL_PACK_ALIGNMENT: u32 = 0x0D05;
const GL_BACK: u32 = 0x0405;
const GL_FRONT: u32 = 0x0404;
const GL_BGR: u32 = 0x80E0;
const GL_UNSIGNED_BYTE: u32 = 0x1401;

const max_width: usize = 2560;
const max_height: usize = 1600;

var pixels: [max_width * max_height * 3]u8 = undefined;

/// Reads back the back buffer and writes it as a BMP.
pub fn capture(width: i32, height: i32, index: u32) void {
    if (!trace.active()) {
        return;
    }
    if (width <= 0 or height <= 0 or width > max_width or height > max_height) {
        trace.log("capture[{d}]: skipped {d}x{d}\n", .{ index, width, height });
        return;
    }
    const read_pixels = modern.read_pixels orelse {
        trace.log("capture[{d}]: glReadPixels unavailable\n", .{index});
        return;
    };

    if (modern.pixel_store_i) |f| f(GL_PACK_ALIGNMENT, 1);

    const w: usize = @intCast(width);
    const h: usize = @intCast(height);
    const count = w * h * 3;

    // Read the back buffer else read the front buffer
    var buffer_name: []const u8 = "back";
    if (modern.read_buffer) |f| f(GL_BACK);
    read_pixels(0, 0, width, height, GL_BGR, GL_UNSIGNED_BYTE, &pixels);
    if (modern.get_error) |f| {
        if (f() != 0) {
            buffer_name = "front";
            if (modern.read_buffer) |rb| rb(GL_FRONT);
            read_pixels(0, 0, width, height, GL_BGR, GL_UNSIGNED_BYTE, &pixels);
            if (modern.get_error) |f2| {
                const second = f2();
                if (second != 0) {
                    trace.log("capture[{d}]: glReadPixels error 0x{x}\n", .{ index, second });
                }
            }
        }
    }

    var sum: u64 = 0;
    var nonzero: usize = 0;
    var min_value: u8 = 255;
    var max_value: u8 = 0;
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const v = pixels[i];
        sum += v;
        if (v != 0) nonzero += 1;
        if (v < min_value) min_value = v;
        if (v > max_value) max_value = v;
    }
    trace.log("capture[{d}]: {s} {d}x{d} mean={d} min={d} max={d} nonzero={d}/{d}\n", .{
        index, buffer_name, width, height, sum / @as(u64, @intCast(count)), min_value, max_value, nonzero, count,
    });

    writeBmp(width, height, index, w, h);
}

fn writeBmp(width: i32, height: i32, index: u32, w: usize, h: usize) void {
    const row_bytes = w * 3;
    const padding = (4 - (row_bytes & 3)) & 3;
    const row_size = row_bytes + padding;
    const image_size: u32 = @intCast(row_size * h);
    const file_size: u32 = 54 + image_size;

    var name_buffer: [64]u8 = undefined;
    const name_text = std.fmt.bufPrint(&name_buffer, "glemu_frame_{d}.bmp\x00", .{index}) catch return;
    const name: [*:0]const u8 = @ptrCast(name_text.ptr);

    const handle = CreateFileA(name, GENERIC_WRITE, 1, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, null);
    if (handle == null or @intFromPtr(handle) == INVALID_HANDLE_VALUE) {
        trace.log("capture[{d}]: could not create {s}\n", .{ index, name });
        return;
    }
    defer _ = CloseHandle(handle);

    var header: [54]u8 = @splat(0);
    header[0] = 'B';
    header[1] = 'M';
    std.mem.writeInt(u32, header[2..6], file_size, .little);
    std.mem.writeInt(u32, header[10..14], 54, .little);
    std.mem.writeInt(u32, header[14..18], 40, .little);
    std.mem.writeInt(i32, header[18..22], width, .little);
    std.mem.writeInt(i32, header[22..26], height, .little); // positive => bottom-up, matches GL
    std.mem.writeInt(u16, header[26..28], 1, .little);
    std.mem.writeInt(u16, header[28..30], 24, .little);
    std.mem.writeInt(u32, header[34..38], image_size, .little);

    writeAll(handle, &header);

    const zero = [_]u8{ 0, 0, 0 };
    var y: usize = 0;
    while (y < h) : (y += 1) {
        writeAll(handle, pixels[y * row_bytes .. y * row_bytes + row_bytes]);
        if (padding != 0) {
            writeAll(handle, zero[0..padding]);
        }
    }
}

fn writeAll(handle: HANDLE, bytes: []const u8) void {
    var written: u32 = 0;
    _ = WriteFile(handle, bytes.ptr, @intCast(bytes.len), &written, null);
}
