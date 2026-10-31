//! state.zig
//! The OpenGL 1.1 state machine

const std = @import("std");
const gl = @import("../gl/gl.zig");
const modern = @import("../gl/modern.zig");
const math = @import("math.zig");
const shaders = @import("shaders.zig");
const trace = @import("trace.zig");
const types = @import("types.zig");

const GL_LINK_STATUS: u32 = 0x8B82;
const GL_INFO_LOG_LENGTH: u32 = 0x8B84;
const GL_VERSION: u32 = 0x1F02;
const GL_RENDERER: u32 = 0x1F01;
const GL_VENDOR: u32 = 0x1F00;

const Vertex = types.Vertex;

pub var g_state = types.State{};

// The attribute stack
var attrib_stack: [16]types.State = undefined;
var attrib_top: usize = 0;
var client_attrib_stack: [16]types.State = undefined;
var client_attrib_top: usize = 0;

// Vertex queue
const max_vertices = 65536;
var vertex_queue: [max_vertices]Vertex = undefined;
var vertex_count: usize = 0;

var scratch: [max_vertices]Vertex = undefined;

// Enable/Disable functions

fn hostEnable(cap: u32) void {
    if (modern.enable) |f| f(cap);
}
fn hostDisable(cap: u32) void {
    if (modern.disable) |f| f(cap);
}

fn hostError() void {}

// Initialize

fn compileShader(kind: u32, source: [:0]const u8) u32 {
    const create = modern.create_shader orelse return 0;
    const shader = create(kind);

    const sources = [_]?[*]const u8{source.ptr};
    const lengths = [_]i32{@intCast(source.len)};
    if (modern.shader_source) |f| f(shader, 1, &sources, &lengths);
    if (modern.compile_shader) |f| f(shader);

    return shader;
}

/// Set up all the state
fn ensureReady() void {
    if (g_state.host.initialized) {
        return;
    }
    trace.name("ensureReady: begin");
    modern.load();

    trace.log("ensureReady: create_shader={d} compile_shader={d} create_program={d} use_program={d} draw_arrays={d} gen_vertex_arrays={d} bind_buffer={d}\n", .{
        @intFromBool(modern.create_shader != null),
        @intFromBool(modern.compile_shader != null),
        @intFromBool(modern.create_program != null),
        @intFromBool(modern.use_program != null),
        @intFromBool(modern.draw_arrays != null),
        @intFromBool(modern.gen_vertex_arrays != null),
        @intFromBool(modern.bind_buffer != null),
    });
    trace.log("ensureReady: get_uniform_location={d} uniform_matrix_4fv={d} uniform_1i={d} uniform_1iv={d} uniform_4fv={d} uniform_3fv={d} uniform_1fv={d} uniform_1f={d} uniform_4f={d} vertex_attrib_pointer={d} enable_vertex_attrib_array={d} bind_vertex_array={d} buffer_data={d} active_texture={d}\n", .{
        @intFromBool(modern.get_uniform_location != null),
        @intFromBool(modern.uniform_matrix_4fv != null),
        @intFromBool(modern.uniform_1i != null),
        @intFromBool(modern.uniform_1iv != null),
        @intFromBool(modern.uniform_4fv != null),
        @intFromBool(modern.uniform_3fv != null),
        @intFromBool(modern.uniform_1fv != null),
        @intFromBool(modern.uniform_1f != null),
        @intFromBool(modern.uniform_4f != null),
        @intFromBool(modern.vertex_attrib_pointer != null),
        @intFromBool(modern.enable_vertex_attrib_array != null),
        @intFromBool(modern.bind_vertex_array != null),
        @intFromBool(modern.buffer_data != null),
        @intFromBool(modern.active_texture != null),
    });
    if (modern.get_string) |get| {
        const version = get(GL_VERSION);
        const renderer = get(GL_RENDERER);
        const vendor = get(GL_VENDOR);
        trace.log("ensureReady: host VERSION={s} RENDERER={s} VENDOR={s}\n", .{
            if (version) |v| std.mem.span(v) else @as([]const u8, "?"),
            if (renderer) |v| std.mem.span(v) else @as([]const u8, "?"),
            if (vendor) |v| std.mem.span(v) else @as([]const u8, "?"),
        });
    }

    // Shaders.
    const vs = compileShader(gl.VERTEX_SHADER, shaders.vertex_stage);
    const fs = compileShader(gl.FRAGMENT_SHADER, shaders.fragment_stage);

    if (modern.create_program) |create| {
        g_state.host.program = create();
    }
    if (modern.attach_shader) |attach| {
        attach(g_state.host.program, vs);
        attach(g_state.host.program, fs);
    }
    if (modern.link_program) |link| {
        link(g_state.host.program);
    }

    var link_status_arr: [1]i32 = .{0};
    if (modern.get_program_iv) |f| f(g_state.host.program, GL_LINK_STATUS, &link_status_arr);
    const link_status = link_status_arr[0];
    trace.log("ensureReady: program={d} linked={d} vs={d} fs={d}\n", .{ g_state.host.program, link_status, vs, fs });
    if (link_status == 0 and modern.get_program_info_log != null) {
        var info_len_arr: [1]i32 = .{0};
        if (modern.get_program_iv) |f| f(g_state.host.program, GL_INFO_LOG_LENGTH, &info_len_arr);
        const info_len = info_len_arr[0];
        if (info_len > 0 and info_len < 2048) {
            var info_buffer: [2048]u8 = undefined;
            if (modern.get_program_info_log) |f| f(g_state.host.program, info_len, null, &info_buffer);
            trace.log("ensureReady: link log: {s}\n", .{info_buffer[0..@intCast(info_len)]});
        }
    }

    // Vertex array + buffer.
    var vao: [1]u32 = .{0};
    if (modern.gen_vertex_arrays) |f| f(1, &vao);
    g_state.host.vao = vao[0];
    if (modern.bind_vertex_array) |f| f(g_state.host.vao);
    var vbo: [1]u32 = .{0};
    if (modern.gen_buffers) |f| f(1, &vbo);
    g_state.host.vbo = vbo[0];
    if (modern.bind_buffer) |f| f(gl.ARRAY_BUFFER, g_state.host.vbo);

    // Attribute locations.
    if (modern.get_attrib_location) |f| {
        const position = f(g_state.host.program, "a_position");
        const color = f(g_state.host.program, "a_color");
        const normal = f(g_state.host.program, "a_normal");
        setupAttrib(position, 4, @offsetOf(Vertex, "position"));
        setupAttrib(color, 4, @offsetOf(Vertex, "color"));
        setupAttrib(normal, 3, @offsetOf(Vertex, "normal"));
        const texcoord = [types.tex_units][*:0]const u8{
            "a_texcoord0", "a_texcoord1", "a_texcoord2", "a_texcoord3",
        };
        const base = @offsetOf(Vertex, "texcoord");
        inline for (0..types.tex_units) |unit| {
            setupAttrib(f(g_state.host.program, texcoord[unit]), 4, base + unit * @sizeOf([4]f32));
        }
        setupAttrib(f(g_state.host.program, "a_fogcoord"), 1, @offsetOf(Vertex, "fog_coord"));
    }

    // Uniform locations.
    if (modern.get_uniform_location) |f| {
        const u = &g_state.host.uniforms;
        u.transform.modelview = f(g_state.host.program, "u_modelview");
        u.transform.projection = f(g_state.host.program, "u_projection");
        u.transform.normalmatrix = f(g_state.host.program, "u_normalmatrix");
        u.transform.texturematrix = f(g_state.host.program, "u_texturematrix");
        u.transform.normalize = f(g_state.host.program, "u_normalize");
        u.lighting.lighting_enabled = f(g_state.host.program, "u_lighting_enabled");
        u.lighting.light_count = f(g_state.host.program, "u_light_count");
        u.lighting.light_ambient = f(g_state.host.program, "u_light_ambient");
        u.lighting.light_diffuse = f(g_state.host.program, "u_light_diffuse");
        u.lighting.light_specular = f(g_state.host.program, "u_light_specular");
        u.lighting.light_position = f(g_state.host.program, "u_light_position");
        u.lighting.light_attenuation = f(g_state.host.program, "u_light_attenuation");
        u.lighting.light_spot_direction = f(g_state.host.program, "u_light_spot_direction");
        u.lighting.light_spot_cutoff = f(g_state.host.program, "u_light_spot_cutoff");
        u.lighting.light_spot_exponent = f(g_state.host.program, "u_light_spot_exponent");
        u.lighting.light_model_ambient = f(g_state.host.program, "u_light_model_ambient");
        u.lighting.material_ambient = f(g_state.host.program, "u_material_ambient");
        u.lighting.material_diffuse = f(g_state.host.program, "u_material_diffuse");
        u.lighting.material_specular = f(g_state.host.program, "u_material_specular");
        u.lighting.material_emissive = f(g_state.host.program, "u_material_emissive");
        u.lighting.material_shininess = f(g_state.host.program, "u_material_shininess");
        u.texture.texgen_mode_s = f(g_state.host.program, "u_texgen_mode_s");
        u.texture.texgen_mode_t = f(g_state.host.program, "u_texgen_mode_t");
        u.texture.texgen_mode_r = f(g_state.host.program, "u_texgen_mode_r");
        u.texture.texgen_mode_q = f(g_state.host.program, "u_texgen_mode_q");
        u.texture.texgen_plane_s = f(g_state.host.program, "u_texgen_plane_s");
        u.texture.texgen_plane_t = f(g_state.host.program, "u_texgen_plane_t");
        u.texture.texgen_plane_r = f(g_state.host.program, "u_texgen_plane_r");
        u.texture.texgen_plane_q = f(g_state.host.program, "u_texgen_plane_q");
        u.fog.fog_enabled = f(g_state.host.program, "u_fog_enabled");
        u.fog.fog_mode = f(g_state.host.program, "u_fog_mode");
        u.fog.fog_source = f(g_state.host.program, "u_fog_source");
        u.fog.fog_density = f(g_state.host.program, "u_fog_density");
        u.fog.fog_start = f(g_state.host.program, "u_fog_start");
        u.fog.fog_end = f(g_state.host.program, "u_fog_end");
        u.fog.fog_color = f(g_state.host.program, "u_fog_color");
        u.texture.tex_enabled = f(g_state.host.program, "u_tex_enabled");
        u.texture.tex_env_mode = f(g_state.host.program, "u_tex_env_mode");
        u.texture.tex_env_color = f(g_state.host.program, "u_tex_env_color");
        u.texture.combine = f(g_state.host.program, "u_combine");
        u.texture.combine_rgb_func = f(g_state.host.program, "u_combine_rgb_func");
        u.texture.combine_alpha_func = f(g_state.host.program, "u_combine_alpha_func");
        u.texture.combine_rgb_source = f(g_state.host.program, "u_combine_rgb_source");
        u.texture.combine_rgb_operand = f(g_state.host.program, "u_combine_rgb_operand");
        u.texture.combine_alpha_source = f(g_state.host.program, "u_combine_alpha_source");
        u.texture.combine_alpha_operand = f(g_state.host.program, "u_combine_alpha_operand");
        u.texture.rgb_scale = f(g_state.host.program, "u_rgb_scale");
        u.texture.alpha_scale = f(g_state.host.program, "u_alpha_scale");
        u.texture.sampler = f(g_state.host.program, "u_texture");
        u.alpha_test.alpha_test_enabled = f(g_state.host.program, "u_alpha_test_enabled");
        u.alpha_test.alpha_func = f(g_state.host.program, "u_alpha_func");
        u.alpha_test.alpha_ref = f(g_state.host.program, "u_alpha_ref");
        u.clip.clip_plane = f(g_state.host.program, "u_clip_plane");
    }
    {
        const u = &g_state.host.uniforms;
        trace.log("ensureReady: locations modelview={d} projection={d} normalmatrix={d} texturematrix={d} tex_enabled={d} tex_env_mode={d} texture={d} clip_plane={d} light_count={d} material_diffuse={d}\n", .{
            u.transform.modelview, u.transform.projection, u.transform.normalmatrix, u.transform.texturematrix, u.texture.tex_enabled, u.texture.tex_env_mode, u.texture.sampler, u.clip.clip_plane, u.lighting.light_count, u.lighting.material_diffuse,
        });
    }

    if (modern.use_program) |f| f(g_state.host.program);
    // Bind each sampler of the array to the matching texture unit.
    if (modern.uniform_1i) |f| {
        inline for (0..types.tex_units) |unit| {
            f(g_state.host.uniforms.texture.sampler + @as(i32, @intCast(unit)), @intCast(unit));
        }
    }
    for (0..6) |i| {
        if (modern.enable) |f| f(gl.CLIP_DISTANCE0 + @as(u32, @intCast(i)));
    }

    g_state.host.initialized = true;
}

fn setupAttrib(location: i32, size: i32, offset: usize) void {
    if (location < 0) {
        return;
    }
    if (modern.enable_vertex_attrib_array) |f| f(@intCast(location));
    if (modern.vertex_attrib_pointer) |f| {
        f(@intCast(location), size, gl.FLOAT, 0, @sizeOf(Vertex), @ptrFromInt(offset));
    }
}

// Apply the large set of uniforms for the OpenGL state

