const math = @import("math.zig");
const gl = @import("../gl/gl.zig");
const std = @import("std");

// Vertex layout
pub const max_stack = 32;
pub const tex_units = 4;
pub const max_lights = 4;
pub const max_clip_planes = 6;

pub const Vertex = extern struct {
    position: [4]f32 = .{ 0, 0, 0, 1 },
    color: [4]f32 = .{ 1, 1, 1, 1 },
    normal: [3]f32 = .{ 0, 0, 1 },
    texcoord: [tex_units][4]f32 = .{
        .{ 0, 0, 0, 1 },
        .{ 0, 0, 0, 1 },
        .{ 0, 0, 0, 1 },
        .{ 0, 0, 0, 1 },
    },
    fog_coord: f32 = 0,
};

// The matrix stack
pub const MatrixStack = struct {
    stack: [max_stack]math.Mat4 = @splat(math.Mat4.identity),
    top: usize = 0,

    pub fn reset(self: *MatrixStack) void {
        self.top = 0;
        self.stack[0] = math.Mat4.identity;
    }
    pub fn current(self: *MatrixStack) math.Mat4 {
        return self.stack[self.top];
    }
    pub fn set(self: *MatrixStack, value: math.Mat4) void {
        self.stack[self.top] = value;
    }
    pub fn push(self: *MatrixStack) void {
        if (self.top + 1 >= max_stack) {
            return; // STUB: GL_STACK_OVERFLOW is not reported.
        }
        self.stack[self.top + 1] = self.stack[self.top];
        self.top += 1;
    }
    pub fn pop(self: *MatrixStack) void {
        if (self.top == 0) {
            return; // STUB: GL_STACK_UNDERFLOW is not reported.
        }
        self.top -= 1;
    }
};

pub const Light = struct {
    ambient: [4]f32 = .{ 0, 0, 0, 1 },
    diffuse: [4]f32 = .{ 1, 1, 1, 1 },
    specular: [4]f32 = .{ 1, 1, 1, 1 },
    position: [4]f32 = .{ 0, 0, 1, 0 },
    attenuation: [3]f32 = .{ 1, 0, 0 },
    spot_direction: [3]f32 = .{ 0, 0, -1 },
    spot_cutoff: f32 = 180,
    spot_exponent: f32 = 0,
    enabled: bool = false,
};

pub const ClientArray = struct {
    enabled: bool = false,
    size: i32 = 4,
    type: DataType = .float,
    stride: i32 = 0,
    buffer: u32 = 0,
    normalized: bool = false,
    pointer: ?*const anyopaque = null,
};

pub const TexGenCoeff = struct {
    mode: TexGenMode = .off,
    plane: [4]f32 = .{ 0, 0, 0, 0 },
};

/// EXT_texture_env_combine
pub const Combine = struct {
    func: CombineFunc = .modulate,
    source: [3]CombineSource = .{ .texture, .previous, .previous },
    operand: [3]CombineOperand = .{ .src_color, .src_color, .src_color },
};

pub const Framebuffer = struct {
    viewport: [4]i32 = .{ 0, 0, 1, 1 },
    depth_range: [2]f64 = .{ 0, 1 },
    clear_color: [4]f32 = .{ 0, 0, 0, 0 },
    clear_index: f32 = 0,
    clear_depth: f64 = 1,
    clear_stencil: i32 = 0,
    color_mask: [4]bool = .{ true, true, true, true },
    index_mask: u32 = 0xFFFFFFFF,
    scissor_box: [4]i32 = .{ 0, 0, 1, 1 },
    scissor_test: bool = false,
    draw_buffer: DrawBufferMode = .back,
    read_buffer: DrawBufferMode = .front,
};

pub const Depth = struct {
    enabled: bool = false,
    func: CompareFunc = .less,
    mask: bool = true,
};

pub const Stencil = struct {
    enabled: bool = false,
    func: CompareFunc = .always,
    ref: i32 = 0,
    value_mask: u32 = 0xFFFFFFFF,
    write_mask: u32 = 0xFFFFFFFF,
    fail: StencilOp = .keep,
    pass_depth_fail: StencilOp = .keep,
    pass_depth_pass: StencilOp = .keep,
};

