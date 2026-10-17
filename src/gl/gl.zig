//! gl.zig

const std = @import("std");

// The primitives
pub const GLenum = u32;
pub const GLboolean = u8;
pub const GLbitfield = u32;
pub const GLbyte = i8;
pub const GLshort = i16;
pub const GLint = i32;
pub const GLsizei = i32;
pub const GLubyte = u8;
pub const GLushort = u16;
pub const GLuint = u32;
pub const GLfloat = f32;
pub const GLclampf = f32;
pub const GLdouble = f64;
pub const GLclampd = f64;
pub const GLsizeiptr = isize;
pub const GLintptr = isize;

const error_mod = @import("error.zig");
const state_mod = @import("../emu/state.zig");

// Error handler
const g_error_handler = &error_mod.gErrorHandler;

// The enums

pub const VERSION_1_1: u32 = 1;

pub const ZERO: u32 = 0;
pub const FALSE: u32 = 0;
pub const LOGIC_OP: u32 = 0x0BF1;
pub const NONE: u32 = 0;
pub const TEXTURE_COMPONENTS: u32 = 0x1003;
pub const NO_ERROR: u32 = 0;
pub const POINTS: u32 = 0x0000;
pub const CURRENT_BIT: u32 = 0x00000001;
pub const TRUE: u32 = 1;
pub const ONE: u32 = 1;
pub const CLIENT_PIXEL_STORE_BIT: u32 = 0x00000001;
pub const LINES: u32 = 0x0001;
pub const LINE_LOOP: u32 = 0x0002;
pub const POINT_BIT: u32 = 0x00000002;
pub const CLIENT_VERTEX_ARRAY_BIT: u32 = 0x00000002;
pub const LINE_STRIP: u32 = 0x0003;
pub const LINE_BIT: u32 = 0x00000004;
pub const TRIANGLES: u32 = 0x0004;
pub const TRIANGLE_STRIP: u32 = 0x0005;
pub const TRIANGLE_FAN: u32 = 0x0006;
pub const QUADS: u32 = 0x0007;
pub const QUAD_STRIP: u32 = 0x0008;
pub const POLYGON_BIT: u32 = 0x00000008;
pub const POLYGON: u32 = 0x0009;
pub const POLYGON_STIPPLE_BIT: u32 = 0x00000010;
pub const PIXEL_MODE_BIT: u32 = 0x00000020;
pub const LIGHTING_BIT: u32 = 0x00000040;
pub const FOG_BIT: u32 = 0x00000080;
pub const DEPTH_BUFFER_BIT: u32 = 0x00000100;
pub const ACCUM: u32 = 0x0100;
pub const LOAD: u32 = 0x0101;
pub const RETURN: u32 = 0x0102;
pub const MULT: u32 = 0x0103;
pub const ADD: u32 = 0x0104;
pub const NEVER: u32 = 0x0200;
pub const ACCUM_BUFFER_BIT: u32 = 0x00000200;
pub const LESS: u32 = 0x0201;
pub const EQUAL: u32 = 0x0202;
pub const LEQUAL: u32 = 0x0203;
pub const GREATER: u32 = 0x0204;
pub const NOTEQUAL: u32 = 0x0205;
pub const GEQUAL: u32 = 0x0206;
pub const ALWAYS: u32 = 0x0207;
pub const SRC_COLOR: u32 = 0x0300;
pub const ONE_MINUS_SRC_COLOR: u32 = 0x0301;
pub const SRC_ALPHA: u32 = 0x0302;
pub const ONE_MINUS_SRC_ALPHA: u32 = 0x0303;
pub const DST_ALPHA: u32 = 0x0304;
pub const ONE_MINUS_DST_ALPHA: u32 = 0x0305;
pub const DST_COLOR: u32 = 0x0306;
pub const ONE_MINUS_DST_COLOR: u32 = 0x0307;
pub const SRC_ALPHA_SATURATE: u32 = 0x0308;
pub const STENCIL_BUFFER_BIT: u32 = 0x00000400;
pub const FRONT_LEFT: u32 = 0x0400;
pub const FRONT_RIGHT: u32 = 0x0401;
pub const BACK_LEFT: u32 = 0x0402;
pub const BACK_RIGHT: u32 = 0x0403;
pub const FRONT: u32 = 0x0404;
pub const BACK: u32 = 0x0405;
pub const LEFT: u32 = 0x0406;
pub const RIGHT: u32 = 0x0407;
pub const FRONT_AND_BACK: u32 = 0x0408;
pub const AUX0: u32 = 0x0409;
pub const AUX1: u32 = 0x040A;
pub const AUX2: u32 = 0x040B;
pub const AUX3: u32 = 0x040C;
pub const INVALID_ENUM: u32 = 0x0500;
pub const INVALID_VALUE: u32 = 0x0501;
pub const INVALID_OPERATION: u32 = 0x0502;
pub const STACK_OVERFLOW: u32 = 0x0503;
pub const STACK_UNDERFLOW: u32 = 0x0504;
pub const OUT_OF_MEMORY: u32 = 0x0505;
pub const GL_2D: u32 = 0x0600;
pub const GL_3D: u32 = 0x0601;
pub const GL_3D_COLOR: u32 = 0x0602;
pub const GL_3D_COLOR_TEXTURE: u32 = 0x0603;
pub const GL_4D_COLOR_TEXTURE: u32 = 0x0604;
pub const PASS_THROUGH_TOKEN: u32 = 0x0700;
pub const POINT_TOKEN: u32 = 0x0701;
pub const LINE_TOKEN: u32 = 0x0702;
pub const POLYGON_TOKEN: u32 = 0x0703;
pub const BITMAP_TOKEN: u32 = 0x0704;
pub const DRAW_PIXEL_TOKEN: u32 = 0x0705;
pub const COPY_PIXEL_TOKEN: u32 = 0x0706;
pub const LINE_RESET_TOKEN: u32 = 0x0707;
pub const EXP: u32 = 0x0800;
pub const VIEWPORT_BIT: u32 = 0x00000800;
pub const EXP2: u32 = 0x0801;
pub const CW: u32 = 0x0900;
pub const CCW: u32 = 0x0901;
pub const COEFF: u32 = 0x0A00;
pub const ORDER: u32 = 0x0A01;
pub const DOMAIN: u32 = 0x0A02;
pub const CURRENT_COLOR: u32 = 0x0B00;
pub const CURRENT_INDEX: u32 = 0x0B01;
pub const CURRENT_NORMAL: u32 = 0x0B02;
pub const CURRENT_TEXTURE_COORDS: u32 = 0x0B03;
pub const CURRENT_RASTER_COLOR: u32 = 0x0B04;
pub const CURRENT_RASTER_INDEX: u32 = 0x0B05;
pub const CURRENT_RASTER_TEXTURE_COORDS: u32 = 0x0B06;
pub const CURRENT_RASTER_POSITION: u32 = 0x0B07;
pub const CURRENT_RASTER_POSITION_VALID: u32 = 0x0B08;
pub const CURRENT_RASTER_DISTANCE: u32 = 0x0B09;
pub const POINT_SMOOTH: u32 = 0x0B10;
pub const POINT_SIZE: u32 = 0x0B11;
pub const POINT_SIZE_RANGE: u32 = 0x0B12;
pub const POINT_SIZE_GRANULARITY: u32 = 0x0B13;
pub const LINE_SMOOTH: u32 = 0x0B20;
pub const LINE_WIDTH: u32 = 0x0B21;
pub const LINE_WIDTH_RANGE: u32 = 0x0B22;
pub const LINE_WIDTH_GRANULARITY: u32 = 0x0B23;
pub const LINE_STIPPLE: u32 = 0x0B24;
pub const LINE_STIPPLE_PATTERN: u32 = 0x0B25;
pub const LINE_STIPPLE_REPEAT: u32 = 0x0B26;
pub const LIST_MODE: u32 = 0x0B30;
pub const MAX_LIST_NESTING: u32 = 0x0B31;
pub const LIST_BASE: u32 = 0x0B32;
pub const LIST_INDEX: u32 = 0x0B33;
pub const POLYGON_MODE: u32 = 0x0B40;
pub const POLYGON_SMOOTH: u32 = 0x0B41;
pub const POLYGON_STIPPLE: u32 = 0x0B42;
pub const EDGE_FLAG: u32 = 0x0B43;
pub const CULL_FACE: u32 = 0x0B44;
pub const CULL_FACE_MODE: u32 = 0x0B45;
pub const FRONT_FACE: u32 = 0x0B46;
pub const LIGHTING: u32 = 0x0B50;
pub const LIGHT_MODEL_LOCAL_VIEWER: u32 = 0x0B51;
pub const LIGHT_MODEL_TWO_SIDE: u32 = 0x0B52;
pub const LIGHT_MODEL_AMBIENT: u32 = 0x0B53;
pub const SHADE_MODEL: u32 = 0x0B54;
pub const COLOR_MATERIAL_FACE: u32 = 0x0B55;
pub const COLOR_MATERIAL_PARAMETER: u32 = 0x0B56;
pub const COLOR_MATERIAL: u32 = 0x0B57;
pub const FOG: u32 = 0x0B60;
pub const FOG_INDEX: u32 = 0x0B61;
pub const FOG_DENSITY: u32 = 0x0B62;
pub const FOG_START: u32 = 0x0B63;
pub const FOG_END: u32 = 0x0B64;
pub const FOG_MODE: u32 = 0x0B65;
pub const FOG_COLOR: u32 = 0x0B66;
pub const DEPTH_RANGE: u32 = 0x0B70;
pub const DEPTH_TEST: u32 = 0x0B71;
pub const DEPTH_WRITEMASK: u32 = 0x0B72;
pub const DEPTH_CLEAR_VALUE: u32 = 0x0B73;
pub const DEPTH_FUNC: u32 = 0x0B74;
pub const ACCUM_CLEAR_VALUE: u32 = 0x0B80;
pub const STENCIL_TEST: u32 = 0x0B90;
pub const STENCIL_CLEAR_VALUE: u32 = 0x0B91;
pub const STENCIL_FUNC: u32 = 0x0B92;
pub const STENCIL_VALUE_MASK: u32 = 0x0B93;
pub const STENCIL_FAIL: u32 = 0x0B94;
pub const STENCIL_PASS_DEPTH_FAIL: u32 = 0x0B95;
pub const STENCIL_PASS_DEPTH_PASS: u32 = 0x0B96;
pub const STENCIL_REF: u32 = 0x0B97;
pub const STENCIL_WRITEMASK: u32 = 0x0B98;
pub const MATRIX_MODE: u32 = 0x0BA0;
pub const NORMALIZE: u32 = 0x0BA1;
pub const VIEWPORT: u32 = 0x0BA2;
pub const MODELVIEW_STACK_DEPTH: u32 = 0x0BA3;
pub const PROJECTION_STACK_DEPTH: u32 = 0x0BA4;
pub const TEXTURE_STACK_DEPTH: u32 = 0x0BA5;
pub const MODELVIEW_MATRIX: u32 = 0x0BA6;
pub const PROJECTION_MATRIX: u32 = 0x0BA7;
pub const TEXTURE_MATRIX: u32 = 0x0BA8;
pub const ATTRIB_STACK_DEPTH: u32 = 0x0BB0;
pub const CLIENT_ATTRIB_STACK_DEPTH: u32 = 0x0BB1;
pub const ALPHA_TEST: u32 = 0x0BC0;
pub const ALPHA_TEST_FUNC: u32 = 0x0BC1;
pub const ALPHA_TEST_REF: u32 = 0x0BC2;
pub const DITHER: u32 = 0x0BD0;
pub const BLEND_DST: u32 = 0x0BE0;
pub const BLEND_SRC: u32 = 0x0BE1;
pub const BLEND: u32 = 0x0BE2;
pub const LOGIC_OP_MODE: u32 = 0x0BF0;
pub const INDEX_LOGIC_OP: u32 = 0x0BF1;
pub const COLOR_LOGIC_OP: u32 = 0x0BF2;
pub const AUX_BUFFERS: u32 = 0x0C00;
pub const DRAW_BUFFER: u32 = 0x0C01;
pub const READ_BUFFER: u32 = 0x0C02;
pub const SCISSOR_BOX: u32 = 0x0C10;
pub const SCISSOR_TEST: u32 = 0x0C11;
pub const INDEX_CLEAR_VALUE: u32 = 0x0C20;
pub const INDEX_WRITEMASK: u32 = 0x0C21;
pub const COLOR_CLEAR_VALUE: u32 = 0x0C22;
pub const COLOR_WRITEMASK: u32 = 0x0C23;
pub const INDEX_MODE: u32 = 0x0C30;
pub const RGBA_MODE: u32 = 0x0C31;
pub const DOUBLEBUFFER: u32 = 0x0C32;
pub const STEREO: u32 = 0x0C33;
pub const RENDER_MODE: u32 = 0x0C40;
pub const PERSPECTIVE_CORRECTION_HINT: u32 = 0x0C50;
pub const POINT_SMOOTH_HINT: u32 = 0x0C51;
pub const LINE_SMOOTH_HINT: u32 = 0x0C52;
pub const POLYGON_SMOOTH_HINT: u32 = 0x0C53;
pub const FOG_HINT: u32 = 0x0C54;
pub const TEXTURE_GEN_S: u32 = 0x0C60;
pub const TEXTURE_GEN_T: u32 = 0x0C61;
pub const TEXTURE_GEN_R: u32 = 0x0C62;
pub const TEXTURE_GEN_Q: u32 = 0x0C63;
pub const PIXEL_MAP_I_TO_I: u32 = 0x0C70;
pub const PIXEL_MAP_S_TO_S: u32 = 0x0C71;
pub const PIXEL_MAP_I_TO_R: u32 = 0x0C72;
pub const PIXEL_MAP_I_TO_G: u32 = 0x0C73;
pub const PIXEL_MAP_I_TO_B: u32 = 0x0C74;
pub const PIXEL_MAP_I_TO_A: u32 = 0x0C75;
pub const PIXEL_MAP_R_TO_R: u32 = 0x0C76;
pub const PIXEL_MAP_G_TO_G: u32 = 0x0C77;
pub const PIXEL_MAP_B_TO_B: u32 = 0x0C78;
pub const PIXEL_MAP_A_TO_A: u32 = 0x0C79;
pub const PIXEL_MAP_I_TO_I_SIZE: u32 = 0x0CB0;
pub const PIXEL_MAP_S_TO_S_SIZE: u32 = 0x0CB1;
pub const PIXEL_MAP_I_TO_R_SIZE: u32 = 0x0CB2;
pub const PIXEL_MAP_I_TO_G_SIZE: u32 = 0x0CB3;
pub const PIXEL_MAP_I_TO_B_SIZE: u32 = 0x0CB4;
pub const PIXEL_MAP_I_TO_A_SIZE: u32 = 0x0CB5;
pub const PIXEL_MAP_R_TO_R_SIZE: u32 = 0x0CB6;
pub const PIXEL_MAP_G_TO_G_SIZE: u32 = 0x0CB7;
pub const PIXEL_MAP_B_TO_B_SIZE: u32 = 0x0CB8;
pub const PIXEL_MAP_A_TO_A_SIZE: u32 = 0x0CB9;
pub const UNPACK_SWAP_BYTES: u32 = 0x0CF0;
pub const UNPACK_LSB_FIRST: u32 = 0x0CF1;
pub const UNPACK_ROW_LENGTH: u32 = 0x0CF2;
pub const UNPACK_SKIP_ROWS: u32 = 0x0CF3;
pub const UNPACK_SKIP_PIXELS: u32 = 0x0CF4;
pub const UNPACK_ALIGNMENT: u32 = 0x0CF5;
pub const PACK_SWAP_BYTES: u32 = 0x0D00;
pub const PACK_LSB_FIRST: u32 = 0x0D01;
pub const PACK_ROW_LENGTH: u32 = 0x0D02;
pub const PACK_SKIP_ROWS: u32 = 0x0D03;
pub const PACK_SKIP_PIXELS: u32 = 0x0D04;
pub const PACK_ALIGNMENT: u32 = 0x0D05;
pub const MAP_COLOR: u32 = 0x0D10;
pub const MAP_STENCIL: u32 = 0x0D11;
pub const INDEX_SHIFT: u32 = 0x0D12;
pub const INDEX_OFFSET: u32 = 0x0D13;
pub const RED_SCALE: u32 = 0x0D14;
pub const RED_BIAS: u32 = 0x0D15;
pub const ZOOM_X: u32 = 0x0D16;
pub const ZOOM_Y: u32 = 0x0D17;
pub const GREEN_SCALE: u32 = 0x0D18;
pub const GREEN_BIAS: u32 = 0x0D19;
pub const BLUE_SCALE: u32 = 0x0D1A;
pub const BLUE_BIAS: u32 = 0x0D1B;
pub const ALPHA_SCALE: u32 = 0x0D1C;
pub const ALPHA_BIAS: u32 = 0x0D1D;
pub const DEPTH_SCALE: u32 = 0x0D1E;
pub const DEPTH_BIAS: u32 = 0x0D1F;
pub const MAX_EVAL_ORDER: u32 = 0x0D30;
pub const MAX_LIGHTS: u32 = 0x0D31;
pub const MAX_CLIP_PLANES: u32 = 0x0D32;
pub const MAX_TEXTURE_SIZE: u32 = 0x0D33;
pub const MAX_PIXEL_MAP_TABLE: u32 = 0x0D34;
pub const MAX_ATTRIB_STACK_DEPTH: u32 = 0x0D35;
pub const MAX_MODELVIEW_STACK_DEPTH: u32 = 0x0D36;
pub const MAX_NAME_STACK_DEPTH: u32 = 0x0D37;
pub const MAX_PROJECTION_STACK_DEPTH: u32 = 0x0D38;
pub const MAX_TEXTURE_STACK_DEPTH: u32 = 0x0D39;
pub const MAX_VIEWPORT_DIMS: u32 = 0x0D3A;
pub const MAX_CLIENT_ATTRIB_STACK_DEPTH: u32 = 0x0D3B;
pub const SUBPIXEL_BITS: u32 = 0x0D50;
pub const INDEX_BITS: u32 = 0x0D51;
pub const RED_BITS: u32 = 0x0D52;
pub const GREEN_BITS: u32 = 0x0D53;
pub const BLUE_BITS: u32 = 0x0D54;
pub const ALPHA_BITS: u32 = 0x0D55;
pub const DEPTH_BITS: u32 = 0x0D56;
pub const STENCIL_BITS: u32 = 0x0D57;
pub const ACCUM_RED_BITS: u32 = 0x0D58;
pub const ACCUM_GREEN_BITS: u32 = 0x0D59;
pub const ACCUM_BLUE_BITS: u32 = 0x0D5A;
pub const ACCUM_ALPHA_BITS: u32 = 0x0D5B;
pub const NAME_STACK_DEPTH: u32 = 0x0D70;
pub const AUTO_NORMAL: u32 = 0x0D80;
pub const MAP1_COLOR_4: u32 = 0x0D90;
pub const MAP1_INDEX: u32 = 0x0D91;
pub const MAP1_NORMAL: u32 = 0x0D92;
pub const MAP1_TEXTURE_COORD_1: u32 = 0x0D93;
pub const MAP1_TEXTURE_COORD_2: u32 = 0x0D94;
pub const MAP1_TEXTURE_COORD_3: u32 = 0x0D95;
pub const MAP1_TEXTURE_COORD_4: u32 = 0x0D96;
pub const MAP1_VERTEX_3: u32 = 0x0D97;
pub const MAP1_VERTEX_4: u32 = 0x0D98;
pub const MAP2_COLOR_4: u32 = 0x0DB0;
pub const MAP2_INDEX: u32 = 0x0DB1;
pub const MAP2_NORMAL: u32 = 0x0DB2;
pub const MAP2_TEXTURE_COORD_1: u32 = 0x0DB3;
pub const MAP2_TEXTURE_COORD_2: u32 = 0x0DB4;
pub const MAP2_TEXTURE_COORD_3: u32 = 0x0DB5;
pub const MAP2_TEXTURE_COORD_4: u32 = 0x0DB6;
pub const MAP2_VERTEX_3: u32 = 0x0DB7;
pub const MAP2_VERTEX_4: u32 = 0x0DB8;
pub const MAP1_GRID_DOMAIN: u32 = 0x0DD0;
pub const MAP1_GRID_SEGMENTS: u32 = 0x0DD1;
pub const MAP2_GRID_DOMAIN: u32 = 0x0DD2;
pub const MAP2_GRID_SEGMENTS: u32 = 0x0DD3;
pub const TEXTURE_1D: u32 = 0x0DE0;
pub const TEXTURE_2D: u32 = 0x0DE1;
pub const FEEDBACK_BUFFER_POINTER: u32 = 0x0DF0;
pub const FEEDBACK_BUFFER_SIZE: u32 = 0x0DF1;
pub const FEEDBACK_BUFFER_TYPE: u32 = 0x0DF2;
pub const SELECTION_BUFFER_POINTER: u32 = 0x0DF3;
pub const SELECTION_BUFFER_SIZE: u32 = 0x0DF4;
pub const TEXTURE_WIDTH: u32 = 0x1000;
pub const TRANSFORM_BIT: u32 = 0x00001000;
pub const TEXTURE_HEIGHT: u32 = 0x1001;
pub const TEXTURE_INTERNAL_FORMAT: u32 = 0x1003;
pub const TEXTURE_BORDER_COLOR: u32 = 0x1004;
pub const TEXTURE_BORDER: u32 = 0x1005;
pub const DONT_CARE: u32 = 0x1100;
pub const FASTEST: u32 = 0x1101;
pub const NICEST: u32 = 0x1102;
pub const AMBIENT: u32 = 0x1200;
pub const DIFFUSE: u32 = 0x1201;
pub const SPECULAR: u32 = 0x1202;
pub const POSITION: u32 = 0x1203;
pub const SPOT_DIRECTION: u32 = 0x1204;
pub const SPOT_EXPONENT: u32 = 0x1205;
pub const SPOT_CUTOFF: u32 = 0x1206;
pub const CONSTANT_ATTENUATION: u32 = 0x1207;
pub const LINEAR_ATTENUATION: u32 = 0x1208;
pub const QUADRATIC_ATTENUATION: u32 = 0x1209;
pub const COMPILE: u32 = 0x1300;
pub const COMPILE_AND_EXECUTE: u32 = 0x1301;
pub const BYTE: u32 = 0x1400;
pub const UNSIGNED_BYTE: u32 = 0x1401;
pub const SHORT: u32 = 0x1402;
pub const UNSIGNED_SHORT: u32 = 0x1403;
pub const INT: u32 = 0x1404;
pub const UNSIGNED_INT: u32 = 0x1405;
pub const FLOAT: u32 = 0x1406;
pub const GL_2_BYTES: u32 = 0x1407;
pub const GL_3_BYTES: u32 = 0x1408;
pub const GL_4_BYTES: u32 = 0x1409;
pub const DOUBLE: u32 = 0x140A;
pub const CLEAR: u32 = 0x1500;
pub const AND: u32 = 0x1501;
pub const AND_REVERSE: u32 = 0x1502;
pub const COPY: u32 = 0x1503;
pub const AND_INVERTED: u32 = 0x1504;
pub const NOOP: u32 = 0x1505;
pub const XOR: u32 = 0x1506;
pub const OR: u32 = 0x1507;
pub const NOR: u32 = 0x1508;
pub const EQUIV: u32 = 0x1509;
pub const INVERT: u32 = 0x150A;
pub const OR_REVERSE: u32 = 0x150B;
pub const COPY_INVERTED: u32 = 0x150C;
pub const OR_INVERTED: u32 = 0x150D;
pub const NAND: u32 = 0x150E;
pub const SET: u32 = 0x150F;
pub const EMISSION: u32 = 0x1600;
pub const SHININESS: u32 = 0x1601;
pub const AMBIENT_AND_DIFFUSE: u32 = 0x1602;
pub const COLOR_INDEXES: u32 = 0x1603;
pub const MODELVIEW: u32 = 0x1700;
pub const PROJECTION: u32 = 0x1701;
pub const TEXTURE: u32 = 0x1702;
pub const COLOR: u32 = 0x1800;
pub const DEPTH: u32 = 0x1801;
pub const STENCIL: u32 = 0x1802;
pub const COLOR_INDEX: u32 = 0x1900;
pub const STENCIL_INDEX: u32 = 0x1901;
pub const DEPTH_COMPONENT: u32 = 0x1902;
pub const RED: u32 = 0x1903;
pub const GREEN: u32 = 0x1904;
pub const BLUE: u32 = 0x1905;
pub const ALPHA: u32 = 0x1906;
pub const RGB: u32 = 0x1907;
pub const RGBA: u32 = 0x1908;
pub const LUMINANCE: u32 = 0x1909;
pub const LUMINANCE_ALPHA: u32 = 0x190A;
pub const BITMAP: u32 = 0x1A00;
pub const POINT: u32 = 0x1B00;
pub const LINE: u32 = 0x1B01;
pub const FILL: u32 = 0x1B02;
pub const RENDER: u32 = 0x1C00;
pub const FEEDBACK: u32 = 0x1C01;
pub const SELECT: u32 = 0x1C02;
pub const FLAT: u32 = 0x1D00;
pub const SMOOTH: u32 = 0x1D01;
pub const KEEP: u32 = 0x1E00;
pub const REPLACE: u32 = 0x1E01;
pub const INCR: u32 = 0x1E02;
pub const DECR: u32 = 0x1E03;
pub const VENDOR: u32 = 0x1F00;
pub const RENDERER: u32 = 0x1F01;
pub const VERSION: u32 = 0x1F02;
pub const EXTENSIONS: u32 = 0x1F03;
pub const S: u32 = 0x2000;
pub const ENABLE_BIT: u32 = 0x00002000;
pub const T: u32 = 0x2001;
pub const R: u32 = 0x2002;
pub const Q: u32 = 0x2003;
pub const MODULATE: u32 = 0x2100;
pub const DECAL: u32 = 0x2101;
pub const TEXTURE_ENV_MODE: u32 = 0x2200;
pub const TEXTURE_ENV_COLOR: u32 = 0x2201;
pub const TEXTURE_ENV: u32 = 0x2300;
pub const EYE_LINEAR: u32 = 0x2400;
pub const OBJECT_LINEAR: u32 = 0x2401;
pub const SPHERE_MAP: u32 = 0x2402;
pub const TEXTURE_GEN_MODE: u32 = 0x2500;
pub const OBJECT_PLANE: u32 = 0x2501;
pub const EYE_PLANE: u32 = 0x2502;
pub const NEAREST: u32 = 0x2600;
pub const LINEAR: u32 = 0x2601;
pub const NEAREST_MIPMAP_NEAREST: u32 = 0x2700;
pub const LINEAR_MIPMAP_NEAREST: u32 = 0x2701;
pub const NEAREST_MIPMAP_LINEAR: u32 = 0x2702;
pub const LINEAR_MIPMAP_LINEAR: u32 = 0x2703;
pub const TEXTURE_MAG_FILTER: u32 = 0x2800;
pub const TEXTURE_MIN_FILTER: u32 = 0x2801;
pub const TEXTURE_WRAP_S: u32 = 0x2802;
pub const TEXTURE_WRAP_T: u32 = 0x2803;
pub const CLAMP: u32 = 0x2900;
pub const REPEAT: u32 = 0x2901;
pub const POLYGON_OFFSET_UNITS: u32 = 0x2A00;
pub const POLYGON_OFFSET_POINT: u32 = 0x2A01;
pub const POLYGON_OFFSET_LINE: u32 = 0x2A02;
pub const R3_G3_B2: u32 = 0x2A10;
pub const V2F: u32 = 0x2A20;
pub const V3F: u32 = 0x2A21;
pub const C4UB_V2F: u32 = 0x2A22;
pub const C4UB_V3F: u32 = 0x2A23;
pub const C3F_V3F: u32 = 0x2A24;
pub const N3F_V3F: u32 = 0x2A25;
pub const C4F_N3F_V3F: u32 = 0x2A26;
pub const T2F_V3F: u32 = 0x2A27;
pub const T4F_V4F: u32 = 0x2A28;
pub const T2F_C4UB_V3F: u32 = 0x2A29;
pub const T2F_C3F_V3F: u32 = 0x2A2A;
pub const T2F_N3F_V3F: u32 = 0x2A2B;
pub const T2F_C4F_N3F_V3F: u32 = 0x2A2C;
pub const T4F_C4F_N3F_V4F: u32 = 0x2A2D;
pub const CLIP_PLANE0: u32 = 0x3000;
pub const CLIP_PLANE1: u32 = 0x3001;
pub const CLIP_PLANE2: u32 = 0x3002;
pub const CLIP_PLANE3: u32 = 0x3003;
pub const CLIP_PLANE4: u32 = 0x3004;
pub const CLIP_PLANE5: u32 = 0x3005;
pub const LIGHT0: u32 = 0x4000;
pub const COLOR_BUFFER_BIT: u32 = 0x00004000;
pub const LIGHT1: u32 = 0x4001;
pub const LIGHT2: u32 = 0x4002;
pub const LIGHT3: u32 = 0x4003;
pub const LIGHT4: u32 = 0x4004;
pub const LIGHT5: u32 = 0x4005;
pub const LIGHT6: u32 = 0x4006;
pub const LIGHT7: u32 = 0x4007;
pub const HINT_BIT: u32 = 0x00008000;
pub const POLYGON_OFFSET_FILL: u32 = 0x8037;
pub const POLYGON_OFFSET_FACTOR: u32 = 0x8038;
pub const ALPHA4: u32 = 0x803B;
pub const ALPHA8: u32 = 0x803C;
pub const ALPHA12: u32 = 0x803D;
pub const ALPHA16: u32 = 0x803E;
pub const LUMINANCE4: u32 = 0x803F;
pub const LUMINANCE8: u32 = 0x8040;
pub const LUMINANCE12: u32 = 0x8041;
pub const LUMINANCE16: u32 = 0x8042;
pub const LUMINANCE4_ALPHA4: u32 = 0x8043;
pub const LUMINANCE6_ALPHA2: u32 = 0x8044;
pub const LUMINANCE8_ALPHA8: u32 = 0x8045;
pub const LUMINANCE12_ALPHA4: u32 = 0x8046;
pub const LUMINANCE12_ALPHA12: u32 = 0x8047;
pub const LUMINANCE16_ALPHA16: u32 = 0x8048;
pub const INTENSITY: u32 = 0x8049;
pub const INTENSITY4: u32 = 0x804A;
pub const INTENSITY8: u32 = 0x804B;
pub const INTENSITY12: u32 = 0x804C;
pub const INTENSITY16: u32 = 0x804D;
pub const RGB4: u32 = 0x804F;
pub const RGB5: u32 = 0x8050;
pub const RGB8: u32 = 0x8051;
pub const RGB10: u32 = 0x8052;
pub const RGB12: u32 = 0x8053;
pub const RGB16: u32 = 0x8054;
pub const RGBA2: u32 = 0x8055;
pub const RGBA4: u32 = 0x8056;
pub const RGB5_A1: u32 = 0x8057;
pub const RGBA8: u32 = 0x8058;
pub const RGB10_A2: u32 = 0x8059;
pub const RGBA12: u32 = 0x805A;
pub const RGBA16: u32 = 0x805B;
pub const TEXTURE_RED_SIZE: u32 = 0x805C;
pub const TEXTURE_GREEN_SIZE: u32 = 0x805D;
pub const TEXTURE_BLUE_SIZE: u32 = 0x805E;
pub const TEXTURE_ALPHA_SIZE: u32 = 0x805F;
pub const TEXTURE_LUMINANCE_SIZE: u32 = 0x8060;
pub const TEXTURE_INTENSITY_SIZE: u32 = 0x8061;
pub const PROXY_TEXTURE_1D: u32 = 0x8063;
pub const PROXY_TEXTURE_2D: u32 = 0x8064;
pub const TEXTURE_PRIORITY: u32 = 0x8066;
pub const TEXTURE_RESIDENT: u32 = 0x8067;
pub const TEXTURE_BINDING_1D: u32 = 0x8068;
pub const TEXTURE_BINDING_2D: u32 = 0x8069;
pub const VERTEX_ARRAY: u32 = 0x8074;
pub const NORMAL_ARRAY: u32 = 0x8075;
pub const COLOR_ARRAY: u32 = 0x8076;
pub const INDEX_ARRAY: u32 = 0x8077;
pub const TEXTURE_COORD_ARRAY: u32 = 0x8078;
pub const EDGE_FLAG_ARRAY: u32 = 0x8079;
pub const VERTEX_ARRAY_SIZE: u32 = 0x807A;
pub const VERTEX_ARRAY_TYPE: u32 = 0x807B;
pub const VERTEX_ARRAY_STRIDE: u32 = 0x807C;
pub const NORMAL_ARRAY_TYPE: u32 = 0x807E;
pub const NORMAL_ARRAY_STRIDE: u32 = 0x807F;
pub const COLOR_ARRAY_SIZE: u32 = 0x8081;
pub const COLOR_ARRAY_TYPE: u32 = 0x8082;
pub const COLOR_ARRAY_STRIDE: u32 = 0x8083;
pub const INDEX_ARRAY_TYPE: u32 = 0x8085;
pub const INDEX_ARRAY_STRIDE: u32 = 0x8086;
pub const TEXTURE_COORD_ARRAY_SIZE: u32 = 0x8088;
pub const TEXTURE_COORD_ARRAY_TYPE: u32 = 0x8089;
pub const TEXTURE_COORD_ARRAY_STRIDE: u32 = 0x808A;
pub const EDGE_FLAG_ARRAY_STRIDE: u32 = 0x808C;
pub const VERTEX_ARRAY_POINTER: u32 = 0x808E;
pub const NORMAL_ARRAY_POINTER: u32 = 0x808F;
pub const COLOR_ARRAY_POINTER: u32 = 0x8090;
pub const INDEX_ARRAY_POINTER: u32 = 0x8091;
pub const TEXTURE_COORD_ARRAY_POINTER: u32 = 0x8092;
pub const EDGE_FLAG_ARRAY_POINTER: u32 = 0x8093;
pub const COLOR_INDEX1_EXT: u32 = 0x80E2;
pub const COLOR_INDEX2_EXT: u32 = 0x80E3;
pub const COLOR_INDEX4_EXT: u32 = 0x80E4;
pub const COLOR_INDEX8_EXT: u32 = 0x80E5;
pub const COLOR_INDEX12_EXT: u32 = 0x80E6;
pub const COLOR_INDEX16_EXT: u32 = 0x80E7;
pub const EVAL_BIT: u32 = 0x00010000;
pub const LIST_BIT: u32 = 0x00020000;
pub const TEXTURE_BIT: u32 = 0x00040000;
pub const SCISSOR_BIT: u32 = 0x00080000;
pub const ALL_ATTRIB_BITS: u32 = 0x000fffff;
pub const CLIENT_ALL_ATTRIB_BITS: u32 = 0xffffffff;

