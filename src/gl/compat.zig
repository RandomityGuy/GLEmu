//! compat.zig
//! The remainder of the OpenGL 1.1 entry-point surface.

const gl = @import("gl.zig");
const state = @import("../emu/state.zig");

const GLenum = gl.GLenum;
const GLboolean = gl.GLboolean;
const GLbyte = gl.GLbyte;
const GLshort = gl.GLshort;
const GLint = gl.GLint;
const GLsizei = gl.GLsizei;
const GLubyte = gl.GLubyte;
const GLushort = gl.GLushort;
const GLuint = gl.GLuint;
const GLfloat = gl.GLfloat;
const GLdouble = gl.GLdouble;

fn f(float: anytype) f32 {
    return @floatCast(float);
}
fn fi(value: anytype) f32 {
    return @floatFromInt(value);
}
fn lightIndex(light: GLenum) u32 {
    if (light >= gl.LIGHT0) return light - gl.LIGHT0;
    return 0;
}

// Colours

fn color3(r: f32, g: f32, b: f32) void {
    state.color3f(r, g, b);
}
fn color4(r: f32, g: f32, b: f32, a: f32) void {
    state.color4f(r, g, b, a);
}

pub fn Color3b(r: GLbyte, g: GLbyte, b: GLbyte) callconv(.winapi) void {
    color3(fi(r) / 127.0, fi(g) / 127.0, fi(b) / 127.0);
}
pub fn Color3bv(v: [*]const GLbyte) callconv(.winapi) void {
    Color3b(v[0], v[1], v[2]);
}
pub fn Color3d(r: GLdouble, g: GLdouble, b: GLdouble) callconv(.winapi) void {
    color3(f(r), f(g), f(b));
}
pub fn Color3dv(v: [*]const GLdouble) callconv(.winapi) void {
    color3(f(v[0]), f(v[1]), f(v[2]));
}
pub fn Color3fv(v: [*]const GLfloat) callconv(.winapi) void {
    color3(v[0], v[1], v[2]);
}
pub fn Color3iv(v: [*]const GLint) callconv(.winapi) void {
    state.color3i(v[0], v[1], v[2]);
}
pub fn Color3s(r: GLshort, g: GLshort, b: GLshort) callconv(.winapi) void {
    color3(fi(r) / 32767.0, fi(g) / 32767.0, fi(b) / 32767.0);
}
pub fn Color3sv(v: [*]const GLshort) callconv(.winapi) void {
    Color3s(v[0], v[1], v[2]);
}
pub fn Color3ubv(v: [*]const GLubyte) callconv(.winapi) void {
    state.color3ub(v[0], v[1], v[2]);
}
pub fn Color3ui(r: GLuint, g: GLuint, b: GLuint) callconv(.winapi) void {
    color3(fi(r) / 4294967295.0, fi(g) / 4294967295.0, fi(b) / 4294967295.0);
}
pub fn Color3uiv(v: [*]const GLuint) callconv(.winapi) void {
    Color3ui(v[0], v[1], v[2]);
}
pub fn Color3usv(v: [*]const GLushort) callconv(.winapi) void {
    state.color3us(v[0], v[1], v[2]);
}