fn applyUniforms() void {
    ensureReady();
    const u = &g_state.host.uniforms;
    const mv = g_state.transform.modelview.current();
    const proj = g_state.transform.projection.current();
    const tex_units = types.tex_units;

    if (modern.uniform_matrix_4fv) |f| {
        f(u.transform.modelview, 1, 0, &mv.m);
        f(u.transform.projection, 1, 0, &proj.m);
        var texture_matrices: [types.tex_units]math.Mat4 = undefined;
        for (&texture_matrices, 0..) |*matrix, unit| {
            matrix.* = g_state.texture_units[unit].matrix.current();
        }
        f(u.transform.texturematrix, types.tex_units, 0, &texture_matrices[0].m);
        const normal = mv.upperLeft3();
        f(u.transform.normalmatrix, 1, 0, &normal.m);
    }
    if (modern.uniform_1i) |f| {
        f(u.transform.normalize, if (g_state.lighting.normalize) 1 else 0);
        f(u.lighting.lighting_enabled, if (g_state.lighting.enabled) 1 else 0);
    }

    // Lighting.
    if (modern.uniform_1i) |f| {
        var count: i32 = 0;
        for (g_state.lighting.lights, 0..) |source, i| {
            if (source.enabled) count = @intCast(i + 1);
        }
        f(u.lighting.light_count, count);
    }
    if (modern.uniform_4fv) |f| {
        var ambient: [16]f32 = undefined;
        var diffuse: [16]f32 = undefined;
        var specular: [16]f32 = undefined;
        var position: [16]f32 = undefined;
        for (g_state.lighting.lights, 0..) |source, i| {
            const on = source.enabled;
            var k: usize = 0;
            while (k < 4) : (k += 1) {
                ambient[i * 4 + k] = if (on) source.ambient[k] else 0;
                diffuse[i * 4 + k] = if (on) source.diffuse[k] else 0;
                specular[i * 4 + k] = if (on) source.specular[k] else 0;
                position[i * 4 + k] = source.position[k];
            }
        }
        f(u.lighting.light_ambient, 4, &ambient);
        f(u.lighting.light_diffuse, 4, &diffuse);
        f(u.lighting.light_specular, 4, &specular);
        f(u.lighting.light_position, 4, &position);
    }
    if (modern.uniform_3fv) |f| {
        var attenuation: [12]f32 = undefined;
        for (g_state.lighting.lights, 0..) |source, i| {
            var k: usize = 0;
            while (k < 3) : (k += 1) {
                attenuation[i * 3 + k] = source.attenuation[k];
            }
        }
        f(u.lighting.light_attenuation, 4, &attenuation);
    }
    if (modern.uniform_3fv) |f| {
        var spot_direction: [12]f32 = undefined;
        for (g_state.lighting.lights, 0..) |source, i| {
            var k: usize = 0;
            while (k < 3) : (k += 1) {
                spot_direction[i * 3 + k] = source.spot_direction[k];
            }
        }
        f(u.lighting.light_spot_direction, 4, &spot_direction);
    }
    if (modern.uniform_1fv) |f| {
        var spot_cutoff: [4]f32 = undefined;
        var spot_exponent: [4]f32 = undefined;
        for (g_state.lighting.lights, 0..) |source, i| {
            spot_cutoff[i] = source.spot_cutoff;
            spot_exponent[i] = source.spot_exponent;
        }
        f(u.lighting.light_spot_cutoff, 4, &spot_cutoff);
        f(u.lighting.light_spot_exponent, 4, &spot_exponent);
    }
    if (modern.uniform_4f) |f| {
        var mat_ambient = g_state.lighting.material.ambient;
        var mat_diffuse = g_state.lighting.material.diffuse;
        var mat_specular = g_state.lighting.material.specular;
        var mat_emissive = g_state.lighting.material.emissive;
        if (g_state.lighting.color_material.enabled) {
            switch (g_state.lighting.color_material.mode) {
                .ambient => mat_ambient = g_state.current.color,
                .diffuse => mat_diffuse = g_state.current.color,
                .specular => mat_specular = g_state.current.color,
                .emission => mat_emissive = g_state.current.color,
                else => {
                    mat_ambient = g_state.current.color;
                    mat_diffuse = g_state.current.color;
                },
            }
        }
        f(u.lighting.light_model_ambient, g_state.lighting.model_ambient[0], g_state.lighting.model_ambient[1], g_state.lighting.model_ambient[2], g_state.lighting.model_ambient[3]);
        f(u.lighting.material_ambient, mat_ambient[0], mat_ambient[1], mat_ambient[2], mat_ambient[3]);
        f(u.lighting.material_diffuse, mat_diffuse[0], mat_diffuse[1], mat_diffuse[2], mat_diffuse[3]);
        f(u.lighting.material_specular, mat_specular[0], mat_specular[1], mat_specular[2], mat_specular[3]);
        f(u.lighting.material_emissive, mat_emissive[0], mat_emissive[1], mat_emissive[2], mat_emissive[3]);
        f(u.fog.fog_color, g_state.fog.color[0], g_state.fog.color[1], g_state.fog.color[2], g_state.fog.color[3]);
    }
    if (modern.uniform_1f) |f| {
        f(u.lighting.material_shininess, g_state.lighting.material.shininess);
        f(u.fog.fog_density, g_state.fog.density);
        f(u.fog.fog_start, g_state.fog.start);
        f(u.fog.fog_end, g_state.fog.end);
        f(u.alpha_test.alpha_ref, g_state.alpha_test.ref);
    }

    // Texturing, texgen and EXT_texture_env_combine (per texture unit).
    if (modern.uniform_1iv) |f| {
        var enable: [tex_units]i32 = undefined;
        var env_mode: [tex_units]i32 = undefined;
        var combine: [tex_units]i32 = undefined;
        var rgb_func: [tex_units]i32 = undefined;
        var alpha_func: [tex_units]i32 = undefined;
        var tg_s: [tex_units]i32 = undefined;
        var tg_t: [tex_units]i32 = undefined;
        var tg_r: [tex_units]i32 = undefined;
        var tg_q: [tex_units]i32 = undefined;
        for (0..tex_units) |unit| {
            const enabled = g_state.texture_units[unit].enabled_2d or g_state.texture_units[unit].enabled_1d;
            enable[unit] = if (enabled) 1 else 0;
            env_mode[unit] = @intCast(@backingInt(g_state.texture_units[unit].env_mode));
            combine[unit] = if (g_state.texture_units[unit].combine_enabled) 1 else 0;
            rgb_func[unit] = @intCast(@backingInt(g_state.texture_units[unit].combine_rgb.func));
            alpha_func[unit] = @intCast(@backingInt(g_state.texture_units[unit].combine_alpha.func));
            tg_s[unit] = if (g_state.texture_units[unit].texgen_enabled[0]) @intCast(@backingInt(g_state.texture_units[unit].texgen[0].mode)) else 0;
            tg_t[unit] = if (g_state.texture_units[unit].texgen_enabled[1]) @intCast(@backingInt(g_state.texture_units[unit].texgen[1].mode)) else 0;
            tg_r[unit] = if (g_state.texture_units[unit].texgen_enabled[2]) @intCast(@backingInt(g_state.texture_units[unit].texgen[2].mode)) else 0;
            tg_q[unit] = if (g_state.texture_units[unit].texgen_enabled[3]) @intCast(@backingInt(g_state.texture_units[unit].texgen[3].mode)) else 0;
        }
        f(u.texture.tex_enabled, tex_units, &enable);
        f(u.texture.tex_env_mode, tex_units, &env_mode);
        f(u.texture.combine, tex_units, &combine);
        f(u.texture.combine_rgb_func, tex_units, &rgb_func);
        f(u.texture.combine_alpha_func, tex_units, &alpha_func);
        f(u.texture.texgen_mode_s, tex_units, &tg_s);
        f(u.texture.texgen_mode_t, tex_units, &tg_t);
        f(u.texture.texgen_mode_r, tex_units, &tg_r);
        f(u.texture.texgen_mode_q, tex_units, &tg_q);

        var rgb_source: [tex_units * 3]i32 = undefined;
        var rgb_operand: [tex_units * 3]i32 = undefined;
        var alpha_source: [tex_units * 3]i32 = undefined;
        var alpha_operand: [tex_units * 3]i32 = undefined;
        for (0..tex_units) |unit| {
            for (0..3) |k| {
                rgb_source[unit * 3 + k] = @intCast(@backingInt(g_state.texture_units[unit].combine_rgb.source[k]));
                rgb_operand[unit * 3 + k] = @intCast(@backingInt(g_state.texture_units[unit].combine_rgb.operand[k]));
                alpha_source[unit * 3 + k] = @intCast(@backingInt(g_state.texture_units[unit].combine_alpha.source[k]));
                alpha_operand[unit * 3 + k] = @intCast(@backingInt(g_state.texture_units[unit].combine_alpha.operand[k]));
            }
        }
        f(u.texture.combine_rgb_source, tex_units * 3, &rgb_source);
        f(u.texture.combine_rgb_operand, tex_units * 3, &rgb_operand);
        f(u.texture.combine_alpha_source, tex_units * 3, &alpha_source);
        f(u.texture.combine_alpha_operand, tex_units * 3, &alpha_operand);
    }
    if (modern.uniform_1fv) |f| {
        var rgb_scale: [tex_units]f32 = undefined;
        var alpha_scale: [tex_units]f32 = undefined;
        for (0..tex_units) |unit| {
            rgb_scale[unit] = g_state.texture_units[unit].rgb_scale;
            alpha_scale[unit] = g_state.texture_units[unit].combine_alpha_scale;
        }
        f(u.texture.rgb_scale, tex_units, &rgb_scale);
        f(u.texture.alpha_scale, tex_units, &alpha_scale);
    }
    if (modern.uniform_4fv) |f| {
        var env_color: [tex_units * 4]f32 = undefined;
        for (0..tex_units) |unit| {
            for (0..4) |k| {
                env_color[unit * 4 + k] = g_state.texture_units[unit].env_color[k];
            }
        }
        f(u.texture.tex_env_color, tex_units, &env_color);

        var tg_plane_s: [tex_units * 4]f32 = undefined;
        var tg_plane_t: [tex_units * 4]f32 = undefined;
        var tg_plane_r: [tex_units * 4]f32 = undefined;
        var tg_plane_q: [tex_units * 4]f32 = undefined;
        for (0..tex_units) |unit| {
            for (0..4) |k| {
                tg_plane_s[unit * 4 + k] = g_state.texture_units[unit].texgen[0].plane[k];
                tg_plane_t[unit * 4 + k] = g_state.texture_units[unit].texgen[1].plane[k];
                tg_plane_r[unit * 4 + k] = g_state.texture_units[unit].texgen[2].plane[k];
                tg_plane_q[unit * 4 + k] = g_state.texture_units[unit].texgen[3].plane[k];
            }
        }
        f(u.texture.texgen_plane_s, tex_units, &tg_plane_s);
        f(u.texture.texgen_plane_t, tex_units, &tg_plane_t);
        f(u.texture.texgen_plane_r, tex_units, &tg_plane_r);
        f(u.texture.texgen_plane_q, tex_units, &tg_plane_q);
    }
    if (modern.uniform_1i) |f| {
        f(u.fog.fog_enabled, if (g_state.fog.enabled) 1 else 0);
        f(u.fog.fog_mode, @intCast(@backingInt(g_state.fog.mode)));
        f(u.fog.fog_source, @intCast(@backingInt(g_state.fog.coord_source)));
        f(u.alpha_test.alpha_test_enabled, if (g_state.alpha_test.enabled) 1 else 0);
        f(u.alpha_test.alpha_func, @intCast(@backingInt(g_state.alpha_test.func)));
    }
    if (modern.uniform_4fv) |f| {
        // A disabled clip plane is represented by the plane (0, 0, 0, 1)
        var clip_planes: [24]f32 = undefined;
        for (g_state.clip.planes, 0..) |plane, i| {
            if (g_state.clip.enabled[i]) {
                for (0..4) |k| {
                    clip_planes[i * 4 + k] = plane[k];
                }
            } else {
                clip_planes[i * 4 + 0] = 0;
                clip_planes[i * 4 + 1] = 0;
                clip_planes[i * 4 + 2] = 0;
                clip_planes[i * 4 + 3] = 1;
            }
        }
        f(u.clip.clip_plane, 6, &clip_planes);
    }
}

fn applyHostState() void {
    ensureReady();

    // Depth test
    if (g_state.depth.enabled) {
        hostEnable(gl.DEPTH_TEST);
    } else {
        hostDisable(gl.DEPTH_TEST);
    }
    if (modern.depth_func) |f| f(@backingInt(g_state.depth.func));
    if (modern.depth_mask) |f| f(if (g_state.depth.mask) 1 else 0);

    // Culling
    if (g_state.raster.cull_face_enabled) {
        hostEnable(gl.CULL_FACE);
    } else {
        hostDisable(gl.CULL_FACE);
    }
    if (modern.cull_face) |f| {
        f(switch (g_state.raster.cull_face) {
            .front => gl.FRONT,
            .back => gl.BACK,
            else => gl.FRONT_AND_BACK,
        });
    }
    if (modern.front_face) |f| f(@backingInt(g_state.raster.front_face));

    // Blending
    if (g_state.blend.enabled) {
        hostEnable(gl.BLEND);
    } else {
        hostDisable(gl.BLEND);
    }
    if (modern.blend_func) |f| f(@backingInt(g_state.blend.src), @backingInt(g_state.blend.dst));
    if (modern.blend_func_separate) |f| {
        f(
            @backingInt(g_state.blend.src_rgb),
            @backingInt(g_state.blend.dst_rgb),
            @backingInt(g_state.blend.src_alpha),
            @backingInt(g_state.blend.dst_alpha),
        );
    }
    if (modern.blend_equation) |f| f(@backingInt(g_state.blend.equation));

    // Logical operation
    if (g_state.blend.logic_enabled) {
        hostEnable(gl.COLOR_LOGIC_OP);
    } else {
        hostDisable(gl.COLOR_LOGIC_OP);
    }
    if (modern.logic_op) |f| f(@backingInt(g_state.blend.logic_op));

    // Scissor
    if (g_state.framebuffer.scissor_test) {
        hostEnable(gl.SCISSOR_TEST);
    } else {
        hostDisable(gl.SCISSOR_TEST);
    }
    if (modern.scissor) |f| f(g_state.framebuffer.scissor_box[0], g_state.framebuffer.scissor_box[1], g_state.framebuffer.scissor_box[2], g_state.framebuffer.scissor_box[3]);

    // Dither
    if (g_state.raster.dither) {
        hostEnable(gl.DITHER);
    } else {
        hostDisable(gl.DITHER);
    }

    // Stencil test
    if (g_state.stencil.enabled) {
        hostEnable(gl.STENCIL_TEST);
    } else {
        hostDisable(gl.STENCIL_TEST);
    }
    if (modern.stencil_mask) |f| f(g_state.stencil.write_mask);
    if (modern.stencil_func) |f| f(@backingInt(g_state.stencil.func), g_state.stencil.ref, g_state.stencil.value_mask);
    if (modern.stencil_op) |f| {
        f(
            @backingInt(g_state.stencil.fail),
            @backingInt(g_state.stencil.pass_depth_fail),
            @backingInt(g_state.stencil.pass_depth_pass),
        );
    }

    // Polygon offset (depth-slope scaled), used for decals and mirror passes.
    if (g_state.raster.polygon_offset_fill) {
        hostEnable(gl.POLYGON_OFFSET_FILL);
    } else {
        hostDisable(gl.POLYGON_OFFSET_FILL);
    }
    if (modern.polygon_offset) |f| f(g_state.raster.polygon_offset_factor, g_state.raster.polygon_offset_units);

    // Colour mask
    if (modern.color_mask) |f| {
        f(@intFromBool(g_state.framebuffer.color_mask[0]), @intFromBool(g_state.framebuffer.color_mask[1]), @intFromBool(g_state.framebuffer.color_mask[2]), @intFromBool(g_state.framebuffer.color_mask[3]));
    }

    // Line and point sizes
    if (modern.line_width) |f| f(g_state.raster.line_width);
    if (modern.point_size) |f| f(g_state.raster.point_size);

    // Polygon rasterization mode
    if (modern.polygon_mode) |f| {
        const mode: types.PolygonMode = if (g_state.raster.polygon_mode_front == g_state.raster.polygon_mode_back)
            g_state.raster.polygon_mode_front
        else
            .fill;
        f(gl.FRONT_AND_BACK, @backingInt(mode));
    }

    // Viewport
    if (modern.viewport) |f| f(g_state.framebuffer.viewport[0], g_state.framebuffer.viewport[1], g_state.framebuffer.viewport[2], g_state.framebuffer.viewport[3]);
}

/// Turns primitives to triangles
fn expandPrimitive(mode: u32, in: []const Vertex, out: []Vertex) ?[]const Vertex {
    switch (mode) {
        gl.QUADS => {
            if (in.len < 4) return out[0..0];
            const quads = in.len / 4;
            var n: usize = 0;
            var q: usize = 0;
            while (q < quads) : (q += 1) {
                const a = in[q * 4 + 0];
                const b = in[q * 4 + 1];
                const c = in[q * 4 + 2];
                const d = in[q * 4 + 3];
                out[n] = a;
                n += 1;
                out[n] = b;
                n += 1;
                out[n] = c;
                n += 1;
                out[n] = a;
                n += 1;
                out[n] = c;
                n += 1;
                out[n] = d;
                n += 1;
            }
            return out[0..n];
        },
        gl.QUAD_STRIP => {
            if (in.len < 4) return out[0..0];
            var n: usize = 0;
            var i: usize = 0;
            while (i + 3 < in.len) : (i += 2) {
                const a = in[i + 0];
                const b = in[i + 1];
                const c = in[i + 2];
                const d = in[i + 3];
                out[n] = a;
                n += 1;
                out[n] = b;
                n += 1;
                out[n] = c;
                n += 1;
                out[n] = c;
                n += 1;
                out[n] = b;
                n += 1;
                out[n] = d;
                n += 1;
            }
            return out[0..n];
        },
        gl.POLYGON => {
            if (in.len < 3) return out[0..0];
            var n: usize = 0;
            var i: usize = 1;
            while (i + 1 < in.len) : (i += 1) {
                out[n] = in[0];
                n += 1;
                out[n] = in[i];
                n += 1;
                out[n] = in[i + 1];
                n += 1;
            }
            return out[0..n];
        },
        else => return null,
    }
}

var draw_counter: u32 = 0;