// GL 1.2

pub const UNSIGNED_BYTE_3_3_2: u32 = 0x8032;
pub const UNSIGNED_SHORT_4_4_4_4: u32 = 0x8033;
pub const UNSIGNED_SHORT_5_5_5_1: u32 = 0x8034;
pub const UNSIGNED_INT_8_8_8_8: u32 = 0x8035;
pub const UNSIGNED_INT_10_10_10_2: u32 = 0x8036;
pub const TEXTURE_BINDING_3D: u32 = 0x806A;
pub const PACK_SKIP_IMAGES: u32 = 0x806B;
pub const PACK_IMAGE_HEIGHT: u32 = 0x806C;
pub const UNPACK_SKIP_IMAGES: u32 = 0x806D;
pub const UNPACK_IMAGE_HEIGHT: u32 = 0x806E;
pub const TEXTURE_3D: u32 = 0x806F;
pub const PROXY_TEXTURE_3D: u32 = 0x8070;
pub const TEXTURE_DEPTH: u32 = 0x8071;
pub const TEXTURE_WRAP_R: u32 = 0x8072;
pub const MAX_3D_TEXTURE_SIZE: u32 = 0x8073;
pub const UNSIGNED_BYTE_2_3_3_REV: u32 = 0x8362;
pub const UNSIGNED_SHORT_5_6_5: u32 = 0x8363;
pub const UNSIGNED_SHORT_5_6_5_REV: u32 = 0x8364;
pub const UNSIGNED_SHORT_4_4_4_4_REV: u32 = 0x8365;
pub const UNSIGNED_SHORT_1_5_5_5_REV: u32 = 0x8366;
pub const UNSIGNED_INT_8_8_8_8_REV: u32 = 0x8367;
pub const UNSIGNED_INT_2_10_10_10_REV: u32 = 0x8368;
pub const BGR: u32 = 0x80E0;
pub const BGRA: u32 = 0x80E1;
pub const MAX_ELEMENTS_VERTICES: u32 = 0x80E8;
pub const MAX_ELEMENTS_INDICES: u32 = 0x80E9;
pub const CLAMP_TO_EDGE: u32 = 0x812F;
pub const TEXTURE_MIN_LOD: u32 = 0x813A;
pub const TEXTURE_MAX_LOD: u32 = 0x813B;
pub const TEXTURE_BASE_LEVEL: u32 = 0x813C;
pub const TEXTURE_MAX_LEVEL: u32 = 0x813D;
pub const SMOOTH_POINT_SIZE_RANGE: u32 = 0x0B12;
pub const SMOOTH_POINT_SIZE_GRANULARITY: u32 = 0x0B13;
pub const SMOOTH_LINE_WIDTH_RANGE: u32 = 0x0B22;
pub const SMOOTH_LINE_WIDTH_GRANULARITY: u32 = 0x0B23;
pub const ALIASED_LINE_WIDTH_RANGE: u32 = 0x846E;
pub const RESCALE_NORMAL: u32 = 0x803A;
pub const LIGHT_MODEL_COLOR_CONTROL: u32 = 0x81F8;
pub const SINGLE_COLOR: u32 = 0x81F9;
pub const SEPARATE_SPECULAR_COLOR: u32 = 0x81FA;
pub const ALIASED_POINT_SIZE_RANGE: u32 = 0x846D;