pub const Blend = struct {
    enabled: bool = false,
    src: BlendFactor = .one,
    dst: BlendFactor = .zero,
    equation: BlendEquation = .add,
    src_rgb: BlendFactor = .one,
    dst_rgb: BlendFactor = .zero,
    src_alpha: BlendFactor = .one,
    dst_alpha: BlendFactor = .zero,
    color: [4]f32 = .{ 0, 0, 0, 0 },
    logic_op: LogicOp = .copy,
    logic_enabled: bool = false,
};

pub const AlphaTest = struct {
    enabled: bool = false,
    func: CompareFunc = .always,
    ref: f32 = 0,
};

pub const Raster = struct {
    point_size: f32 = 1,
    point_size_min: f32 = 0,
    point_size_max: f32 = 1,
    point_distance_attenuation: [3]f32 = .{ 1, 0, 0 },
    line_width: f32 = 1,
    line_stipple_factor: i32 = 1,
    line_stipple_pattern: u16 = 0xFFFF,
    polygon_mode_front: PolygonMode = .fill,
    polygon_mode_back: PolygonMode = .fill,
    front_face: FrontFace = .ccw,
    cull_face: CullFace = .back,
    cull_face_enabled: bool = false,
    shade_model: ShadeModel = .smooth,
    polygon_offset_factor: f32 = 0,
    polygon_offset_units: f32 = 0,
    polygon_offset_fill: bool = false,
    point_smooth: bool = false,
    line_smooth: bool = false,
    polygon_smooth: bool = false,
    dither: bool = true,
};

pub const Fog = struct {
    enabled: bool = false,
    mode: FogMode = .exp,
    density: f32 = 1,
    start: f32 = 0,
    end: f32 = 1,
    color: [4]f32 = .{ 0, 0, 0, 0 },
    index: f32 = 0,
    coord_source: FogCoordSource = .fragment_depth,
};

pub const Material = struct {
    ambient: [4]f32 = .{ 0.2, 0.2, 0.2, 1 },
    diffuse: [4]f32 = .{ 0.8, 0.8, 0.8, 1 },
    specular: [4]f32 = .{ 0, 0, 0, 1 },
    emissive: [4]f32 = .{ 0, 0, 0, 1 },
    shininess: f32 = 0,
};

pub const ColorMaterial = struct {
    enabled: bool = false,
    face: MaterialFace = .front_and_back,
    mode: ColorMaterialMode = .ambient_and_diffuse,
};

pub const Lighting = struct {
    enabled: bool = false,
    normalize: bool = false,
    model_ambient: [4]f32 = .{ 0.2, 0.2, 0.2, 1 },
    material: Material = .{},
    color_material: ColorMaterial = .{},
    lights: [max_lights]Light = .{ .{}, .{}, .{}, .{} },
};

pub const Transform = struct {
    mode: MatrixMode = .modelview,
    modelview: MatrixStack = .{},
    projection: MatrixStack = .{},
    color_stack: [max_stack][4]f32 = @splat(.{ 0, 0, 0, 0 }),
    color_stack_top: usize = 0,
};

pub const Clip = struct {
    planes: [max_clip_planes][4]f32 = @splat(.{ 0, 0, 0, 0 }),
    enabled: [max_clip_planes]bool = @splat(false),
};

pub const PixelTransfer = struct {
    unpack_alignment: i32 = 4,
    unpack_row_length: i32 = 0,
    unpack_skip_rows: i32 = 0,
    unpack_skip_pixels: i32 = 0,
    unpack_swap_bytes: bool = false,
    unpack_lsb_first: bool = false,
    pack_alignment: i32 = 4,
    pack_row_length: i32 = 0,
    pack_skip_rows: i32 = 0,
    pack_skip_pixels: i32 = 0,
    pack_swap_bytes: bool = false,
    pack_lsb_first: bool = false,
    index_shift: i32 = 0,
    index_offset: i32 = 0,
    red_scale: f32 = 1,
    green_scale: f32 = 1,
    blue_scale: f32 = 1,
    alpha_scale: f32 = 1,
    depth_scale: f32 = 1,
    red_bias: f32 = 0,
    green_bias: f32 = 0,
    blue_bias: f32 = 0,
    alpha_bias: f32 = 0,
    depth_bias: f32 = 0,
};