fn submit(mode: u32, vertices: []const Vertex) void {
    if (vertices.len == 0) {
        return;
    }
    ensureReady();
    applyUniforms();
    applyHostState();

    var host_mode = mode;
    var data = vertices;
    if (expandPrimitive(mode, vertices, scratch[0..])) |expanded| {
        host_mode = gl.TRIANGLES;
        data = expanded;
    }

    trace.log("DRAW mode=0x{x} verts={d} host_mode=0x{x}\n", .{ mode, data.len, host_mode });
    if (trace.active()) {
        trace.log("TEXSTATE c0(en={d} mode=0x{x} cmb={d} f=0x{x} s0=0x{x} o0=0x{x} s1=0x{x} s2=0x{x}) c1(en={d} mode=0x{x} cmb={d} f=0x{x} s0=0x{x} s1=0x{x} s2=0x{x}) ca={d} mdiff_a={d} cc_a={d}\n", .{
            @intFromBool(g_state.texture_units[0].enabled_2d), g_state.texture_units[0].env_mode, @intFromBool(g_state.texture_units[0].combine_enabled), g_state.texture_units[0].combine_rgb.func, g_state.texture_units[0].combine_rgb.source[0], g_state.texture_units[0].combine_rgb.operand[0], g_state.texture_units[0].combine_rgb.source[1], g_state.texture_units[0].combine_rgb.source[2],
            @intFromBool(g_state.texture_units[1].enabled_2d), g_state.texture_units[1].env_mode, @intFromBool(g_state.texture_units[1].combine_enabled), g_state.texture_units[1].combine_rgb.func, g_state.texture_units[1].combine_rgb.source[0], g_state.texture_units[1].combine_rgb.source[1],  g_state.texture_units[1].combine_rgb.source[2], @intFromBool(g_state.client_arrays.color.enabled),
            g_state.lighting.material.diffuse[3],              g_state.current.color[3],
        });
    }

    draw_counter += 1;
    if (draw_counter <= 3) {
        const p = g_state.transform.projection.current();
        const m = g_state.transform.modelview.current();
        trace.log("MATRIX proj=[{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d}]\n", .{
            p.m[0], p.m[1], p.m[2],  p.m[3],  p.m[4],  p.m[5],  p.m[6],  p.m[7],
            p.m[8], p.m[9], p.m[10], p.m[11], p.m[12], p.m[13], p.m[14], p.m[15],
        });
        trace.log("MATRIX mv=[{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d}]\n", .{
            m.m[0], m.m[1], m.m[2],  m.m[3],  m.m[4],  m.m[5],  m.m[6],  m.m[7],
            m.m[8], m.m[9], m.m[10], m.m[11], m.m[12], m.m[13], m.m[14], m.m[15],
        });
        trace.log("MATRIX v0=({d},{d},{d},{d})\n", .{ data[0].position[0], data[0].position[1], data[0].position[2], data[0].position[3] });
    }

    // Texture binding
    if (modern.active_texture) |f| {
        if (modern.bind_texture) |bind| {
            for (0..types.tex_units) |unit| {
                f(gl.TEXTURE0 + @as(u32, @intCast(unit)));
                bind(gl.TEXTURE_2D, g_state.texture_units[unit].bound_2d);
            }
        }
        f(gl.TEXTURE0);
    } else if (modern.bind_texture) |f| {
        f(gl.TEXTURE_2D, g_state.texture_units[0].bound_2d);
    }

    if (modern.bind_buffer) |f| f(gl.ARRAY_BUFFER, g_state.host.vbo);
    if (modern.buffer_data) |f| {
        f(gl.ARRAY_BUFFER, @intCast(data.len * @sizeOf(Vertex)), @ptrCast(data.ptr), gl.STREAM_DRAW);
    }
    if (modern.bind_vertex_array) |f| f(g_state.host.vao);
    if (modern.draw_arrays) |f| f(host_mode, 0, @intCast(data.len));
    if (trace.active()) {
        if (modern.get_error) |f| {
            const error_code = f();
            if (error_code != 0) {
                trace.log("HOST GL ERROR 0x{x} after draw\n", .{error_code});
            }
        }
        trace.flush();
    }
}

// Client-array reading.

fn readComponent(base: [*]const u8, index: i32, size: usize, type_: types.DataType, stride: i32, component: usize, default: f32) f32 {
    if (component >= size) {
        return default;
    }
    const step: usize = if (stride != 0) @intCast(stride) else size * typeSize(type_);
    const element = base + @as(usize, @intCast(index)) * step;
    const p = element + component * typeSize(type_);
    return switch (type_) {
        .float => @as(*align(1) const f32, @ptrCast(p)).*,
        .double => @floatCast(@as(*align(1) const f64, @ptrCast(p)).*),
        .int => @floatFromInt(@as(*align(1) const i32, @ptrCast(p)).*),
        .short => @floatFromInt(@as(*align(1) const i16, @ptrCast(p)).*),
        .byte => @floatFromInt(@as(*align(1) const i8, @ptrCast(p)).*),
        .unsigned_byte => @as(f32, @floatFromInt(@as(*align(1) const u8, @ptrCast(p)).*)) / 255.0,
        .unsigned_short => @as(f32, @floatFromInt(@as(*align(1) const u16, @ptrCast(p)).*)) / 65535.0,
        .unsigned_int => @floatFromInt(@as(*align(1) const u32, @ptrCast(p)).*),
    };
}

fn typeSize(type_: types.DataType) usize {
    return switch (type_) {
        .float => 4,
        .double => 8,
        .int, .unsigned_int => 4,
        .short, .unsigned_short => 2,
        .byte, .unsigned_byte => 1,
    };
}

// Buffer-backed array access.

const max_array_maps = 12;

const ArrayMap = struct {
    buffer: u32 = 0,
    ptr: [*]const u8 = undefined,
};

var array_maps: [max_array_maps]ArrayMap = undefined;
var array_map_count: usize = 0;

fn mapBufferForRead(buffer: u32) ?[*]const u8 {
    for (array_maps[0..array_map_count]) |m| {
        if (m.buffer == buffer) return m.ptr;
    }
    if (array_map_count >= max_array_maps) return null;
    const bind = modern.bind_buffer orelse return null;
    const map = modern.map_buffer orelse return null;
    bind(gl.ARRAY_BUFFER, buffer);
    const p = map(gl.ARRAY_BUFFER, gl.READ_ONLY) orelse return null;
    const bytes: [*]const u8 = @ptrCast(p);
    array_maps[array_map_count] = .{ .buffer = buffer, .ptr = bytes };
    array_map_count += 1;
    return bytes;
}

fn beginArrayRead() void {
    array_map_count = 0;
}

fn endArrayRead() void {
    const bind = modern.bind_buffer;
    const unmap = modern.unmap_buffer;
    for (array_maps[0..array_map_count]) |m| {
        if (bind) |f| f(gl.ARRAY_BUFFER, m.buffer);
        if (unmap) |f| _ = f(gl.ARRAY_BUFFER);
    }
    array_map_count = 0;
}

fn arrayBase(a: *const types.ClientArray) ?[*]const u8 {
    if (a.buffer != 0) {
        const mapped = mapBufferForRead(a.buffer) orelse return null;
        const offset: usize = if (a.pointer) |p| @intFromPtr(p) else 0;
        return mapped + offset;
    }
    if (a.pointer) |p| return @as([*]const u8, @ptrCast(p));
    return null;
}

fn indexByteBase(indices: *const anyopaque) ?[*]const u8 {
    if (g_state.client_arrays.element_array_buffer_binding != 0) {
        const mapped = mapBufferForRead(g_state.client_arrays.element_array_buffer_binding) orelse return null;
        return mapped + @intFromPtr(indices);
    }
    return @as([*]const u8, @ptrCast(indices));
}

fn vertexFromArrays(index: i32) Vertex {
    var v = Vertex{};
    const va = &g_state.client_arrays.vertex;
    if (va.enabled) {
        if (arrayBase(va)) |base| {
            v.position = .{
                readComponent(base, index, @intCast(va.size), va.type, va.stride, 0, 0),
                readComponent(base, index, @intCast(va.size), va.type, va.stride, 1, 0),
                readComponent(base, index, @intCast(va.size), va.type, va.stride, 2, 0),
                readComponent(base, index, @intCast(va.size), va.type, va.stride, 3, 1),
            };
        } else {
            v.position = .{ 0, 0, 0, 1 };
        }
    } else {
        v.position = .{ 0, 0, 0, 1 };
    }
    const ca = &g_state.client_arrays.color;
    if (ca.enabled) {
        if (arrayBase(ca)) |base| {
            v.color = .{
                readComponent(base, index, @intCast(ca.size), ca.type, ca.stride, 0, 1),
                readComponent(base, index, @intCast(ca.size), ca.type, ca.stride, 1, 1),
                readComponent(base, index, @intCast(ca.size), ca.type, ca.stride, 2, 1),
                readComponent(base, index, @intCast(ca.size), ca.type, ca.stride, 3, 1),
            };
        } else {
            v.color = g_state.current.color;
        }
    } else {
        v.color = g_state.current.color;
    }
    const na = &g_state.client_arrays.normal;
    if (na.enabled) {
        if (arrayBase(na)) |base| {
            v.normal = .{
                readComponent(base, index, 3, na.type, na.stride, 0, 0),
                readComponent(base, index, 3, na.type, na.stride, 1, 0),
                readComponent(base, index, 3, na.type, na.stride, 2, 1),
            };
        } else {
            v.normal = g_state.current.normal;
        }
    } else {
        v.normal = g_state.current.normal;
    }
    for (0..types.tex_units) |unit| {
        const a = &g_state.texture_units[unit].coord_array;
        if (a.enabled) {
            if (arrayBase(a)) |base| {
                v.texcoord[unit] = .{
                    readComponent(base, index, @intCast(a.size), a.type, a.stride, 0, 0),
                    readComponent(base, index, @intCast(a.size), a.type, a.stride, 1, 0),
                    readComponent(base, index, @intCast(a.size), a.type, a.stride, 2, 0),
                    readComponent(base, index, @intCast(a.size), a.type, a.stride, 3, 1),
                };
                continue;
            }
        }
        v.texcoord[unit] = g_state.texture_units[unit].current_coord;
    }
    const fa = &g_state.client_arrays.fogcoord;
    if (fa.enabled) {
        if (arrayBase(fa)) |base| {
            v.fog_coord = readComponent(base, index, 1, fa.type, fa.stride, 0, 0);
        } else {
            v.fog_coord = g_state.current.fog_coord;
        }
    } else {
        v.fog_coord = g_state.current.fog_coord;
    }
    return v;
}

pub fn getError() u32 {
    _ = &hostError;
    return @backingInt(@import("../gl/error.zig").gErrorHandler.get());
}

// Immediate mode

pub fn beginCommand(mode: u32) void {
    trace.log("BEGIN mode=0x{x}\n", .{mode});
    g_state.immediate.begun = true;
    g_state.immediate.begin_mode = mode;
    vertex_count = 0;
}

pub fn endCommand() void {
    if (!g_state.immediate.begun) {
        return;
    }
    g_state.immediate.begun = false;
    submit(g_state.immediate.begin_mode, vertex_queue[0..vertex_count]);
    vertex_count = 0;
}

/// Store the current texcoords
fn currentTexcoords() [types.tex_units][4]f32 {
    var tc: [types.tex_units][4]f32 = undefined;
    for (0..types.tex_units) |unit| tc[unit] = g_state.texture_units[unit].current_coord;
    return tc;
}

fn pushVertex(position: [4]f32) void {
    if (!g_state.immediate.begun or vertex_count >= max_vertices) {
        return;
    }
    vertex_queue[vertex_count] = .{
        .position = position,
        .color = g_state.current.color,
        .normal = g_state.current.normal,
        .texcoord = currentTexcoords(),
    };
    vertex_count += 1;
}

fn unpack_float_array(v: anytype, comptime T: type, comptime default_value: T) T {
    const args = @TypeOf(v);
    const info = @typeInfo(args);

    if (info != .@"struct" or !info.@"struct".is_tuple) {
        @compileError("Expected an anonymous tuple or struct, e.g., .{r, g, b}");
    }

    const len = info.@"struct".field_names.len;
    const target_len = @typeInfo(T).array.len;

    if (len > target_len) {
        @compileError("Tuple has too many components.");
    }

    var out: T = default_value;
    const ElemType = @typeInfo(T).array.child;

    inline for (info.@"struct".field_names, info.@"struct".field_types, 0..) |f_name, F_Type, i| {
        const val = @field(v, f_name);

        out[i] = switch (@typeInfo(F_Type)) {
            .float => |f| if (f.bits > 32) @floatCast(val) else @as(ElemType, val),
            .comptime_float => @floatCast(val),
            .int => |int| switch (int.signedness) {
                .signed => @floatFromInt(val),
                .unsigned => blk: {
                    const max_val = comptime @as(ElemType, @floatFromInt(std.math.maxInt(F_Type)));
                    break :blk @as(ElemType, @floatFromInt(val)) / max_val;
                },
            },
            .comptime_int => @floatFromInt(val),
            else => @compileError("Unsupported coordinate type: " ++ @typeName(F_Type)),
        };
    }

    return out;
}

pub fn vertex(v: anytype) void {
    const out = unpack_float_array(v, [4]f32, .{ 0.0, 0.0, 0.0, 1.0 });
    pushVertex(out);
}

pub fn set_color(v: anytype) void {
    const out = unpack_float_array(v, [4]f32, .{ 0.0, 0.0, 0.0, 1.0 });
    g_state.current.color = out;
}

pub fn set_index(index: f32) void {
    g_state.current.index = index;
}

pub fn set_normal(nx: f32, ny: f32, nz: f32) void {
    g_state.current.normal = .{ nx, ny, nz };
}

pub fn set_tex_coord(v: anytype) void {
    const out = unpack_float_array(v, [4]f32, .{ 0, 0, 0, 1 });
    g_state.texture_units[g_state.client_arrays.active_texture].current_coord = out;
}

//  ARB_multitexture

pub fn activeTextureARB(texture: u32) void {
    trace.log("ACTIVE_TEXTURE 0x{x}\n", .{texture});
    g_state.texture.active_texture = textureUnitIndex(texture);
}
pub fn clientActiveTextureARB(texture: u32) void {
    g_state.client_arrays.active_texture = textureUnitIndex(texture);
}

pub fn set_multitex_coord(target: u32, v: anytype) void {
    const out = unpack_float_array(v, [4]f32, .{ 0, 0, 0, 1 });
    g_state.texture_units[textureUnitIndex(target)].current_coord = out;
}

/// Map a `GL_TEXTUREn_ARB` target onto a texture-unit index.
fn textureUnitIndex(texture: u32) usize {
    if (texture >= gl.TEXTURE0_ARB and texture < gl.TEXTURE0_ARB + types.tex_units) {
        return texture - gl.TEXTURE0_ARB;
    }
    return 0;
}
pub fn edgeFlag(flag: u8) void {
    g_state.current.edge_flag = flag != 0;
}

// Client arrays

pub fn enableClientState(capability: u32) void {
    trace.log("ENABLE_CLIENT_STATE 0x{x}\n", .{capability});
    switch (capability) {
        gl.VERTEX_ARRAY => g_state.client_arrays.vertex.enabled = true,
        gl.NORMAL_ARRAY => g_state.client_arrays.normal.enabled = true,
        gl.COLOR_ARRAY => g_state.client_arrays.color.enabled = true,
        gl.TEXTURE_COORD_ARRAY => g_state.texture_units[g_state.client_arrays.active_texture].coord_array.enabled = true,
        gl.INDEX_ARRAY => g_state.client_arrays.index.enabled = true,
        gl.FOG_COORDINATE_ARRAY_EXT => g_state.client_arrays.fogcoord.enabled = true,
        else => {},
    }
}

pub fn disableClientState(capability: u32) void {
    switch (capability) {
        gl.VERTEX_ARRAY => g_state.client_arrays.vertex.enabled = false,
        gl.NORMAL_ARRAY => g_state.client_arrays.normal.enabled = false,
        gl.COLOR_ARRAY => g_state.client_arrays.color.enabled = false,
        gl.TEXTURE_COORD_ARRAY => g_state.texture_units[g_state.client_arrays.active_texture].coord_array.enabled = false,
        gl.INDEX_ARRAY => g_state.client_arrays.index.enabled = false,
        gl.FOG_COORDINATE_ARRAY_EXT => g_state.client_arrays.fogcoord.enabled = false,
        else => {},
    }
}

pub fn vertexPointer(size: i32, type_: u32, stride: i32, pointer: ?*const anyopaque) void {
    trace.log("VERTEX_POINTER size={d} type=0x{x} stride={d} ptr={d}\n", .{ size, type_, stride, @intFromBool(pointer != null) });
    g_state.client_arrays.vertex.size = size;
    g_state.client_arrays.vertex.type = .fromGL(type_);
    g_state.client_arrays.vertex.stride = stride;
    g_state.client_arrays.vertex.buffer = g_state.client_arrays.array_buffer_binding;
    g_state.client_arrays.vertex.pointer = pointer;
}
pub fn normalPointer(type_: u32, stride: i32, pointer: ?*const anyopaque) void {
    g_state.client_arrays.normal.size = 3;
    g_state.client_arrays.normal.type = .fromGL(type_);
    g_state.client_arrays.normal.stride = stride;
    g_state.client_arrays.normal.buffer = g_state.client_arrays.array_buffer_binding;
    g_state.client_arrays.normal.pointer = pointer;
}
pub fn colorPointer(size: i32, type_: u32, stride: i32, pointer: ?*const anyopaque) void {
    trace.log("COLOR_POINTER size={d} type=0x{x} stride={d} ptr={d}\n", .{ size, type_, stride, @intFromBool(pointer != null) });
    g_state.client_arrays.color.size = size;
    g_state.client_arrays.color.type = .fromGL(type_);
    g_state.client_arrays.color.stride = stride;
    g_state.client_arrays.color.buffer = g_state.client_arrays.array_buffer_binding;
    g_state.client_arrays.color.pointer = pointer;
}
pub fn texCoordPointer(size: i32, type_: u32, stride: i32, pointer: ?*const anyopaque) void {
    trace.log("TEXCOORD_POINTER size={d} type=0x{x} stride={d} ptr={d} unit={d}\n", .{ size, type_, stride, @intFromBool(pointer != null), g_state.client_arrays.active_texture });
    const a = &g_state.texture_units[g_state.client_arrays.active_texture].coord_array;
    a.size = size;
    a.type = .fromGL(type_);
    a.stride = stride;
    a.buffer = g_state.client_arrays.array_buffer_binding;
    a.pointer = pointer;
}
pub fn indexPointer(type_: u32, stride: i32, pointer: ?*const anyopaque) void {
    g_state.client_arrays.index.type = .fromGL(type_);
    g_state.client_arrays.index.stride = stride;
    g_state.client_arrays.index.buffer = g_state.client_arrays.array_buffer_binding;
    g_state.client_arrays.index.pointer = pointer;
}
pub fn edgeFlagPointer(stride: i32, pointer: ?*const anyopaque) void {
    _ = stride;
    _ = pointer;
}