// GL 1.3

pub const TEXTURE0: u32 = 0x84C0;
pub const TEXTURE1: u32 = 0x84C1;
pub const TEXTURE2: u32 = 0x84C2;
pub const TEXTURE3: u32 = 0x84C3;
pub const TEXTURE4: u32 = 0x84C4;
pub const TEXTURE5: u32 = 0x84C5;
pub const TEXTURE6: u32 = 0x84C6;
pub const TEXTURE7: u32 = 0x84C7;
pub const TEXTURE8: u32 = 0x84C8;
pub const TEXTURE9: u32 = 0x84C9;
pub const TEXTURE10: u32 = 0x84CA;
pub const TEXTURE11: u32 = 0x84CB;
pub const TEXTURE12: u32 = 0x84CC;
pub const TEXTURE13: u32 = 0x84CD;
pub const TEXTURE14: u32 = 0x84CE;
pub const TEXTURE15: u32 = 0x84CF;
pub const TEXTURE16: u32 = 0x84D0;
pub const TEXTURE17: u32 = 0x84D1;
pub const TEXTURE18: u32 = 0x84D2;
pub const TEXTURE19: u32 = 0x84D3;
pub const TEXTURE20: u32 = 0x84D4;
pub const TEXTURE21: u32 = 0x84D5;
pub const TEXTURE22: u32 = 0x84D6;
pub const TEXTURE23: u32 = 0x84D7;
pub const TEXTURE24: u32 = 0x84D8;
pub const TEXTURE25: u32 = 0x84D9;
pub const TEXTURE26: u32 = 0x84DA;
pub const TEXTURE27: u32 = 0x84DB;
pub const TEXTURE28: u32 = 0x84DC;
pub const TEXTURE29: u32 = 0x84DD;
pub const TEXTURE30: u32 = 0x84DE;
pub const TEXTURE31: u32 = 0x84DF;
pub const ACTIVE_TEXTURE: u32 = 0x84E0;
pub const MULTISAMPLE: u32 = 0x809D;
pub const SAMPLE_ALPHA_TO_COVERAGE: u32 = 0x809E;
pub const SAMPLE_ALPHA_TO_ONE: u32 = 0x809F;
pub const SAMPLE_COVERAGE: u32 = 0x80A0;
pub const SAMPLE_BUFFERS: u32 = 0x80A8;
pub const SAMPLES: u32 = 0x80A9;
pub const SAMPLE_COVERAGE_VALUE: u32 = 0x80AA;
pub const SAMPLE_COVERAGE_INVERT: u32 = 0x80AB;
pub const TEXTURE_CUBE_MAP: u32 = 0x8513;
pub const TEXTURE_BINDING_CUBE_MAP: u32 = 0x8514;
pub const TEXTURE_CUBE_MAP_POSITIVE_X: u32 = 0x8515;
pub const TEXTURE_CUBE_MAP_NEGATIVE_X: u32 = 0x8516;
pub const TEXTURE_CUBE_MAP_POSITIVE_Y: u32 = 0x8517;
pub const TEXTURE_CUBE_MAP_NEGATIVE_Y: u32 = 0x8518;
pub const TEXTURE_CUBE_MAP_POSITIVE_Z: u32 = 0x8519;
pub const TEXTURE_CUBE_MAP_NEGATIVE_Z: u32 = 0x851A;
pub const PROXY_TEXTURE_CUBE_MAP: u32 = 0x851B;
pub const MAX_CUBE_MAP_TEXTURE_SIZE: u32 = 0x851C;
pub const COMPRESSED_RGB: u32 = 0x84ED;
pub const COMPRESSED_RGBA: u32 = 0x84EE;
pub const TEXTURE_COMPRESSION_HINT: u32 = 0x84EF;
pub const TEXTURE_COMPRESSED_IMAGE_SIZE: u32 = 0x86A0;
pub const TEXTURE_COMPRESSED: u32 = 0x86A1;
pub const NUM_COMPRESSED_TEXTURE_FORMATS: u32 = 0x86A2;
pub const COMPRESSED_TEXTURE_FORMATS: u32 = 0x86A3;
pub const CLAMP_TO_BORDER: u32 = 0x812D;
pub const CLIENT_ACTIVE_TEXTURE: u32 = 0x84E1;
pub const MAX_TEXTURE_UNITS: u32 = 0x84E2;
pub const TRANSPOSE_MODELVIEW_MATRIX: u32 = 0x84E3;
pub const TRANSPOSE_PROJECTION_MATRIX: u32 = 0x84E4;
pub const TRANSPOSE_TEXTURE_MATRIX: u32 = 0x84E5;
pub const TRANSPOSE_COLOR_MATRIX: u32 = 0x84E6;
pub const MULTISAMPLE_BIT: u32 = 0x20000000;
pub const NORMAL_MAP: u32 = 0x8511;
pub const REFLECTION_MAP: u32 = 0x8512;
pub const COMPRESSED_ALPHA: u32 = 0x84E9;
pub const COMPRESSED_LUMINANCE: u32 = 0x84EA;
pub const COMPRESSED_LUMINANCE_ALPHA: u32 = 0x84EB;
pub const COMPRESSED_INTENSITY: u32 = 0x84EC;
pub const COMBINE: u32 = 0x8570;
pub const COMBINE_RGB: u32 = 0x8571;
pub const COMBINE_ALPHA: u32 = 0x8572;
pub const SOURCE0_RGB: u32 = 0x8580;
pub const SOURCE1_RGB: u32 = 0x8581;
pub const SOURCE2_RGB: u32 = 0x8582;
pub const SOURCE0_ALPHA: u32 = 0x8588;
pub const SOURCE1_ALPHA: u32 = 0x8589;
pub const SOURCE2_ALPHA: u32 = 0x858A;
pub const OPERAND0_RGB: u32 = 0x8590;
pub const OPERAND1_RGB: u32 = 0x8591;
pub const OPERAND2_RGB: u32 = 0x8592;
pub const OPERAND0_ALPHA: u32 = 0x8598;
pub const OPERAND1_ALPHA: u32 = 0x8599;
pub const OPERAND2_ALPHA: u32 = 0x859A;
pub const RGB_SCALE: u32 = 0x8573;
pub const ADD_SIGNED: u32 = 0x8574;
pub const INTERPOLATE: u32 = 0x8575;
pub const SUBTRACT: u32 = 0x84E7;
pub const CONSTANT: u32 = 0x8576;
pub const PRIMARY_COLOR: u32 = 0x8577;
pub const PREVIOUS: u32 = 0x8578;
pub const DOT3_RGB: u32 = 0x86AE;
pub const DOT3_RGBA: u32 = 0x86AF;

// GL 1.4