pub fn Color4b(r: GLbyte, g: GLbyte, b: GLbyte, a: GLbyte) callconv(.winapi) void {
    color4(fi(r) / 127.0, fi(g) / 127.0, fi(b) / 127.0, fi(a) / 127.0);
}
pub fn Color4bv(v: [*]const GLbyte) callconv(.winapi) void {
    Color4b(v[0], v[1], v[2], v[3]);
}
pub fn Color4d(r: GLdouble, g: GLdouble, b: GLdouble, a: GLdouble) callconv(.winapi) void {
    color4(f(r), f(g), f(b), f(a));
}
pub fn Color4dv(v: [*]const GLdouble) callconv(.winapi) void {
    color4(f(v[0]), f(v[1]), f(v[2]), f(v[3]));
}
pub fn Color4fv(v: [*]const GLfloat) callconv(.winapi) void {
    color4(v[0], v[1], v[2], v[3]);
}
pub fn Color4iv(v: [*]const GLint) callconv(.winapi) void {
    state.color4i(v[0], v[1], v[2], v[3]);
}
pub fn Color4s(r: GLshort, g: GLshort, b: GLshort, a: GLshort) callconv(.winapi) void {
    color4(fi(r) / 32767.0, fi(g) / 32767.0, fi(b) / 32767.0, fi(a) / 32767.0);
}
pub fn Color4sv(v: [*]const GLshort) callconv(.winapi) void {
    Color4s(v[0], v[1], v[2], v[3]);
}
pub fn Color4ubv(v: [*]const GLubyte) callconv(.winapi) void {
    state.color4ub(v[0], v[1], v[2], v[3]);
}
pub fn Color4ui(r: GLuint, g: GLuint, b: GLuint, a: GLuint) callconv(.winapi) void {
    color4(fi(r) / 4294967295.0, fi(g) / 4294967295.0, fi(b) / 4294967295.0, fi(a) / 4294967295.0);
}
pub fn Color4uiv(v: [*]const GLuint) callconv(.winapi) void {
    Color4ui(v[0], v[1], v[2], v[3]);
}
pub fn Color4usv(v: [*]const GLushort) callconv(.winapi) void {
    state.color4us(v[0], v[1], v[2], v[3]);
}

// Normals

pub fn Normal3b(nx: GLbyte, ny: GLbyte, nz: GLbyte) callconv(.winapi) void {
    state.normal3f(fi(nx) / 127.0, fi(ny) / 127.0, fi(nz) / 127.0);
}
pub fn Normal3bv(v: [*]const GLbyte) callconv(.winapi) void {
    Normal3b(v[0], v[1], v[2]);
}
pub fn Normal3dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.normal3d(v[0], v[1], v[2]);
}
pub fn Normal3fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.normal3f(v[0], v[1], v[2]);
}
pub fn Normal3i(nx: GLint, ny: GLint, nz: GLint) callconv(.winapi) void {
    state.normal3f(fi(nx), fi(ny), fi(nz));
}
pub fn Normal3iv(v: [*]const GLint) callconv(.winapi) void {
    Normal3i(v[0], v[1], v[2]);
}
pub fn Normal3s(nx: GLshort, ny: GLshort, nz: GLshort) callconv(.winapi) void {
    state.normal3f(fi(nx) / 32767.0, fi(ny) / 32767.0, fi(nz) / 32767.0);
}
pub fn Normal3sv(v: [*]const GLshort) callconv(.winapi) void {
    Normal3s(v[0], v[1], v[2]);
}

// Vertices

pub fn Vertex2dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.vertex2d(v[0], v[1]);
}
pub fn Vertex2fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.vertex2f(v[0], v[1]);
}
pub fn Vertex2iv(v: [*]const GLint) callconv(.winapi) void {
    state.vertex2i(v[0], v[1]);
}
pub fn Vertex2sv(v: [*]const GLshort) callconv(.winapi) void {
    state.vertex2s(v[0], v[1]);
}
pub fn Vertex3dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.vertex3d(v[0], v[1], v[2]);
}
pub fn Vertex3fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.vertex3f(v[0], v[1], v[2]);
}
pub fn Vertex3iv(v: [*]const GLint) callconv(.winapi) void {
    state.vertex3i(v[0], v[1], v[2]);
}
pub fn Vertex3sv(v: [*]const GLshort) callconv(.winapi) void {
    state.vertex3s(v[0], v[1], v[2]);
}
pub fn Vertex4dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.vertex4d(v[0], v[1], v[2], v[3]);
}
pub fn Vertex4fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.vertex4f(v[0], v[1], v[2], v[3]);
}
pub fn Vertex4iv(v: [*]const GLint) callconv(.winapi) void {
    state.vertex4i(v[0], v[1], v[2], v[3]);
}
pub fn Vertex4sv(v: [*]const GLshort) callconv(.winapi) void {
    state.vertex4s(v[0], v[1], v[2], v[3]);
}

// Texture coordinates

pub fn TexCoord1d(s: GLdouble) callconv(.winapi) void {
    state.texCoord1f(f(s));
}
pub fn TexCoord1dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.texCoord1f(f(v[0]));
}
pub fn TexCoord1fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.texCoord1f(v[0]);
}
pub fn TexCoord1i(s: GLint) callconv(.winapi) void {
    state.texCoord1f(fi(s));
}
pub fn TexCoord1iv(v: [*]const GLint) callconv(.winapi) void {
    state.texCoord1f(fi(v[0]));
}
pub fn TexCoord1s(s: GLshort) callconv(.winapi) void {
    state.texCoord1f(fi(s));
}
pub fn TexCoord1sv(v: [*]const GLshort) callconv(.winapi) void {
    state.texCoord1f(fi(v[0]));
}

