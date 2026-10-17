//! wgl.zig
//! The Windows GL context/loader entry points.

const std = @import("std");
const host = @import("host.zig");
const gl = @import("gl.zig");
const trace = @import("../emu/trace.zig");
const capture = @import("../emu/capture.zig");
const renderdoc = @import("../emu/renderdoc.zig");

const RECT = extern struct { left: i32, top: i32, right: i32, bottom: i32 };
extern "user32" fn GetClientRect(hwnd: ?*anyopaque, rect: *RECT) callconv(.winapi) BOOL;
extern "user32" fn WindowFromDC(hdc: HDC) callconv(.winapi) ?*anyopaque;

const HDC = ?*anyopaque;
const HGLRC = ?*anyopaque;
const BOOL = i32;
const UINT = u32;
const INT = i32;
const DWORD = u32;
const FLOAT = f32;
const PROC = ?*const anyopaque;
const LPCSTR = [*:0]const u8;
const COLORREF = u32;
const LPVOID = ?*anyopaque;

fn real(comptime T: type, name: [*:0]const u8) ?T {
    const raw = host.resolve(name) orelse return null;
    return @ptrCast(raw);
}

// Extension lookup table.
const ExtEntry = struct {
    name: [*:0]const u8,
    ptr: *const anyopaque,
};