// Buffer objects (OpenGL 1.5 / ARB_vertex_buffer_object) and generic vertex attributes (OpenGL 2.0).

pub fn genBuffers(n: i32, buffers: [*]u32) void {
    if (modern.gen_buffers) |f| {
        f(n, buffers);
    } else {
        var i: usize = 0;
        while (i < @as(usize, @intCast(n))) : (i += 1) buffers[i] = 0;
    }
}

pub fn deleteBuffers(n: i32, buffers: [*]const u32) void {
    var i: usize = 0;
    while (i < @as(usize, @intCast(n))) : (i += 1) {
        const name = buffers[i];
        if (name == g_state.client_arrays.array_buffer_binding) g_state.client_arrays.array_buffer_binding = 0;
        if (name == g_state.client_arrays.element_array_buffer_binding) g_state.client_arrays.element_array_buffer_binding = 0;
    }
    if (modern.delete_buffers) |f| f(n, buffers);
}

pub fn bindBuffer(target: u32, buffer: u32) void {
    switch (target) {
        gl.ARRAY_BUFFER => g_state.client_arrays.array_buffer_binding = buffer,
        gl.ELEMENT_ARRAY_BUFFER => g_state.client_arrays.element_array_buffer_binding = buffer,
        else => {},
    }
    if (modern.bind_buffer) |f| f(target, buffer);
}

pub fn bufferData(target: u32, size: isize, data: ?*const anyopaque, usage: u32) void {
    if (modern.buffer_data) |f| f(target, size, data, usage);
}

pub fn bufferSubData(target: u32, offset: isize, size: isize, data: ?*const anyopaque) void {
    if (modern.buffer_sub_data) |f| f(target, offset, size, data);
}

pub fn isBuffer(buffer: u32) u8 {
    if (modern.is_buffer) |f| return f(buffer);
    return 0;
}

pub fn mapBuffer(target: u32, access: u32) ?*anyopaque {
    if (modern.map_buffer) |f| return f(target, access);
    return null;
}

pub fn unmapBuffer(target: u32) u8 {
    if (modern.unmap_buffer) |f| return f(target);
    return 1;
}

pub fn getBufferParameteriv(target: u32, pname: u32, params: [*]i32) void {
    if (modern.get_buffer_parameteriv) |f| {
        f(target, pname, params);
    } else {
        params[0] = 0;
    }
}

pub fn getBufferPointerv(target: u32, pname: u32, params: [*]?*anyopaque) void {
    _ = target;
    _ = pname;
    params[0] = null;
}

pub fn getBufferSubData(target: u32, offset: isize, size: isize, data: ?*anyopaque) void {
    if (modern.get_buffer_sub_data) |f| f(target, offset, size, data);
}

/// Maps a generic vertex attribute index onto the fixed-function array
fn attribArray(index: u32) ?*types.ClientArray {
    return switch (index) {
        0 => &g_state.client_arrays.vertex,
        2 => &g_state.client_arrays.normal,
        3 => &g_state.client_arrays.color,
        5 => &g_state.client_arrays.fogcoord,
        8 => &g_state.texture_units[0].coord_array,
        9 => &g_state.texture_units[1].coord_array,
        10 => &g_state.texture_units[2].coord_array,
        11 => &g_state.texture_units[3].coord_array,
        else => null,
    };
}

pub fn vertexAttribPointer(index: u32, size: i32, type_: u32, normalized: u8, stride: i32, pointer: ?*const anyopaque) void {
    if (attribArray(index)) |a| {
        a.size = size;
        a.type = .fromGL(type_);
        a.stride = stride;
        a.normalized = normalized != 0;
        a.buffer = g_state.client_arrays.array_buffer_binding;
        a.pointer = pointer;
    }
}

pub fn enableVertexAttribArray(index: u32) void {
    if (attribArray(index)) |a| a.enabled = true;
}

pub fn disableVertexAttribArray(index: u32) void {
    if (attribArray(index)) |a| a.enabled = false;
}

pub fn vertexAttribDivisor(index: u32, divisor: u32) void {
    _ = index;
    _ = divisor;
}

pub fn getVertexAttribiv(index: u32, pname: u32, params: [*]i32) void {
    const a = attribArray(index);
    switch (pname) {
        gl.VERTEX_ATTRIB_ARRAY_ENABLED => params[0] = if (a != null and a.?.enabled) 1 else 0,
        gl.VERTEX_ATTRIB_ARRAY_SIZE => params[0] = if (a) |x| x.size else 4,
        gl.VERTEX_ATTRIB_ARRAY_STRIDE => params[0] = if (a) |x| x.stride else 0,
        gl.VERTEX_ATTRIB_ARRAY_TYPE => params[0] = if (a) |x| @intCast(@backingInt(x.type)) else @intCast(gl.FLOAT),
        gl.VERTEX_ATTRIB_ARRAY_NORMALIZED => params[0] = if (a != null and a.?.normalized) 1 else 0,
        gl.VERTEX_ATTRIB_ARRAY_BUFFER_BINDING => params[0] = if (a) |x| @intCast(x.buffer) else 0,
        gl.VERTEX_ATTRIB_ARRAY_INTEGER => params[0] = 0,
        gl.VERTEX_ATTRIB_ARRAY_DIVISOR => params[0] = 0,
        gl.CURRENT_VERTEX_ATTRIB => {
            params[0] = 0;
            params[1] = 0;
            params[2] = 0;
            params[3] = @bitCast(@as(f32, 1.0));
        },
        else => params[0] = 0,
    }
}

pub fn getVertexAttribfv(index: u32, pname: u32, params: [*]f32) void {
    _ = index;
    switch (pname) {
        gl.CURRENT_VERTEX_ATTRIB => {
            params[0] = 0;
            params[1] = 0;
            params[2] = 0;
            params[3] = 1;
        },
        else => params[0] = 0,
    }
}

pub fn getVertexAttribPointerv(index: u32, pname: u32, pointer: [*]?*anyopaque) void {
    if (pname != gl.VERTEX_ATTRIB_ARRAY_POINTER) {
        pointer[0] = null;
        return;
    }
    if (attribArray(index)) |a| {
        pointer[0] = if (a.pointer) |p| @constCast(p) else null;
    } else {
        pointer[0] = null;
    }
}

// Host-forwarded modern entry points.

pub fn createShader(type_: u32) u32 {
    if (modern.create_shader) |f| return f(type_);
    return 0;
}
pub fn shaderSource(shader: u32, count: i32, strings: [*]const ?[*]const u8, lengths: ?[*]const i32) void {
    if (modern.shader_source) |f| f(shader, count, strings, lengths);
}
pub fn compileShaderObject(shader: u32) void {
    if (modern.compile_shader) |f| f(shader);
}
pub fn deleteShader(shader: u32) void {
    if (modern.delete_shader) |f| f(shader);
}
pub fn getShaderiv(shader: u32, pname: u32, params: [*]i32) void {
    if (modern.get_shader_iv) |f| f(shader, pname, params) else params[0] = 0;
}
pub fn getShaderInfoLog(shader: u32, maxLength: i32, length: ?[*]i32, log: [*]u8) void {
    if (modern.get_shader_info_log) |f| f(shader, maxLength, length, log);
}
pub fn createProgram() u32 {
    if (modern.create_program) |f| return f();
    return 0;
}
pub fn attachShader(program: u32, shader: u32) void {
    if (modern.attach_shader) |f| f(program, shader);
}
pub fn bindAttribLocation(program: u32, index: u32, name: [*:0]const u8) void {
    if (modern.bind_attrib_location) |f| f(program, index, name);
}
pub fn linkProgram(program: u32) void {
    if (modern.link_program) |f| f(program);
}
pub fn deleteProgram(program: u32) void {
    if (modern.delete_program) |f| f(program);
}
pub fn getProgramiv(program: u32, pname: u32, params: [*]i32) void {
    if (modern.get_program_iv) |f| f(program, pname, params) else params[0] = 0;
}
pub fn getProgramInfoLog(program: u32, maxLength: i32, length: ?*i32, log: [*]u8) void {
    if (modern.get_program_info_log) |f| f(program, maxLength, length, log);
}
pub fn useProgram(program: u32) void {
    if (modern.use_program) |f| f(program);
}
pub fn getUniformLocation(program: u32, name: [*:0]const u8) i32 {
    if (modern.get_uniform_location) |f| return f(program, name);
    return -1;
}
pub fn uniform1i(location: i32, value: i32) void {
    if (modern.uniform_1i) |f| f(location, value);
}
pub fn uniform4fv(location: i32, count: i32, value: [*]const f32) void {
    if (modern.uniform_4fv) |f| f(location, count, value);
}
pub fn genVertexArrays(n: i32, arrays: [*]u32) void {
    if (modern.gen_vertex_arrays) |f| f(n, arrays);
}
pub fn bindVertexArray(array: u32) void {
    if (modern.bind_vertex_array) |f| f(array);
}
pub fn deleteVertexArrays(n: i32, arrays: [*]const u32) void {
    if (modern.delete_vertex_arrays) |f| f(n, arrays);
}
pub fn blendEquationSeparate(modeRGB: u32, modeAlpha: u32) void {
    if (modern.blend_equation_separate) |f| f(modeRGB, modeAlpha);
}
pub fn getTexImage(target: u32, level: i32, format: u32, type_: u32, pixels: ?*anyopaque) void {
    if (modern.get_tex_image) |f| f(target, level, format, type_, pixels);
}
pub fn getTexLevelParameteriv(target: u32, level: i32, pname: u32, params: [*]i32) void {
    if (modern.get_tex_level_parameteriv) |f| f(target, level, pname, params) else params[0] = 0;
}
pub fn genFramebuffers(n: i32, framebuffers: [*]u32) void {
    if (modern.gen_framebuffers) |f| f(n, framebuffers);
}
pub fn bindFramebuffer(target: u32, framebuffer: u32) void {
    if (modern.bind_framebuffer) |f| f(target, framebuffer);
}
pub fn deleteFramebuffers(n: i32, framebuffers: [*]const u32) void {
    if (modern.delete_framebuffers) |f| f(n, framebuffers);
}
pub fn framebufferTexture2D(target: u32, attachment: u32, textarget: u32, texture: u32, level: i32) void {
    if (modern.framebuffer_texture_2d) |f| f(target, attachment, textarget, texture, level);
}
pub fn checkFramebufferStatus(target: u32) u32 {
    if (modern.check_framebuffer_status) |f| return f(target);
    return 0;
}

pub fn arrayElement(index: i32) void {
    beginArrayRead();
    const v = vertexFromArrays(index);
    endArrayRead();
    if (g_state.immediate.begun and vertex_count < max_vertices) {
        vertex_queue[vertex_count] = v;
        vertex_count += 1;
    }
}

pub fn drawArrays(mode: u32, first: i32, count: i32) void {
    beginArrayRead();
    var i: i32 = 0;
    var n: usize = 0;
    while (i < count and n < max_vertices) : (i += 1) {
        vertex_queue[n] = vertexFromArrays(first + i);
        n += 1;
    }
    endArrayRead();
    submit(mode, vertex_queue[0..n]);
}

pub fn drawElements(mode: u32, count: i32, type_: u32, indices: [*]const u32) void {
    beginArrayRead();
    var i: i32 = 0;
    var n: usize = 0;
    const base = indexByteBase(@ptrCast(indices));
    while (i < count and n < max_vertices) : (i += 1) {
        const index = if (base) |b| readIndex(@ptrCast(b), @intCast(i), type_) else 0;
        vertex_queue[n] = vertexFromArrays(index);
        n += 1;
    }
    endArrayRead();
    submit(mode, vertex_queue[0..n]);
}

pub fn drawRangeElements(mode: u32, start: u32, end: u32, count: i32, type_: u32, indices: ?*const anyopaque) void {
    _ = start;
    _ = end;
    if (indices == null) {
        return;
    }
    beginArrayRead();
    var i: i32 = 0;
    var n: usize = 0;
    const base = indexByteBase(indices.?);
    while (i < count and n < max_vertices) : (i += 1) {
        const index = if (base) |b| readIndex(@ptrCast(b), @intCast(i), type_) else 0;
        vertex_queue[n] = vertexFromArrays(index);
        n += 1;
    }
    endArrayRead();
    submit(mode, vertex_queue[0..n]);
}

/// Reads the i-th element of an index array of the given GL type.
fn readIndex(raw: *const anyopaque, i: usize, type_: u32) i32 {
    const bytes: [*]const u8 = @ptrCast(raw);
    return switch (type_) {
        gl.UNSIGNED_SHORT => @intCast(@as(u16, bytes[i * 2]) | (@as(u16, bytes[i * 2 + 1]) << 8)),
        gl.UNSIGNED_INT => blk: {
            const value = @as(u32, bytes[i * 4]) |
                (@as(u32, bytes[i * 4 + 1]) << 8) |
                (@as(u32, bytes[i * 4 + 2]) << 16) |
                (@as(u32, bytes[i * 4 + 3]) << 24);
            break :blk @intCast(value);
        },
        else => @intCast(bytes[i]),
    };
}

// EXT_compiled_vertex_array

var locked_array_range: ?[2]i32 = null;

pub fn lockArraysEXT(first: i32, count: i32) void {
    locked_array_range = .{ first, count };
}
pub fn unlockArraysEXT() void {
    locked_array_range = null;
}

// Multi-draw (OpenGL 1.4)

pub fn multiDrawArrays(mode: u32, first: [*]const i32, count: [*]const i32, primcount: i32) void {
    var i: usize = 0;
    while (i < @as(usize, @intCast(primcount))) : (i += 1) {
        drawArrays(mode, first[i], count[i]);
    }
}

pub fn multiDrawElements(mode: u32, count: [*]const i32, type_: u32, indices: [*]const ?*const anyopaque, primcount: i32) void {
    var i: usize = 0;
    while (i < @as(usize, @intCast(primcount))) : (i += 1) {
        if (indices[i]) |ptr| {
            drawRangeElements(mode, 0, std.math.maxInt(u32), count[i], type_, ptr);
        }
    }
}

// EXT_vertex_buffer

pub fn availableVertexBufferEXT() u8 {
    return 0;
}
pub fn allocateVertexBufferEXT(size: i32, format: i32, preserve: u8) i32 {
    _ = size;
    _ = format;
    _ = preserve;
    return -1;
}
pub fn lockVertexBufferEXT(handle: i32, size: i32) ?*anyopaque {
    _ = handle;
    _ = size;
    return null;
}
pub fn unlockVertexBufferEXT(handle: i32) void {
    _ = handle;
}
pub fn setVertexBufferEXT(handle: i32) void {
    _ = handle;
}
pub fn offsetVertexBufferEXT(handle: i32, offset: u32) void {
    _ = handle;
    _ = offset;
}
pub fn fillVertexBufferEXT(handle: i32, first: i32, count: i32) void {
    _ = handle;
    _ = first;
    _ = count;
}
pub fn freeVertexBufferEXT(handle: i32) void {
    _ = handle;
}

// ATI PN triangles

pub fn nPatchSetInt(pname: u32, param: i32) void {
    _ = pname;
    _ = param;
}

pub fn interleavedArrays(format: u32, stride: i32, pointer: ?*const anyopaque) void {
    trace.log("INTERLEAVED_ARRAYS format=0x{x} stride={d} ptr={d}\n", .{ format, stride, @intFromBool(pointer != null) });
}

// Rectangles

fn rect(min: [2]f32, max: [2]f32) void {
    const tc = currentTexcoords();
    vertex_queue[0] = .{ .position = .{ min[0], min[1], 0, 1 }, .color = g_state.current.color, .normal = g_state.current.normal, .texcoord = tc };
    vertex_queue[1] = .{ .position = .{ max[0], min[1], 0, 1 }, .color = g_state.current.color, .normal = g_state.current.normal, .texcoord = tc };
    vertex_queue[2] = .{ .position = .{ max[0], max[1], 0, 1 }, .color = g_state.current.color, .normal = g_state.current.normal, .texcoord = tc };
    vertex_queue[3] = .{ .position = .{ min[0], max[1], 0, 1 }, .color = g_state.current.color, .normal = g_state.current.normal, .texcoord = tc };
    // Correct texture coordinates for the rectangle (unit 0).
    const coords = [4][2]f32{ .{ 0, 0 }, .{ 1, 0 }, .{ 1, 1 }, .{ 0, 1 } };
    for (0..4) |k| {
        vertex_queue[k].texcoord[0] = .{ coords[k][0], coords[k][1], 0, 1 };
    }
    submit(gl.QUADS, vertex_queue[0..4]);
}

