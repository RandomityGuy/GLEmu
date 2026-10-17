//! tests.zig

const std = @import("std");
const testing = std.testing;

const gl = @import("gl/gl.zig");
const compat = @import("gl/compat.zig");
const wgl = @import("gl/wgl.zig");
const state = @import("emu/state.zig");

test "every public entry point is analysed" {
    @setEvalBranchQuota(200000);
    inline for (@typeInfo(gl).@"struct".decl_names) |name| {
        const decl = @field(gl, name);
        switch (@typeInfo(@TypeOf(decl))) {
            .@"fn" => _ = &decl,
            else => {},
        }
    }
    inline for (@typeInfo(compat).@"struct".decl_names) |name| {
        const decl = @field(compat, name);
        switch (@typeInfo(@TypeOf(decl))) {
            .@"fn" => _ = &decl,
            else => {},
        }
    }
    inline for (@typeInfo(wgl).@"struct".decl_names) |name| {
        const decl = @field(wgl, name);
        switch (@typeInfo(@TypeOf(decl))) {
            .@"fn" => _ = &decl,
            else => {},
        }
    }
}

test "capabilities can be enabled, disabled and queried" {
    gl.Disable(gl.BLEND);
    try testing.expectEqual(@as(u8, 0), gl.IsEnabled(gl.BLEND));
    gl.Enable(gl.BLEND);
    try testing.expectEqual(@as(u8, 1), gl.IsEnabled(gl.BLEND));
    gl.Disable(gl.BLEND);
}

test "the matrix mode round-trips" {
    gl.MatrixMode(gl.PROJECTION);
    var params = [_]i32{0};
    gl.GetIntegerv(gl.MATRIX_MODE, &params);
    try testing.expectEqual(@as(i32, @intCast(gl.PROJECTION)), params[0]);
    gl.MatrixMode(gl.MODELVIEW);
}

test "user clip planes are stored, enabled and read back" {
    const equation = [4]f64{ 1, 0, 0, -2 };
    gl.ClipPlane(gl.CLIP_PLANE0, &equation);
    gl.Enable(gl.CLIP_PLANE0);
    try testing.expectEqual(@as(u8, 1), gl.IsEnabled(gl.CLIP_PLANE0));

    var out = [4]f64{ 0, 0, 0, 0 };
    gl.GetClipPlane(gl.CLIP_PLANE0, &out);
    try testing.expectApproxEqAbs(@as(f64, 1), out[0], 1e-6);
    try testing.expectApproxEqAbs(@as(f64, -2), out[3], 1e-6);

    gl.Disable(gl.CLIP_PLANE0);
    try testing.expectEqual(@as(u8, 0), gl.IsEnabled(gl.CLIP_PLANE0));
}

test "push and pop attrib restore the current colour" {
    gl.Color4f(0.25, 0.5, 0.75, 1.0);
    var before = [4]f32{ 0, 0, 0, 0 };
    gl.GetFloatv(gl.CURRENT_COLOR, &before);

    gl.PushAttrib(gl.ALL_ATTRIB_BITS);
    gl.Color4f(1, 1, 1, 1);
    try testing.expectApproxEqAbs(@as(f32, 1), state.g_state.current.color[0], 1e-6);
    gl.PopAttrib();

    try testing.expectApproxEqAbs(before[0], state.g_state.current.color[0], 1e-6);
    try testing.expectApproxEqAbs(before[2], state.g_state.current.color[2], 1e-6);
}

test "light and material queries reflect their setters" {
    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();
    const position = [4]f32{ 0, 0, 1, 1 };
    gl.Lightfv(gl.LIGHT0, gl.POSITION, &position);
    var light_out = [4]f32{ 0, 0, 0, 0 };
    gl.GetLightfv(gl.LIGHT0, gl.POSITION, &light_out);
    try testing.expectApproxEqAbs(@as(f32, 1), light_out[3], 1e-6);

    const ambient = [4]f32{ 0.1, 0.2, 0.3, 1 };
    gl.Materialfv(gl.FRONT_AND_BACK, gl.AMBIENT, &ambient);
    var material_out = [4]f32{ 0, 0, 0, 0 };
    gl.GetMaterialfv(gl.FRONT_AND_BACK, gl.AMBIENT, &material_out);
    try testing.expectApproxEqAbs(@as(f32, 0.1), material_out[0], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 0.3), material_out[2], 1e-6);
}