pub fn TexCoord2d(s: GLdouble, t: GLdouble) callconv(.winapi) void {
    state.texCoord2f(f(s), f(t));
}
pub fn TexCoord2dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.texCoord2f(f(v[0]), f(v[1]));
}
pub fn TexCoord2fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.texCoord2f(v[0], v[1]);
}
pub fn TexCoord2i(s: GLint, t: GLint) callconv(.winapi) void {
    state.texCoord2f(fi(s), fi(t));
}
pub fn TexCoord2iv(v: [*]const GLint) callconv(.winapi) void {
    state.texCoord2f(fi(v[0]), fi(v[1]));
}
pub fn TexCoord2s(s: GLshort, t: GLshort) callconv(.winapi) void {
    state.texCoord2f(fi(s), fi(t));
}
pub fn TexCoord2sv(v: [*]const GLshort) callconv(.winapi) void {
    state.texCoord2f(fi(v[0]), fi(v[1]));
}

pub fn TexCoord3d(s: GLdouble, t: GLdouble, r: GLdouble) callconv(.winapi) void {
    state.texCoord3f(f(s), f(t), f(r));
}
pub fn TexCoord3dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.texCoord3f(f(v[0]), f(v[1]), f(v[2]));
}
pub fn TexCoord3fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.texCoord3f(v[0], v[1], v[2]);
}
pub fn TexCoord3i(s: GLint, t: GLint, r: GLint) callconv(.winapi) void {
    state.texCoord3f(fi(s), fi(t), fi(r));
}
pub fn TexCoord3iv(v: [*]const GLint) callconv(.winapi) void {
    state.texCoord3f(fi(v[0]), fi(v[1]), fi(v[2]));
}
pub fn TexCoord3s(s: GLshort, t: GLshort, r: GLshort) callconv(.winapi) void {
    state.texCoord3f(fi(s), fi(t), fi(r));
}
pub fn TexCoord3sv(v: [*]const GLshort) callconv(.winapi) void {
    state.texCoord3f(fi(v[0]), fi(v[1]), fi(v[2]));
}

pub fn TexCoord4d(s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble) callconv(.winapi) void {
    state.texCoord4f(f(s), f(t), f(r), f(q));
}
pub fn TexCoord4dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.texCoord4f(f(v[0]), f(v[1]), f(v[2]), f(v[3]));
}
pub fn TexCoord4fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.texCoord4f(v[0], v[1], v[2], v[3]);
}
pub fn TexCoord4i(s: GLint, t: GLint, r: GLint, q: GLint) callconv(.winapi) void {
    state.texCoord4f(fi(s), fi(t), fi(r), fi(q));
}
pub fn TexCoord4iv(v: [*]const GLint) callconv(.winapi) void {
    state.texCoord4f(fi(v[0]), fi(v[1]), fi(v[2]), fi(v[3]));
}
pub fn TexCoord4s(s: GLshort, t: GLshort, r: GLshort, q: GLshort) callconv(.winapi) void {
    state.texCoord4f(fi(s), fi(t), fi(r), fi(q));
}
pub fn TexCoord4sv(v: [*]const GLshort) callconv(.winapi) void {
    state.texCoord4f(fi(v[0]), fi(v[1]), fi(v[2]), fi(v[3]));
}

pub fn EdgeFlagv(v: [*]const GLboolean) callconv(.winapi) void {
    state.edgeFlag(v[0]);
}

// Raster position