pub fn rectf(x1: f32, y1: f32, x2: f32, y2: f32) void {
    rect(.{ x1, y1 }, .{ x2, y2 });
}
pub fn recti(x1: i32, y1: i32, x2: i32, y2: i32) void {
    rect(.{ @floatFromInt(x1), @floatFromInt(y1) }, .{ @floatFromInt(x2), @floatFromInt(y2) });
}

// Matrices

fn currentMatrixStack() *types.MatrixStack {
    return switch (g_state.transform.mode) {
        .projection => &g_state.transform.projection,
        .texture => &g_state.texture_units[g_state.texture.active_texture].matrix,
        else => &g_state.transform.modelview,
    };
}

pub fn matrixMode(mode: u32) void {
    trace.log("MATRIX_MODE 0x{x}\n", .{mode});
    g_state.transform.mode = .fromGL(mode);
}
pub fn loadMatrix(m: [*]const f32) void {
    trace.name("LOAD_MATRIX");
    var value: math.Mat4 = undefined;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        value.m[i] = m[i];
    }
    currentMatrixStack().set(value);
}
pub fn multMatrix(m: [*]const f32) void {
    trace.name("MULT_MATRIX");
    var value: math.Mat4 = undefined;
    var i: usize = 0;
    while (i < 16) : (i += 1) {
        value.m[i] = m[i];
    }
    const stack = currentMatrixStack();
    stack.set(math.Mat4.mul(stack.current(), value));
}
pub fn loadIdentity() void {
    currentMatrixStack().set(math.Mat4.identity);
}
pub fn rotate(angle: f32, x: f32, y: f32, z: f32) void {
    trace.log("ROTATE angle={d} axis=({d},{d},{d})\n", .{ angle, x, y, z });
    const stack = currentMatrixStack();
    stack.set(math.Mat4.mul(stack.current(), math.Mat4.rotation(angle, x, y, z)));
}
pub fn translate(x: f32, y: f32, z: f32) void {
    trace.log("TRANSLATE ({d},{d},{d})\n", .{ x, y, z });
    const stack = currentMatrixStack();
    stack.set(math.Mat4.mul(stack.current(), math.Mat4.translation(x, y, z)));
}
pub fn scale(x: f32, y: f32, z: f32) void {
    trace.log("SCALE ({d},{d},{d})\n", .{ x, y, z });
    const stack = currentMatrixStack();
    stack.set(math.Mat4.mul(stack.current(), math.Mat4.scaling(x, y, z)));
}
pub fn frustum(l: f64, r: f64, b: f64, t: f64, n: f64, f: f64) void {
    trace.log("FRUSTUM ({d},{d},{d},{d},{d},{d})\n", .{ l, r, b, t, n, f });
    const stack = currentMatrixStack();
    stack.set(math.Mat4.mul(stack.current(), math.Mat4.frustum(l, r, b, t, n, f)));
}
pub fn ortho(l: f64, r: f64, b: f64, t: f64, n: f64, f: f64) void {
    trace.log("ORTHO ({d},{d},{d},{d},{d},{d})\n", .{ l, r, b, t, n, f });
    const stack = currentMatrixStack();
    stack.set(math.Mat4.mul(stack.current(), math.Mat4.ortho(l, r, b, t, n, f)));
}
pub fn pushMatrix() void {
    currentMatrixStack().push();
}
pub fn popMatrix() void {
    currentMatrixStack().pop();
}
pub fn viewport(x: i32, y: i32, width: i32, height: i32) void {
    trace.log("VIEWPORT x={d} y={d} w={d} h={d}\n", .{ x, y, width, height });
    g_state.framebuffer.viewport = .{ x, y, width, height };
    g_state.framebuffer.scissor_box = .{ x, y, width, height };
}
pub fn depthRange(n: f64, f: f64) void {
    g_state.framebuffer.depth_range = .{ n, f };
}

// Texgen and clipping

pub fn texGen(coord: u32, pname: u32, param: f32) void {
    const unit = g_state.texture.active_texture;
    const target = switch (coord) {
        gl.S => &g_state.texture_units[unit].texgen[0],
        gl.T => &g_state.texture_units[unit].texgen[1],
        gl.R => &g_state.texture_units[unit].texgen[2],
        else => &g_state.texture_units[unit].texgen[3],
    };
    if (pname == gl.TEXTURE_GEN_MODE) {
        target.mode = .fromGL(@intFromFloat(param));
    }
}

pub fn texGenfv(coord: u32, pname: u32, params: [*]const f32) void {
    const unit = g_state.texture.active_texture;
    const target = switch (coord) {
        gl.S => &g_state.texture_units[unit].texgen[0],
        gl.T => &g_state.texture_units[unit].texgen[1],
        gl.R => &g_state.texture_units[unit].texgen[2],
        else => &g_state.texture_units[unit].texgen[3],
    };
    switch (pname) {
        gl.TEXTURE_GEN_MODE => target.mode = .fromGL(@intFromFloat(params[0])),
        gl.OBJECT_PLANE => target.plane = .{ params[0], params[1], params[2], params[3] },
        gl.EYE_PLANE => target.plane = .{ params[0], params[1], params[2], params[3] },
        else => {},
    }
}
pub fn clipPlane(plane: u32, eqn: [*]const f64) void {
    if (plane < gl.CLIP_PLANE0 or plane > gl.CLIP_PLANE0 + 5) {
        return;
    }
    const index = plane - gl.CLIP_PLANE0;
    g_state.clip.planes[index] = .{
        @floatCast(eqn[0]),
        @floatCast(eqn[1]),
        @floatCast(eqn[2]),
        @floatCast(eqn[3]),
    };
}

pub fn rasterPos2f(x: f32, y: f32) void {
    _ = x;
    _ = y;
}
pub fn rasterPos3f(x: f32, y: f32, z: f32) void {
    _ = x;
    _ = y;
    _ = z;
}
pub fn rasterPos4f(x: f32, y: f32, z: f32, w: f32) void {
    _ = x;
    _ = y;
    _ = z;
    _ = w;
}

// --- Colouring ---

pub fn colorMaterial(face: u32, mode: u32) void {
    g_state.lighting.color_material.face = .fromGL(face);
    g_state.lighting.color_material.mode = .fromGL(mode);
}
pub fn frontFace(dir: u32) void {
    g_state.raster.front_face = if (dir == gl.CW) .cw else .ccw;
}
pub fn shadeModel(mode: u32) void {
    g_state.raster.shade_model = .fromGL(mode);
}

pub fn fogCoordf(pname: u32, param: f32) void {
    _ = pname;
    g_state.current.fog_coord = param;
}
pub fn fogCoordfv(pname: u32, params: [*]const f32) void {
    _ = pname;
    g_state.current.fog_coord = params[0];
}
pub fn fogCoordd(pname: u32, param: f64) void {
    _ = pname;
    g_state.current.fog_coord = @floatCast(param);
}
pub fn fogCoorddv(pname: u32, params: [*]const f64) void {
    _ = pname;
    g_state.current.fog_coord = @floatCast(params[0]);
}
pub fn fogCoordPointer(type_: u32, stride: i32, pointer: ?*const anyopaque) void {
    g_state.client_arrays.fogcoord.size = 1;
    g_state.client_arrays.fogcoord.type = .fromGL(type_);
    g_state.client_arrays.fogcoord.stride = stride;
    g_state.client_arrays.fogcoord.buffer = g_state.client_arrays.array_buffer_binding;
    g_state.client_arrays.fogcoord.pointer = pointer;
}

// Rasterization state

pub fn pointSize(size: f32) void {
    g_state.raster.point_size = size;
    if (modern.point_size) |f| f(size);
}
pub fn lineWidth(width: f32) void {
    g_state.raster.line_width = width;
    if (modern.line_width) |f| f(width);
}
pub fn lineStipple(factor: i32, pattern: u16) void {
    g_state.raster.line_stipple_factor = factor;
    g_state.raster.line_stipple_pattern = pattern;
}
pub fn polygonStipple(pattern: [*]const u8) void {
    _ = pattern;
}
pub fn polygonMode(face: u32, mode: u32) void {
    if (face == gl.FRONT or face == gl.FRONT_AND_BACK) {
        g_state.raster.polygon_mode_front = .fromGL(mode);
    }
    if (face == gl.BACK or face == gl.FRONT_AND_BACK) {
        g_state.raster.polygon_mode_back = .fromGL(mode);
    }
}
pub fn alphaFunc(func: u32, ref: f32) void {
    g_state.alpha_test.func = .fromGL(func);
    g_state.alpha_test.ref = ref;
}
pub fn scissor(left: i32, bottom: i32, width: i32, height: i32) void {
    g_state.framebuffer.scissor_box = .{ left, bottom, width, height };
}
pub fn blendFunc(src: u32, dst: u32) void {
    trace.log("BLEND_FUNC src=0x{x} dst=0x{x}\n", .{ src, dst });
    g_state.blend.src = .fromGL(src);
    g_state.blend.dst = .fromGL(dst);
    g_state.blend.src_rgb = .fromGL(src);
    g_state.blend.dst_rgb = .fromGL(dst);
    g_state.blend.src_alpha = .fromGL(src);
    g_state.blend.dst_alpha = .fromGL(dst);
}
pub fn blendEquation(mode: u32) void {
    trace.log("BLEND_EQUATION 0x{x}\n", .{mode});
    g_state.blend.equation = .fromGL(mode);
}
pub fn blendFuncSeparate(src_rgb: u32, dst_rgb: u32, src_alpha: u32, dst_alpha: u32) void {
    g_state.blend.src_rgb = .fromGL(src_rgb);
    g_state.blend.dst_rgb = .fromGL(dst_rgb);
    g_state.blend.src_alpha = .fromGL(src_alpha);
    g_state.blend.dst_alpha = .fromGL(dst_alpha);
    g_state.blend.src = .fromGL(src_rgb);
    g_state.blend.dst = .fromGL(dst_rgb);
}
pub fn blendColor(red: f32, green: f32, blue: f32, alpha: f32) void {
    trace.log("BLEND_COLOR {d} {d} {d} {d}\n", .{ red, green, blue, alpha });
    g_state.blend.color = .{ red, green, blue, alpha };
    if (modern.blend_color) |f| f(red, green, blue, alpha);
}
pub fn secondaryColor(color: [4]f32) void {
    g_state.current.secondary_color = color;
}
pub fn pointParameter(pname: u32, params: [*]const f32) void {
    switch (pname) {
        gl.POINT_SIZE_MIN => g_state.raster.point_size_min = params[0],
        gl.POINT_SIZE_MAX => g_state.raster.point_size_max = params[0],
        gl.POINT_DISTANCE_ATTENUATION => g_state.raster.point_distance_attenuation = .{ params[0], params[1], params[2] },
        else => {},
    }
}
pub fn logicOp(op: u32) void {
    g_state.blend.logic_op = .fromGL(op);
}
pub fn depthFunc(func: u32) void {
    trace.log("DEPTH_FUNC 0x{x}\n", .{func});
    g_state.depth.func = .fromGL(func);
}
pub fn depthMask(mask: u8) void {
    g_state.depth.mask = mask != 0;
}

// Framebuffer

pub fn drawBuffer(buf: u32) void {
    g_state.framebuffer.draw_buffer = .fromGL(buf);
}
pub fn readBuffer(buf: u32) void {
    g_state.framebuffer.read_buffer = .fromGL(buf);
}
pub fn clearColor(r: f32, g: f32, b: f32, a: f32) void {
    trace.log("CLEAR_COLOR ({d},{d},{d},{d})\n", .{ r, g, b, a });
    g_state.framebuffer.clear_color = .{ r, g, b, a };
}
pub fn clearIndex(index: f32) void {
    g_state.framebuffer.clear_index = index;
}
pub fn clearDepth(depth: f64) void {
    g_state.framebuffer.clear_depth = depth;
}
pub fn clearStencil(stencil: i32) void {
    g_state.framebuffer.clear_stencil = stencil;
}
pub fn colorMask(r: u8, g: u8, b: u8, a: u8) void {
    trace.log("COLOR_MASK {d}{d}{d}{d}\n", .{ r, g, b, a });
    g_state.framebuffer.color_mask = .{ r != 0, g != 0, b != 0, a != 0 };
}
pub fn indexMask(mask: u32) void {
    g_state.framebuffer.index_mask = mask;
}
pub fn stencilMask(mask: u32) void {
    g_state.stencil.write_mask = mask;
    if (modern.stencil_mask) |f| f(mask);
}

// Stencil, culling, hints, polygon offset

pub fn cullFace(mode: u32) void {
    g_state.raster.cull_face = .fromGL(mode);
}

pub fn stencilFunc(func: u32, ref: i32, mask: u32) void {
    g_state.stencil.func = .fromGL(func);
    g_state.stencil.ref = ref;
    g_state.stencil.value_mask = mask;
}

pub fn stencilOp(fail: u32, zfail: u32, zpass: u32) void {
    g_state.stencil.fail = .fromGL(fail);
    g_state.stencil.pass_depth_fail = .fromGL(zfail);
    g_state.stencil.pass_depth_pass = .fromGL(zpass);
}

pub fn hint(target: u32, mode: u32) void {
    switch (target) {
        gl.PERSPECTIVE_CORRECTION_HINT => g_state.hints.perspective = .fromGL(mode),
        gl.POINT_SMOOTH_HINT => g_state.hints.point_smooth = .fromGL(mode),
        gl.LINE_SMOOTH_HINT => g_state.hints.line_smooth = .fromGL(mode),
        gl.POLYGON_SMOOTH_HINT => g_state.hints.polygon_smooth = .fromGL(mode),
        gl.FOG_HINT => g_state.hints.fog = .fromGL(mode),
        else => {},
    }
}

pub fn polygonOffset(factor: f32, units: f32) void {
    g_state.raster.polygon_offset_factor = factor;
    g_state.raster.polygon_offset_units = units;
}

// Display lists

var next_list: u32 = 1;
var list_base: u32 = 0;

pub fn genLists(range: i32) u32 {
    if (range <= 0) {
        return 0;
    }
    const first = next_list;
    next_list +%= @intCast(range);
    return first;
}

pub fn deleteLists(list: u32, range: i32) void {
    _ = list;
    _ = range;
}

pub fn isList(list: u32) u8 {
    _ = list;
    return 0;
}

pub fn listBase(base: u32) void {
    list_base = base;
}

pub fn callLists(n: i32, type_: u32, lists: ?*const anyopaque) void {
    _ = n;
    _ = type_;
    _ = lists;
}

// Name stack

var name_stack: [64]u32 = @splat(0);
var name_top: usize = 0;

pub fn initNames() void {
    name_top = 0;
}

pub fn pushName(name: u32) void {
    if (name_top < name_stack.len) {
        name_stack[name_top] = name;
        name_top += 1;
    }
}

pub fn popName() void {
    if (name_top > 0) {
        name_top -= 1;
    }
}

pub fn loadName(name: u32) void {
    if (name_top == 0) {
        name_top = 1;
    }
    name_stack[name_top - 1] = name;
}

pub fn clear(mask: u32) void {
    ensureReady();
    trace.log("CLEAR mask=0x{x}\n", .{mask});
    var host_mask: u32 = 0;
    if (mask & gl.COLOR_BUFFER_BIT != 0) host_mask |= gl.COLOR_BUFFER_BIT;
    if (mask & gl.DEPTH_BUFFER_BIT != 0) host_mask |= gl.DEPTH_BUFFER_BIT;
    if (mask & gl.STENCIL_BUFFER_BIT != 0) host_mask |= gl.STENCIL_BUFFER_BIT;

    if (modern.clear_color) |f| f(g_state.framebuffer.clear_color[0], g_state.framebuffer.clear_color[1], g_state.framebuffer.clear_color[2], g_state.framebuffer.clear_color[3]);
    if (modern.clear_depth) |f| f(g_state.framebuffer.clear_depth);
    if (modern.clear_stencil) |f| f(g_state.framebuffer.clear_stencil);
    if (modern.color_mask) |f| f(1, 1, 1, 1);
    if (modern.depth_mask) |f| f(1);
    if (modern.clear) |f| f(host_mask);
    if (modern.color_mask) |f| {
        f(@intFromBool(g_state.framebuffer.color_mask[0]), @intFromBool(g_state.framebuffer.color_mask[1]), @intFromBool(g_state.framebuffer.color_mask[2]), @intFromBool(g_state.framebuffer.color_mask[3]));
    }
    if (modern.depth_mask) |f| f(if (g_state.depth.mask) 1 else 0);
    trace.flush();
}