test "spot light parameters are stored per source" {
    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();
    const direction = [4]f32{ 0, -1, 0, 0 };
    gl.Lightfv(gl.LIGHT1, gl.SPOT_DIRECTION, &direction);
    gl.Lightf(gl.LIGHT1, gl.SPOT_CUTOFF, 25);

    var out = [4]f32{ 0, 0, 0, 0 };
    gl.GetLightfv(gl.LIGHT1, gl.SPOT_DIRECTION, &out);
    try testing.expectApproxEqAbs(@as(f32, -1), out[1], 1e-6);
    gl.GetLightfv(gl.LIGHT1, gl.SPOT_CUTOFF, &out);
    try testing.expectApproxEqAbs(@as(f32, 25), out[0], 1e-6);
}

test "glLight transforms the position into eye coordinates" {
    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();
    gl.Translate(10, 0, 0);
    const position = [4]f32{ 1, 0, 0, 1 };
    gl.Lightfv(gl.LIGHT0, gl.POSITION, &position);
    var out = [4]f32{ 0, 0, 0, 0 };
    gl.GetLightfv(gl.LIGHT0, gl.POSITION, &out);
    try testing.expectApproxEqAbs(@as(f32, 11), out[0], 1e-5);
    try testing.expectApproxEqAbs(@as(f32, 1), out[3], 1e-5);

    const direction = [4]f32{ 0, 0, -1, 0 };
    gl.Lightfv(gl.LIGHT0, gl.POSITION, &direction);
    gl.GetLightfv(gl.LIGHT0, gl.POSITION, &out);
    try testing.expectApproxEqAbs(@as(f32, 0), out[3], 1e-5);
    try testing.expectApproxEqAbs(@as(f32, -1), out[2], 1e-5);

    gl.LoadIdentity();
    gl.Disable(gl.LIGHT0);
}

test "glTexGen stores the object-plane coefficients" {
    gl.ActiveTextureARB(gl.TEXTURE0_ARB);
    const plane = [4]f32{ 0.5, 0.25, 0.125, 1.0 };
    compat.TexGenfv(gl.S, gl.OBJECT_PLANE, &plane);
    var out = [4]f32{ 0, 0, 0, 0 };
    gl.GetTexGenfv(gl.S, gl.OBJECT_PLANE, &out);
    try testing.expectApproxEqAbs(@as(f32, 0.5), out[0], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 0.125), out[2], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 1.0), out[3], 1e-6);
}

test "texture environment is queried back" {
    gl.TexEnvi(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, @intCast(gl.DECAL));
    var mode = [_]f32{0};
    gl.GetTexEnvfv(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, &mode);
    try testing.expectEqual(@as(f32, @floatFromInt(gl.DECAL)), mode[0]);
}

test "ARB_multitexture keeps texture environment per unit" {
    gl.ActiveTextureARB(gl.TEXTURE0_ARB);
    gl.TexEnvi(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, @intCast(gl.MODULATE));
    gl.ActiveTextureARB(gl.TEXTURE2_ARB);
    gl.TexEnvi(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, @intCast(gl.DECAL));

    var active = [_]i32{0};
    gl.GetIntegerv(gl.ACTIVE_TEXTURE_ARB, &active);
    try testing.expectEqual(@as(i32, @intCast(gl.TEXTURE2_ARB)), active[0]);

    var mode = [_]f32{0};
    gl.GetTexEnvfv(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, &mode);
    try testing.expectEqual(@as(f32, @floatFromInt(gl.DECAL)), mode[0]);

    gl.ActiveTextureARB(gl.TEXTURE0_ARB);
    gl.GetTexEnvfv(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, &mode);
    try testing.expectEqual(@as(f32, @floatFromInt(gl.MODULATE)), mode[0]);
}