pub const Current = struct {
    color: [4]f32 = .{ 1, 1, 1, 1 },
    index: f32 = 1,
    normal: [3]f32 = .{ 0, 0, 1 },
    edge_flag: bool = true,
    fog_coord: f32 = 0,
    /// EXT_secondary_color.
    secondary_color: [4]f32 = .{ 0, 0, 0, 1 },
};

pub const ClientArrays = struct {
    active_texture: usize = 0,
    vertex: ClientArray = .{},
    normal: ClientArray = .{},
    color: ClientArray = .{},
    fogcoord: ClientArray = .{},
    index: ClientArray = .{},
    array_buffer_binding: u32 = 0,
    element_array_buffer_binding: u32 = 0,
};

pub const Immediate = struct {
    begun: bool = false,
    begin_mode: u32 = 0,
};

pub const Hints = struct {
    perspective: HintMode = .dont_care,
    point_smooth: HintMode = .dont_care,
    line_smooth: HintMode = .dont_care,
    polygon_smooth: HintMode = .dont_care,
    fog: HintMode = .dont_care,
};

/// Global texturing state
pub const Texture = struct {
    active_texture: usize = 0,
    enabled_2d: bool = false,
    enabled_1d: bool = false,
};

/// Everything that is per texture unit
pub const TexUnit = struct {
    bound_1d: u32 = 0,
    bound_2d: u32 = 0,
    enabled_2d: bool = false,
    enabled_1d: bool = false,

    env_mode: TextureEnvMode = .modulate,
    env_color: [4]f32 = .{ 0, 0, 0, 0 },

    combine_enabled: bool = false,
    combine_rgb: Combine = .{},
    combine_alpha: Combine = .{},
    rgb_scale: f32 = 1,
    combine_alpha_scale: f32 = 1,

    /// Indexed by texture coordinate (S/T/R/Q).
    texgen: [4]TexGenCoeff = .{ .{}, .{}, .{}, .{} },
    texgen_enabled: [4]bool = @splat(false),

    matrix: MatrixStack = .{},
    coord_array: ClientArray = .{},
    current_coord: [4]f32 = .{ 0, 0, 0, 1 },
};

// Shader uniform locations

pub const TransformUniforms = struct {
    modelview: i32 = -1,
    projection: i32 = -1,
    normalmatrix: i32 = -1,
    texturematrix: i32 = -1,
    normalize: i32 = -1,
};

pub const LightingUniforms = struct {
    lighting_enabled: i32 = -1,
    light_count: i32 = -1,
    light_ambient: i32 = -1,
    light_diffuse: i32 = -1,
    light_specular: i32 = -1,
    light_position: i32 = -1,
    light_attenuation: i32 = -1,
    light_spot_direction: i32 = -1,
    light_spot_cutoff: i32 = -1,
    light_spot_exponent: i32 = -1,
    light_model_ambient: i32 = -1,
    material_ambient: i32 = -1,
    material_diffuse: i32 = -1,
    material_specular: i32 = -1,
    material_emissive: i32 = -1,
    material_shininess: i32 = -1,
};

pub const FogUniforms = struct {
    fog_enabled: i32 = -1,
    fog_mode: i32 = -1,
    fog_source: i32 = -1,
    fog_density: i32 = -1,
    fog_start: i32 = -1,
    fog_end: i32 = -1,
    fog_color: i32 = -1,
};