pub fn RasterPos2d(x: GLdouble, y: GLdouble) callconv(.winapi) void {
    state.rasterPos2f(f(x), f(y));
}
pub fn RasterPos2dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.rasterPos2f(f(v[0]), f(v[1]));
}
pub fn RasterPos2fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.rasterPos2f(v[0], v[1]);
}
pub fn RasterPos2i(x: GLint, y: GLint) callconv(.winapi) void {
    state.rasterPos2f(fi(x), fi(y));
}
pub fn RasterPos2iv(v: [*]const GLint) callconv(.winapi) void {
    state.rasterPos2f(fi(v[0]), fi(v[1]));
}
pub fn RasterPos2s(x: GLshort, y: GLshort) callconv(.winapi) void {
    state.rasterPos2f(fi(x), fi(y));
}
pub fn RasterPos2sv(v: [*]const GLshort) callconv(.winapi) void {
    state.rasterPos2f(fi(v[0]), fi(v[1]));
}
pub fn RasterPos3d(x: GLdouble, y: GLdouble, z: GLdouble) callconv(.winapi) void {
    state.rasterPos3f(f(x), f(y), f(z));
}
pub fn RasterPos3dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.rasterPos3f(f(v[0]), f(v[1]), f(v[2]));
}
pub fn RasterPos3fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.rasterPos3f(v[0], v[1], v[2]);
}
pub fn RasterPos3i(x: GLint, y: GLint, z: GLint) callconv(.winapi) void {
    state.rasterPos3f(fi(x), fi(y), fi(z));
}
pub fn RasterPos3iv(v: [*]const GLint) callconv(.winapi) void {
    state.rasterPos3f(fi(v[0]), fi(v[1]), fi(v[2]));
}
pub fn RasterPos3s(x: GLshort, y: GLshort, z: GLshort) callconv(.winapi) void {
    state.rasterPos3f(fi(x), fi(y), fi(z));
}
pub fn RasterPos3sv(v: [*]const GLshort) callconv(.winapi) void {
    state.rasterPos3f(fi(v[0]), fi(v[1]), fi(v[2]));
}
pub fn RasterPos4d(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble) callconv(.winapi) void {
    state.rasterPos4f(f(x), f(y), f(z), f(w));
}
pub fn RasterPos4dv(v: [*]const GLdouble) callconv(.winapi) void {
    state.rasterPos4f(f(v[0]), f(v[1]), f(v[2]), f(v[3]));
}
pub fn RasterPos4fv(v: [*]const GLfloat) callconv(.winapi) void {
    state.rasterPos4f(v[0], v[1], v[2], v[3]);
}
pub fn RasterPos4i(x: GLint, y: GLint, z: GLint, w: GLint) callconv(.winapi) void {
    state.rasterPos4f(fi(x), fi(y), fi(z), fi(w));
}
pub fn RasterPos4iv(v: [*]const GLint) callconv(.winapi) void {
    state.rasterPos4f(fi(v[0]), fi(v[1]), fi(v[2]), fi(v[3]));
}
pub fn RasterPos4s(x: GLshort, y: GLshort, z: GLshort, w: GLshort) callconv(.winapi) void {
    state.rasterPos4f(fi(x), fi(y), fi(z), fi(w));
}
pub fn RasterPos4sv(v: [*]const GLshort) callconv(.winapi) void {
    state.rasterPos4f(fi(v[0]), fi(v[1]), fi(v[2]), fi(v[3]));
}

// Rectangles

pub fn Rectd(x1: GLdouble, y1: GLdouble, x2: GLdouble, y2: GLdouble) callconv(.winapi) void {
    state.rectf(f(x1), f(y1), f(x2), f(y2));
}
pub fn Rectdv(v1: [*]const GLdouble, v2: [*]const GLdouble) callconv(.winapi) void {
    state.rectf(f(v1[0]), f(v1[1]), f(v2[0]), f(v2[1]));
}
pub fn Rectfv(v1: [*]const GLfloat, v2: [*]const GLfloat) callconv(.winapi) void {
    state.rectf(v1[0], v1[1], v2[0], v2[1]);
}
pub fn Rectiv(v1: [*]const GLint, v2: [*]const GLint) callconv(.winapi) void {
    state.recti(v1[0], v1[1], v2[0], v2[1]);
}
pub fn Rects(x1: GLshort, y1: GLshort, x2: GLshort, y2: GLshort) callconv(.winapi) void {
    state.rectf(fi(x1), fi(y1), fi(x2), fi(y2));
}
pub fn Rectsv(v1: [*]const GLshort, v2: [*]const GLshort) callconv(.winapi) void {
    state.rectf(fi(v1[0]), fi(v1[1]), fi(v2[0]), fi(v2[1]));
}