// Enable/disable

pub fn enableCapability(capability: u32) void {
    trace.log("ENABLE 0x{x}\n", .{capability});
    switch (capability) {
        gl.LIGHTING => g_state.lighting.enabled = true,
        gl.NORMALIZE => g_state.lighting.normalize = true,
        gl.FOG => g_state.fog.enabled = true,
        gl.POINT_SMOOTH => g_state.raster.point_smooth = true,
        gl.LINE_SMOOTH => g_state.raster.line_smooth = true,
        gl.POLYGON_SMOOTH => g_state.raster.polygon_smooth = true,
        gl.ALPHA_TEST => g_state.alpha_test.enabled = true,
        gl.SCISSOR_TEST => g_state.framebuffer.scissor_test = true,
        gl.BLEND => g_state.blend.enabled = true,
        gl.DITHER => g_state.raster.dither = true,
        gl.CULL_FACE => g_state.raster.cull_face_enabled = true,
        gl.COLOR_MATERIAL => g_state.lighting.color_material.enabled = true,
        gl.POLYGON_OFFSET_FILL => g_state.raster.polygon_offset_fill = true,
        gl.DEPTH_TEST => g_state.depth.enabled = true,
        gl.STENCIL_TEST => g_state.stencil.enabled = true,
        gl.TEXTURE_2D => {
            g_state.texture.enabled_2d = true;
            g_state.texture_units[g_state.texture.active_texture].enabled_2d = true;
        },
        gl.TEXTURE_1D => {
            g_state.texture.enabled_1d = true;
            g_state.texture_units[g_state.texture.active_texture].enabled_1d = true;
        },
        gl.TEXTURE_GEN_S => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[0] = true,
        gl.TEXTURE_GEN_T => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[1] = true,
        gl.TEXTURE_GEN_R => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[2] = true,
        gl.TEXTURE_GEN_Q => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[3] = true,
        else => {
            if (capability >= gl.LIGHT0 and capability <= gl.LIGHT0 + 3) {
                g_state.lighting.lights[capability - gl.LIGHT0].enabled = true;
            } else if (capability >= gl.CLIP_PLANE0 and capability <= gl.CLIP_PLANE0 + 5) {
                g_state.clip.enabled[capability - gl.CLIP_PLANE0] = true;
            }
        },
    }
}

pub fn disableCapability(capability: u32) void {
    trace.log("DISABLE 0x{x}\n", .{capability});
    switch (capability) {
        gl.LIGHTING => g_state.lighting.enabled = false,
        gl.NORMALIZE => g_state.lighting.normalize = false,
        gl.FOG => g_state.fog.enabled = false,
        gl.POINT_SMOOTH => g_state.raster.point_smooth = false,
        gl.LINE_SMOOTH => g_state.raster.line_smooth = false,
        gl.POLYGON_SMOOTH => g_state.raster.polygon_smooth = false,
        gl.ALPHA_TEST => g_state.alpha_test.enabled = false,
        gl.SCISSOR_TEST => g_state.framebuffer.scissor_test = false,
        gl.BLEND => g_state.blend.enabled = false,
        gl.DITHER => g_state.raster.dither = false,
        gl.CULL_FACE => g_state.raster.cull_face_enabled = false,
        gl.COLOR_MATERIAL => g_state.lighting.color_material.enabled = false,
        gl.POLYGON_OFFSET_FILL => g_state.raster.polygon_offset_fill = false,
        gl.DEPTH_TEST => g_state.depth.enabled = false,
        gl.STENCIL_TEST => g_state.stencil.enabled = false,
        gl.TEXTURE_2D => {
            g_state.texture.enabled_2d = false;
            g_state.texture_units[g_state.texture.active_texture].enabled_2d = false;
        },
        gl.TEXTURE_1D => {
            g_state.texture.enabled_1d = false;
            g_state.texture_units[g_state.texture.active_texture].enabled_1d = false;
        },
        gl.TEXTURE_GEN_S => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[0] = false,
        gl.TEXTURE_GEN_T => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[1] = false,
        gl.TEXTURE_GEN_R => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[2] = false,
        gl.TEXTURE_GEN_Q => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[3] = false,
        else => {
            if (capability >= gl.LIGHT0 and capability <= gl.LIGHT0 + 3) {
                g_state.lighting.lights[capability - gl.LIGHT0].enabled = false;
            } else if (capability >= gl.CLIP_PLANE0 and capability <= gl.CLIP_PLANE0 + 5) {
                g_state.clip.enabled[capability - gl.CLIP_PLANE0] = false;
            }
        },
    }
}

pub fn isEnabled(capability: u32) u8 {
    return @intFromBool(switch (capability) {
        gl.LIGHTING => g_state.lighting.enabled,
        gl.NORMALIZE => g_state.lighting.normalize,
        gl.FOG => g_state.fog.enabled,
        gl.POINT_SMOOTH => g_state.raster.point_smooth,
        gl.LINE_SMOOTH => g_state.raster.line_smooth,
        gl.POLYGON_SMOOTH => g_state.raster.polygon_smooth,
        gl.ALPHA_TEST => g_state.alpha_test.enabled,
        gl.SCISSOR_TEST => g_state.framebuffer.scissor_test,
        gl.BLEND => g_state.blend.enabled,
        gl.DITHER => g_state.raster.dither,
        gl.CULL_FACE => g_state.raster.cull_face_enabled,
        gl.COLOR_MATERIAL => g_state.lighting.color_material.enabled,
        gl.POLYGON_OFFSET_FILL => g_state.raster.polygon_offset_fill,
        gl.DEPTH_TEST => g_state.depth.enabled,
        gl.STENCIL_TEST => g_state.stencil.enabled,
        gl.TEXTURE_2D => g_state.texture_units[g_state.texture.active_texture].enabled_2d,
        gl.TEXTURE_1D => g_state.texture_units[g_state.texture.active_texture].enabled_1d,
        gl.TEXTURE_GEN_S => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[0],
        gl.TEXTURE_GEN_T => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[1],
        gl.TEXTURE_GEN_R => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[2],
        gl.TEXTURE_GEN_Q => g_state.texture_units[g_state.texture.active_texture].texgen_enabled[3],
        else => if (capability >= gl.CLIP_PLANE0 and capability <= gl.CLIP_PLANE0 + 5)
            g_state.clip.enabled[capability - gl.CLIP_PLANE0]
        else
            false,
    });
}

// Pixel store / transfer

pub fn pixelStoref(pname: u32, param: f32) void {
    pixelStorei(pname, @intFromFloat(param));
}
pub fn pixelStorei(pname: u32, param: i32) void {
    switch (pname) {
        gl.UNPACK_ALIGNMENT => {
            g_state.pixel_transfer.unpack_alignment = param;
            if (modern.pixel_store_i) |f| f(gl.UNPACK_ALIGNMENT, param);
        },
        gl.PACK_ALIGNMENT => {
            g_state.pixel_transfer.pack_alignment = param;
            if (modern.pixel_store_i) |f| f(gl.PACK_ALIGNMENT, param);
        },
        gl.UNPACK_ROW_LENGTH => {
            g_state.pixel_transfer.unpack_row_length = param;
            if (modern.pixel_store_i) |f| f(gl.UNPACK_ROW_LENGTH, param);
        },
        gl.PACK_ROW_LENGTH => {
            g_state.pixel_transfer.pack_row_length = param;
            if (modern.pixel_store_i) |f| f(gl.PACK_ROW_LENGTH, param);
        },
        gl.UNPACK_SKIP_ROWS => g_state.pixel_transfer.unpack_skip_rows = param,
        gl.UNPACK_SKIP_PIXELS => g_state.pixel_transfer.unpack_skip_pixels = param,
        gl.PACK_SKIP_ROWS => g_state.pixel_transfer.pack_skip_rows = param,
        gl.PACK_SKIP_PIXELS => g_state.pixel_transfer.pack_skip_pixels = param,
        gl.UNPACK_SWAP_BYTES => g_state.pixel_transfer.unpack_swap_bytes = param != 0,
        gl.PACK_SWAP_BYTES => g_state.pixel_transfer.pack_swap_bytes = param != 0,
        gl.UNPACK_LSB_FIRST => g_state.pixel_transfer.unpack_lsb_first = param != 0,
        gl.PACK_LSB_FIRST => g_state.pixel_transfer.pack_lsb_first = param != 0,
        else => {},
    }
}
pub fn pixelTransferf(pname: u32, param: f32) void {
    switch (pname) {
        gl.RED_SCALE => g_state.pixel_transfer.red_scale = param,
        gl.GREEN_SCALE => g_state.pixel_transfer.green_scale = param,
        gl.BLUE_SCALE => g_state.pixel_transfer.blue_scale = param,
        gl.ALPHA_SCALE => g_state.pixel_transfer.alpha_scale = param,
        gl.DEPTH_SCALE => g_state.pixel_transfer.depth_scale = param,
        gl.RED_BIAS => g_state.pixel_transfer.red_bias = param,
        gl.GREEN_BIAS => g_state.pixel_transfer.green_bias = param,
        gl.BLUE_BIAS => g_state.pixel_transfer.blue_bias = param,
        gl.ALPHA_BIAS => g_state.pixel_transfer.alpha_bias = param,
        gl.DEPTH_BIAS => g_state.pixel_transfer.depth_bias = param,
        else => {},
    }
}
pub fn pixelTransferi(pname: u32, param: i32) void {
    switch (pname) {
        gl.INDEX_SHIFT => g_state.pixel_transfer.index_shift = param,
        gl.INDEX_OFFSET => g_state.pixel_transfer.index_offset = param,
        else => {},
    }
}
pub fn pixelMapf(pname: u32, size: i32, values: [*]const f32) void {
    _ = pname;
    _ = size;
    _ = values;
}
pub fn pixelMapi(pname: u32, size: i32, values: [*]const i32) void {
    _ = pname;
    _ = size;
    _ = values;
}

pub fn readPixels(x: i32, y: i32, width: i32, height: i32, format: u32, type_: u32, pixels: [*]u8) void {
    ensureReady();
    if (modern.read_pixels) |f| {
        f(x, y, width, height, hostFormat(format), hostType(type_), @ptrCast(pixels));
    }
}

pub fn drawPixels(width: i32, height: i32, format: u32, type_: u32, pixels: [*]const u8) void {
    _ = width;
    _ = height;
    _ = format;
    _ = type_;
    _ = pixels;
}

pub fn copyPixels(x: i32, y: i32, width: i32, height: i32, kind: u32) void {
    _ = x;
    _ = y;
    _ = width;
    _ = height;
    _ = kind;
}

fn hostFormat(format: u32) u32 {
    return format;
}

fn hostType(type_: u32) u32 {
    return type_;
}

// Texturing

pub fn genTextures(count: i32, textures: [*]u32) void {
    ensureReady();
    if (modern.gen_textures) |f| f(count, textures);
}

pub fn bindTexture(target: u32, texture: u32) void {
    ensureReady();
    trace.log("BIND_TEXTURE target=0x{x} id={d} unit={d}\n", .{ target, texture, g_state.texture.active_texture });
    const unit = g_state.texture.active_texture;
    if (target == gl.TEXTURE_1D) {
        g_state.texture_units[unit].bound_1d = texture;
    } else {
        g_state.texture_units[unit].bound_2d = texture;
    }
    makeActiveUnitCurrent();
}

fn makeActiveUnitCurrent() void {
    if (modern.active_texture) |f| f(gl.TEXTURE0 + @as(u32, @intCast(g_state.texture.active_texture)));
    if (modern.bind_texture) |f| {
        f(gl.TEXTURE_1D, g_state.texture_units[g_state.texture.active_texture].bound_1d);
        f(gl.TEXTURE_2D, g_state.texture_units[g_state.texture.active_texture].bound_2d);
    }
}

pub fn deleteTextures(count: i32, textures: [*]const u32) void {
    if (modern.delete_textures) |f| f(count, textures);
}

pub fn areTexturesResident(count: i32, textures: [*]const u32, residences: [*]u8) void {
    var i: i32 = 0;
    while (i < count) : (i += 1) {
        _ = textures;
        residences[@intCast(i)] = 1;
    }
}

pub fn prioritizeTextures(count: i32, textures: [*]const u32, priorities: [*]const f32) void {
    _ = count;
    _ = textures;
    _ = priorities;
}

pub fn texImage2D(target: u32, level: i32, internalformat: i32, width: i32, height: i32, border: i32, format: u32, type_: u32, pixels: ?*const anyopaque) void {
    ensureReady();
    trace.log("TEX_IMAGE_2D level={d} internal=0x{x} w={d} h={d} format=0x{x} type=0x{x} pixels={d}\n", .{ level, internalformat, width, height, format, type_, @intFromBool(pixels != null) });
    _ = target;
    makeActiveUnitCurrent();
    const host_internal = hostInternalFormat(internalformat);
    if (modern.tex_image_2d) |f| {
        f(gl.TEXTURE_2D, level, host_internal, width, height, border, coreTexFormat(format), hostType(type_), pixels);
    }
    applyTextureSwizzle(internalformat);
    regenerateMipmaps();
}

pub fn texImage1D(target: u32, level: i32, internalformat: i32, width: i32, border: i32, format: u32, type_: u32, pixels: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.tex_image_1d) |f| {
        f(gl.TEXTURE_1D, level, hostInternalFormat(internalformat), width, border, coreTexFormat(format), hostType(type_), pixels);
    }
    applyTextureSwizzle(internalformat);
}

// Compressed textures

pub fn compressedTexImage2D(target: u32, level: i32, internalformat: u32, width: i32, height: i32, border: i32, image_size: i32, data: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.compressed_tex_image_2d) |f| {
        f(gl.TEXTURE_2D, level, internalformat, width, height, border, image_size, data);
    }
}

pub fn compressedTexImage1D(target: u32, level: i32, internalformat: u32, width: i32, border: i32, image_size: i32, data: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.compressed_tex_image_1d) |f| {
        f(gl.TEXTURE_1D, level, internalformat, width, border, image_size, data);
    }
}

pub fn compressedTexImage3D(target: u32, level: i32, internalformat: u32, width: i32, height: i32, depth: i32, border: i32, image_size: i32, data: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.compressed_tex_image_3d) |f| {
        f(gl.TEXTURE_3D, level, internalformat, width, height, depth, border, image_size, data);
    }
}

pub fn compressedTexSubImage2D(target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, image_size: i32, data: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.compressed_tex_sub_image_2d) |f| {
        f(gl.TEXTURE_2D, level, xoffset, yoffset, width, height, format, image_size, data);
    }
}

pub fn compressedTexSubImage1D(target: u32, level: i32, xoffset: i32, width: i32, format: u32, image_size: i32, data: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.compressed_tex_sub_image_1d) |f| {
        f(gl.TEXTURE_1D, level, xoffset, width, format, image_size, data);
    }
}

pub fn compressedTexSubImage3D(target: u32, level: i32, xoffset: i32, yoffset: i32, zoffset: i32, width: i32, height: i32, depth: i32, format: u32, image_size: i32, data: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.compressed_tex_sub_image_3d) |f| {
        f(gl.TEXTURE_3D, level, xoffset, yoffset, zoffset, width, height, depth, format, image_size, data);
    }
}

pub fn getCompressedTexImage(target: u32, level: i32, pixels: ?*anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.get_compressed_tex_image) |f| {
        f(gl.TEXTURE_2D, level, pixels);
    }
}

pub fn texSubImage2D(target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32, format: u32, type_: u32, pixels: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.tex_sub_image_2d) |f| {
        f(gl.TEXTURE_2D, level, xoffset, yoffset, width, height, coreTexFormat(format), hostType(type_), pixels);
    }
    regenerateMipmaps();
}

pub fn copyTexImage2D(target: u32, level: i32, internalformat: u32, x: i32, y: i32, width: i32, height: i32, border: i32) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.copy_tex_image_2d) |f| {
        f(gl.TEXTURE_2D, level, hostInternalFormat(@intCast(internalformat)), x, y, width, height, border);
    }
}

pub fn copyTexSubImage2D(target: u32, level: i32, xoffset: i32, yoffset: i32, width: i32, height: i32) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.copy_tex_sub_image_2d) |f| {
        f(gl.TEXTURE_2D, level, xoffset, yoffset, width, height);
    }
}

pub fn texSubImage1D(target: u32, level: i32, xoffset: i32, width: i32, format: u32, type_: u32, pixels: ?*const anyopaque) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.tex_sub_image_1d) |f| {
        f(gl.TEXTURE_1D, level, xoffset, width, coreTexFormat(format), hostType(type_), pixels);
    }
}

