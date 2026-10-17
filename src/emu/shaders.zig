//! shaders.zig
//! The GLSL shaders used by the emulation.

const std = @import("std");

pub const vertex_stage =
    \\#version 330 core
    \\
    \\// OpenGL 1.1 emulation: vertex processing.
    \\
    \\in vec4 a_position;
    \\in vec4 a_color;
    \\in vec3 a_normal;
    \\in vec4 a_texcoord0;
    \\in vec4 a_texcoord1;
    \\in vec4 a_texcoord2;
    \\in vec4 a_texcoord3;
    \\in float a_fogcoord;
    \\
    \\uniform mat4 u_modelview;
    \\uniform mat4 u_projection;
    \\uniform mat4 u_normalmatrix;
    \\uniform mat4 u_texturematrix[4];
    \\uniform bool u_normalize;
    \\uniform bool u_lighting_enabled;
    \\
    \\// Lighting state. Up to four light sources are supported.
    \\uniform int u_light_count;
    \\uniform vec4 u_light_ambient[4];
    \\uniform vec4 u_light_diffuse[4];
    \\uniform vec4 u_light_specular[4];
    \\uniform vec4 u_light_position[4];
    \\uniform vec3 u_light_attenuation[4];
    \\uniform vec3 u_light_spot_direction[4];
    \\uniform float u_light_spot_cutoff[4];
    \\uniform float u_light_spot_exponent[4];
    \\uniform vec4 u_light_model_ambient;
    \\uniform vec4 u_material_ambient;
    \\uniform vec4 u_material_diffuse;
    \\uniform vec4 u_material_specular;
    \\uniform vec4 u_material_emissive;
    \\uniform float u_material_shininess;
    \\
    \\// Texture-coordinate generation, per unit.
    \\uniform int u_texgen_mode_s[4];
    \\uniform int u_texgen_mode_t[4];
    \\uniform int u_texgen_mode_r[4];
    \\uniform int u_texgen_mode_q[4];
    \\uniform vec4 u_texgen_plane_s[4];
    \\uniform vec4 u_texgen_plane_t[4];
    \\uniform vec4 u_texgen_plane_r[4];
    \\uniform vec4 u_texgen_plane_q[4];
    \\
    \\// User clip planes, in object coordinates.
    \\uniform vec4 u_clip_plane[6];
    \\
    \\out vec4 v_color;
    \\out vec4 v_texcoord[4];
    \\out float v_eye_z;
    \\out float v_fog_coord;
    \\
    \\void main() {
    \\    vec4 object_position = a_position;
    \\    vec4 eye_position = u_modelview * object_position;
    \\    gl_Position = u_projection * eye_position;
    \\
    \\    vec3 eye_normal = mat3(u_normalmatrix) * a_normal;
    \\    if (u_normalize) {
    \\        eye_normal = normalize(eye_normal);
    \\    }
    \\
    \\    vec4 in_texcoord[4];
    \\    in_texcoord[0] = a_texcoord0;
    \\    in_texcoord[1] = a_texcoord1;
    \\    in_texcoord[2] = a_texcoord2;
    \\    in_texcoord[3] = a_texcoord3;
    \\    for (int i = 0; i < 4; i++) {
    \\        vec4 texcoord = in_texcoord[i];
    \\        int ms = u_texgen_mode_s[i];
    \\        int mt = u_texgen_mode_t[i];
    \\        int mr = u_texgen_mode_r[i];
    \\        int mq = u_texgen_mode_q[i];
    \\
    \\        if (ms == 0x2402 || mt == 0x2402 || ms == 0x8512 || mt == 0x8512 || mr == 0x8512) {
    \\            vec3 u = normalize(eye_position.xyz);
    \\            vec3 n = normalize(eye_normal);
    \\            vec3 f = u - 2.0 * n * dot(n, u);
    \\            if (ms == 0x2402 || mt == 0x2402) {
    \\                float m = 2.0 * sqrt(f.x * f.x + f.y * f.y + (f.z + 1.0) * (f.z + 1.0));
    \\                texcoord.x = f.x / m + 0.5;
    \\                texcoord.y = f.y / m + 0.5;
    \\            }
    \\            if (ms == 0x8512) texcoord.x = f.x;
    \\            if (mt == 0x8512) texcoord.y = f.y;
    \\            if (mr == 0x8512) texcoord.z = f.z;
    \\        } else {
    \\            // GL_OBJECT_LINEAR (0x2400) uses object coordinates, GL_EYE_LINEAR
    \\            // (0x2401) uses eye coordinates.
    \\            if (ms == 0x2400) texcoord.x = dot(u_texgen_plane_s[i], object_position);
    \\            else if (ms == 0x2401) texcoord.x = dot(u_texgen_plane_s[i], eye_position);
    \\            if (mt == 0x2400) texcoord.y = dot(u_texgen_plane_t[i], object_position);
    \\            else if (mt == 0x2401) texcoord.y = dot(u_texgen_plane_t[i], eye_position);
    \\            if (mr == 0x2400) texcoord.z = dot(u_texgen_plane_r[i], object_position);
    \\            else if (mr == 0x2401) texcoord.z = dot(u_texgen_plane_r[i], eye_position);
    \\            if (mq == 0x2400) texcoord.w = dot(u_texgen_plane_q[i], object_position);
    \\            else if (mq == 0x2401) texcoord.w = dot(u_texgen_plane_q[i], eye_position);
    \\        }
    \\
    \\        v_texcoord[i] = u_texturematrix[i] * texcoord;
    \\    }
    \\
    \\    vec4 color = a_color;
    \\    vec3 eye_dir = normalize(-eye_position.xyz);
    \\    if (u_lighting_enabled) {
    \\    vec3 lit = u_material_emissive.rgb + u_material_ambient.rgb * u_light_model_ambient.rgb;
    \\    for (int i = 0; i < 4; i++) {
    \\        if (i >= u_light_count) {
    \\            break;
    \\        }
    \\        vec4 light_position = u_light_position[i];
    \\        vec3 to_light;
    \\        float attenuation = 1.0;
    \\        if (light_position.w > 0.0) {
    \\            to_light = light_position.xyz - eye_position.xyz;
    \\            float distance = length(to_light);
    \\            to_light = to_light / max(distance, 0.000001);
    \\            float k0 = u_light_attenuation[i].x;
    \\            float k1 = u_light_attenuation[i].y;
    \\            float k2 = u_light_attenuation[i].z;
    \\            attenuation = 1.0 / max(k0 + k1 * distance + k2 * distance * distance, 0.000001);
    \\        } else {
    \\            to_light = normalize(light_position.xyz);
    \\        }
    \\
    \\        // Spot light.
    \\        float spot = 1.0;
    \\        if (light_position.w > 0.0 && u_light_spot_cutoff[i] < 180.0) {
    \\            vec3 spot_dir = normalize(u_light_spot_direction[i]);
    \\            float cosine = dot(-to_light, spot_dir);
    \\            if (degrees(acos(clamp(cosine, -1.0, 1.0))) > u_light_spot_cutoff[i]) {
    \\                spot = 0.0;
    \\            } else {
    \\                spot = pow(max(cosine, 0.0), max(u_light_spot_exponent[i], 0.0001));
    \\            }
    \\        }
    \\
    \\        vec3 half_vector = normalize(to_light + eye_dir);
    \\        float ndotl = max(dot(eye_normal, to_light), 0.0);
    \\        float ndoth = max(dot(eye_normal, half_vector), 0.0);
    \\        float specular = pow(ndoth, max(u_material_shininess, 0.0001));
    \\        lit += spot * attenuation * (u_material_ambient.rgb * u_light_ambient[i].rgb
    \\            + u_material_diffuse.rgb * u_light_diffuse[i].rgb * ndotl
    \\            + u_material_specular.rgb * u_light_specular[i].rgb * specular);
    \\    }
    \\    color = vec4(clamp(lit, 0.0, 1.0), u_material_diffuse.a);
    \\    }
    \\
    \\    v_color = color;
    \\    v_eye_z = eye_position.z;
    \\    v_fog_coord = a_fogcoord;
    \\
    \\    // User clip planes.
    \\    gl_ClipDistance[0] = dot(object_position, u_clip_plane[0]);
    \\    gl_ClipDistance[1] = dot(object_position, u_clip_plane[1]);
    \\    gl_ClipDistance[2] = dot(object_position, u_clip_plane[2]);
    \\    gl_ClipDistance[3] = dot(object_position, u_clip_plane[3]);
    \\    gl_ClipDistance[4] = dot(object_position, u_clip_plane[4]);
    \\    gl_ClipDistance[5] = dot(object_position, u_clip_plane[5]);
    \\}
    \\