// Colour indices

pub fn Indexd(index: GLdouble) callconv(.winapi) void {
    state.indexf(f(index));
}
pub fn Indexdv(index: [*]const GLdouble) callconv(.winapi) void {
    state.indexf(f(index[0]));
}
pub fn Indexfv(index: [*]const GLfloat) callconv(.winapi) void {
    state.indexf(index[0]);
}
pub fn Indexiv(index: [*]const GLint) callconv(.winapi) void {
    state.indexi(index[0]);
}
pub fn Indexs(index: GLshort) callconv(.winapi) void {
    state.indexf(fi(index));
}
pub fn Indexsv(index: [*]const GLshort) callconv(.winapi) void {
    state.indexf(fi(index[0]));
}
pub fn Indexub(index: GLubyte) callconv(.winapi) void {
    state.indexf(fi(index) / 255.0);
}
pub fn Indexubv(index: [*]const GLubyte) callconv(.winapi) void {
    state.indexf(fi(index[0]) / 255.0);
}

// Matrices

pub fn Translatef(x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state.translate(x, y, z);
}
pub fn Translated(x: GLdouble, y: GLdouble, z: GLdouble) callconv(.winapi) void {
    state.translate(f(x), f(y), f(z));
}
pub fn Rotatef(angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state.rotate(angle, x, y, z);
}
pub fn Rotated(angle: GLdouble, x: GLdouble, y: GLdouble, z: GLdouble) callconv(.winapi) void {
    state.rotate(f(angle), f(x), f(y), f(z));
}
pub fn Scalef(x: GLfloat, y: GLfloat, z: GLfloat) callconv(.winapi) void {
    state.scale(x, y, z);
}
pub fn Scaled(x: GLdouble, y: GLdouble, z: GLdouble) callconv(.winapi) void {
    state.scale(f(x), f(y), f(z));
}
pub fn LoadMatrixf(m: [*]const GLfloat) callconv(.winapi) void {
    state.loadMatrix(m);
}
pub fn LoadMatrixd(m: [*]const GLdouble) callconv(.winapi) void {
    var temp: [16]f32 = undefined;
    for (&temp, 0..) |*slot, i| slot.* = f(m[i]);
    state.loadMatrix(&temp);
}
pub fn MultMatrixf(m: [*]const GLfloat) callconv(.winapi) void {
    state.multMatrix(m);
}
pub fn MultMatrixd(m: [*]const GLdouble) callconv(.winapi) void {
    var temp: [16]f32 = undefined;
    for (&temp, 0..) |*slot, i| slot.* = f(m[i]);
    state.multMatrix(&temp);
}

// Fog, lighting and materials

pub fn Fogiv(pname: GLenum, params: [*]const GLint) callconv(.winapi) void {
    var values = [4]f32{ fi(params[0]), fi(params[1]), fi(params[2]), fi(params[3]) };
    state.fog(pname, &values);
}
pub fn Lightiv(light: GLenum, pname: GLenum, params: [*]const GLint) callconv(.winapi) void {
    var values = [4]f32{ fi(params[0]), fi(params[1]), fi(params[2]), fi(params[3]) };
    state.light(lightIndex(light), pname, &values);
}
pub fn LightModeliv(pname: GLenum, params: [*]const GLint) callconv(.winapi) void {
    var values = [4]f32{ fi(params[0]), fi(params[1]), fi(params[2]), fi(params[3]) };
    state.lightModel(pname, &values);
}
pub fn Materialiv(face: GLenum, pname: GLenum, params: [*]const GLint) callconv(.winapi) void {
    var values = [4]f32{ fi(params[0]), fi(params[1]), fi(params[2]), fi(params[3]) };
    state.lightMaterial(face, pname, &values);
}

// Texture parameters and coordinate generation