const extension_table = [_]ExtEntry{
    .{ .name = "glActiveTextureARB", .ptr = @ptrCast(&gl.ActiveTextureARB) },
    .{ .name = "glClientActiveTextureARB", .ptr = @ptrCast(&gl.ClientActiveTextureARB) },
    .{ .name = "glMultiTexCoord2fARB", .ptr = @ptrCast(&gl.MultiTexCoord2f) },
    .{ .name = "glMultiTexCoord2fvARB", .ptr = @ptrCast(&gl.MultiTexCoord2fv) },
    .{ .name = "glMultiTexCoord1fARB", .ptr = @ptrCast(&gl.MultiTexCoord1f) },
    .{ .name = "glMultiTexCoord1fvARB", .ptr = @ptrCast(&gl.MultiTexCoord1fv) },
    .{ .name = "glMultiTexCoord3fARB", .ptr = @ptrCast(&gl.MultiTexCoord3f) },
    .{ .name = "glMultiTexCoord3fvARB", .ptr = @ptrCast(&gl.MultiTexCoord3fv) },
    .{ .name = "glMultiTexCoord4fARB", .ptr = @ptrCast(&gl.MultiTexCoord4f) },
    .{ .name = "glMultiTexCoord4fvARB", .ptr = @ptrCast(&gl.MultiTexCoord4fv) },
    .{ .name = "glMultiTexCoord2iARB", .ptr = @ptrCast(&gl.MultiTexCoord2i) },
    .{ .name = "glMultiTexCoord2sARB", .ptr = @ptrCast(&gl.MultiTexCoord2s) },
    .{ .name = "glMultiTexCoord2dARB", .ptr = @ptrCast(&gl.MultiTexCoord2d) },
    .{ .name = "glGenTexturesEXT", .ptr = @ptrCast(&gl.GenTexturesEXT) },
    .{ .name = "glBindTextureEXT", .ptr = @ptrCast(&gl.BindTextureEXT) },
    .{ .name = "glDeleteTexturesEXT", .ptr = @ptrCast(&gl.DeleteTexturesEXT) },
    .{ .name = "glIsTextureEXT", .ptr = @ptrCast(&gl.IsTextureEXT) },
    .{ .name = "glAreTexturesResidentEXT", .ptr = @ptrCast(&gl.AreTexturesResidentEXT) },
    .{ .name = "glPrioritizeTexturesEXT", .ptr = @ptrCast(&gl.PrioritizeTexturesEXT) },
    .{ .name = "glVertexPointerEXT", .ptr = @ptrCast(&gl.VertexPointerEXT) },
    .{ .name = "glNormalPointerEXT", .ptr = @ptrCast(&gl.NormalPointerEXT) },
    .{ .name = "glColorPointerEXT", .ptr = @ptrCast(&gl.ColorPointerEXT) },
    .{ .name = "glIndexPointerEXT", .ptr = @ptrCast(&gl.IndexPointerEXT) },
    .{ .name = "glTexCoordPointerEXT", .ptr = @ptrCast(&gl.TexCoordPointerEXT) },
    .{ .name = "glEdgeFlagPointerEXT", .ptr = @ptrCast(&gl.EdgeFlagPointerEXT) },
    .{ .name = "glGetPointervEXT", .ptr = @ptrCast(&gl.GetPointervEXT) },
    .{ .name = "glArrayElementEXT", .ptr = @ptrCast(&gl.ArrayElementEXT) },
    .{ .name = "glDrawArraysEXT", .ptr = @ptrCast(&gl.DrawArraysEXT) },
    .{ .name = "glMultiDrawArraysEXT", .ptr = @ptrCast(&gl.MultiDrawArraysEXT) },
    .{ .name = "glMultiDrawElementsEXT", .ptr = @ptrCast(&gl.MultiDrawElementsEXT) },
    .{ .name = "glBlendColorEXT", .ptr = @ptrCast(&gl.BlendColorEXT) },
    .{ .name = "glLockArraysEXT", .ptr = @ptrCast(&gl.LockArraysEXT) },
    .{ .name = "glUnlockArraysEXT", .ptr = @ptrCast(&gl.UnlockArraysEXT) },
    .{ .name = "glFogCoordfEXT", .ptr = @ptrCast(&gl.FogCoordfEXT) },
    .{ .name = "glFogCoordPointerEXT", .ptr = @ptrCast(&gl.FogCoordPointerEXT) },
    .{ .name = "glCompressedTexImage3DARB", .ptr = @ptrCast(&gl.CompressedTexImage3DARB) },
    .{ .name = "glCompressedTexImage2DARB", .ptr = @ptrCast(&gl.CompressedTexImage2DARB) },
    .{ .name = "glCompressedTexImage1DARB", .ptr = @ptrCast(&gl.CompressedTexImage1DARB) },
    .{ .name = "glCompressedTexSubImage3DARB", .ptr = @ptrCast(&gl.CompressedTexSubImage3DARB) },
    .{ .name = "glCompressedTexSubImage2DARB", .ptr = @ptrCast(&gl.CompressedTexSubImage2DARB) },
    .{ .name = "glCompressedTexSubImage1DARB", .ptr = @ptrCast(&gl.CompressedTexSubImage1DARB) },
    .{ .name = "glGetCompressedTexImageARB", .ptr = @ptrCast(&gl.GetCompressedTexImageARB) },
    .{ .name = "glColorTableEXT", .ptr = @ptrCast(&gl.ColorTableEXT) },
    .{ .name = "glColorSubTableEXT", .ptr = @ptrCast(&gl.ColorSubTableEXT) },
    .{ .name = "glGetColorTableEXT", .ptr = @ptrCast(&gl.GetColorTableEXT) },
    .{ .name = "glGetColorTableParameterivEXT", .ptr = @ptrCast(&gl.GetColorTableParameterivEXT) },
    .{ .name = "glGetColorTableParameterfvEXT", .ptr = @ptrCast(&gl.GetColorTableParameterfvEXT) },
    .{ .name = "glAvailableVertexBufferEXT", .ptr = @ptrCast(&gl.AvailableVertexBufferEXT) },
    .{ .name = "glAllocateVertexBufferEXT", .ptr = @ptrCast(&gl.AllocateVertexBufferEXT) },
    .{ .name = "glLockVertexBufferEXT", .ptr = @ptrCast(&gl.LockVertexBufferEXT) },
    .{ .name = "glUnlockVertexBufferEXT", .ptr = @ptrCast(&gl.UnlockVertexBufferEXT) },
    .{ .name = "glSetVertexBufferEXT", .ptr = @ptrCast(&gl.SetVertexBufferEXT) },
    .{ .name = "glOffsetVertexBufferEXT", .ptr = @ptrCast(&gl.OffsetVertexBufferEXT) },
    .{ .name = "glFillVertexBufferEXT", .ptr = @ptrCast(&gl.FillVertexBufferEXT) },
    .{ .name = "glFreeVertexBufferEXT", .ptr = @ptrCast(&gl.FreeVertexBufferEXT) },
    .{ .name = "glNPatchSetInt", .ptr = @ptrCast(&gl.NPatchSetInt) },
    .{ .name = "glNPatchSetFloat", .ptr = @ptrCast(&gl.NPatchSetFloat) },
    .{ .name = "glNPatchSetMode", .ptr = @ptrCast(&gl.NPatchSetMode) },
    .{ .name = "glBlendEquationEXT", .ptr = @ptrCast(&gl.BlendEquation) },
    .{ .name = "glBlendFuncSeparateEXT", .ptr = @ptrCast(&gl.BlendFuncSeparate) },
    .{ .name = "glSecondaryColor3fEXT", .ptr = @ptrCast(&gl.SecondaryColor3fEXT) },
    .{ .name = "glSecondaryColor3fvEXT", .ptr = @ptrCast(&gl.SecondaryColor3fvEXT) },
    .{ .name = "glSecondaryColor3ubEXT", .ptr = @ptrCast(&gl.SecondaryColor3ubEXT) },
    .{ .name = "glSecondaryColor3ubvEXT", .ptr = @ptrCast(&gl.SecondaryColor3ubvEXT) },
    .{ .name = "wglSwapIntervalEXT", .ptr = @ptrCast(&wglSwapIntervalEXT) },
};