pub fn copyTexImage1D(target: u32, level: i32, internalformat: u32, x: i32, y: i32, width: i32, border: i32) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.copy_tex_image_1d) |f| {
        f(gl.TEXTURE_1D, level, hostInternalFormat(@intCast(internalformat)), x, y, width, border);
    }
}

pub fn copyTexSubImage1D(target: u32, level: i32, xoffset: i32, x: i32, y: i32, width: i32) void {
    ensureReady();
    _ = target;
    makeActiveUnitCurrent();
    if (modern.copy_tex_sub_image_1d) |f| {
        f(gl.TEXTURE_1D, level, xoffset, x, y, width);
    }
}

pub fn texParameterf(target: u32, pname: u32, param: f32) void {
    switch (pname) {
        gl.TEXTURE_MIN_FILTER => texParameteri(target, pname, @intFromFloat(param)),
        gl.TEXTURE_MAG_FILTER => texParameteri(target, pname, @intFromFloat(param)),
        gl.TEXTURE_WRAP_S => texParameteri(target, pname, @intFromFloat(param)),
        gl.TEXTURE_WRAP_T => texParameteri(target, pname, @intFromFloat(param)),
        else => {
            ensureReady();
            makeActiveUnitCurrent();
            if (modern.tex_parameter_f) |f| f(gl.TEXTURE_2D, hostTextureParam(pname), param);
        },
    }
}

pub fn texParameteri(target: u32, pname: u32, param: i32) void {
    _ = target;
    ensureReady();
    trace.log("TEX_PARAM pname=0x{x} param=0x{x}\n", .{ pname, param });
    makeActiveUnitCurrent();
    if (modern.tex_parameter_i) |f| {
        f(gl.TEXTURE_2D, hostTextureParam(pname), hostTextureValue(pname, param));
    }
}

pub fn texEnvf(target: u32, pname: u32, param: f32) void {
    texEnvi(target, pname, @intFromFloat(param));
}

pub fn texEnvi(target: u32, pname: u32, param: i32) void {
    _ = target;
    trace.log("TEX_ENV pname=0x{x} param=0x{x}\n", .{ pname, param });
    const unit = g_state.texture.active_texture;
    switch (pname) {
        gl.TEXTURE_ENV_MODE => {
            g_state.texture_units[unit].env_mode = .fromGL(@as(u32, @bitCast(param)));
            g_state.texture_units[unit].combine_enabled = @as(u32, @bitCast(param)) == gl.COMBINE_EXT;
        },
        gl.COMBINE_RGB_EXT => {
            g_state.texture_units[unit].combine_rgb.func = .fromGL(@as(u32, @bitCast(param)));
            g_state.texture_units[unit].combine_enabled = true;
        },
        gl.COMBINE_ALPHA_EXT => {
            g_state.texture_units[unit].combine_alpha.func = .fromGL(@as(u32, @bitCast(param)));
            g_state.texture_units[unit].combine_enabled = true;
        },
        gl.SOURCE0_RGB_EXT => g_state.texture_units[unit].combine_rgb.source[0] = .fromGL(@as(u32, @bitCast(param))),
        gl.SOURCE1_RGB_EXT => g_state.texture_units[unit].combine_rgb.source[1] = .fromGL(@as(u32, @bitCast(param))),
        gl.SOURCE2_RGB_EXT => g_state.texture_units[unit].combine_rgb.source[2] = .fromGL(@as(u32, @bitCast(param))),
        gl.SOURCE0_ALPHA_EXT => g_state.texture_units[unit].combine_alpha.source[0] = .fromGL(@as(u32, @bitCast(param))),
        gl.SOURCE1_ALPHA_EXT => g_state.texture_units[unit].combine_alpha.source[1] = .fromGL(@as(u32, @bitCast(param))),
        gl.SOURCE2_ALPHA_EXT => g_state.texture_units[unit].combine_alpha.source[2] = .fromGL(@as(u32, @bitCast(param))),
        gl.OPERAND0_RGB_EXT => g_state.texture_units[unit].combine_rgb.operand[0] = .fromGL(@as(u32, @bitCast(param))),
        gl.OPERAND1_RGB_EXT => g_state.texture_units[unit].combine_rgb.operand[1] = .fromGL(@as(u32, @bitCast(param))),
        gl.OPERAND2_RGB_EXT => g_state.texture_units[unit].combine_rgb.operand[2] = .fromGL(@as(u32, @bitCast(param))),
        gl.OPERAND0_ALPHA_EXT => g_state.texture_units[unit].combine_alpha.operand[0] = .fromGL(@as(u32, @bitCast(param))),
        gl.OPERAND1_ALPHA_EXT => g_state.texture_units[unit].combine_alpha.operand[1] = .fromGL(@as(u32, @bitCast(param))),
        gl.OPERAND2_ALPHA_EXT => g_state.texture_units[unit].combine_alpha.operand[2] = .fromGL(@as(u32, @bitCast(param))),
        gl.RGB_SCALE_EXT => g_state.texture_units[unit].rgb_scale = @floatFromInt(param),
        gl.ALPHA_SCALE => g_state.texture_units[unit].combine_alpha_scale = @floatFromInt(param),
        else => {},
    }
}

pub fn texEnvColor(color: [4]f32) void {
    g_state.texture_units[g_state.texture.active_texture].env_color = color;
}

fn hostInternalFormat(internalformat: i32) i32 {
    return switch (@as(u32, @intCast(internalformat))) {
        gl.RGBA => @intCast(gl.RGBA8),
        gl.RGB => @intCast(gl.RGB8),
        gl.ALPHA, gl.ALPHA4, gl.ALPHA8, gl.ALPHA12, gl.ALPHA16 => @intCast(gl.R8),
        gl.LUMINANCE, gl.LUMINANCE4, gl.LUMINANCE8, gl.LUMINANCE12, gl.LUMINANCE16 => @intCast(gl.R8),
        gl.INTENSITY, gl.INTENSITY4, gl.INTENSITY8, gl.INTENSITY12, gl.INTENSITY16 => @intCast(gl.R8),
        gl.LUMINANCE_ALPHA, gl.LUMINANCE4_ALPHA4, gl.LUMINANCE6_ALPHA2, gl.LUMINANCE8_ALPHA8, gl.LUMINANCE12_ALPHA4, gl.LUMINANCE12_ALPHA12, gl.LUMINANCE16_ALPHA16 => @intCast(gl.RG8),
        gl.COMPRESSED_RGB_ARB => @intCast(gl.RGB8),
        gl.COMPRESSED_RGBA_ARB => @intCast(gl.RGBA8),
        gl.COMPRESSED_ALPHA_ARB => @intCast(gl.R8),
        gl.COMPRESSED_LUMINANCE_ARB => @intCast(gl.R8),
        gl.COMPRESSED_INTENSITY_ARB => @intCast(gl.R8),
        gl.COMPRESSED_LUMINANCE_ALPHA_ARB => @intCast(gl.RG8),
        else => internalformat,
    };
}

/// Pixel format of the client data for a legacy one- or two-component image.
fn coreTexFormat(format: u32) u32 {
    return switch (format) {
        gl.ALPHA, gl.LUMINANCE, gl.INTENSITY => gl.RED,
        gl.LUMINANCE_ALPHA => gl.RG,
        else => format,
    };
}

fn applyTextureSwizzle(internalformat: i32) void {
    const f = modern.tex_parameter_i orelse return;
    const sw: [4]u32 = switch (@as(u32, @intCast(internalformat))) {
        gl.ALPHA, gl.ALPHA4, gl.ALPHA8, gl.ALPHA12, gl.ALPHA16, gl.COMPRESSED_ALPHA_ARB => .{ gl.ONE, gl.ONE, gl.ONE, gl.RED },
        gl.LUMINANCE, gl.LUMINANCE4, gl.LUMINANCE8, gl.LUMINANCE12, gl.LUMINANCE16, gl.COMPRESSED_LUMINANCE_ARB => .{ gl.RED, gl.RED, gl.RED, gl.ONE },
        gl.INTENSITY, gl.INTENSITY4, gl.INTENSITY8, gl.INTENSITY12, gl.INTENSITY16, gl.COMPRESSED_INTENSITY_ARB => .{ gl.RED, gl.RED, gl.RED, gl.RED },
        gl.LUMINANCE_ALPHA, gl.LUMINANCE4_ALPHA4, gl.LUMINANCE6_ALPHA2, gl.LUMINANCE8_ALPHA8, gl.LUMINANCE12_ALPHA4, gl.LUMINANCE12_ALPHA12, gl.LUMINANCE16_ALPHA16, gl.COMPRESSED_LUMINANCE_ALPHA_ARB => .{ gl.RED, gl.RED, gl.RED, gl.GREEN },
        else => .{ gl.RED, gl.GREEN, gl.BLUE, gl.ALPHA },
    };
    f(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_R_EXT, @intCast(sw[0]));
    f(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_G_EXT, @intCast(sw[1]));
    f(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_B_EXT, @intCast(sw[2]));
    f(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_A_EXT, @intCast(sw[3]));
}

fn regenerateMipmaps() void {
    if (modern.generate_mipmap) |f| f(gl.TEXTURE_2D);
}

fn hostTextureParam(pname: u32) u32 {
    return switch (pname) {
        gl.TEXTURE_MIN_FILTER => gl.TEXTURE_MIN_FILTER,
        gl.TEXTURE_MAG_FILTER => gl.TEXTURE_MAG_FILTER,
        gl.TEXTURE_WRAP_S => gl.TEXTURE_WRAP_S,
        gl.TEXTURE_WRAP_T => gl.TEXTURE_WRAP_T,
        else => pname,
    };
}

fn hostTextureValue(pname: u32, param: i32) i32 {
    switch (pname) {
        gl.TEXTURE_MIN_FILTER, gl.TEXTURE_MAG_FILTER => {
            return @intCast(switch (@as(u32, @intCast(param))) {
                gl.NEAREST => gl.NEAREST,
                gl.LINEAR => gl.LINEAR,
                gl.NEAREST_MIPMAP_NEAREST => gl.NEAREST_MIPMAP_NEAREST,
                gl.LINEAR_MIPMAP_NEAREST => gl.LINEAR_MIPMAP_NEAREST,
                gl.NEAREST_MIPMAP_LINEAR => gl.NEAREST_MIPMAP_LINEAR,
                gl.LINEAR_MIPMAP_LINEAR => gl.LINEAR_MIPMAP_LINEAR,
                else => gl.NEAREST,
            });
        },
        gl.TEXTURE_WRAP_S, gl.TEXTURE_WRAP_T => {
            return @intCast(switch (@as(u32, @intCast(param))) {
                gl.REPEAT => gl.REPEAT,
                gl.CLAMP, gl.CLAMP_TO_EDGE => gl.CLAMP_TO_EDGE,
                else => gl.REPEAT,
            });
        },
        else => return param,
    }
}

// Lighting material/light

pub fn lightMaterial(face: u32, pname: u32, params: [*]const f32) void {
    _ = face;
    switch (pname) {
        gl.AMBIENT => g_state.lighting.material.ambient = .{ params[0], params[1], params[2], params[3] },
        gl.DIFFUSE => g_state.lighting.material.diffuse = .{ params[0], params[1], params[2], params[3] },
        gl.SPECULAR => g_state.lighting.material.specular = .{ params[0], params[1], params[2], params[3] },
        gl.EMISSION => g_state.lighting.material.emissive = .{ params[0], params[1], params[2], params[3] },
        gl.AMBIENT_AND_DIFFUSE => {
            g_state.lighting.material.ambient = .{ params[0], params[1], params[2], params[3] };
            g_state.lighting.material.diffuse = .{ params[0], params[1], params[2], params[3] };
        },
        gl.SHININESS => g_state.lighting.material.shininess = params[0],
        else => {},
    }
}

pub fn light(light_index: u32, pname: u32, params: [*]const f32) void {
    if (light_index >= 4) {
        return;
    }
    const target = &g_state.lighting.lights[light_index];
    switch (pname) {
        gl.AMBIENT => target.ambient = .{ params[0], params[1], params[2], params[3] },
        gl.DIFFUSE => target.diffuse = .{ params[0], params[1], params[2], params[3] },
        gl.SPECULAR => target.specular = .{ params[0], params[1], params[2], params[3] },
        gl.POSITION => target.position = transformVec4(g_state.transform.modelview.current(), .{ params[0], params[1], params[2], params[3] }),
        gl.SPOT_DIRECTION => {
            const mv = g_state.transform.modelview.current();
            target.spot_direction = .{
                mv.m[0] * params[0] + mv.m[4] * params[1] + mv.m[8] * params[2],
                mv.m[1] * params[0] + mv.m[5] * params[1] + mv.m[9] * params[2],
                mv.m[2] * params[0] + mv.m[6] * params[1] + mv.m[10] * params[2],
            };
        },
        gl.SPOT_CUTOFF => target.spot_cutoff = params[0],
        gl.SPOT_EXPONENT => target.spot_exponent = params[0],
        gl.CONSTANT_ATTENUATION => target.attenuation[0] = params[0],
        gl.LINEAR_ATTENUATION => target.attenuation[1] = params[0],
        gl.QUADRATIC_ATTENUATION => target.attenuation[2] = params[0],
        else => {},
    }
}

/// Multiplies a column vector by a column-major matrix.
fn transformVec4(matrix: math.Mat4, v: [4]f32) [4]f32 {
    return .{
        matrix.m[0] * v[0] + matrix.m[4] * v[1] + matrix.m[8] * v[2] + matrix.m[12] * v[3],
        matrix.m[1] * v[0] + matrix.m[5] * v[1] + matrix.m[9] * v[2] + matrix.m[13] * v[3],
        matrix.m[2] * v[0] + matrix.m[6] * v[1] + matrix.m[10] * v[2] + matrix.m[14] * v[3],
        matrix.m[3] * v[0] + matrix.m[7] * v[1] + matrix.m[11] * v[2] + matrix.m[15] * v[3],
    };
}

pub fn lightModel(pname: u32, params: [*]const f32) void {
    if (pname == gl.AMBIENT) {
        g_state.lighting.model_ambient = .{ params[0], params[1], params[2], params[3] };
    }
}

pub fn fog(pname: u32, params: [*]const f32) void {
    switch (pname) {
        gl.FOG_MODE => g_state.fog.mode = .fromGL(@intFromFloat(params[0])),
        gl.FOG_DENSITY => g_state.fog.density = params[0],
        gl.FOG_START => g_state.fog.start = params[0],
        gl.FOG_END => g_state.fog.end = params[0],
        gl.FOG_COLOR => g_state.fog.color = .{ params[0], params[1], params[2], params[3] },
        gl.FOG_INDEX => g_state.fog.index = params[0],
        gl.FOG_COORDINATE_SOURCE_EXT => g_state.fog.coord_source = .fromGL(@as(u32, @intFromFloat(params[0]))),
        else => {},
    }
}

// Special functions

pub fn newList(list: u32, mode: u32) void {
    _ = list;
    _ = mode;
}
pub fn endList() void {}
pub fn callList(list: u32) void {
    _ = list;
}
pub fn renderMode(mode: u32) u32 {
    _ = mode;
    return gl.RENDER;
}
pub fn selectBuffer(n: i32, buffer: [*]u32) void {
    _ = n;
    _ = buffer;
}
pub fn feedbackBuffer(n: i32, buffer: [*]f32) void {
    _ = n;
    _ = buffer;
}
pub fn map1(target: u32, u: f64, u_max: f64, stride: i32, order: i32, points: [*]const f64) void {
    _ = target;
    _ = u;
    _ = u_max;
    _ = stride;
    _ = order;
    _ = points;
}
pub fn evalCoord1(arg: f32) void {
    _ = arg;
}
pub fn evalPoint1(p: i32) void {
    _ = p;
}

// Attribute stack

fn restoreState(saved: types.State) void {
    const initialized = g_state.host.initialized;
    const program = g_state.host.program;
    const vao = g_state.host.vao;
    const vbo = g_state.host.vbo;
    const uniforms = g_state.host.uniforms;
    g_state = saved;
    g_state.host.initialized = initialized;
    g_state.host.program = program;
    g_state.host.vao = vao;
    g_state.host.vbo = vbo;
    g_state.host.uniforms = uniforms;
}

pub fn pushAttrib(mask: u32) void {
    _ = mask;
    if (attrib_top < attrib_stack.len) {
        attrib_stack[attrib_top] = g_state;
        attrib_top += 1;
    }
}
pub fn popAttrib() void {
    if (attrib_top == 0) {
        return;
    }
    attrib_top -= 1;
    restoreState(attrib_stack[attrib_top]);
}