pub fn TexParameterfv(target: GLenum, pname: GLenum, params: [*]const GLfloat) callconv(.winapi) void {
    state.texParameterf(target, pname, params[0]);
}
pub fn TexParameteriv(target: GLenum, pname: GLenum, params: [*]const GLint) callconv(.winapi) void {
    state.texParameteri(target, pname, params[0]);
}
pub fn TexGend(coord: GLenum, pname: GLenum, param: GLdouble) callconv(.winapi) void {
    state.texGen(coord, pname, f(param));
}
pub fn TexGendv(coord: GLenum, pname: GLenum, params: [*]const GLdouble) callconv(.winapi) void {
    if (pname == gl.TEXTURE_GEN_MODE) {
        state.texGen(coord, pname, f(params[0]));
    } else {
        var values = [4]f32{ f(params[0]), f(params[1]), f(params[2]), f(params[3]) };
        state.texGenfv(coord, pname, &values);
    }
}
pub fn TexGenf(coord: GLenum, pname: GLenum, param: GLfloat) callconv(.winapi) void {
    state.texGen(coord, pname, param);
}
pub fn TexGenfv(coord: GLenum, pname: GLenum, params: [*]const GLfloat) callconv(.winapi) void {
    state.texGenfv(coord, pname, params);
}
pub fn TexGeni(coord: GLenum, pname: GLenum, param: GLint) callconv(.winapi) void {
    state.texGen(coord, pname, fi(param));
}
pub fn TexGeniv(coord: GLenum, pname: GLenum, params: [*]const GLint) callconv(.winapi) void {
    if (pname == gl.TEXTURE_GEN_MODE) {
        state.texGen(coord, pname, fi(params[0]));
    } else {
        var values = [4]f32{ fi(params[0]), fi(params[1]), fi(params[2]), fi(params[3]) };
        state.texGenfv(coord, pname, &values);
    }
}

// Pixel maps

pub fn PixelMapfv(pname: GLenum, size: GLint, values: [*]const GLfloat) callconv(.winapi) void {
    state.pixelMapf(pname, size, values);
}
pub fn PixelMapuiv(pname: GLenum, size: GLint, values: [*]const GLuint) callconv(.winapi) void {
    var temp: [256]i32 = undefined;
    const n: usize = if (size < 0 or size > temp.len) temp.len else @intCast(size);
    for (0..n) |i| temp[i] = @bitCast(values[i]);
    state.pixelMapi(pname, size, &temp);
}
pub fn PixelMapusv(pname: GLenum, size: GLint, values: [*]const GLushort) callconv(.winapi) void {
    var temp: [256]i32 = undefined;
    const n: usize = if (size < 0 or size > temp.len) temp.len else @intCast(size);
    for (0..n) |i| temp[i] = values[i];
    state.pixelMapi(pname, size, &temp);
}

// Rasterization state

pub fn CullFace(mode: GLenum) callconv(.winapi) void {
    state.cullFace(mode);
}
pub fn StencilFunc(func: GLenum, ref: GLint, mask: GLuint) callconv(.winapi) void {
    state.stencilFunc(func, ref, mask);
}
pub fn StencilOp(fail: GLenum, zfail: GLenum, zpass: GLenum) callconv(.winapi) void {
    state.stencilOp(fail, zfail, zpass);
}
pub fn Hint(target: GLenum, mode: GLenum) callconv(.winapi) void {
    state.hint(target, mode);
}
pub fn PolygonOffset(factor: GLfloat, units: GLfloat) callconv(.winapi) void {
    state.polygonOffset(factor, units);
}

// Display lists

pub fn GenLists(range: GLsizei) callconv(.winapi) GLuint {
    return state.genLists(range);
}
pub fn DeleteLists(list: GLuint, range: GLsizei) callconv(.winapi) void {
    state.deleteLists(list, range);
}
pub fn ListBase(base: GLuint) callconv(.winapi) void {
    state.listBase(base);
}
pub fn CallLists(n: GLsizei, type_: GLenum, lists: ?*const anyopaque) callconv(.winapi) void {
    state.callLists(n, type_, lists);
}

// Selection names

pub fn InitNames() callconv(.winapi) void {
    state.initNames();
}
pub fn PushName(name: GLuint) callconv(.winapi) void {
    state.pushName(name);
}
pub fn PopName() callconv(.winapi) void {
    state.popName();
}
pub fn LoadName(name: GLuint) callconv(.winapi) void {
    state.loadName(name);
}