fn lookup(name: LPCSTR) ?*const anyopaque {
    const wanted = std.mem.span(name);
    for (&extension_table) |entry| {
        if (std.mem.eql(u8, wanted, std.mem.span(entry.name))) {
            return entry.ptr;
        }
    }
    return null;
}

fn startsWithGl(name: LPCSTR) bool {
    return name[0] == 'g' and name[1] == 'l';
}

// Loader.

pub fn wglGetProcAddress(name: LPCSTR) callconv(.winapi) PROC {
    trace.log("wglGetProcAddress({s})\n", .{std.mem.span(name)});
    if (lookup(name)) |p| {
        return p;
    }

    if (startsWithGl(name)) {
        return null;
    }
    if (real(WglGetProcAddressFn, "wglGetProcAddress")) |f| {
        return f(name);
    }
    return host.resolve(name);
}

// Context management, forward to real driver

const WglCreateContextFn = *const fn (HDC) callconv(.winapi) HGLRC;
const WglDeleteContextFn = *const fn (HGLRC) callconv(.winapi) BOOL;
const WglMakeCurrentFn = *const fn (HDC, HGLRC) callconv(.winapi) BOOL;
const WglGetCurrentContextFn = *const fn () callconv(.winapi) HGLRC;
const WglGetCurrentDCFn = *const fn () callconv(.winapi) HDC;
const WglGetProcAddressFn = *const fn (LPCSTR) callconv(.winapi) PROC;
const WglCopyContextFn = *const fn (HGLRC, HGLRC, UINT) callconv(.winapi) BOOL;
const WglCreateLayerContextFn = *const fn (HDC, INT) callconv(.winapi) HGLRC;
const WglDescribeLayerPlaneFn = *const fn (HDC, INT, INT, UINT, LPVOID) callconv(.winapi) BOOL;
const WglGetLayerPaletteEntriesFn = *const fn (HDC, INT, INT, INT, [*]COLORREF) callconv(.winapi) INT;
const WglRealizeLayerPaletteFn = *const fn (HDC, INT, BOOL) callconv(.winapi) BOOL;
const WglSetLayerPaletteEntriesFn = *const fn (HDC, INT, INT, INT, [*]const COLORREF) callconv(.winapi) INT;
const WglShareListsFn = *const fn (HGLRC, HGLRC) callconv(.winapi) BOOL;
const WglSwapLayerBuffersFn = *const fn (HDC, UINT) callconv(.winapi) BOOL;
const WglUseFontBitmapsFn = *const fn (HDC, DWORD, DWORD, DWORD) callconv(.winapi) BOOL;
const WglUseFontOutlinesFn = *const fn (HDC, DWORD, DWORD, DWORD, FLOAT, FLOAT, INT, LPVOID) callconv(.winapi) BOOL;
const WglChoosePixelFormatFn = *const fn (HDC, ?*const anyopaque) callconv(.winapi) INT;
const WglDescribePixelFormatFn = *const fn (HDC, INT, UINT, ?*anyopaque) callconv(.winapi) INT;
const WglGetPixelFormatFn = *const fn (HDC) callconv(.winapi) INT;
const WglSetPixelFormatFn = *const fn (HDC, INT, ?*const anyopaque) callconv(.winapi) BOOL;
const WglSwapBuffersFn = *const fn (HDC) callconv(.winapi) BOOL;
const WglSwapIntervalExtFn = *const fn (INT) callconv(.winapi) BOOL;
const WglCreateContextAttribsArbFn = *const fn (HDC, HGLRC, ?[*]const INT) callconv(.winapi) HGLRC;