pub const TextureUniforms = struct {
    tex_enabled: i32 = -1,
    tex_env_mode: i32 = -1,
    tex_env_color: i32 = -1,
    combine: i32 = -1,
    combine_rgb_func: i32 = -1,
    combine_alpha_func: i32 = -1,
    combine_rgb_source: i32 = -1,
    combine_rgb_operand: i32 = -1,
    combine_alpha_source: i32 = -1,
    combine_alpha_operand: i32 = -1,
    rgb_scale: i32 = -1,
    alpha_scale: i32 = -1,
    sampler: i32 = -1,
    texgen_mode_s: i32 = -1,
    texgen_mode_t: i32 = -1,
    texgen_mode_r: i32 = -1,
    texgen_mode_q: i32 = -1,
    texgen_plane_s: i32 = -1,
    texgen_plane_t: i32 = -1,
    texgen_plane_r: i32 = -1,
    texgen_plane_q: i32 = -1,
};

pub const AlphaTestUniforms = struct {
    alpha_test_enabled: i32 = -1,
    alpha_func: i32 = -1,
    alpha_ref: i32 = -1,
};

pub const ClipUniforms = struct {
    clip_plane: i32 = -1,
};

pub const Uniforms = struct {
    transform: TransformUniforms = .{},
    lighting: LightingUniforms = .{},
    fog: FogUniforms = .{},
    texture: TextureUniforms = .{},
    alpha_test: AlphaTestUniforms = .{},
    clip: ClipUniforms = .{},
};

pub const Host = struct {
    initialized: bool = false,
    program: u32 = 0,
    vao: u32 = 0,
    vbo: u32 = 0,
    uniforms: Uniforms = .{},
};

pub const State = struct {
    framebuffer: Framebuffer = .{},
    depth: Depth = .{},
    stencil: Stencil = .{},
    blend: Blend = .{},
    alpha_test: AlphaTest = .{},
    raster: Raster = .{},
    fog: Fog = .{},
    lighting: Lighting = .{},
    transform: Transform = .{},
    clip: Clip = .{},
    pixel_transfer: PixelTransfer = .{},
    current: Current = .{},
    client_arrays: ClientArrays = .{},
    immediate: Immediate = .{},
    hints: Hints = .{},

    texture: Texture = .{},
    texture_units: [tex_units]TexUnit = .{ .{}, .{}, .{}, .{} },

    // Render mode (chapter 5, stubbed).
    render_mode: u32 = gl.RENDER,
    list_base: u32 = 0,

    host: Host = .{},
};

// Typed state enums

fn enumFromGL(comptime T: type, v: u32, default: T) T {
    const info = @typeInfo(T).@"enum";
    inline for (info.field_values, info.field_names) |value, name| {
        if (value == v) return @field(T, name);
    }
    return default;
}

pub const MatrixMode = enum(u32) {
    modelview = gl.MODELVIEW,
    projection = gl.PROJECTION,
    texture = gl.TEXTURE,
    color = gl.COLOR,

    pub inline fn fromGL(v: u32) MatrixMode {
        return enumFromGL(MatrixMode, v, .modelview);
    }
};

pub const CompareFunc = enum(u32) {
    never = gl.NEVER,
    less = gl.LESS,
    equal = gl.EQUAL,
    lequal = gl.LEQUAL,
    greater = gl.GREATER,
    notequal = gl.NOTEQUAL,
    gequal = gl.GEQUAL,
    always = gl.ALWAYS,

    pub inline fn fromGL(v: u32) CompareFunc {
        return enumFromGL(CompareFunc, v, .always);
    }
};

pub const BlendFactor = enum(u32) {
    zero = gl.ZERO,
    one = gl.ONE,
    src_color = gl.SRC_COLOR,
    one_minus_src_color = gl.ONE_MINUS_SRC_COLOR,
    dst_color = gl.DST_COLOR,
    one_minus_dst_color = gl.ONE_MINUS_DST_COLOR,
    src_alpha = gl.SRC_ALPHA,
    one_minus_src_alpha = gl.ONE_MINUS_SRC_ALPHA,
    dst_alpha = gl.DST_ALPHA,
    one_minus_dst_alpha = gl.ONE_MINUS_DST_ALPHA,
    src_alpha_saturate = gl.SRC_ALPHA_SATURATE,
    constant_color = gl.CONSTANT_COLOR,
    one_minus_constant_color = gl.ONE_MINUS_CONSTANT_COLOR,
    constant_alpha = gl.CONSTANT_ALPHA,
    one_minus_constant_alpha = gl.ONE_MINUS_CONSTANT_ALPHA,

    pub inline fn fromGL(v: u32) BlendFactor {
        return enumFromGL(BlendFactor, v, .one);
    }
};