pub fn Accum(op: GLenum, value: GLfloat) callconv(.winapi) void {
    _ = op;
    _ = value;
}
pub fn ClearAccum(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat) callconv(.winapi) void {
    _ = r;
    _ = g;
    _ = b;
    _ = a;
}
pub fn Bitmap(width: GLsizei, height: GLsizei, xorig: GLfloat, yorig: GLfloat, xmove: GLfloat, ymove: GLfloat, bitmap: ?[*]const GLubyte) callconv(.winapi) void {
    _ = width;
    _ = height;
    _ = xorig;
    _ = yorig;
    _ = xmove;
    _ = ymove;
    _ = bitmap;
}
pub fn PassThrough(token: GLfloat) callconv(.winapi) void {
    _ = token;
}

// Evaluators

pub fn Map1d(target: GLenum, u_start: GLdouble, u_end: GLdouble, stride: GLint, order: GLint, points: [*]const GLdouble) callconv(.winapi) void {
    _ = target;
    _ = u_start;
    _ = u_end;
    _ = stride;
    _ = order;
    _ = points;
}
pub fn Map1f(target: GLenum, u_start: GLfloat, u_end: GLfloat, stride: GLint, order: GLint, points: [*]const GLfloat) callconv(.winapi) void {
    _ = target;
    _ = u_start;
    _ = u_end;
    _ = stride;
    _ = order;
    _ = points;
}
pub fn Map2d(target: GLenum, u_start: GLdouble, u_end: GLdouble, ustride: GLint, uorder: GLint, v_start: GLdouble, v_end: GLdouble, vstride: GLint, vorder: GLint, points: [*]const GLdouble) callconv(.winapi) void {
    _ = target;
    _ = u_start;
    _ = u_end;
    _ = ustride;
    _ = uorder;
    _ = v_start;
    _ = v_end;
    _ = vstride;
    _ = vorder;
    _ = points;
}
pub fn Map2f(target: GLenum, u_start: GLfloat, u_end: GLfloat, ustride: GLint, uorder: GLint, v_start: GLfloat, v_end: GLfloat, vstride: GLint, vorder: GLint, points: [*]const GLfloat) callconv(.winapi) void {
    _ = target;
    _ = u_start;
    _ = u_end;
    _ = ustride;
    _ = uorder;
    _ = v_start;
    _ = v_end;
    _ = vstride;
    _ = vorder;
    _ = points;
}
pub fn MapGrid1d(un: GLint, u_start: GLdouble, u_end: GLdouble) callconv(.winapi) void {
    _ = un;
    _ = u_start;
    _ = u_end;
}
pub fn MapGrid1f(un: GLint, u_start: GLfloat, u_end: GLfloat) callconv(.winapi) void {
    _ = un;
    _ = u_start;
    _ = u_end;
}
pub fn MapGrid2d(un: GLint, u_start: GLdouble, u_end: GLdouble, vn: GLint, v_start: GLdouble, v_end: GLdouble) callconv(.winapi) void {
    _ = un;
    _ = u_start;
    _ = u_end;
    _ = vn;
    _ = v_start;
    _ = v_end;
}
pub fn MapGrid2f(un: GLint, u_start: GLfloat, u_end: GLfloat, vn: GLint, v_start: GLfloat, v_end: GLfloat) callconv(.winapi) void {
    _ = un;
    _ = u_start;
    _ = u_end;
    _ = vn;
    _ = v_start;
    _ = v_end;
}
pub fn EvalCoord1d(u: GLdouble) callconv(.winapi) void {
    _ = u;
}
pub fn EvalCoord1dv(u: [*]const GLdouble) callconv(.winapi) void {
    _ = u;
}
pub fn EvalCoord1f(u: GLfloat) callconv(.winapi) void {
    _ = u;
}
pub fn EvalCoord1fv(u: [*]const GLfloat) callconv(.winapi) void {
    _ = u;
}
pub fn EvalCoord2d(u: GLdouble, v: GLdouble) callconv(.winapi) void {
    _ = u;
    _ = v;
}
pub fn EvalCoord2dv(u: [*]const GLdouble) callconv(.winapi) void {
    _ = u;
}
pub fn EvalCoord2f(u: GLfloat, v: GLfloat) callconv(.winapi) void {
    _ = u;
    _ = v;
}
pub fn EvalCoord2fv(u: [*]const GLfloat) callconv(.winapi) void {
    _ = u;
}
pub fn EvalMesh1(mode: GLenum, i_start: GLint, i_end: GLint) callconv(.winapi) void {
    _ = mode;
    _ = i_start;
    _ = i_end;
}
pub fn EvalMesh2(mode: GLenum, i_start: GLint, i_end: GLint, j_start: GLint, j_end: GLint) callconv(.winapi) void {
    _ = mode;
    _ = i_start;
    _ = i_end;
    _ = j_start;
    _ = j_end;
}
pub fn EvalPoint2(i: GLint, j: GLint) callconv(.winapi) void {
    _ = i;
    _ = j;
}