pub const BLEND_DST_RGB: u32 = 0x80C8;
pub const BLEND_SRC_RGB: u32 = 0x80C9;
pub const BLEND_DST_ALPHA: u32 = 0x80CA;
pub const BLEND_SRC_ALPHA: u32 = 0x80CB;
pub const POINT_FADE_THRESHOLD_SIZE: u32 = 0x8128;
pub const DEPTH_COMPONENT16: u32 = 0x81A5;
pub const DEPTH_COMPONENT24: u32 = 0x81A6;
pub const DEPTH_COMPONENT32: u32 = 0x81A7;
pub const MIRRORED_REPEAT: u32 = 0x8370;
pub const MAX_TEXTURE_LOD_BIAS: u32 = 0x84FD;
pub const TEXTURE_LOD_BIAS: u32 = 0x8501;
pub const INCR_WRAP: u32 = 0x8507;
pub const DECR_WRAP: u32 = 0x8508;
pub const TEXTURE_DEPTH_SIZE: u32 = 0x884A;
pub const TEXTURE_COMPARE_MODE: u32 = 0x884C;
pub const TEXTURE_COMPARE_FUNC: u32 = 0x884D;
pub const POINT_SIZE_MIN: u32 = 0x8126;
pub const POINT_SIZE_MAX: u32 = 0x8127;
pub const POINT_DISTANCE_ATTENUATION: u32 = 0x8129;
pub const GENERATE_MIPMAP: u32 = 0x8191;
pub const GENERATE_MIPMAP_HINT: u32 = 0x8192;
pub const FOG_COORDINATE_SOURCE: u32 = 0x8450;
pub const FOG_COORDINATE: u32 = 0x8451;
pub const FRAGMENT_DEPTH: u32 = 0x8452;
pub const CURRENT_FOG_COORDINATE: u32 = 0x8453;
pub const FOG_COORDINATE_ARRAY_TYPE: u32 = 0x8454;
pub const FOG_COORDINATE_ARRAY_STRIDE: u32 = 0x8455;
pub const FOG_COORDINATE_ARRAY_POINTER: u32 = 0x8456;
pub const FOG_COORDINATE_ARRAY: u32 = 0x8457;
pub const COLOR_SUM: u32 = 0x8458;
pub const CURRENT_SECONDARY_COLOR: u32 = 0x8459;
pub const SECONDARY_COLOR_ARRAY_SIZE: u32 = 0x845A;
pub const SECONDARY_COLOR_ARRAY_TYPE: u32 = 0x845B;
pub const SECONDARY_COLOR_ARRAY_STRIDE: u32 = 0x845C;
pub const SECONDARY_COLOR_ARRAY_POINTER: u32 = 0x845D;
pub const SECONDARY_COLOR_ARRAY: u32 = 0x845E;
pub const TEXTURE_FILTER_CONTROL: u32 = 0x8500;
pub const DEPTH_TEXTURE_MODE: u32 = 0x884B;
pub const COMPARE_R_TO_TEXTURE: u32 = 0x884E;
pub const BLEND_COLOR: u32 = 0x8005;
pub const BLEND_EQUATION: u32 = 0x8009;
pub const CONSTANT_COLOR: u32 = 0x8001;
pub const ONE_MINUS_CONSTANT_COLOR: u32 = 0x8002;
pub const CONSTANT_ALPHA: u32 = 0x8003;
pub const ONE_MINUS_CONSTANT_ALPHA: u32 = 0x8004;
pub const FUNC_ADD: u32 = 0x8006;
pub const FUNC_REVERSE_SUBTRACT: u32 = 0x800B;
pub const FUNC_SUBTRACT: u32 = 0x800A;
pub const MIN: u32 = 0x8007;
pub const MAX: u32 = 0x8008;

// GL 1.5
pub const BUFFER_SIZE: u32 = 0x8764;
pub const BUFFER_USAGE: u32 = 0x8765;
pub const QUERY_COUNTER_BITS: u32 = 0x8864;
pub const CURRENT_QUERY: u32 = 0x8865;
pub const QUERY_RESULT: u32 = 0x8866;
pub const QUERY_RESULT_AVAILABLE: u32 = 0x8867;
pub const ARRAY_BUFFER: u32 = 0x8892;
pub const ELEMENT_ARRAY_BUFFER: u32 = 0x8893;
pub const ARRAY_BUFFER_BINDING: u32 = 0x8894;
pub const ELEMENT_ARRAY_BUFFER_BINDING: u32 = 0x8895;
pub const VERTEX_ATTRIB_ARRAY_BUFFER_BINDING: u32 = 0x889F;
pub const READ_ONLY: u32 = 0x88B8;
pub const WRITE_ONLY: u32 = 0x88B9;
pub const READ_WRITE: u32 = 0x88BA;
pub const BUFFER_ACCESS: u32 = 0x88BB;
pub const BUFFER_MAPPED: u32 = 0x88BC;
pub const BUFFER_MAP_POINTER: u32 = 0x88BD;
pub const STREAM_DRAW: u32 = 0x88E0;
pub const STREAM_READ: u32 = 0x88E1;
pub const STREAM_COPY: u32 = 0x88E2;
pub const STATIC_DRAW: u32 = 0x88E4;
pub const STATIC_READ: u32 = 0x88E5;
pub const STATIC_COPY: u32 = 0x88E6;
pub const DYNAMIC_DRAW: u32 = 0x88E8;
pub const DYNAMIC_READ: u32 = 0x88E9;
pub const DYNAMIC_COPY: u32 = 0x88EA;
pub const SAMPLES_PASSED: u32 = 0x8914;
pub const SRC1_ALPHA: u32 = 0x8589;
pub const VERTEX_ARRAY_BUFFER_BINDING: u32 = 0x8896;
pub const NORMAL_ARRAY_BUFFER_BINDING: u32 = 0x8897;
pub const COLOR_ARRAY_BUFFER_BINDING: u32 = 0x8898;
pub const INDEX_ARRAY_BUFFER_BINDING: u32 = 0x8899;
pub const TEXTURE_COORD_ARRAY_BUFFER_BINDING: u32 = 0x889A;
pub const EDGE_FLAG_ARRAY_BUFFER_BINDING: u32 = 0x889B;
pub const SECONDARY_COLOR_ARRAY_BUFFER_BINDING: u32 = 0x889C;
pub const FOG_COORDINATE_ARRAY_BUFFER_BINDING: u32 = 0x889D;
pub const WEIGHT_ARRAY_BUFFER_BINDING: u32 = 0x889E;
pub const FOG_COORD_SRC: u32 = 0x8450;
pub const FOG_COORD: u32 = 0x8451;
pub const CURRENT_FOG_COORD: u32 = 0x8453;
pub const FOG_COORD_ARRAY_TYPE: u32 = 0x8454;
pub const FOG_COORD_ARRAY_STRIDE: u32 = 0x8455;
pub const FOG_COORD_ARRAY_POINTER: u32 = 0x8456;
pub const FOG_COORD_ARRAY: u32 = 0x8457;
pub const FOG_COORD_ARRAY_BUFFER_BINDING: u32 = 0x889D;
pub const SRC0_RGB: u32 = 0x8580;
pub const SRC1_RGB: u32 = 0x8581;
pub const SRC2_RGB: u32 = 0x8582;
pub const SRC0_ALPHA: u32 = 0x8588;
pub const SRC2_ALPHA: u32 = 0x858A;

// GL 2.0

pub const BLEND_EQUATION_RGB: u32 = 0x8009;
pub const VERTEX_ATTRIB_ARRAY_ENABLED: u32 = 0x8622;
pub const VERTEX_ATTRIB_ARRAY_SIZE: u32 = 0x8623;
pub const VERTEX_ATTRIB_ARRAY_STRIDE: u32 = 0x8624;
pub const VERTEX_ATTRIB_ARRAY_TYPE: u32 = 0x8625;
pub const CURRENT_VERTEX_ATTRIB: u32 = 0x8626;
pub const VERTEX_PROGRAM_POINT_SIZE: u32 = 0x8642;
pub const VERTEX_ATTRIB_ARRAY_POINTER: u32 = 0x8645;
pub const STENCIL_BACK_FUNC: u32 = 0x8800;
pub const STENCIL_BACK_FAIL: u32 = 0x8801;
pub const STENCIL_BACK_PASS_DEPTH_FAIL: u32 = 0x8802;
pub const STENCIL_BACK_PASS_DEPTH_PASS: u32 = 0x8803;
pub const MAX_DRAW_BUFFERS: u32 = 0x8824;
pub const DRAW_BUFFER0: u32 = 0x8825;
pub const DRAW_BUFFER1: u32 = 0x8826;
pub const DRAW_BUFFER2: u32 = 0x8827;
pub const DRAW_BUFFER3: u32 = 0x8828;
pub const DRAW_BUFFER4: u32 = 0x8829;
pub const DRAW_BUFFER5: u32 = 0x882A;
pub const DRAW_BUFFER6: u32 = 0x882B;
pub const DRAW_BUFFER7: u32 = 0x882C;
pub const DRAW_BUFFER8: u32 = 0x882D;
pub const DRAW_BUFFER9: u32 = 0x882E;
pub const DRAW_BUFFER10: u32 = 0x882F;
pub const DRAW_BUFFER11: u32 = 0x8830;
pub const DRAW_BUFFER12: u32 = 0x8831;
pub const DRAW_BUFFER13: u32 = 0x8832;
pub const DRAW_BUFFER14: u32 = 0x8833;
pub const DRAW_BUFFER15: u32 = 0x8834;
pub const BLEND_EQUATION_ALPHA: u32 = 0x883D;
pub const MAX_VERTEX_ATTRIBS: u32 = 0x8869;
pub const VERTEX_ATTRIB_ARRAY_NORMALIZED: u32 = 0x886A;
pub const MAX_TEXTURE_IMAGE_UNITS: u32 = 0x8872;
pub const FRAGMENT_SHADER: u32 = 0x8B30;
pub const VERTEX_SHADER: u32 = 0x8B31;
pub const MAX_FRAGMENT_UNIFORM_COMPONENTS: u32 = 0x8B49;
pub const MAX_VERTEX_UNIFORM_COMPONENTS: u32 = 0x8B4A;
pub const MAX_VARYING_FLOATS: u32 = 0x8B4B;
pub const MAX_VERTEX_TEXTURE_IMAGE_UNITS: u32 = 0x8B4C;
pub const MAX_COMBINED_TEXTURE_IMAGE_UNITS: u32 = 0x8B4D;
pub const SHADER_TYPE: u32 = 0x8B4F;
pub const FLOAT_VEC2: u32 = 0x8B50;
pub const FLOAT_VEC3: u32 = 0x8B51;
pub const FLOAT_VEC4: u32 = 0x8B52;
pub const INT_VEC2: u32 = 0x8B53;
pub const INT_VEC3: u32 = 0x8B54;
pub const INT_VEC4: u32 = 0x8B55;
pub const BOOL: u32 = 0x8B56;
pub const BOOL_VEC2: u32 = 0x8B57;
pub const BOOL_VEC3: u32 = 0x8B58;
pub const BOOL_VEC4: u32 = 0x8B59;
pub const FLOAT_MAT2: u32 = 0x8B5A;
pub const FLOAT_MAT3: u32 = 0x8B5B;
pub const FLOAT_MAT4: u32 = 0x8B5C;
pub const SAMPLER_1D: u32 = 0x8B5D;
pub const SAMPLER_2D: u32 = 0x8B5E;
pub const SAMPLER_3D: u32 = 0x8B5F;
pub const SAMPLER_CUBE: u32 = 0x8B60;
pub const SAMPLER_1D_SHADOW: u32 = 0x8B61;
pub const SAMPLER_2D_SHADOW: u32 = 0x8B62;
pub const DELETE_STATUS: u32 = 0x8B80;
pub const COMPILE_STATUS: u32 = 0x8B81;
pub const LINK_STATUS: u32 = 0x8B82;
pub const VALIDATE_STATUS: u32 = 0x8B83;
pub const INFO_LOG_LENGTH: u32 = 0x8B84;
pub const ATTACHED_SHADERS: u32 = 0x8B85;
pub const ACTIVE_UNIFORMS: u32 = 0x8B86;
pub const ACTIVE_UNIFORM_MAX_LENGTH: u32 = 0x8B87;
pub const SHADER_SOURCE_LENGTH: u32 = 0x8B88;
pub const ACTIVE_ATTRIBUTES: u32 = 0x8B89;
pub const ACTIVE_ATTRIBUTE_MAX_LENGTH: u32 = 0x8B8A;
pub const FRAGMENT_SHADER_DERIVATIVE_HINT: u32 = 0x8B8B;
pub const SHADING_LANGUAGE_VERSION: u32 = 0x8B8C;
pub const CURRENT_PROGRAM: u32 = 0x8B8D;
pub const POINT_SPRITE_COORD_ORIGIN: u32 = 0x8CA0;
pub const LOWER_LEFT: u32 = 0x8CA1;
pub const UPPER_LEFT: u32 = 0x8CA2;
pub const STENCIL_BACK_REF: u32 = 0x8CA3;
pub const STENCIL_BACK_VALUE_MASK: u32 = 0x8CA4;
pub const STENCIL_BACK_WRITEMASK: u32 = 0x8CA5;
pub const VERTEX_PROGRAM_TWO_SIDE: u32 = 0x8643;
pub const POINT_SPRITE: u32 = 0x8861;
pub const COORD_REPLACE: u32 = 0x8862;
pub const MAX_TEXTURE_COORDS: u32 = 0x8871;

// GL 2.0

pub const PIXEL_PACK_BUFFER: u32 = 0x88EB;
pub const PIXEL_UNPACK_BUFFER: u32 = 0x88EC;
pub const PIXEL_PACK_BUFFER_BINDING: u32 = 0x88ED;
pub const PIXEL_UNPACK_BUFFER_BINDING: u32 = 0x88EF;
pub const FLOAT_MAT2x3: u32 = 0x8B65;
pub const FLOAT_MAT2x4: u32 = 0x8B66;
pub const FLOAT_MAT3x2: u32 = 0x8B67;
pub const FLOAT_MAT3x4: u32 = 0x8B68;
pub const FLOAT_MAT4x2: u32 = 0x8B69;
pub const FLOAT_MAT4x3: u32 = 0x8B6A;
pub const SRGB: u32 = 0x8C40;
pub const SRGB8: u32 = 0x8C41;
pub const SRGB_ALPHA: u32 = 0x8C42;
pub const SRGB8_ALPHA8: u32 = 0x8C43;
pub const COMPRESSED_SRGB: u32 = 0x8C48;
pub const COMPRESSED_SRGB_ALPHA: u32 = 0x8C49;
pub const CURRENT_RASTER_SECONDARY_COLOR: u32 = 0x845F;
pub const SLUMINANCE_ALPHA: u32 = 0x8C44;
pub const SLUMINANCE8_ALPHA8: u32 = 0x8C45;
pub const SLUMINANCE: u32 = 0x8C46;
pub const SLUMINANCE8: u32 = 0x8C47;
pub const COMPRESSED_SLUMINANCE: u32 = 0x8C4A;
pub const COMPRESSED_SLUMINANCE_ALPHA: u32 = 0x8C4B;

// GL 3.0