;

pub const fragment_stage =
    \\#version 330 core
    \\
    \\// OpenGL 1.1 emulation: per-fragment operations.
    \\
    \\in vec4 v_color;
    \\in vec4 v_texcoord[4];
    \\in float v_eye_z;
    \\in float v_fog_coord;
    \\
    \\uniform bool u_fog_enabled;
    \\uniform int u_fog_mode;
    \\uniform int u_fog_source;
    \\uniform float u_fog_density;
    \\uniform float u_fog_start;
    \\uniform float u_fog_end;
    \\uniform vec4 u_fog_color;
    \\
    \\// Per-unit texturing state (ARB_multitexture).
    \\uniform bool u_tex_enabled[4];
    \\uniform int u_tex_env_mode[4];
    \\uniform vec4 u_tex_env_color[4];
    \\
    \\// EXT_texture_env_combine state.
    \\uniform bool u_combine[4];
    \\uniform int u_combine_rgb_func[4];
    \\uniform int u_combine_alpha_func[4];
    \\uniform int u_combine_rgb_source[12];
    \\uniform int u_combine_rgb_operand[12];
    \\uniform int u_combine_alpha_source[12];
    \\uniform int u_combine_alpha_operand[12];
    \\uniform float u_rgb_scale[4];
    \\uniform float u_alpha_scale[4];
    \\
    \\uniform sampler2D u_texture[4];
    \\
    \\uniform bool u_alpha_test_enabled;
    \\uniform int u_alpha_func;
    \\uniform float u_alpha_ref;
    \\
    \\out vec4 frag_color;
    \\
    \\// Applies alpha test.
    \\bool alpha_test(float a) {
    \\    if (u_alpha_func == 0x0200) return false;            // NEVER
    \\    if (u_alpha_func == 0x0207) return true;             // ALWAYS
    \\    if (u_alpha_func == 0x0201) return a <  u_alpha_ref; // LESS
    \\    if (u_alpha_func == 0x0203) return a <= u_alpha_ref; // LEQUAL
    \\    if (u_alpha_func == 0x0202) return a == u_alpha_ref; // EQUAL
    \\    if (u_alpha_func == 0x0206) return a >= u_alpha_ref; // GEQUAL
    \\    if (u_alpha_func == 0x0204) return a >  u_alpha_ref; // GREATER
    \\    if (u_alpha_func == 0x0205) return a != u_alpha_ref; // NOTEQUAL
    \\    return true;
    \\}
    \\
    \\// One combine source term (EXT_texture_env_combine).
    \\vec4 combine_source(int unit, int source, int operand, vec4 previous, vec4 texel) {
    \\    vec4 value;
    \\    if (source == 0x1702) {          // GL_TEXTURE
    \\        value = texel;
    \\    } else if (source == 0x8576) {   // GL_CONSTANT_EXT
    \\        value = u_tex_env_color[unit];
    \\    } else if (source == 0x8577) {   // GL_PRIMARY_COLOR_EXT
    \\        value = v_color;
    \\    } else {                         // GL_PREVIOUS_EXT
    \\        value = previous;
    \\    }
    \\    if (operand == 0x0300) {         // GL_SRC_COLOR
    \\        return value;
    \\    } else if (operand == 0x0301) {  // GL_ONE_MINUS_SRC_COLOR
    \\        return vec4(1.0) - value;
    \\    } else if (operand == 0x0302) {  // GL_SRC_ALPHA
    \\        return vec4(value.a);
    \\    } else {                         // GL_ONE_MINUS_SRC_ALPHA
    \\        return vec4(1.0 - value.a);
    \\    }
    \\}
    \\
    \\vec4 combine_function(int function, vec4 a0, vec4 a1, vec4 a2) {
    \\    if (function == 0x1E01) {        // GL_REPLACE
    \\        return a0;
    \\    } else if (function == 0x2100) { // GL_MODULATE
    \\        return a0 * a1;
    \\    } else if (function == 0x0104) { // GL_ADD
    \\        return a0 + a1;
    \\    } else if (function == 0x8574) { // GL_ADD_SIGNED_EXT
    \\        return a0 + a1 - vec4(0.5);
    \\    } else if (function == 0x8575) { // GL_INTERPOLATE_EXT
    \\        return a0 * a2 + a1 * (vec4(1.0) - a2);
    \\    } else {                         // GL_SUBTRACT
    \\        return a0 - a1;
    \\    }
    \\}
    \\
    \\// Applies one texture unit and returns the resulting colour.
    \\vec4 apply_unit(int unit, vec4 previous, vec4 texel) {
    \\    if (!u_combine[unit]) {
    \\        int mode = u_tex_env_mode[unit];
    \\        if (mode == 0x1E01) {                       // GL_REPLACE
    \\            return vec4(texel.rgb, previous.a);
    \\        } else if (mode == 0x2100) {                // GL_MODULATE
    \\            return texel * previous;
    \\        } else if (mode == 0x2101) {                // GL_DECAL
    \\            return vec4(mix(previous.rgb, texel.rgb, texel.a), previous.a);
    \\        } else {                                    // GL_BLEND
    \\            return vec4(mix(previous.rgb, u_tex_env_color[unit].rgb, texel.rgb),
    \\                        previous.a * texel.a);
    \\        }
    \\    }
    \\
    \\    int base = unit * 3;
    \\    vec4 rgb0 = combine_source(unit, u_combine_rgb_source[base + 0], u_combine_rgb_operand[base + 0], previous, texel);
    \\    vec4 rgb1 = combine_source(unit, u_combine_rgb_source[base + 1], u_combine_rgb_operand[base + 1], previous, texel);
    \\    vec4 rgb2 = combine_source(unit, u_combine_rgb_source[base + 2], u_combine_rgb_operand[base + 2], previous, texel);
    \\    vec4 a0 = combine_source(unit, u_combine_alpha_source[base + 0], u_combine_alpha_operand[base + 0], previous, texel);
    \\    vec4 a1 = combine_source(unit, u_combine_alpha_source[base + 1], u_combine_alpha_operand[base + 1], previous, texel);
    \\    vec4 a2 = combine_source(unit, u_combine_alpha_source[base + 2], u_combine_alpha_operand[base + 2], previous, texel);
    \\
    \\    vec3 rgb = combine_function(u_combine_rgb_func[unit], rgb0, rgb1, rgb2).rgb * u_rgb_scale[unit];
    \\    float alpha = combine_function(u_combine_alpha_func[unit], a0, a1, a2).a * u_alpha_scale[unit];
    \\    return vec4(rgb, alpha);
    \\}
    \\
    \\void main() {
    \\    vec4 color = v_color;
    \\
    \\    // Texturing 
    \\    if (u_tex_enabled[0]) color = apply_unit(0, color, texture(u_texture[0], v_texcoord[0].xy));
    \\    if (u_tex_enabled[1]) color = apply_unit(1, color, texture(u_texture[1], v_texcoord[1].xy));
    \\    if (u_tex_enabled[2]) color = apply_unit(2, color, texture(u_texture[2], v_texcoord[2].xy));
    \\    if (u_tex_enabled[3]) color = apply_unit(3, color, texture(u_texture[3], v_texcoord[3].xy));
    \\
    \\    // Fog
    \\    if (u_fog_enabled) {
    \\        float fog_distance = (u_fog_source == 0x8451) ? v_fog_coord : abs(v_eye_z);
    \\        float f;
    \\        if (u_fog_mode == 0x0800) {                  // GL_EXP
    \\            f = exp(-u_fog_density * fog_distance);
    \\        } else if (u_fog_mode == 0x0801) {           // GL_EXP2
    \\            float z = u_fog_density * fog_distance;
    \\            f = exp(-(z * z));
    \\        } else {                                     // GL_LINEAR
    \\            f = (u_fog_end - fog_distance) / (u_fog_end - u_fog_start);
    \\        }
    \\        f = clamp(f, 0.0, 1.0);
    \\        color.rgb = mix(u_fog_color.rgb, color.rgb, f);
    \\    }
    \\
    \\    if (u_alpha_test_enabled && !alpha_test(color.a)) {
    \\        discard;
    \\    }
    \\
    \\    frag_color = color;
    \\}
    \\
;