// WGL_ARB_create_context.
const WGL_CONTEXT_MAJOR_VERSION_ARB: INT = 0x2091;
const WGL_CONTEXT_MINOR_VERSION_ARB: INT = 0x2092;
const WGL_CONTEXT_PROFILE_MASK_ARB: INT = 0x9126;
const WGL_CONTEXT_CORE_PROFILE_BIT_ARB: INT = 0x00000001;

pub fn wglCreateContext(hdc: HDC) callconv(.winapi) HGLRC {
    // Create a core-profile context.
    if (createCoreContext(hdc)) |ctx| {
        trace.log("wglCreateContext -> core profile {any}\n", .{ctx});
        return ctx;
    }
    const result = if (real(WglCreateContextFn, "wglCreateContext")) |f| f(hdc) else null;
    trace.log("wglCreateContext -> legacy {any}\n", .{result});
    return result;
}

fn arbEntryPoint() ?WglCreateContextAttribsArbFn {
    const get_proc = real(WglGetProcAddressFn, "wglGetProcAddress") orelse return null;
    const raw = get_proc("wglCreateContextAttribsARB") orelse return null;
    return @ptrCast(raw);
}

/// Creates a core-profile context
fn createCoreContext(hdc: HDC) ?HGLRC {
    var create = arbEntryPoint();

    var temp: HGLRC = null;
    if (create == null) {
        if (real(WglCreateContextFn, "wglCreateContext")) |f| temp = f(hdc);
        if (temp) |t| {
            if (real(WglMakeCurrentFn, "wglMakeCurrent")) |make_current| _ = make_current(hdc, t);
            create = arbEntryPoint();
        }
    }
    defer if (temp) |t| {
        if (real(WglMakeCurrentFn, "wglMakeCurrent")) |make_current| _ = make_current(hdc, null);
        if (real(WglDeleteContextFn, "wglDeleteContext")) |delete| _ = delete(t);
    };

    const create_fn = create orelse return null;

    var attribs = [_]INT{
        WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
        WGL_CONTEXT_MINOR_VERSION_ARB, 3,
        WGL_CONTEXT_PROFILE_MASK_ARB,  WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
        0,
    };
    return create_fn(hdc, null, &attribs);
}
pub fn wglDeleteContext(ctx: HGLRC) callconv(.winapi) BOOL {
    trace.log("wglDeleteContext {any}\n", .{ctx});
    if (real(WglDeleteContextFn, "wglDeleteContext")) |f| return f(ctx);
    return 0;
}
pub fn wglMakeCurrent(hdc: HDC, ctx: HGLRC) callconv(.winapi) BOOL {
    const result = if (real(WglMakeCurrentFn, "wglMakeCurrent")) |f| f(hdc, ctx) else 0;
    trace.log("wglMakeCurrent hdc={any} ctx={any} -> {d}\n", .{ hdc, ctx, result });
    if (result != 0) renderdoc.init();
    return result;
}
pub fn wglGetCurrentContext() callconv(.winapi) HGLRC {
    if (real(WglGetCurrentContextFn, "wglGetCurrentContext")) |f| return f();
    return null;
}
pub fn wglGetCurrentDC() callconv(.winapi) HDC {
    if (real(WglGetCurrentDCFn, "wglGetCurrentDC")) |f| return f();
    return null;
}
pub fn wglCopyContext(src: HGLRC, dst: HGLRC, mask: UINT) callconv(.winapi) BOOL {
    if (real(WglCopyContextFn, "wglCopyContext")) |f| return f(src, dst, mask);
    return 0;
}
pub fn wglCreateLayerContext(hdc: HDC, plane: INT) callconv(.winapi) HGLRC {
    if (real(WglCreateLayerContextFn, "wglCreateLayerContext")) |f| return f(hdc, plane);
    return null;
}
pub fn wglDescribeLayerPlane(hdc: HDC, pixel_format: INT, plane: INT, bytes: UINT, descriptor: LPVOID) callconv(.winapi) BOOL {
    if (real(WglDescribeLayerPlaneFn, "wglDescribeLayerPlane")) |f| return f(hdc, pixel_format, plane, bytes, descriptor);
    return 0;
}
pub fn wglGetLayerPaletteEntries(hdc: HDC, plane: INT, first: INT, count: INT, entries: [*]COLORREF) callconv(.winapi) INT {
    if (real(WglGetLayerPaletteEntriesFn, "wglGetLayerPaletteEntries")) |f| return f(hdc, plane, first, count, entries);
    return 0;
}
pub fn wglRealizeLayerPalette(hdc: HDC, plane: INT, realize: BOOL) callconv(.winapi) BOOL {
    if (real(WglRealizeLayerPaletteFn, "wglRealizeLayerPalette")) |f| return f(hdc, plane, realize);
    return 0;
}
pub fn wglSetLayerPaletteEntries(hdc: HDC, plane: INT, first: INT, count: INT, entries: [*]const COLORREF) callconv(.winapi) INT {
    if (real(WglSetLayerPaletteEntriesFn, "wglSetLayerPaletteEntries")) |f| return f(hdc, plane, first, count, entries);
    return 0;
}
pub fn wglShareLists(share: HGLRC, source: HGLRC) callconv(.winapi) BOOL {
    if (real(WglShareListsFn, "wglShareLists")) |f| return f(share, source);
    return 0;
}
pub fn wglSwapLayerBuffers(hdc: HDC, planes: UINT) callconv(.winapi) BOOL {
    if (real(WglSwapLayerBuffersFn, "wglSwapLayerBuffers")) |f| return f(hdc, planes);
    return 0;
}
pub fn wglUseFontBitmapsA(hdc: HDC, first: DWORD, count: DWORD, list_base: DWORD) callconv(.winapi) BOOL {
    if (real(WglUseFontBitmapsFn, "wglUseFontBitmapsA")) |f| return f(hdc, first, count, list_base);
    return 0;
}
pub fn wglUseFontOutlinesA(hdc: HDC, first: DWORD, count: DWORD, list_base: DWORD, deviation: FLOAT, extrusion: FLOAT, format: INT, metrics: LPVOID) callconv(.winapi) BOOL {
    if (real(WglUseFontOutlinesFn, "wglUseFontOutlinesA")) |f| return f(hdc, first, count, list_base, deviation, extrusion, format, metrics);
    return 0;
}