test "EXT_texture_env_combine state round-trips" {
    gl.ActiveTextureARB(gl.TEXTURE1_ARB);
    gl.TexEnvi(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, @intCast(gl.COMBINE_EXT));
    gl.TexEnvi(gl.TEXTURE_ENV, gl.COMBINE_RGB_EXT, @intCast(gl.INTERPOLATE_EXT));
    gl.TexEnvi(gl.TEXTURE_ENV, gl.SOURCE0_RGB_EXT, @intCast(gl.PRIMARY_COLOR_EXT));
    gl.TexEnvi(gl.TEXTURE_ENV, gl.RGB_SCALE_EXT, 2);

    var out = [_]f32{0};
    gl.GetTexEnvfv(gl.TEXTURE_ENV, gl.COMBINE_RGB_EXT, &out);
    try testing.expectEqual(@as(f32, @floatFromInt(gl.INTERPOLATE_EXT)), out[0]);
    gl.GetTexEnvfv(gl.TEXTURE_ENV, gl.SOURCE0_RGB_EXT, &out);
    try testing.expectEqual(@as(f32, @floatFromInt(gl.PRIMARY_COLOR_EXT)), out[0]);
    gl.GetTexEnvfv(gl.TEXTURE_ENV, gl.RGB_SCALE_EXT, &out);
    try testing.expectApproxEqAbs(@as(f32, 2), out[0], 1e-6);

    gl.ActiveTextureARB(gl.TEXTURE0_ARB);
}

test "MultiTexCoordARB stores coordinates per unit" {
    gl.ClientActiveTextureARB(gl.TEXTURE1_ARB);
    gl.MultiTexCoord2f(gl.TEXTURE1_ARB, 0.25, 0.75);
    try testing.expectApproxEqAbs(@as(f32, 0.25), state.g_state.texture_units[1].current_coord[0], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 0.75), state.g_state.texture_units[1].current_coord[1], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 0), state.g_state.texture_units[0].current_coord[0], 1e-6);
    gl.ClientActiveTextureARB(gl.TEXTURE0_ARB);
}

test "EXT_fog_coord stores the current fog coordinate and source" {
    gl.FogCoordfEXT(3.5);
    try testing.expectApproxEqAbs(@as(f32, 3.5), state.g_state.current.fog_coord, 1e-6);
    gl.Fogi(gl.FOG_COORDINATE_SOURCE_EXT, @intCast(gl.FOG_COORDINATE_EXT));
    try testing.expectEqual(gl.FOG_COORDINATE_EXT, @backingInt(state.g_state.fog.coord_source));
    gl.Fogi(gl.FOG_COORDINATE_SOURCE_EXT, @intCast(gl.FRAGMENT_DEPTH_EXT));
    try testing.expectEqual(gl.FRAGMENT_DEPTH_EXT, @backingInt(state.g_state.fog.coord_source));
}

test "the blend equation round-trips" {
    gl.BlendEquation(gl.FUNC_SUBTRACT);
    var out = [_]i32{0};
    gl.GetIntegerv(gl.BLEND_EQUATION, &out);
    try testing.expectEqual(@as(i32, @intCast(gl.FUNC_SUBTRACT)), out[0]);
    gl.BlendEquation(gl.FUNC_ADD);
}

test "EXT_compiled_vertex_array accepts lock and unlock" {
    gl.LockArraysEXT(0, 16);
    gl.UnlockArraysEXT();
}

test "EXT_blend_func_separate updates the blend factors" {
    gl.BlendFuncSeparate(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA, gl.ONE, gl.ONE);
    var out = [_]i32{0};
    gl.GetIntegerv(gl.BLEND_SRC, &out);
    try testing.expectEqual(@as(i32, @intCast(gl.SRC_ALPHA)), out[0]);
    try testing.expectEqual(@as(u32, gl.ONE), @backingInt(state.g_state.blend.src_alpha));
    gl.BlendFunc(gl.ONE, gl.ZERO);
}