pub const CLIP_DISTANCE0: u32 = CLIP_PLANE0;
pub const CLIP_DISTANCE1: u32 = CLIP_PLANE1;
pub const CLIP_DISTANCE2: u32 = CLIP_PLANE2;
pub const CLIP_DISTANCE3: u32 = CLIP_PLANE3;
pub const CLIP_DISTANCE4: u32 = CLIP_PLANE4;
pub const CLIP_DISTANCE5: u32 = CLIP_PLANE5;
pub const COMPARE_REF_TO_TEXTURE: u32 = 0x884E;
pub const MAX_CLIP_DISTANCES: u32 = MAX_CLIP_PLANES;
pub const MAX_VARYING_COMPONENTS: u32 = MAX_VARYING_FLOATS;
pub const CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT: u32 = 0x0001;
pub const MAJOR_VERSION: u32 = 0x821B;
pub const MINOR_VERSION: u32 = 0x821C;
pub const NUM_EXTENSIONS: u32 = 0x821D;
pub const CONTEXT_FLAGS: u32 = 0x821E;
pub const DEPTH_BUFFER: u32 = 0x8223;
pub const STENCIL_BUFFER: u32 = 0x8224;
pub const RGBA32F: u32 = 0x8814;
pub const RGB32F: u32 = 0x8815;
pub const RGBA16F: u32 = 0x881A;
pub const RGB16F: u32 = 0x881B;
pub const VERTEX_ATTRIB_ARRAY_INTEGER: u32 = 0x88FD;
pub const MAX_ARRAY_TEXTURE_LAYERS: u32 = 0x88FF;
pub const MIN_PROGRAM_TEXEL_OFFSET: u32 = 0x8904;
pub const MAX_PROGRAM_TEXEL_OFFSET: u32 = 0x8905;
pub const CLAMP_VERTEX_COLOR: u32 = 0x891A;
pub const CLAMP_FRAGMENT_COLOR: u32 = 0x891B;
pub const CLAMP_READ_COLOR: u32 = 0x891C;
pub const FIXED_ONLY: u32 = 0x891D;
pub const TEXTURE_RED_TYPE: u32 = 0x8C10;
pub const TEXTURE_GREEN_TYPE: u32 = 0x8C11;
pub const TEXTURE_BLUE_TYPE: u32 = 0x8C12;
pub const TEXTURE_ALPHA_TYPE: u32 = 0x8C13;
pub const TEXTURE_LUMINANCE_TYPE: u32 = 0x8C14;
pub const TEXTURE_INTENSITY_TYPE: u32 = 0x8C15;
pub const TEXTURE_DEPTH_TYPE: u32 = 0x8C16;
pub const TEXTURE_1D_ARRAY: u32 = 0x8C18;
pub const PROXY_TEXTURE_1D_ARRAY: u32 = 0x8C19;
pub const TEXTURE_2D_ARRAY: u32 = 0x8C1A;
pub const PROXY_TEXTURE_2D_ARRAY: u32 = 0x8C1B;
pub const TEXTURE_BINDING_1D_ARRAY: u32 = 0x8C1C;
pub const TEXTURE_BINDING_2D_ARRAY: u32 = 0x8C1D;
pub const R11F_G11F_B10F: u32 = 0x8C3A;
pub const UNSIGNED_INT_10F_11F_11F_REV: u32 = 0x8C3B;
pub const RGB9_E5: u32 = 0x8C3D;
pub const UNSIGNED_INT_5_9_9_9_REV: u32 = 0x8C3E;
pub const TEXTURE_SHARED_SIZE: u32 = 0x8C3F;
pub const TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH: u32 = 0x8C76;
pub const TRANSFORM_FEEDBACK_BUFFER_MODE: u32 = 0x8C7F;
pub const MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS: u32 = 0x8C80;
pub const TRANSFORM_FEEDBACK_VARYINGS: u32 = 0x8C83;
pub const TRANSFORM_FEEDBACK_BUFFER_START: u32 = 0x8C84;
pub const TRANSFORM_FEEDBACK_BUFFER_SIZE: u32 = 0x8C85;
pub const PRIMITIVES_GENERATED: u32 = 0x8C87;
pub const TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN: u32 = 0x8C88;
pub const RASTERIZER_DISCARD: u32 = 0x8C89;
pub const MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS: u32 = 0x8C8A;
pub const MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS: u32 = 0x8C8B;
pub const INTERLEAVED_ATTRIBS: u32 = 0x8C8C;
pub const SEPARATE_ATTRIBS: u32 = 0x8C8D;
pub const TRANSFORM_FEEDBACK_BUFFER: u32 = 0x8C8E;
pub const TRANSFORM_FEEDBACK_BUFFER_BINDING: u32 = 0x8C8F;
pub const RGBA32UI: u32 = 0x8D70;
pub const RGB32UI: u32 = 0x8D71;
pub const RGBA16UI: u32 = 0x8D76;
pub const RGB16UI: u32 = 0x8D77;
pub const RGBA8UI: u32 = 0x8D7C;
pub const RGB8UI: u32 = 0x8D7D;
pub const RGBA32I: u32 = 0x8D82;
pub const RGB32I: u32 = 0x8D83;
pub const RGBA16I: u32 = 0x8D88;
pub const RGB16I: u32 = 0x8D89;
pub const RGBA8I: u32 = 0x8D8E;
pub const RGB8I: u32 = 0x8D8F;
pub const RED_INTEGER: u32 = 0x8D94;
pub const GREEN_INTEGER: u32 = 0x8D95;
pub const BLUE_INTEGER: u32 = 0x8D96;
pub const ALPHA_INTEGER: u32 = 0x8D97;
pub const RGB_INTEGER: u32 = 0x8D98;
pub const RGBA_INTEGER: u32 = 0x8D99;
pub const BGR_INTEGER: u32 = 0x8D9A;
pub const BGRA_INTEGER: u32 = 0x8D9B;
pub const SAMPLER_1D_ARRAY: u32 = 0x8DC0;
pub const SAMPLER_2D_ARRAY: u32 = 0x8DC1;
pub const SAMPLER_1D_ARRAY_SHADOW: u32 = 0x8DC3;
pub const SAMPLER_2D_ARRAY_SHADOW: u32 = 0x8DC4;
pub const SAMPLER_CUBE_SHADOW: u32 = 0x8DC5;
pub const UNSIGNED_INT_VEC2: u32 = 0x8DC6;
pub const UNSIGNED_INT_VEC3: u32 = 0x8DC7;
pub const UNSIGNED_INT_VEC4: u32 = 0x8DC8;
pub const INT_SAMPLER_1D: u32 = 0x8DC9;
pub const INT_SAMPLER_2D: u32 = 0x8DCA;
pub const INT_SAMPLER_3D: u32 = 0x8DCB;
pub const INT_SAMPLER_CUBE: u32 = 0x8DCC;
pub const INT_SAMPLER_1D_ARRAY: u32 = 0x8DCE;
pub const INT_SAMPLER_2D_ARRAY: u32 = 0x8DCF;
pub const UNSIGNED_INT_SAMPLER_1D: u32 = 0x8DD1;
pub const UNSIGNED_INT_SAMPLER_2D: u32 = 0x8DD2;
pub const UNSIGNED_INT_SAMPLER_3D: u32 = 0x8DD3;
pub const UNSIGNED_INT_SAMPLER_CUBE: u32 = 0x8DD4;
pub const UNSIGNED_INT_SAMPLER_1D_ARRAY: u32 = 0x8DD6;
pub const UNSIGNED_INT_SAMPLER_2D_ARRAY: u32 = 0x8DD7;
pub const QUERY_WAIT: u32 = 0x8E13;
pub const QUERY_NO_WAIT: u32 = 0x8E14;
pub const QUERY_BY_REGION_WAIT: u32 = 0x8E15;
pub const QUERY_BY_REGION_NO_WAIT: u32 = 0x8E16;

// GL 3.3
pub const VERTEX_ATTRIB_ARRAY_DIVISOR: u32 = 0x88FE;

// ARB_multitexture
pub const TEXTURE0_ARB: u32 = 0x000084C0;
pub const TEXTURE1_ARB: u32 = 0x000084C1;
pub const TEXTURE2_ARB: u32 = 0x000084C2;
pub const TEXTURE3_ARB: u32 = 0x000084C3;
pub const TEXTURE4_ARB: u32 = 0x000084C4;
pub const TEXTURE5_ARB: u32 = 0x000084C5;
pub const TEXTURE6_ARB: u32 = 0x000084C6;
pub const TEXTURE7_ARB: u32 = 0x000084C7;
pub const TEXTURE8_ARB: u32 = 0x000084C8;
pub const TEXTURE9_ARB: u32 = 0x000084C9;
pub const TEXTURE10_ARB: u32 = 0x000084CA;
pub const TEXTURE11_ARB: u32 = 0x000084CB;
pub const TEXTURE12_ARB: u32 = 0x000084CC;
pub const TEXTURE13_ARB: u32 = 0x000084CD;
pub const TEXTURE14_ARB: u32 = 0x000084CE;
pub const TEXTURE15_ARB: u32 = 0x000084CF;
pub const TEXTURE16_ARB: u32 = 0x000084D0;
pub const TEXTURE17_ARB: u32 = 0x000084D1;
pub const TEXTURE18_ARB: u32 = 0x000084D2;
pub const TEXTURE19_ARB: u32 = 0x000084D3;
pub const TEXTURE20_ARB: u32 = 0x000084D4;
pub const TEXTURE21_ARB: u32 = 0x000084D5;
pub const TEXTURE22_ARB: u32 = 0x000084D6;
pub const TEXTURE23_ARB: u32 = 0x000084D7;
pub const TEXTURE24_ARB: u32 = 0x000084D8;
pub const TEXTURE25_ARB: u32 = 0x000084D9;
pub const TEXTURE26_ARB: u32 = 0x000084DA;
pub const TEXTURE27_ARB: u32 = 0x000084DB;
pub const TEXTURE28_ARB: u32 = 0x000084DC;
pub const TEXTURE29_ARB: u32 = 0x000084DD;
pub const TEXTURE30_ARB: u32 = 0x000084DE;
pub const TEXTURE31_ARB: u32 = 0x000084DF;
pub const ACTIVE_TEXTURE_ARB: u32 = 0x000084E0;
pub const CLIENT_ACTIVE_TEXTURE_ARB: u32 = 0x000084E1;
pub const MAX_TEXTURE_UNITS_ARB: u32 = 0x000084E2;

pub const COMBINE_EXT: u32 = 0x00008570;
pub const COMBINE_RGB_EXT: u32 = 0x00008571;
pub const COMBINE_ALPHA_EXT: u32 = 0x00008572;
pub const RGB_SCALE_EXT: u32 = 0x00008573;
pub const ADD_SIGNED_EXT: u32 = 0x00008574;
pub const INTERPOLATE_EXT: u32 = 0x00008575;
pub const CONSTANT_EXT: u32 = 0x00008576;
pub const PRIMARY_COLOR_EXT: u32 = 0x00008577;
pub const PREVIOUS_EXT: u32 = 0x00008578;
pub const SOURCE0_RGB_EXT: u32 = 0x00008580;
pub const SOURCE1_RGB_EXT: u32 = 0x00008581;
pub const SOURCE2_RGB_EXT: u32 = 0x00008582;
pub const SOURCE0_ALPHA_EXT: u32 = 0x00008588;
pub const SOURCE1_ALPHA_EXT: u32 = 0x00008589;
pub const SOURCE2_ALPHA_EXT: u32 = 0x0000858A;
pub const OPERAND0_RGB_EXT: u32 = 0x00008590;
pub const OPERAND1_RGB_EXT: u32 = 0x00008591;
pub const OPERAND2_RGB_EXT: u32 = 0x00008592;
pub const OPERAND0_ALPHA_EXT: u32 = 0x00008598;
pub const OPERAND1_ALPHA_EXT: u32 = 0x00008599;
pub const OPERAND2_ALPHA_EXT: u32 = 0x0000859A;

pub const FOG_COORDINATE_SOURCE_EXT: u32 = 0x00008450;
pub const FOG_COORDINATE_EXT: u32 = 0x00008451;
pub const FRAGMENT_DEPTH_EXT: u32 = 0x00008452;
pub const CURRENT_FOG_COORDINATE_EXT: u32 = 0x00008453;
pub const FOG_COORDINATE_ARRAY_TYPE_EXT: u32 = 0x00008454;
pub const FOG_COORDINATE_ARRAY_STRIDE_EXT: u32 = 0x00008455;
pub const FOG_COORDINATE_ARRAY_POINTER_EXT: u32 = 0x00008456;
pub const FOG_COORDINATE_ARRAY_EXT: u32 = 0x00008457;

// Texture compression internal formats (ARB_texture_compression / S3TC).
pub const COMPRESSED_ALPHA_ARB: u32 = 0x000084E9;
pub const COMPRESSED_LUMINANCE_ARB: u32 = 0x000084EA;
pub const COMPRESSED_LUMINANCE_ALPHA_ARB: u32 = 0x000084EB;
pub const COMPRESSED_INTENSITY_ARB: u32 = 0x000084EC;
pub const COMPRESSED_RGB_ARB: u32 = 0x000084ED;
pub const COMPRESSED_RGBA_ARB: u32 = 0x000084EE;
pub const COMPRESSED_RGB_S3TC_DXT1_EXT: u32 = 0x000083F0;
pub const COMPRESSED_RGBA_S3TC_DXT1_EXT: u32 = 0x000083F1;
pub const COMPRESSED_RGBA_S3TC_DXT3_EXT: u32 = 0x000083F2;
pub const COMPRESSED_RGBA_S3TC_DXT5_EXT: u32 = 0x000083F3;

// GL_ARB_vertex_array_object
pub const VERTEX_ARRAY_BINDING: u32 = 0x85B5;

// GL_EXT_texture_swizzle
pub const TEXTURE_SWIZZLE_R_EXT = 0x8E42;
pub const TEXTURE_SWIZZLE_G_EXT = 0x8E43;
pub const TEXTURE_SWIZZLE_B_EXT = 0x8E44;
pub const TEXTURE_SWIZZLE_A_EXT = 0x8E45;
pub const TEXTURE_SWIZZLE_RGBA_EXT = 0x8E46;

// GL_ARB_texture_rg
pub const COMPRESSED_RED: u32 = 0x8225;
pub const COMPRESSED_RG: u32 = 0x8226;
pub const RG: u32 = 0x8227;
pub const RG_INTEGER: u32 = 0x8228;
pub const R8: u32 = 0x8229;
pub const R16: u32 = 0x822A;
pub const RG8: u32 = 0x822B;
pub const RG16: u32 = 0x822C;
pub const R16F: u32 = 0x822D;
pub const R32F: u32 = 0x822E;
pub const RG16F: u32 = 0x822F;
pub const RG32F: u32 = 0x8230;
pub const R8I: u32 = 0x8231;
pub const R8UI: u32 = 0x8232;
pub const R16I: u32 = 0x8233;
pub const R16UI: u32 = 0x8234;
pub const R32I: u32 = 0x8235;
pub const R32UI: u32 = 0x8236;
pub const RG8I: u32 = 0x8237;
pub const RG8UI: u32 = 0x8238;
pub const RG16I: u32 = 0x8239;
pub const RG16UI: u32 = 0x823A;
pub const RG32I: u32 = 0x823B;
pub const RG32UI: u32 = 0x823C;

// All the functions
pub fn GetError() callconv(.winapi) u32 {
    return @backingInt(g_error_handler.get());
}