// Pixel format and buffer swap.

pub fn wglChoosePixelFormat(hdc: HDC, descriptor: ?*const anyopaque) callconv(.winapi) INT {
    const result = if (real(WglChoosePixelFormatFn, "wglChoosePixelFormat")) |f| f(hdc, descriptor) else 0;
    trace.log("wglChoosePixelFormat -> {d}\n", .{result});
    return result;
}
pub fn wglDescribePixelFormat(hdc: HDC, format: INT, bytes: UINT, descriptor: ?*anyopaque) callconv(.winapi) INT {
    if (real(WglDescribePixelFormatFn, "wglDescribePixelFormat")) |f| return f(hdc, format, bytes, descriptor);
    return 0;
}
pub fn wglGetPixelFormat(hdc: HDC) callconv(.winapi) INT {
    if (real(WglGetPixelFormatFn, "wglGetPixelFormat")) |f| return f(hdc);
    return 0;
}
pub fn wglSetPixelFormat(hdc: HDC, format: INT, descriptor: ?*const anyopaque) callconv(.winapi) BOOL {
    const result = if (real(WglSetPixelFormatFn, "wglSetPixelFormat")) |f| f(hdc, format, descriptor) else 0;
    trace.log("wglSetPixelFormat format={d} -> {d}\n", .{ format, result });
    return result;
}
var swap_count: u32 = 0;