pub const BlendEquation = enum(u32) {
    add = gl.FUNC_ADD,
    subtract = gl.FUNC_SUBTRACT,
    reverse_subtract = gl.FUNC_REVERSE_SUBTRACT,
    min = gl.MIN,
    max = gl.MAX,

    pub inline fn fromGL(v: u32) BlendEquation {
        return enumFromGL(BlendEquation, v, .add);
    }
};

pub const LogicOp = enum(u32) {
    clear = gl.CLEAR,
    and_ = gl.AND,
    and_reverse = gl.AND_REVERSE,
    copy = gl.COPY,
    and_inverted = gl.AND_INVERTED,
    noop = gl.NOOP,
    xor = gl.XOR,
    or_ = gl.OR,
    nor = gl.NOR,
    equiv = gl.EQUIV,
    invert = gl.INVERT,
    or_reverse = gl.OR_REVERSE,
    copy_inverted = gl.COPY_INVERTED,
    or_inverted = gl.OR_INVERTED,
    nand = gl.NAND,
    set = gl.SET,

    pub inline fn fromGL(v: u32) LogicOp {
        return enumFromGL(LogicOp, v, .copy);
    }
};

pub const StencilOp = enum(u32) {
    keep = gl.KEEP,
    zero = gl.ZERO,
    replace = gl.REPLACE,
    incr = gl.INCR,
    decr = gl.DECR,
    invert = gl.INVERT,
    incr_wrap = gl.INCR_WRAP,
    decr_wrap = gl.DECR_WRAP,

    pub inline fn fromGL(v: u32) StencilOp {
        return enumFromGL(StencilOp, v, .keep);
    }
};

pub const CullFace = enum(u32) {
    front = gl.FRONT,
    back = gl.BACK,
    front_and_back = gl.FRONT_AND_BACK,

    pub inline fn fromGL(v: u32) CullFace {
        return enumFromGL(CullFace, v, .back);
    }
};

pub const FrontFace = enum(u32) {
    cw = gl.CW,
    ccw = gl.CCW,

    pub inline fn fromGL(v: u32) FrontFace {
        return enumFromGL(FrontFace, v, .ccw);
    }
};

pub const ShadeModel = enum(u32) {
    flat = gl.FLAT,
    smooth = gl.SMOOTH,

    pub inline fn fromGL(v: u32) ShadeModel {
        return enumFromGL(ShadeModel, v, .smooth);
    }
};

pub const PolygonMode = enum(u32) {
    point = gl.POINT,
    line = gl.LINE,
    fill = gl.FILL,

    pub inline fn fromGL(v: u32) PolygonMode {
        return enumFromGL(PolygonMode, v, .fill);
    }
};

pub const FogMode = enum(u32) {
    linear = gl.LINEAR,
    exp = gl.EXP,
    exp2 = gl.EXP2,

    pub inline fn fromGL(v: u32) FogMode {
        return enumFromGL(FogMode, v, .exp);
    }
};

pub const FogCoordSource = enum(u32) {
    fragment_depth = gl.FRAGMENT_DEPTH_EXT,
    fog_coordinate = gl.FOG_COORDINATE_EXT,

    pub inline fn fromGL(v: u32) FogCoordSource {
        return enumFromGL(FogCoordSource, v, .fragment_depth);
    }
};

pub const MaterialFace = enum(u32) {
    front = gl.FRONT,
    back = gl.BACK,
    front_and_back = gl.FRONT_AND_BACK,

    pub inline fn fromGL(v: u32) MaterialFace {
        return enumFromGL(MaterialFace, v, .front_and_back);
    }
};