// Begin/end and vertex specification
pub fn Begin(mode: u32) callconv(.winapi) void {
    state_mod.beginCommand(mode);
}
pub fn End() callconv(.winapi) void {
    state_mod.endCommand();
}
pub fn Vertex2f(x: GLfloat, y: GLfloat) callconv(.winapi) void {
    state_mod.vertex2f(x, y);
}
pub fn Vertex3f(x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state_mod.vertex3f(x, y, z);
}
pub fn Vertex4f(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) callconv(.winapi) void {
    state_mod.vertex4f(x, y, z, w);
}
pub fn Vertex2i(x: GLint, y: GLint) callconv(.winapi) void {
    state_mod.vertex2i(x, y);
}
pub fn Vertex3i(x: GLint, y: GLint, z: GLint) callconv(.winapi) void {
    state_mod.vertex3i(x, y, z);
}
pub fn Vertex4i(x: GLint, y: GLint, z: GLint, w: GLint) callconv(.winapi) void {
    state_mod.vertex4i(x, y, z, w);
}
pub fn Vertex2s(x: GLshort, y: GLshort) callconv(.winapi) void {
    state_mod.vertex2s(x, y);
}
pub fn Vertex3s(x: GLshort, y: GLshort, z: GLshort) callconv(.winapi) void {
    state_mod.vertex3s(x, y, z);
}
pub fn Vertex4s(x: GLshort, y: GLshort, z: GLshort, w: GLshort) callconv(.winapi) void {
    state_mod.vertex4s(x, y, z, w);
}
pub fn Vertex2d(x: GLdouble, y: GLdouble) callconv(.winapi) void {
    state_mod.vertex2d(x, y);
}
pub fn Vertex3d(x: GLdouble, y: GLdouble, z: GLdouble) callconv(.winapi) void {
    state_mod.vertex3d(x, y, z);
}
pub fn Vertex4d(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) callconv(.winapi) void {
    state_mod.vertex4d(x, y, z, w);
}
pub fn Color3f(r: GLfloat, g: GLfloat, b: GLfloat) callconv(.winapi) void {
    state_mod.color3f(r, g, b);
}
pub fn Color4f(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat) callconv(.winapi) void {
    state_mod.color4f(r, g, b, a);
}
pub fn Color3ub(r: GLubyte, g: GLubyte, b: GLubyte) callconv(.winapi) void {
    state_mod.color3ub(r, g, b);
}
pub fn Color4ub(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte) callconv(.winapi) void {
    state_mod.color4ub(r, g, b, a);
}
pub fn Color3i(r: GLint, g: GLint, b: GLint) callconv(.winapi) void {
    state_mod.color3i(r, g, b);
}
pub fn Color4i(r: GLint, g: GLint, b: GLint, a: GLint) callconv(.winapi) void {
    state_mod.color4i(r, g, b, a);
}
pub fn Color3us(r: GLushort, g: GLushort, b: GLushort) callconv(.winapi) void {
    state_mod.color3us(r, g, b);
}
pub fn Color4us(r: GLushort, g: GLushort, b: GLushort, a: GLushort) callconv(.winapi) void {
    state_mod.color4us(r, g, b, a);
}
pub fn Indexf(index: GLfloat) callconv(.winapi) void {
    state_mod.indexf(index);
}
pub fn Indexi(index: GLint) callconv(.winapi) void {
    state_mod.indexi(index);
}
pub fn Normal3f(nx: GLfloat, ny: GLfloat, nz: GLfloat) callconv(.winapi) void {
    state_mod.normal3f(nx, ny, nz);
}
pub fn Normal3d(nx: GLdouble, ny: GLdouble, nz: GLdouble) callconv(.winapi) void {
    state_mod.normal3d(nx, ny, nz);
}
pub fn TexCoord1f(s: GLfloat) callconv(.winapi) void {
    state_mod.texCoord1f(s);
}
pub fn TexCoord2f(s: GLfloat, t: GLfloat) callconv(.winapi) void {
    state_mod.texCoord2f(s, t);
}
pub fn TexCoord3f(s: GLfloat, t: GLfloat, r: GLfloat) callconv(.winapi) void {
    state_mod.texCoord3f(s, t, r);
}
pub fn TexCoord4f(s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat) callconv(.winapi) void {
    state_mod.texCoord4f(s, t, r, q);
}
pub fn EdgeFlag(flag: GLboolean) callconv(.winapi) void {
    state_mod.edgeFlag(flag);
}

// Client state and vertex arrays
pub fn EnableClientState(capability: u32) callconv(.winapi) void {
    state_mod.enableClientState(capability);
}
pub fn DisableClientState(capability: u32) callconv(.winapi) void {
    state_mod.disableClientState(capability);
}
pub fn VertexPointer(size: GLint, type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.vertexPointer(size, type_, stride, pointer);
}
pub fn NormalPointer(type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.normalPointer(type_, stride, pointer);
}
pub fn ColorPointer(size: GLint, type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.colorPointer(size, type_, stride, pointer);
}
pub fn TexCoordPointer(size: GLint, type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.texCoordPointer(size, type_, stride, pointer);
}
pub fn IndexPointer(type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.indexPointer(type_, stride, pointer);
}
pub fn EdgeFlagPointer(stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.edgeFlagPointer(stride, pointer);
}
pub fn ArrayElement(index: GLint) callconv(.winapi) void {
    state_mod.arrayElement(index);
}
pub fn DrawArrays(mode: u32, first: GLint, count: GLsizei) callconv(.winapi) void {
    state_mod.drawArrays(mode, first, count);
}
pub fn DrawElements(mode: u32, count: GLsizei, type_: u32, indices: [*]const u32) callconv(.winapi) void {
    state_mod.drawElements(mode, count, type_, indices);
}
pub fn InterleavedArrays(format: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.interleavedArrays(format, stride, pointer);
}

// Buffer objects
pub fn GenBuffers(n: GLsizei, buffers: [*]GLuint) callconv(.winapi) void {
    state_mod.genBuffers(n, buffers);
}
pub fn DeleteBuffers(n: GLsizei, buffers: [*]const GLuint) callconv(.winapi) void {
    state_mod.deleteBuffers(n, buffers);
}
pub fn BindBuffer(target: u32, buffer: GLuint) callconv(.winapi) void {
    state_mod.bindBuffer(target, buffer);
}
pub fn BufferData(target: u32, size: GLsizeiptr, data: ?*const anyopaque, usage: u32) callconv(.winapi) void {
    state_mod.bufferData(target, size, data, usage);
}
pub fn BufferSubData(target: u32, offset: GLintptr, size: GLsizeiptr, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.bufferSubData(target, offset, size, data);
}
pub fn IsBuffer(buffer: GLuint) callconv(.winapi) GLboolean {
    return state_mod.isBuffer(buffer);
}
pub fn MapBuffer(target: u32, access: u32) callconv(.winapi) ?*anyopaque {
    return state_mod.mapBuffer(target, access);
}
pub fn UnmapBuffer(target: u32) callconv(.winapi) GLboolean {
    return state_mod.unmapBuffer(target);
}
pub fn GetBufferParameteriv(target: u32, pname: u32, params: [*]GLint) callconv(.winapi) void {
    state_mod.getBufferParameteriv(target, pname, params);
}
pub fn GetBufferPointerv(target: u32, pname: u32, params: [*]?*anyopaque) callconv(.winapi) void {
    state_mod.getBufferPointerv(target, pname, params);
}
pub fn GetBufferSubData(target: u32, offset: GLintptr, size: GLsizeiptr, data: ?*anyopaque) callconv(.winapi) void {
    state_mod.getBufferSubData(target, offset, size, data);
}

// Generic vertex attributes
pub fn VertexAttribPointer(index: GLuint, size: GLint, type_: u32, normalized: GLboolean, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.vertexAttribPointer(index, size, type_, normalized, stride, pointer);
}
pub fn EnableVertexAttribArray(index: GLuint) callconv(.winapi) void {
    state_mod.enableVertexAttribArray(index);
}
pub fn DisableVertexAttribArray(index: GLuint) callconv(.winapi) void {
    state_mod.disableVertexAttribArray(index);
}
pub fn VertexAttribDivisor(index: GLuint, divisor: GLuint) callconv(.winapi) void {
    state_mod.vertexAttribDivisor(index, divisor);
}
pub fn GetVertexAttribiv(index: GLuint, pname: u32, params: [*]GLint) callconv(.winapi) void {
    state_mod.getVertexAttribiv(index, pname, params);
}
pub fn GetVertexAttribfv(index: GLuint, pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    state_mod.getVertexAttribfv(index, pname, params);
}
pub fn GetVertexAttribPointerv(index: GLuint, pname: u32, pointer: [*]?*anyopaque) callconv(.winapi) void {
    state_mod.getVertexAttribPointerv(index, pname, pointer);
}

// Shader / program objects
pub fn CreateShader(type_: u32) callconv(.winapi) GLuint {
    return state_mod.createShader(type_);
}
pub fn ShaderSource(shader: GLuint, count: GLsizei, string: [*]const ?[*]const u8, length: ?[*]const GLint) callconv(.winapi) void {
    state_mod.shaderSource(shader, count, string, length);
}
pub fn CompileShader(shader: GLuint) callconv(.winapi) void {
    state_mod.compileShaderObject(shader);
}
pub fn DeleteShader(shader: GLuint) callconv(.winapi) void {
    state_mod.deleteShader(shader);
}
pub fn GetShaderiv(shader: GLuint, pname: u32, params: [*]GLint) callconv(.winapi) void {
    state_mod.getShaderiv(shader, pname, params);
}
pub fn GetShaderInfoLog(shader: GLuint, maxLength: GLsizei, length: ?[*]GLsizei, infoLog: [*]u8) callconv(.winapi) void {
    state_mod.getShaderInfoLog(shader, maxLength, length, infoLog);
}
pub fn CreateProgram() callconv(.winapi) GLuint {
    return state_mod.createProgram();
}
pub fn AttachShader(program: GLuint, shader: GLuint) callconv(.winapi) void {
    state_mod.attachShader(program, shader);
}
pub fn BindAttribLocation(program: GLuint, index: GLuint, name: [*:0]const u8) callconv(.winapi) void {
    state_mod.bindAttribLocation(program, index, name);
}
pub fn LinkProgram(program: GLuint) callconv(.winapi) void {
    state_mod.linkProgram(program);
}
pub fn DeleteProgram(program: GLuint) callconv(.winapi) void {
    state_mod.deleteProgram(program);
}
pub fn GetProgramiv(program: GLuint, pname: u32, params: [*]GLint) callconv(.winapi) void {
    state_mod.getProgramiv(program, pname, params);
}
pub fn GetProgramInfoLog(program: GLuint, maxLength: GLsizei, length: ?*GLsizei, infoLog: [*]u8) callconv(.winapi) void {
    state_mod.getProgramInfoLog(program, maxLength, length, infoLog);
}
pub fn UseProgram(program: GLuint) callconv(.winapi) void {
    state_mod.useProgram(program);
}
pub fn GetUniformLocation(program: GLuint, name: [*:0]const u8) callconv(.winapi) GLint {
    return state_mod.getUniformLocation(program, name);
}
pub fn Uniform1i(location: GLint, v0: GLint) callconv(.winapi) void {
    state_mod.uniform1i(location, v0);
}
pub fn Uniform4fv(location: GLint, count: GLsizei, value: [*]const GLfloat) callconv(.winapi) void {
    state_mod.uniform4fv(location, count, value);
}

// Vertex array objects
pub fn GenVertexArrays(n: GLsizei, arrays: [*]GLuint) callconv(.winapi) void {
    state_mod.genVertexArrays(n, arrays);
}
pub fn BindVertexArray(array: GLuint) callconv(.winapi) void {
    state_mod.bindVertexArray(array);
}
pub fn DeleteVertexArrays(n: GLsizei, arrays: [*]const GLuint) callconv(.winapi) void {
    state_mod.deleteVertexArrays(n, arrays);
}

// Framebuffer objects
pub fn GenFramebuffers(n: GLsizei, framebuffers: [*]GLuint) callconv(.winapi) void {
    state_mod.genFramebuffers(n, framebuffers);
}
pub fn BindFramebuffer(target: u32, framebuffer: GLuint) callconv(.winapi) void {
    state_mod.bindFramebuffer(target, framebuffer);
}
pub fn DeleteFramebuffers(n: GLsizei, framebuffers: [*]const GLuint) callconv(.winapi) void {
    state_mod.deleteFramebuffers(n, framebuffers);
}
pub fn FramebufferTexture2D(target: u32, attachment: u32, textarget: u32, texture: GLuint, level: GLint) callconv(.winapi) void {
    state_mod.framebufferTexture2D(target, attachment, textarget, texture, level);
}
pub fn CheckFramebufferStatus(target: u32) callconv(.winapi) u32 {
    return state_mod.checkFramebufferStatus(target);
}

// Separated blend equation
pub fn BlendEquationSeparate(modeRGB: u32, modeAlpha: u32) callconv(.winapi) void {
    state_mod.blendEquationSeparate(modeRGB, modeAlpha);
}

// Rectangles
pub fn Rectf(x1: GLfloat, y1: GLfloat, x2: GLfloat, y2: GLfloat) callconv(.winapi) void {
    state_mod.rectf(x1, y1, x2, y2);
}
pub fn Recti(x1: GLint, y1: GLint, x2: GLint, y2: GLint) callconv(.winapi) void {
    state_mod.recti(x1, y1, x2, y2);
}

// Matrices
pub fn MatrixMode(mode: u32) callconv(.winapi) void {
    state_mod.matrixMode(mode);
}
pub fn LoadMatrix(m: [*]const GLfloat) callconv(.winapi) void {
    state_mod.loadMatrix(m);
}
pub fn MultMatrix(m: [*]const GLfloat) callconv(.winapi) void {
    state_mod.multMatrix(m);
}
pub fn LoadIdentity() callconv(.winapi) void {
    state_mod.loadIdentity();
}
pub fn Rotate(angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state_mod.rotate(angle, x, y, z);
}
pub fn Translate(x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state_mod.translate(x, y, z);
}
pub fn Scale(x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state_mod.scale(x, y, z);
}
pub fn Frustum(l: GLdouble, r: GLdouble, b: GLdouble, t: GLdouble, n: GLdouble, f: GLdouble) callconv(.winapi) void {
    state_mod.frustum(l, r, b, t, n, f);
}
pub fn Ortho(l: GLdouble, r: GLdouble, b: GLdouble, t: GLdouble, n: GLdouble, f: GLdouble) callconv(.winapi) void {
    state_mod.ortho(l, r, b, t, n, f);
}
pub fn PushMatrix() callconv(.winapi) void {
    state_mod.pushMatrix();
}
pub fn PopMatrix() callconv(.winapi) void {
    state_mod.popMatrix();
}
pub fn Viewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) callconv(.winapi) void {
    state_mod.viewport(x, y, width, height);
}
pub fn DepthRange(n: GLdouble, f: GLdouble) callconv(.winapi) void {
    state_mod.depthRange(n, f);
}

// Texture coordinate generation
pub fn TexGen(coord: u32, pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.texGen(coord, pname, param);
}

// Clipping
pub fn ClipPlane(plane: u32, eqn: [*]const GLdouble) callconv(.winapi) void {
    state_mod.clipPlane(plane, eqn);
}

// Raster position
pub fn RasterPos2f(x: GLfloat, y: GLfloat) callconv(.winapi) void {
    state_mod.rasterPos2f(x, y);
}
pub fn RasterPos3f(x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state_mod.rasterPos3f(x, y, z);
}
pub fn RasterPos4f(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat) callconv(.winapi) void {
    state_mod.rasterPos4f(x, y, z, w);
}

// Colors and coloring
pub fn ColorMaterial(face: u32, mode: u32) callconv(.winapi) void {
    state_mod.colorMaterial(face, mode);
}
pub fn FrontFace(dir: u32) callconv(.winapi) void {
    state_mod.frontFace(dir);
}
pub fn ShadeModel(mode: u32) callconv(.winapi) void {
    state_mod.shadeModel(mode);
}

// Fog
pub fn FogCoordf(pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.fogCoordf(pname, param);
}
pub fn FogCoordfv(pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    state_mod.fogCoordfv(pname, params);
}