pub fn wglSwapBuffers(hdc: HDC) callconv(.winapi) BOOL {
    swap_count += 1;
    if (trace.active()) {
        trace.log("wglSwapBuffers #{d}\n", .{swap_count});
        switch (swap_count) {
            1, 5, 30, 120, 600 => {
                var rect: RECT = undefined;
                const hwnd = WindowFromDC(hdc);
                if (hwnd != null and GetClientRect(hwnd, &rect) != 0) {
                    capture.capture(rect.right - rect.left, rect.bottom - rect.top, swap_count);
                } else {
                    trace.log("capture[{d}]: no window rect\n", .{swap_count});
                }
            },
            else => {},
        }
    }
    const result = if (real(WglSwapBuffersFn, "wglSwapBuffers")) |f| f(hdc) else 0;
    renderdoc.onSwap(swap_count);
    trace.flush();
    return result;
}

const WglGetDefaultProcAddressFn = *const fn (LPCSTR) callconv(.winapi) PROC;
const WglSwapMultipleBuffersFn = *const fn (UINT, ?*const anyopaque) callconv(.winapi) DWORD;

pub fn wglGetDefaultProcAddress(name: LPCSTR) callconv(.winapi) PROC {
    if (real(WglGetDefaultProcAddressFn, "wglGetDefaultProcAddress")) |f| return f(name);
    return null;
}
pub fn wglSwapMultipleBuffers(count: UINT, swaps: ?*const anyopaque) callconv(.winapi) DWORD {
    if (real(WglSwapMultipleBuffersFn, "wglSwapMultipleBuffers")) |f| return f(count, swaps);
    return 0;
}
pub fn wglUseFontBitmapsW(hdc: HDC, first: DWORD, count: DWORD, list_base: DWORD) callconv(.winapi) BOOL {
    if (real(WglUseFontBitmapsFn, "wglUseFontBitmapsW")) |f| return f(hdc, first, count, list_base);
    return 0;
}
pub fn wglUseFontOutlinesW(hdc: HDC, first: DWORD, count: DWORD, list_base: DWORD, deviation: FLOAT, extrusion: FLOAT, format: INT, metrics: LPVOID) callconv(.winapi) BOOL {
    if (real(WglUseFontOutlinesFn, "wglUseFontOutlinesW")) |f| return f(hdc, first, count, list_base, deviation, extrusion, format, metrics);
    return 0;
}

// WGL_EXT_swap_control.

pub fn wglSwapIntervalEXT(interval: INT) callconv(.winapi) BOOL {
    if (real(WglSwapIntervalExtFn, "wglSwapIntervalEXT")) |f| return f(interval);
    return 1;
}