// Queries

pub fn GetMapdv(target: GLenum, query: GLenum, v: [*]GLdouble) callconv(.winapi) void {
    _ = target;
    _ = query;
    v[0] = 0;
}
pub fn GetMapfv(target: GLenum, query: GLenum, v: [*]GLfloat) callconv(.winapi) void {
    _ = target;
    _ = query;
    v[0] = 0;
}
pub fn GetMapiv(target: GLenum, query: GLenum, v: [*]GLint) callconv(.winapi) void {
    _ = target;
    _ = query;
    v[0] = 0;
}
pub fn GetPixelMapfv(pname: GLenum, values: [*]GLfloat) callconv(.winapi) void {
    _ = pname;
    values[0] = 0;
}
pub fn GetPixelMapuiv(pname: GLenum, values: [*]GLuint) callconv(.winapi) void {
    _ = pname;
    values[0] = 0;
}
pub fn GetPixelMapusv(pname: GLenum, values: [*]GLushort) callconv(.winapi) void {
    _ = pname;
    values[0] = 0;
}
pub fn GetPolygonStipple(mask: [*]GLubyte) callconv(.winapi) void {
    _ = mask;
}
pub fn GetLevelParameterfv(target: GLenum, level: GLint, pname: GLenum, params: [*]GLfloat) callconv(.winapi) void {
    _ = target;
    _ = level;
    _ = pname;
    params[0] = 0;
}
pub fn GetLevelParameteriv(target: GLenum, level: GLint, pname: GLenum, params: [*]GLint) callconv(.winapi) void {
    _ = target;
    _ = level;
    _ = pname;
    params[0] = 0;
}

pub fn GetTexLevelParameterfv(target: GLenum, level: GLint, pname: GLenum, params: [*]GLfloat) callconv(.winapi) void {
    _ = target;
    _ = level;
    _ = pname;
    params[0] = 0;
}
pub fn GetTexLevelParameteriv(target: GLenum, level: GLint, pname: GLenum, params: [*]GLint) callconv(.winapi) void {
    state.getTexLevelParameteriv(target, level, pname, params);
}
pub fn GetTexGendv(coord: GLenum, pname: GLenum, params: [*]GLdouble) callconv(.winapi) void {
    var values = [4]f32{ 0, 0, 0, 0 };
    state.getTexGenfv(coord, pname, &values);
    for (0..4) |i| params[i] = values[i];
}
pub fn GetTexImage(target: GLenum, level: GLint, format: GLenum, type_: GLenum, pixels: ?*anyopaque) callconv(.winapi) void {
    state.getTexImage(target, level, format, type_, pixels);
}
pub fn GetTexParameterfv(target: GLenum, pname: GLenum, params: [*]GLfloat) callconv(.winapi) void {
    _ = target;
    params[0] = switch (pname) {
        gl.TEXTURE_MAG_FILTER => @floatFromInt(gl.LINEAR),
        gl.TEXTURE_MIN_FILTER => @floatFromInt(gl.NEAREST_MIPMAP_LINEAR),
        gl.TEXTURE_WRAP_S, gl.TEXTURE_WRAP_T => @floatFromInt(gl.REPEAT),
        gl.TEXTURE_PRIORITY => 1,
        else => 0,
    };
}
pub fn GetTexParameteriv(target: GLenum, pname: GLenum, params: [*]GLint) callconv(.winapi) void {
    _ = target;
    params[0] = switch (pname) {
        gl.TEXTURE_MAG_FILTER => @intCast(gl.LINEAR),
        gl.TEXTURE_MIN_FILTER => @intCast(gl.NEAREST_MIPMAP_LINEAR),
        gl.TEXTURE_WRAP_S, gl.TEXTURE_WRAP_T => @intCast(gl.REPEAT),
        gl.TEXTURE_PRIORITY => 1,
        else => 0,
    };
}