// Rasterization state
pub fn PointSize(size: GLfloat) callconv(.winapi) void {
    state_mod.pointSize(size);
}
pub fn LineWidth(width: GLfloat) callconv(.winapi) void {
    state_mod.lineWidth(width);
}
pub fn LineStipple(factor: GLint, pattern: GLushort) callconv(.winapi) void {
    state_mod.lineStipple(factor, pattern);
}
pub fn PolygonStipple(pattern: [*]const GLubyte) callconv(.winapi) void {
    state_mod.polygonStipple(pattern);
}
pub fn PolygonMode(face: u32, mode: u32) callconv(.winapi) void {
    state_mod.polygonMode(face, mode);
}
pub fn AlphaFunc(func: u32, ref: GLfloat) callconv(.winapi) void {
    state_mod.alphaFunc(func, ref);
}
pub fn Scissor(left: GLint, bottom: GLint, width: GLsizei, height: GLsizei) callconv(.winapi) void {
    state_mod.scissor(left, bottom, width, height);
}
pub fn BlendFunc(src: u32, dst: u32) callconv(.winapi) void {
    state_mod.blendFunc(src, dst);
}
pub fn LogicOp(op: u32) callconv(.winapi) void {
    state_mod.logicOp(op);
}
pub fn DepthFunc(func: u32) callconv(.winapi) void {
    state_mod.depthFunc(func);
}
pub fn DepthMask(mask: GLboolean) callconv(.winapi) void {
    state_mod.depthMask(mask);
}

// Framebuffer
pub fn DrawBuffer(buf: u32) callconv(.winapi) void {
    state_mod.drawBuffer(buf);
}
pub fn ReadBuffer(buf: u32) callconv(.winapi) void {
    state_mod.readBuffer(buf);
}
pub fn ClearColor(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat) callconv(.winapi) void {
    state_mod.clearColor(r, g, b, a);
}
pub fn ClearIndex(index: GLfloat) callconv(.winapi) void {
    state_mod.clearIndex(index);
}
pub fn ClearDepth(depth: GLdouble) callconv(.winapi) void {
    state_mod.clearDepth(depth);
}
pub fn ClearStencil(stencil: GLint) callconv(.winapi) void {
    state_mod.clearStencil(stencil);
}
pub fn ColorMask(r: GLboolean, g: GLboolean, b: GLboolean, a: GLboolean) callconv(.winapi) void {
    state_mod.colorMask(r, g, b, a);
}
pub fn IndexMask(mask: GLushort) callconv(.winapi) void {
    state_mod.indexMask(mask);
}
pub fn StencilMask(mask: GLushort) callconv(.winapi) void {
    state_mod.stencilMask(mask);
}

// Pixel rectangles
pub fn PixelStoref(pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.pixelStoref(pname, param);
}
pub fn PixelStorei(pname: u32, param: GLint) callconv(.winapi) void {
    state_mod.pixelStorei(pname, param);
}
pub fn PixelTransferf(pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.pixelTransferf(pname, param);
}
pub fn PixelTransferi(pname: u32, param: GLint) callconv(.winapi) void {
    state_mod.pixelTransferi(pname, param);
}
pub fn PixelMapf(pname: u32, size: GLint, values: [*]const GLfloat) callconv(.winapi) void {
    state_mod.pixelMapf(pname, size, values);
}
pub fn PixelMapi(pname: u32, size: GLint, values: [*]const GLint) callconv(.winapi) void {
    state_mod.pixelMapi(pname, size, values);
}

// Texturing
pub fn TexImage2D(target: u32, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: u32, type_: u32, pixels: ?*const anyopaque) callconv(.winapi) void {
    state_mod.texImage2D(target, level, internalformat, width, height, border, format, type_, pixels);
}
pub fn TexImage1D(target: u32, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: u32, type_: u32, pixels: ?*const anyopaque) callconv(.winapi) void {
    state_mod.texImage1D(target, level, internalformat, width, border, format, type_, pixels);
}
pub fn TexSubImage2D(target: u32, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: u32, type_: u32, pixels: ?*const anyopaque) callconv(.winapi) void {
    state_mod.texSubImage2D(target, level, xoffset, yoffset, width, height, format, type_, pixels);
}
pub fn CopyTexImage2D(target: u32, level: GLint, internalformat: u32, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint) callconv(.winapi) void {
    state_mod.copyTexImage2D(target, level, internalformat, x, y, width, height, border);
}
pub fn CopyTexSubImage2D(target: u32, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei) callconv(.winapi) void {
    state_mod.copyTexSubImage2D(target, level, xoffset, yoffset, width, height);
}
pub fn BindTexture(target: u32, texture: GLuint) callconv(.winapi) void {
    state_mod.bindTexture(target, texture);
}
pub fn DeleteTextures(count: GLint, textures: [*]const GLuint) callconv(.winapi) void {
    state_mod.deleteTextures(count, textures);
}
pub fn AreTexturesResident(count: GLint, textures: [*]const GLuint, residences: [*]GLboolean) callconv(.winapi) void {
    state_mod.areTexturesResident(count, textures, residences);
}
pub fn PrioritizeTextures(count: GLint, textures: [*]const GLuint, priorities: [*]const GLfloat) callconv(.winapi) void {
    state_mod.prioritizeTextures(count, textures, priorities);
}
pub fn TexParameterf(target: u32, pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.texParameterf(target, pname, param);
}
pub fn TexParameteri(target: u32, pname: u32, param: GLint) callconv(.winapi) void {
    state_mod.texParameteri(target, pname, param);
}
pub fn TexEnvf(target: u32, pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.texEnvf(target, pname, param);
}

// Reading pixels
pub fn ReadPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: u32, type_: u32, pixels: [*]u8) callconv(.winapi) void {
    state_mod.readPixels(x, y, width, height, format, type_, pixels);
}

// Special functions
pub fn NewList(list: GLuint, mode: u32) callconv(.winapi) void {
    state_mod.newList(list, mode);
}
pub fn EndList() callconv(.winapi) void {
    state_mod.endList();
}
pub fn CallList(list: GLuint) callconv(.winapi) void {
    state_mod.callList(list);
}
pub fn RenderMode(mode: u32) callconv(.winapi) u32 {
    return state_mod.renderMode(mode);
}
pub fn SelectBuffer(n: GLint, buffer: [*]u32) callconv(.winapi) void {
    state_mod.selectBuffer(n, buffer);
}
pub fn FeedbackBuffer(n: GLint, buffer: [*]f32) callconv(.winapi) void {
    state_mod.feedbackBuffer(n, buffer);
}
pub fn Map1(target: u32, u: GLdouble, u_max: GLdouble, stride: GLint, order: GLint, points: [*]const f64) callconv(.winapi) void {
    state_mod.map1(target, u, u_max, stride, order, points);
}
pub fn EvalCoord1(arg: f32) callconv(.winapi) void {
    state_mod.evalCoord1(arg);
}
pub fn EvalPoint1(p: GLint) callconv(.winapi) void {
    state_mod.evalPoint1(p);
}

// Other misc functions
pub fn Enable(capability: u32) callconv(.winapi) void {
    state_mod.enableCapability(capability);
}
pub fn Disable(capability: u32) callconv(.winapi) void {
    state_mod.disableCapability(capability);
}
pub fn IsEnabled(capability: u32) callconv(.winapi) GLboolean {
    return state_mod.isEnabled(capability);
}
pub fn Clear(mask: u32) callconv(.winapi) void {
    state_mod.clear(mask);
}
pub fn Flush() callconv(.winapi) void {
    state_mod.flush();
}
pub fn Finish() callconv(.winapi) void {
    state_mod.finish();
}

pub fn GetBooleanv(pname: u32, params: [*]GLboolean) callconv(.winapi) void {
    state_mod.getBooleanv(pname, params);
}
pub fn GetDoublev(pname: u32, params: [*]GLdouble) callconv(.winapi) void {
    var temp: [16]f32 = undefined;
    state_mod.getFloatv(pname, &temp);
    const count: usize = switch (pname) {
        MODELVIEW_MATRIX, PROJECTION_MATRIX, TEXTURE_MATRIX => 16,
        else => 4,
    };
    var i: usize = 0;
    while (i < count) : (i += 1) {
        params[i] = @floatCast(temp[i]);
    }
}
pub fn GetFloatv(pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    state_mod.getFloatv(pname, params);
}
pub fn GetIntegerv(pname: u32, params: [*]GLint) callconv(.winapi) void {
    state_mod.getIntegerv(pname, params);
}
pub fn GetString(name: u32) callconv(.winapi) ?[*:0]const u8 {
    return state_mod.getString(name);
}
pub fn GetClipPlane(plane: u32, equation: [*]GLdouble) callconv(.winapi) void {
    state_mod.getClipPlane(plane, equation);
}
pub fn GetLightfv(light: u32, pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    state_mod.getLightfv(lightIndex(light), pname, params);
}
pub fn GetLightiv(light: u32, pname: u32, params: [*]GLint) callconv(.winapi) void {
    var values = [_]GLfloat{ 0, 0, 0, 0 };
    state_mod.getLightfv(lightIndex(light), pname, &values);
    var i: usize = 0;
    while (i < 4) : (i += 1) params[i] = @intFromFloat(values[i]);
}
pub fn GetMaterialfv(face: u32, pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    state_mod.getMaterialfv(face, pname, params);
}
pub fn GetMaterialiv(face: u32, pname: u32, params: [*]GLint) callconv(.winapi) void {
    var values = [_]GLfloat{ 0, 0, 0, 0 };
    state_mod.getMaterialfv(face, pname, &values);
    var i: usize = 0;
    while (i < 4) : (i += 1) params[i] = @intFromFloat(values[i]);
}
pub fn GetTexEnvfv(target: u32, pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    state_mod.getTexEnvfv(target, pname, params);
}
pub fn GetTexEnviv(target: u32, pname: u32, params: [*]GLint) callconv(.winapi) void {
    var values = [_]GLfloat{ 0, 0, 0, 0 };
    state_mod.getTexEnvfv(target, pname, &values);
    var i: usize = 0;
    while (i < 4) : (i += 1) params[i] = @intFromFloat(values[i]);
}
pub fn GetTexGenfv(coord: u32, pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    state_mod.getTexGenfv(coord, pname, params);
}
pub fn GetTexGeniv(coord: u32, pname: u32, params: [*]GLint) callconv(.winapi) void {
    var values = [_]GLfloat{ 0, 0, 0, 0 };
    state_mod.getTexGenfv(coord, pname, &values);
    var i: usize = 0;
    while (i < 4) : (i += 1) params[i] = @intFromFloat(values[i]);
}
pub fn GetPointerv(pname: u32, params: [*]?*anyopaque) callconv(.winapi) void {
    const pointer = state_mod.getPointer(pname);
    if (pointer) |p| params[0] = @constCast(p);
}

pub fn GenTextures(n: GLsizei, textures: [*]GLuint) callconv(.winapi) void {
    state_mod.genTextures(n, textures);
}
pub fn IsTexture(texture: GLuint) callconv(.winapi) GLboolean {
    return state_mod.isTexture(texture);
}
pub fn IsList(list: GLuint) callconv(.winapi) GLboolean {
    _ = list;
    return state_mod.isTexture(0) * 0 + 0;
}

pub fn DrawPixels(width: GLsizei, height: GLsizei, format: u32, type_: u32, pixels: ?*const anyopaque) callconv(.winapi) void {
    state_mod.drawPixels(width, height, format, type_, @ptrCast(pixels));
}
pub fn CopyPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, kind: u32) callconv(.winapi) void {
    state_mod.copyPixels(x, y, width, height, kind);
}
pub fn PixelZoom(xfactor: GLfloat, yfactor: GLfloat) callconv(.winapi) void {
    _ = xfactor;
    _ = yfactor;
}

pub fn PushAttrib(mask: u32) callconv(.winapi) void {
    state_mod.pushAttrib(mask);
}
pub fn PopAttrib() callconv(.winapi) void {
    state_mod.popAttrib();
}
pub fn PushClientAttrib(mask: u32) callconv(.winapi) void {
    state_mod.pushClientAttrib(mask);
}
pub fn PopClientAttrib() callconv(.winapi) void {
    state_mod.popClientAttrib();
}

pub fn Materialf(face: u32, pname: u32, param: GLfloat) callconv(.winapi) void {
    var values = [_]GLfloat{ param, param, param, param };
    state_mod.lightMaterial(face, pname, &values);
}
pub fn Materiali(face: u32, pname: u32, param: GLint) callconv(.winapi) void {
    Materialf(face, pname, @floatFromInt(param));
}
pub fn Materialfv(face: u32, pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    state_mod.lightMaterial(face, pname, params);
}

pub fn Lightf(light: u32, pname: u32, param: GLfloat) callconv(.winapi) void {
    const index = lightIndex(light);
    var values = [_]GLfloat{ param, param, param, param };
    state_mod.light(index, pname, &values);
}
pub fn Lighti(light: u32, pname: u32, param: GLint) callconv(.winapi) void {
    Lightf(light, pname, @floatFromInt(param));
}
pub fn Lightfv(light: u32, pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    state_mod.light(lightIndex(light), pname, params);
}

pub fn LightModelf(pname: u32, param: GLfloat) callconv(.winapi) void {
    var values = [_]GLfloat{ param, param, param, param };
    state_mod.lightModel(pname, &values);
}
pub fn LightModeli(pname: u32, param: GLint) callconv(.winapi) void {
    LightModelf(pname, @floatFromInt(param));
}
pub fn LightModelfv(pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    state_mod.lightModel(pname, params);
}

pub fn Fogf(pname: u32, param: GLfloat) callconv(.winapi) void {
    var values = [_]GLfloat{ param, param, param, param };
    state_mod.fog(pname, &values);
}
pub fn Fogi(pname: u32, param: GLint) callconv(.winapi) void {
    Fogf(pname, @floatFromInt(param));
}
pub fn Fogfv(pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    state_mod.fog(pname, params);
}

pub fn TexEnvfv(target: u32, pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    if (pname == TEXTURE_ENV_COLOR) {
        state_mod.texEnvColor(.{ params[0], params[1], params[2], params[3] });
    } else {
        state_mod.texEnvi(target, pname, @intFromFloat(params[0]));
    }
}
pub fn TexEnvi(target: u32, pname: u32, param: GLint) callconv(.winapi) void {
    state_mod.texEnvi(target, pname, param);
}
pub fn TexEnviv(target: u32, pname: u32, params: [*]const GLint) callconv(.winapi) void {
    if (pname == TEXTURE_ENV_COLOR) {
        state_mod.texEnvColor(.{
            @floatFromInt(params[0]),
            @floatFromInt(params[1]),
            @floatFromInt(params[2]),
            @floatFromInt(params[3]),
        });
    } else {
        state_mod.texEnvi(target, pname, params[0]);
    }
}

fn lightIndex(light: u32) u32 {
    if (light >= LIGHT0) {
        return light - LIGHT0;
    }
    return 0;
}

// ARB_multitexture