pub fn pushClientAttrib(mask: u32) void {
    _ = mask;
    if (client_attrib_top < client_attrib_stack.len) {
        client_attrib_stack[client_attrib_top] = g_state;
        client_attrib_top += 1;
    }
}
pub fn popClientAttrib() void {
    if (client_attrib_top == 0) {
        return;
    }
    client_attrib_top -= 1;
    restoreState(client_attrib_stack[client_attrib_top]);
}

// Queries

const string_vendor: [*:0]const u8 = "GLEmu";
const string_renderer: [*:0]const u8 = "GLEmu OpenGL Fixed Function emulation";
const string_version: [*:0]const u8 = "1.0.0";
const string_extensions: [*:0]const u8 =
    "GL_ARB_multitexture GL_EXT_texture_env_combine GL_EXT_fog_coord " ++
    "GL_EXT_compiled_vertex_array GL_ARB_texture_compression " ++
    "GL_EXT_texture_compression_s3tc GL_EXT_texture_edge_clamp " ++
    "GL_SGIS_texture_edge_clamp GL_EXT_secondary_color " ++
    "GL_EXT_blend_func_separate GL_EXT_blend_minmax GL_EXT_blend_subtract " ++
    "GL_EXT_blend_color GL_EXT_texture_object GL_EXT_vertex_array " ++
    "GL_EXT_multi_draw_arrays " ++
    "GL_EXT_texture_filter_anisotropic WGL_EXT_swap_control";

pub fn getString(name: u32) ?[*:0]const u8 {
    trace.log("GETSTRING 0x{x}\n", .{name});
    switch (name) {
        gl.VENDOR => return string_vendor,
        gl.RENDERER => return string_renderer,
        gl.VERSION => return string_version,
        gl.EXTENSIONS => return string_extensions,
        else => {},
    }
    ensureReady();
    if (modern.get_string) |f| {
        return f(name);
    }
    return null;
}

pub fn getIntegerv(pname: u32, params: [*]i32) void {
    trace.log("GETINTEGERV 0x{x}\n", .{pname});
    switch (pname) {
        gl.VIEWPORT => {
            var i: usize = 0;
            while (i < 4) : (i += 1) params[i] = g_state.framebuffer.viewport[i];
        },
        gl.MATRIX_MODE => params[0] = @intCast(@backingInt(g_state.transform.mode)),
        gl.BLEND_SRC => params[0] = @intCast(@backingInt(g_state.blend.src)),
        gl.BLEND_DST => params[0] = @intCast(@backingInt(g_state.blend.dst)),
        gl.BLEND_EQUATION => params[0] = @intCast(@backingInt(g_state.blend.equation)),
        gl.DEPTH_FUNC => params[0] = @intCast(@backingInt(g_state.depth.func)),
        gl.CULL_FACE_MODE => params[0] = @intCast(@backingInt(g_state.raster.cull_face)),
        gl.FRONT_FACE => params[0] = @intCast(@backingInt(g_state.raster.front_face)),
        gl.SHADE_MODEL => params[0] = @intCast(@backingInt(g_state.raster.shade_model)),
        gl.FOG_MODE => params[0] = @intCast(@backingInt(g_state.fog.mode)),
        gl.TEXTURE_BINDING_2D => params[0] = @intCast(g_state.texture_units[g_state.texture.active_texture].bound_2d),
        gl.TEXTURE_BINDING_1D => params[0] = @intCast(g_state.texture_units[g_state.texture.active_texture].bound_1d),
        gl.ACTIVE_TEXTURE_ARB => params[0] = @intCast(gl.TEXTURE0_ARB + g_state.texture.active_texture),
        gl.CLIENT_ACTIVE_TEXTURE_ARB => params[0] = @intCast(gl.TEXTURE0_ARB + g_state.client_arrays.active_texture),
        gl.MAX_TEXTURE_UNITS_ARB => params[0] = @intCast(types.tex_units),
        gl.MAX_LIGHTS => params[0] = 4,
        gl.MAX_TEXTURE_SIZE => params[0] = 4096,
        gl.MODELVIEW_STACK_DEPTH => params[0] = @intCast(g_state.transform.modelview.top + 1),
        gl.PROJECTION_STACK_DEPTH => params[0] = @intCast(g_state.transform.projection.top + 1),
        gl.TEXTURE_STACK_DEPTH => params[0] = @intCast(g_state.texture_units[g_state.texture.active_texture].matrix.top + 1),
        gl.ATTRIB_STACK_DEPTH => params[0] = @intCast(attrib_top),
        gl.CLIENT_ATTRIB_STACK_DEPTH => params[0] = @intCast(client_attrib_top),
        gl.ARRAY_BUFFER_BINDING => params[0] = @intCast(g_state.client_arrays.array_buffer_binding),
        gl.ELEMENT_ARRAY_BUFFER_BINDING => params[0] = @intCast(g_state.client_arrays.element_array_buffer_binding),
        gl.VERTEX_ARRAY_BINDING => params[0] = 0,
        gl.STENCIL_FUNC => params[0] = @intCast(@backingInt(g_state.stencil.func)),
        gl.STENCIL_REF => params[0] = g_state.stencil.ref,
        gl.STENCIL_VALUE_MASK => params[0] = @intCast(g_state.stencil.value_mask),
        gl.STENCIL_FAIL => params[0] = @intCast(@backingInt(g_state.stencil.fail)),
        gl.STENCIL_PASS_DEPTH_FAIL => params[0] = @intCast(@backingInt(g_state.stencil.pass_depth_fail)),
        gl.STENCIL_PASS_DEPTH_PASS => params[0] = @intCast(@backingInt(g_state.stencil.pass_depth_pass)),
        gl.STENCIL_WRITEMASK => params[0] = @intCast(g_state.stencil.write_mask),
        else => {
            if (modern.get_integer_v) |f| {
                f(pname, params);
            } else {
                params[0] = 0;
            }
        },
    }
}

fn storeMatrix(params: [*]f32, matrix: math.Mat4) void {
    var i: usize = 0;
    while (i < 16) : (i += 1) params[i] = matrix.m[i];
}

pub fn getFloatv(pname: u32, params: [*]f32) void {
    switch (pname) {
        gl.ALPHA_TEST_REF => params[0] = @floatCast(g_state.alpha_test.ref),
        gl.COLOR_CLEAR_VALUE => storeN(params, &g_state.framebuffer.clear_color),
        gl.CURRENT_COLOR => storeN(params, &g_state.current.color),
        gl.CURRENT_NORMAL => storeN(params, &g_state.current.normal),
        gl.CURRENT_RASTER_COLOR => storeN(params, &g_state.current.color),
        gl.CURRENT_SECONDARY_COLOR => storeN(params, &g_state.current.secondary_color),
        gl.CURRENT_TEXTURE_COORDS => storeN(params, &g_state.texture_units[g_state.texture.active_texture].current_coord),
        gl.CURRENT_RASTER_TEXTURE_COORDS => storeN(params, &g_state.texture_units[g_state.texture.active_texture].current_coord),
        gl.DEPTH_CLEAR_VALUE => params[0] = @floatCast(g_state.framebuffer.clear_depth),
        gl.DEPTH_RANGE => {
            params[0] = @floatCast(g_state.framebuffer.depth_range[0]);
            params[1] = @floatCast(g_state.framebuffer.depth_range[1]);
        },
        gl.FOG_COLOR => storeN(params, &g_state.fog.color),
        gl.FOG_DENSITY => params[0] = g_state.fog.density,
        gl.FOG_END => params[0] = g_state.fog.end,
        gl.LINE_WIDTH => params[0] = g_state.raster.line_width,
        gl.POINT_SIZE => params[0] = g_state.raster.point_size,
        gl.POLYGON_OFFSET_FACTOR => params[0] = g_state.raster.polygon_offset_factor,
        gl.POLYGON_OFFSET_UNITS => params[0] = g_state.raster.polygon_offset_units,
        gl.MODELVIEW_MATRIX => storeMatrix(params, g_state.transform.modelview.current()),
        gl.PROJECTION_MATRIX => storeMatrix(params, g_state.transform.projection.current()),
        gl.TEXTURE_MATRIX => storeMatrix(params, g_state.texture_units[g_state.texture.active_texture].matrix.current()),
        else => {
            if (modern.get_float_v) |f| {
                f(pname, params);
            } else {
                params[0] = 0;
            }
        },
    }
}

pub fn getBoolean(pname: u32) bool {
    switch (pname) {
        gl.BLEND => return (g_state.blend.enabled),
        gl.FOG => return (g_state.fog.enabled),
        gl.ALPHA_TEST => return (g_state.alpha_test.enabled),
        gl.CLIP_PLANE0...gl.CLIP_PLANE5 => return (g_state.clip.enabled[pname - gl.CLIP_PLANE0]),
        gl.COLOR_ARRAY => return (g_state.client_arrays.color.enabled),
        gl.COLOR_LOGIC_OP => return (g_state.blend.logic_enabled),
        gl.COLOR_MATERIAL => return (g_state.lighting.color_material.enabled),
        gl.CULL_FACE => return (g_state.raster.cull_face_enabled),
        gl.DEPTH_TEST => return (g_state.depth.enabled),
        gl.DEPTH_WRITEMASK => return (g_state.depth.mask),
        gl.DITHER => return (g_state.raster.dither),
        gl.FOG_COORD_ARRAY => return (g_state.client_arrays.fogcoord.enabled),
        gl.INDEX_ARRAY => return (g_state.client_arrays.index.enabled),
        gl.LIGHTING => return (g_state.lighting.enabled),
        gl.LIGHT0...gl.LIGHT7 => return (g_state.lighting.lights[pname - gl.LIGHT0].enabled),
        gl.LINE_SMOOTH => return (g_state.raster.line_smooth),
        gl.LINE_STIPPLE => return (g_state.raster.line_stipple_pattern != 0xFFFF),
        gl.NORMAL_ARRAY => return (g_state.client_arrays.normal.enabled),
        gl.POINT_SMOOTH => return (g_state.raster.point_smooth),
        gl.NORMALIZE => return (g_state.lighting.normalize),
        gl.POLYGON_OFFSET_FILL => return (g_state.raster.polygon_offset_fill),
        gl.POLYGON_OFFSET_LINE => return (g_state.raster.polygon_offset_fill),
        gl.POLYGON_OFFSET_POINT => return (g_state.raster.polygon_offset_fill),
        gl.POLYGON_SMOOTH => return (g_state.raster.polygon_smooth),
        gl.RESCALE_NORMAL => return (g_state.lighting.normalize),
        gl.SCISSOR_TEST => return (g_state.framebuffer.scissor_test),
        gl.STENCIL_TEST => return (g_state.stencil.enabled),
        gl.TEXTURE_1D => return (g_state.texture.enabled_1d),
        gl.TEXTURE_2D => return (g_state.texture.enabled_2d),
        gl.TEXTURE_COORD_ARRAY => return (g_state.texture_units[g_state.texture.active_texture].coord_array.enabled),
        gl.TEXTURE_GEN_Q => return (g_state.texture_units[g_state.texture.active_texture].texgen_enabled[3]),
        gl.TEXTURE_GEN_R => return (g_state.texture_units[g_state.texture.active_texture].texgen_enabled[2]),
        gl.TEXTURE_GEN_S => return (g_state.texture_units[g_state.texture.active_texture].texgen_enabled[0]),
        gl.TEXTURE_GEN_T => return (g_state.texture_units[g_state.texture.active_texture].texgen_enabled[1]),
        gl.VERTEX_ARRAY => return (g_state.client_arrays.vertex.enabled),
        else => {
            if (modern.get_boolean_v) |f| {
                var value: [1]u8 = .{0};
                f(pname, &value);
                return (value[0] != 0);
            } else {
                return false;
            }
        },
    }
}

pub fn isTexture(texture: u32) u8 {
    return @intFromBool(texture != 0);
}

// Object queries

fn storeN(params: [*]f32, value: []const f32) void {
    var i: usize = 0;
    while (i < value.len) : (i += 1) params[i] = value[i];
}

pub fn getLight(light_index: u32, pname: u32, params: [*]f32) void {
    if (light_index >= types.max_lights) {
        params[0] = 0;
        return;
    }
    const source = &g_state.lighting.lights[light_index];
    switch (pname) {
        gl.AMBIENT => storeN(params, &source.ambient),
        gl.DIFFUSE => storeN(params, &source.diffuse),
        gl.SPECULAR => storeN(params, &source.specular),
        gl.POSITION => storeN(params, &source.position),
        gl.SPOT_DIRECTION => {
            var k: usize = 0;
            while (k < 3) : (k += 1) params[k] = source.spot_direction[k];
        },
        gl.SPOT_CUTOFF => params[0] = source.spot_cutoff,
        gl.SPOT_EXPONENT => params[0] = source.spot_exponent,
        gl.CONSTANT_ATTENUATION => params[0] = source.attenuation[0],
        gl.LINEAR_ATTENUATION => params[0] = source.attenuation[1],
        gl.QUADRATIC_ATTENUATION => params[0] = source.attenuation[2],
        else => params[0] = 0,
    }
}

pub fn getMaterial(pname: u32, params: [*]f32) void {
    switch (pname) {
        gl.AMBIENT => storeN(params, &g_state.lighting.material.ambient),
        gl.DIFFUSE => storeN(params, &g_state.lighting.material.diffuse),
        gl.SPECULAR => storeN(params, &g_state.lighting.material.specular),
        gl.EMISSION => storeN(params, &g_state.lighting.material.emissive),
        gl.SHININESS => params[0] = g_state.lighting.material.shininess,
        else => params[0] = 0,
    }
}

pub fn getTexEnv(pname: u32, params: [*]f32) void {
    const unit = g_state.texture.active_texture;
    switch (pname) {
        gl.TEXTURE_ENV_MODE => {
            params[0] = @floatFromInt(if (g_state.texture_units[unit].combine_enabled) gl.COMBINE_EXT else @backingInt(g_state.texture_units[unit].env_mode));
        },
        gl.TEXTURE_ENV_COLOR => storeN(params, &g_state.texture_units[unit].env_color),
        gl.COMBINE_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.func)),
        gl.COMBINE_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.func)),
        gl.SOURCE0_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.source[0])),
        gl.SOURCE1_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.source[1])),
        gl.SOURCE2_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.source[2])),
        gl.SOURCE0_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.source[0])),
        gl.SOURCE1_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.source[1])),
        gl.SOURCE2_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.source[2])),
        gl.OPERAND0_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.operand[0])),
        gl.OPERAND1_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.operand[1])),
        gl.OPERAND2_RGB_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_rgb.operand[2])),
        gl.OPERAND0_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.operand[0])),
        gl.OPERAND1_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.operand[1])),
        gl.OPERAND2_ALPHA_EXT => params[0] = @floatFromInt(@backingInt(g_state.texture_units[unit].combine_alpha.operand[2])),
        gl.RGB_SCALE_EXT => params[0] = g_state.texture_units[unit].rgb_scale,
        gl.ALPHA_SCALE => params[0] = g_state.texture_units[unit].combine_alpha_scale,
        else => params[0] = 0,
    }
}

pub fn getTexGen(coord: u32, pname: u32, params: [*]f32) void {
    const unit = g_state.texture.active_texture;
    const target = switch (coord) {
        gl.S => &g_state.texture_units[unit].texgen[0],
        gl.T => &g_state.texture_units[unit].texgen[1],
        gl.R => &g_state.texture_units[unit].texgen[2],
        else => &g_state.texture_units[unit].texgen[3],
    };
    switch (pname) {
        gl.TEXTURE_GEN_MODE => params[0] = @floatFromInt(@backingInt(target.mode)),
        gl.OBJECT_PLANE, gl.EYE_PLANE => storeN(params, &target.plane),
        else => params[0] = 0,
    }
}

pub fn getClipPlane(plane: u32) ?[4]f32 {
    if (plane < gl.CLIP_PLANE0 or plane > gl.CLIP_PLANE0 + 5) {
        return null;
    }
    const value = g_state.clip.planes[plane - gl.CLIP_PLANE0];
    return value;
}

pub fn getPointer(pname: u32) ?*const anyopaque {
    const pointer: ?*const anyopaque = switch (pname) {
        gl.VERTEX_ARRAY_POINTER => g_state.client_arrays.vertex.pointer,
        gl.NORMAL_ARRAY_POINTER => g_state.client_arrays.normal.pointer,
        gl.COLOR_ARRAY_POINTER => g_state.client_arrays.color.pointer,
        gl.INDEX_ARRAY_POINTER => g_state.client_arrays.index.pointer,
        gl.TEXTURE_COORD_ARRAY_POINTER => g_state.texture_units[g_state.client_arrays.active_texture].coord_array.pointer,
        gl.FOG_COORD_ARRAY_POINTER => g_state.client_arrays.fogcoord.pointer,
        else => null,
    };
    return pointer;
}

pub fn flush() void {}

pub fn finish() void {}