test "glBlendFunc keeps the separate blend factors in sync" {
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
    try testing.expectEqual(@as(u32, gl.SRC_ALPHA), @backingInt(state.g_state.blend.src_rgb));
    try testing.expectEqual(@as(u32, gl.ONE_MINUS_SRC_ALPHA), @backingInt(state.g_state.blend.dst_rgb));
    try testing.expectEqual(@as(u32, gl.SRC_ALPHA), @backingInt(state.g_state.blend.src_alpha));
    try testing.expectEqual(@as(u32, gl.ONE_MINUS_SRC_ALPHA), @backingInt(state.g_state.blend.dst_alpha));
    gl.BlendFunc(gl.ONE, gl.ZERO);
}

test "point parameters and secondary colour are stored" {
    gl.PointParameterf(gl.POINT_SIZE_MAX, 8.0); // GL_POINT_SIZE_MAX
    try testing.expectApproxEqAbs(@as(f32, 8.0), state.g_state.raster.point_size_max, 1e-6);
    gl.SecondaryColor3f(0.1, 0.2, 0.3);
    try testing.expectApproxEqAbs(@as(f32, 0.2), state.g_state.current.secondary_color[1], 1e-6);
}

test "EXT_vertex_buffer is advertised as unavailable" {
    try testing.expectEqual(@as(u8, 0), gl.AvailableVertexBufferEXT());
    try testing.expectEqual(@as(i32, -1), gl.AllocateVertexBufferEXT(512, 0x8702, 0));
    gl.FreeVertexBufferEXT(-1);
}

test "ortho maps the viewport corners into clip space with w=1" {
    const math = @import("emu/math.zig");

    const apply = struct {
        fn f(mat: math.Mat4, v: [4]f32) [4]f32 {
            var out: [4]f32 = .{ 0, 0, 0, 0 };
            for (0..4) |row| {
                var sum: f32 = 0;
                for (0..4) |col| sum += mat.m[col * 4 + row] * v[col];
                out[row] = sum;
            }
            return out;
        }
    }.f;

    const m = math.Mat4.ortho(0, 1336, 768, 0, 0, 1);

    const lt = apply(m, .{ 0, 0, 0, 1 });
    try testing.expectApproxEqAbs(@as(f32, 1), lt[3], 1e-4);
    try testing.expectApproxEqAbs(@as(f32, -1), lt[0] / lt[3], 1e-4);
    try testing.expectApproxEqAbs(@as(f32, 1), lt[1] / lt[3], 1e-4);

    const rb = apply(m, .{ 1336, 768, 0, 1 });
    try testing.expectApproxEqAbs(@as(f32, 1), rb[3], 1e-4);
    try testing.expectApproxEqAbs(@as(f32, 1), rb[0] / rb[3], 1e-4);
    try testing.expectApproxEqAbs(@as(f32, -1), rb[1] / rb[3], 1e-4);
}

test "glGetFloatv returns the emulated model-view matrix" {
    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();
    gl.Translate(3, 4, 5);

    var out: [16]f32 = undefined;
    gl.GetFloatv(gl.MODELVIEW_MATRIX, &out);
    try testing.expectApproxEqAbs(@as(f32, 3), out[12], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 4), out[13], 1e-6);
    try testing.expectApproxEqAbs(@as(f32, 5), out[14], 1e-6);
    gl.LoadIdentity();
}

test "glGetDoublev returns all sixteen matrix values" {
    gl.MatrixMode(gl.MODELVIEW);
    gl.LoadIdentity();
    gl.Translate(1, 2, 3);

    var out: [16]f64 = undefined;
    gl.GetDoublev(gl.MODELVIEW_MATRIX, &out);
    try testing.expectApproxEqAbs(@as(f64, 1), out[12], 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 2), out[13], 1e-6);
    try testing.expectApproxEqAbs(@as(f64, 3), out[14], 1e-6);
    gl.LoadIdentity();
}