pub fn ActiveTextureARB(texture: u32) callconv(.winapi) void {
    state_mod.activeTextureARB(texture);
}
pub fn ClientActiveTextureARB(texture: u32) callconv(.winapi) void {
    state_mod.clientActiveTextureARB(texture);
}
pub fn MultiTexCoord1f(target: u32, s: GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord1f(target, s);
}
pub fn MultiTexCoord2f(target: u32, s: GLfloat, t: GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord2f(target, s, t);
}
pub fn MultiTexCoord3f(target: u32, s: GLfloat, t: GLfloat, r: GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord3f(target, s, t, r);
}
pub fn MultiTexCoord4f(target: u32, s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord4f(target, s, t, r, q);
}
pub fn MultiTexCoord1fv(target: u32, v: [*]const GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord1fv(target, v);
}
pub fn MultiTexCoord2fv(target: u32, v: [*]const GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord2fv(target, v);
}
pub fn MultiTexCoord3fv(target: u32, v: [*]const GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord3fv(target, v);
}
pub fn MultiTexCoord4fv(target: u32, v: [*]const GLfloat) callconv(.winapi) void {
    state_mod.multiTexCoord4fv(target, v);
}
pub fn MultiTexCoord2i(target: u32, s: GLint, t: GLint) callconv(.winapi) void {
    state_mod.multiTexCoord2i(target, s, t);
}
pub fn MultiTexCoord2s(target: u32, s: i16, t: i16) callconv(.winapi) void {
    state_mod.multiTexCoord2s(target, s, t);
}
pub fn MultiTexCoord2d(target: u32, s: f64, t: f64) callconv(.winapi) void {
    state_mod.multiTexCoord2d(target, s, t);
}

// EXT_fog_coord

pub fn FogCoordfEXT(coord: GLfloat) callconv(.winapi) void {
    state_mod.fogCoordf(0, coord);
}
pub fn FogCoordfvEXT(coord: [*]const GLfloat) callconv(.winapi) void {
    state_mod.fogCoordfv(0, coord);
}
pub fn FogCoorddEXT(coord: f64) callconv(.winapi) void {
    state_mod.fogCoordd(0, coord);
}
pub fn FogCoorddvEXT(coord: [*]const f64) callconv(.winapi) void {
    state_mod.fogCoorddv(0, coord);
}
pub fn FogCoordPointerEXT(type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    state_mod.fogCoordPointer(type_, stride, pointer);
}

// EXT_compiled_vertex_array

pub fn LockArraysEXT(first: GLint, count: GLsizei) callconv(.winapi) void {
    state_mod.lockArraysEXT(first, count);
}
pub fn UnlockArraysEXT() callconv(.winapi) void {
    state_mod.unlockArraysEXT();
}

// EXT_texture_object
pub fn GenTexturesEXT(n: GLsizei, textures: [*]GLuint) callconv(.winapi) void {
    state_mod.genTextures(n, textures);
}
pub fn BindTextureEXT(target: u32, texture: GLuint) callconv(.winapi) void {
    state_mod.bindTexture(target, texture);
}
pub fn DeleteTexturesEXT(n: GLsizei, textures: [*]const GLuint) callconv(.winapi) void {
    state_mod.deleteTextures(n, textures);
}
pub fn IsTextureEXT(texture: GLuint) callconv(.winapi) GLboolean {
    return state_mod.isTexture(texture);
}
pub fn AreTexturesResidentEXT(n: GLsizei, textures: [*]const GLuint, residences: [*]GLboolean) callconv(.winapi) GLboolean {
    state_mod.areTexturesResident(n, textures, residences);
    return 1;
}
pub fn PrioritizeTexturesEXT(n: GLsizei, textures: [*]const GLuint, priorities: [*]const GLfloat) callconv(.winapi) void {
    state_mod.prioritizeTextures(n, textures, priorities);
}

// EXT_vertex_array
pub fn VertexPointerEXT(size: GLint, type_: u32, stride: GLsizei, count: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = count;
    state_mod.vertexPointer(size, type_, stride, pointer);
}
pub fn NormalPointerEXT(type_: u32, stride: GLsizei, count: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = count;
    state_mod.normalPointer(type_, stride, pointer);
}
pub fn ColorPointerEXT(size: GLint, type_: u32, stride: GLsizei, count: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = count;
    state_mod.colorPointer(size, type_, stride, pointer);
}
pub fn IndexPointerEXT(type_: u32, stride: GLsizei, count: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = count;
    state_mod.indexPointer(type_, stride, pointer);
}
pub fn TexCoordPointerEXT(size: GLint, type_: u32, stride: GLsizei, count: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = count;
    state_mod.texCoordPointer(size, type_, stride, pointer);
}
pub fn EdgeFlagPointerEXT(stride: GLsizei, count: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = count;
    state_mod.edgeFlagPointer(stride, pointer);
}
pub fn GetPointervEXT(pname: u32, params: [*]?*anyopaque) callconv(.winapi) void {
    state_mod.getPointerv(pname, params);
}
pub fn ArrayElementEXT(index: GLint) callconv(.winapi) void {
    state_mod.arrayElement(index);
}
pub fn DrawArraysEXT(mode: u32, first: GLint, count: GLsizei) callconv(.winapi) void {
    state_mod.drawArrays(mode, first, count);
}

// EXT_multi_draw_arrays
pub fn MultiDrawArraysEXT(mode: u32, first: [*]const GLint, count: [*]const GLsizei, primcount: GLsizei) callconv(.winapi) void {
    state_mod.multiDrawArrays(mode, first, count, primcount);
}
pub fn MultiDrawElementsEXT(mode: u32, count: [*]const GLsizei, type_: u32, indices: [*]const ?*const anyopaque, primcount: GLsizei) callconv(.winapi) void {
    state_mod.multiDrawElements(mode, count, type_, indices, primcount);
}

// EXT_blend_color
pub fn BlendColorEXT(red: GLclampf, green: GLclampf, blue: GLclampf, alpha: GLclampf) callconv(.winapi) void {
    state_mod.blendColor(red, green, blue, alpha);
}

// EXT_blend_minmax
pub fn BlendEquation(mode: u32) callconv(.winapi) void {
    state_mod.blendEquation(mode);
}

// draw range elements

pub fn DrawRangeElements(mode: u32, start: GLuint, end: GLuint, count: GLsizei, type_: u32, indices: ?*const anyopaque) callconv(.winapi) void {
    state_mod.drawRangeElements(mode, start, end, count, type_, indices);
}

// ARB_texture_compression

pub fn CompressedTexImage1DARB(target: u32, level: GLint, internalformat: u32, width: GLsizei, border: GLint, imageSize: GLsizei, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.compressedTexImage1D(target, level, internalformat, width, border, imageSize, data);
}
pub fn CompressedTexImage2DARB(target: u32, level: GLint, internalformat: u32, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.compressedTexImage2D(target, level, internalformat, width, height, border, imageSize, data);
}
pub fn CompressedTexImage3DARB(target: u32, level: GLint, internalformat: u32, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.compressedTexImage3D(target, level, internalformat, width, height, depth, border, imageSize, data);
}
pub fn CompressedTexSubImage1DARB(target: u32, level: GLint, xoffset: GLint, width: GLsizei, format: u32, imageSize: GLsizei, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.compressedTexSubImage1D(target, level, xoffset, width, format, imageSize, data);
}
pub fn CompressedTexSubImage2DARB(target: u32, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: u32, imageSize: GLsizei, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.compressedTexSubImage2D(target, level, xoffset, yoffset, width, height, format, imageSize, data);
}
pub fn CompressedTexSubImage3DARB(target: u32, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: u32, imageSize: GLsizei, data: ?*const anyopaque) callconv(.winapi) void {
    state_mod.compressedTexSubImage3D(target, level, xoffset, yoffset, zoffset, width, height, depth, format, imageSize, data);
}
pub fn GetCompressedTexImageARB(target: u32, level: GLint, img: ?*anyopaque) callconv(.winapi) void {
    state_mod.getCompressedTexImage(target, level, img);
}

// 1D texture sub-images

pub fn TexSubImage1D(target: u32, level: GLint, xoffset: GLint, width: GLsizei, format: u32, type_: u32, pixels: ?*const anyopaque) callconv(.winapi) void {
    state_mod.texSubImage1D(target, level, xoffset, width, format, type_, pixels);
}
pub fn CopyTexImage1D(target: u32, level: GLint, internalformat: u32, x: GLint, y: GLint, width: GLsizei, border: GLint) callconv(.winapi) void {
    state_mod.copyTexImage1D(target, level, internalformat, x, y, width, border);
}
pub fn CopyTexSubImage1D(target: u32, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei) callconv(.winapi) void {
    state_mod.copyTexSubImage1D(target, level, xoffset, x, y, width);
}

// Texture-unit selection

pub fn ActiveTexture(texture: u32) callconv(.winapi) void {
    state_mod.activeTextureARB(texture);
}
pub fn ClientActiveTexture(texture: u32) callconv(.winapi) void {
    state_mod.clientActiveTextureARB(texture);
}

// EXT_blend_func_separate

pub fn BlendFuncSeparate(srcRGB: u32, dstRGB: u32, srcAlpha: u32, dstAlpha: u32) callconv(.winapi) void {
    state_mod.blendFuncSeparate(srcRGB, dstRGB, srcAlpha, dstAlpha);
}

// ARB_point_parameters

pub fn PointParameterf(pname: u32, param: GLfloat) callconv(.winapi) void {
    var values = [_]GLfloat{ param, param, param, param };
    state_mod.pointParameter(pname, &values);
}
pub fn PointParameterfv(pname: u32, params: [*]const GLfloat) callconv(.winapi) void {
    state_mod.pointParameter(pname, params);
}
pub fn PointParameteri(pname: u32, param: GLint) callconv(.winapi) void {
    PointParameterf(pname, @floatFromInt(param));
}
pub fn PointParameteriv(pname: u32, params: [*]const GLint) callconv(.winapi) void {
    var values = [_]GLfloat{
        @floatFromInt(params[0]),
        @floatFromInt(params[1]),
        @floatFromInt(params[2]),
        @floatFromInt(params[3]),
    };
    state_mod.pointParameter(pname, &values);
}

// EXT_secondary_color

pub fn SecondaryColor3f(r: GLfloat, g: GLfloat, b: GLfloat) callconv(.winapi) void {
    state_mod.secondaryColor(.{ r, g, b, 1 });
}
pub fn SecondaryColor3fv(v: [*]const GLfloat) callconv(.winapi) void {
    state_mod.secondaryColor(.{ v[0], v[1], v[2], 1 });
}
pub fn SecondaryColor3b(r: i8, g: i8, b: i8) callconv(.winapi) void {
    SecondaryColor3f(@as(f32, @floatFromInt(r)) / 127.0, @as(f32, @floatFromInt(g)) / 127.0, @as(f32, @floatFromInt(b)) / 127.0);
}
pub fn SecondaryColor3ub(r: u8, g: u8, b: u8) callconv(.winapi) void {
    SecondaryColor3f(@as(f32, @floatFromInt(r)) / 255.0, @as(f32, @floatFromInt(g)) / 255.0, @as(f32, @floatFromInt(b)) / 255.0);
}
pub fn SecondaryColor3d(r: f64, g: f64, b: f64) callconv(.winapi) void {
    SecondaryColor3f(@floatCast(r), @floatCast(g), @floatCast(b));
}
pub fn SecondaryColor3dv(v: [*]const f64) callconv(.winapi) void {
    SecondaryColor3f(@floatCast(v[0]), @floatCast(v[1]), @floatCast(v[2]));
}
pub fn SecondaryColor3fEXT(r: GLfloat, g: GLfloat, b: GLfloat) callconv(.winapi) void {
    SecondaryColor3f(r, g, b);
}
pub fn SecondaryColor3fvEXT(v: [*]const GLfloat) callconv(.winapi) void {
    SecondaryColor3fv(v);
}
pub fn SecondaryColor3ubEXT(r: u8, g: u8, b: u8) callconv(.winapi) void {
    SecondaryColor3ub(r, g, b);
}
pub fn SecondaryColor3ubvEXT(v: [*]const u8) callconv(.winapi) void {
    SecondaryColor3ub(v[0], v[1], v[2]);
}
pub fn SecondaryColorPointer(size: GLint, type_: u32, stride: GLsizei, pointer: ?*const anyopaque) callconv(.winapi) void {
    _ = size;
    _ = type_;
    _ = stride;
    _ = pointer;
}

// Multi-draw

pub fn MultiDrawArrays(mode: u32, first: [*]const GLint, count: [*]const GLsizei, primcount: GLsizei) callconv(.winapi) void {
    state_mod.multiDrawArrays(mode, first, count, primcount);
}
pub fn MultiDrawElements(mode: u32, count: [*]const GLsizei, type_: u32, indices: [*]const ?*const anyopaque, primcount: GLsizei) callconv(.winapi) void {
    state_mod.multiDrawElements(mode, count, type_, indices, primcount);
}

// EXT_vertex_buffer

pub fn AvailableVertexBufferEXT() callconv(.winapi) GLboolean {
    return state_mod.availableVertexBufferEXT();
}
pub fn AllocateVertexBufferEXT(size: GLsizei, format: GLint, preserve: GLboolean) callconv(.winapi) GLint {
    return state_mod.allocateVertexBufferEXT(size, format, preserve);
}
pub fn LockVertexBufferEXT(handle: GLint, size: GLsizei) callconv(.winapi) ?*anyopaque {
    return state_mod.lockVertexBufferEXT(handle, size);
}
pub fn UnlockVertexBufferEXT(handle: GLint) callconv(.winapi) void {
    state_mod.unlockVertexBufferEXT(handle);
}
pub fn SetVertexBufferEXT(handle: GLint) callconv(.winapi) void {
    state_mod.setVertexBufferEXT(handle);
}
pub fn OffsetVertexBufferEXT(handle: GLint, offset: GLuint) callconv(.winapi) void {
    state_mod.offsetVertexBufferEXT(handle, offset);
}
pub fn FillVertexBufferEXT(handle: GLint, first: GLint, count: GLsizei) callconv(.winapi) void {
    state_mod.fillVertexBufferEXT(handle, first, count);
}
pub fn FreeVertexBufferEXT(handle: GLint) callconv(.winapi) void {
    state_mod.freeVertexBufferEXT(handle);
}

// ATI PN triangles

pub fn NPatchSetInt(pname: u32, param: GLint) callconv(.winapi) void {
    state_mod.nPatchSetInt(pname, param);
}
pub fn NPatchSetFloat(pname: u32, param: GLfloat) callconv(.winapi) void {
    state_mod.nPatchSetInt(pname, @intFromFloat(param));
}
pub fn NPatchSetMode(pname: u32, param: GLint) callconv(.winapi) void {
    state_mod.nPatchSetInt(pname, param);
}

// EXT_paletted_texture

pub fn ColorTableEXT(target: u32, internalFormat: u32, width: GLsizei, format: u32, type_: u32, table: ?*const anyopaque) callconv(.winapi) void {
    _ = target;
    _ = internalFormat;
    _ = width;
    _ = format;
    _ = type_;
    _ = table;
}
pub fn ColorSubTableEXT(target: u32, start: GLsizei, count: GLsizei, format: u32, type_: u32, data: ?*const anyopaque) callconv(.winapi) void {
    _ = target;
    _ = start;
    _ = count;
    _ = format;
    _ = type_;
    _ = data;
}
pub fn GetColorTableEXT(target: u32, format: u32, type_: u32, table: ?*anyopaque) callconv(.winapi) void {
    _ = target;
    _ = format;
    _ = type_;
    _ = table;
}
pub fn GetColorTableParameterivEXT(target: u32, pname: u32, params: [*]GLint) callconv(.winapi) void {
    _ = target;
    _ = pname;
    params[0] = 0;
}
pub fn GetColorTableParameterfvEXT(target: u32, pname: u32, params: [*]GLfloat) callconv(.winapi) void {
    _ = target;
    _ = pname;
    params[0] = 0;
}