pub const ColorMaterialMode = enum(u32) {
    emission = gl.EMISSION,
    ambient = gl.AMBIENT,
    diffuse = gl.DIFFUSE,
    specular = gl.SPECULAR,
    ambient_and_diffuse = gl.AMBIENT_AND_DIFFUSE,

    pub inline fn fromGL(v: u32) ColorMaterialMode {
        return enumFromGL(ColorMaterialMode, v, .ambient_and_diffuse);
    }
};

pub const HintMode = enum(u32) {
    dont_care = gl.DONT_CARE,
    fastest = gl.FASTEST,
    nicest = gl.NICEST,

    pub inline fn fromGL(v: u32) HintMode {
        return enumFromGL(HintMode, v, .dont_care);
    }
};

pub const TextureEnvMode = enum(u32) {
    modulate = gl.MODULATE,
    decal = gl.DECAL,
    blend = gl.BLEND,
    replace = gl.REPLACE,
    combine = gl.COMBINE_EXT,
    add = gl.ADD,

    pub inline fn fromGL(v: u32) TextureEnvMode {
        return enumFromGL(TextureEnvMode, v, .modulate);
    }
};

pub const CombineFunc = enum(u32) {
    replace = gl.REPLACE,
    modulate = gl.MODULATE,
    add = gl.ADD,
    add_signed = gl.ADD_SIGNED_EXT,
    interpolate = gl.INTERPOLATE_EXT,
    subtract = gl.SUBTRACT,

    pub inline fn fromGL(v: u32) CombineFunc {
        return enumFromGL(CombineFunc, v, .modulate);
    }
};

pub const CombineSource = enum(u32) {
    texture = gl.TEXTURE,
    constant = gl.CONSTANT_EXT,
    primary_color = gl.PRIMARY_COLOR_EXT,
    previous = gl.PREVIOUS_EXT,

    pub inline fn fromGL(v: u32) CombineSource {
        return enumFromGL(CombineSource, v, .previous);
    }
};

pub const CombineOperand = enum(u32) {
    src_color = gl.SRC_COLOR,
    one_minus_src_color = gl.ONE_MINUS_SRC_COLOR,
    src_alpha = gl.SRC_ALPHA,
    one_minus_src_alpha = gl.ONE_MINUS_SRC_ALPHA,

    pub inline fn fromGL(v: u32) CombineOperand {
        return enumFromGL(CombineOperand, v, .src_color);
    }
};

pub const TexGenMode = enum(u32) {
    off = 0,
    object_linear = gl.OBJECT_LINEAR,
    eye_linear = gl.EYE_LINEAR,
    sphere_map = gl.SPHERE_MAP,
    reflection_map = gl.REFLECTION_MAP,

    pub inline fn fromGL(v: u32) TexGenMode {
        return enumFromGL(TexGenMode, v, .object_linear);
    }
};

pub const DataType = enum(u32) {
    byte = gl.BYTE,
    unsigned_byte = gl.UNSIGNED_BYTE,
    short = gl.SHORT,
    unsigned_short = gl.UNSIGNED_SHORT,
    int = gl.INT,
    unsigned_int = gl.UNSIGNED_INT,
    float = gl.FLOAT,
    double = gl.DOUBLE,

    pub inline fn fromGL(v: u32) DataType {
        return enumFromGL(DataType, v, .float);
    }
};

pub const DrawBufferMode = enum(u32) {
    none = gl.NONE,
    front_left = gl.FRONT_LEFT,
    front_right = gl.FRONT_RIGHT,
    back_left = gl.BACK_LEFT,
    back_right = gl.BACK_RIGHT,
    front = gl.FRONT,
    back = gl.BACK,
    left = gl.LEFT,
    right = gl.RIGHT,
    front_and_back = gl.FRONT_AND_BACK,

    pub inline fn fromGL(v: u32) DrawBufferMode {
        return enumFromGL(DrawBufferMode, v, .back);
    }
};
