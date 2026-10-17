//! math.zig
//! Matrix arithmetic for the emulation.

const std = @import("std");

pub const Mat4 = struct {
    m: [16]f32 = identity.m,

    pub const identity = Mat4{ .m = .{
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    } };

    /// Builds a column-major matrix from a row-major one.
    pub fn fromRowMajor(rm: [16]f32) Mat4 {
        var r: Mat4 = undefined;
        var row: usize = 0;
        while (row < 4) : (row += 1) {
            var col: usize = 0;
            while (col < 4) : (col += 1) {
                r.m[col * 4 + row] = rm[row * 4 + col];
            }
        }
        return r;
    }

    /// Returns the product `a * b`.
    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var r: Mat4 = undefined;
        var col: usize = 0;
        while (col < 4) : (col += 1) {
            var row: usize = 0;
            while (row < 4) : (row += 1) {
                r.m[col * 4 + row] = a.m[0 * 4 + row] * b.m[col * 4 + 0] +
                    a.m[1 * 4 + row] * b.m[col * 4 + 1] +
                    a.m[2 * 4 + row] * b.m[col * 4 + 2] +
                    a.m[3 * 4 + row] * b.m[col * 4 + 3];
            }
        }
        return r;
    }

    pub fn translation(x: f32, y: f32, z: f32) Mat4 {
        return fromRowMajor(.{
            1, 0, 0, x,
            0, 1, 0, y,
            0, 0, 1, z,
            0, 0, 0, 1,
        });
    }

    pub fn scaling(x: f32, y: f32, z: f32) Mat4 {
        return fromRowMajor(.{
            x, 0, 0, 0,
            0, y, 0, 0,
            0, 0, z, 0,
            0, 0, 0, 1,
        });
    }

    pub fn rotation(angle_degrees: f32, x: f32, y: f32, z: f32) Mat4 {
        const a = angle_degrees * std.math.pi / 180.0;
        const c = @cos(a);
        const s = @sin(a);

        const length = @sqrt(x * x + y * y + z * z);
        if (length == 0.0) {
            return Mat4.identity;
        }
        const nx = x / length;
        const ny = y / length;
        const nz = z / length;
        const nc = 1.0 - c;

        return fromRowMajor(.{
            nx * nx * nc + c,      nx * ny * nc - nz * s, nx * nz * nc + ny * s, 0,
            ny * nx * nc + nz * s, ny * ny * nc + c,      ny * nz * nc - nx * s, 0,
            nz * nx * nc - ny * s, nz * ny * nc + nx * s, nz * nz * nc + c,      0,
            0,                     0,                     0,                     1,
        });
    }

    pub fn frustum(left: f64, right: f64, bottom: f64, top: f64, near: f64, far: f64) Mat4 {
        const a = (right + left) / (right - left);
        const b = (top + bottom) / (top - bottom);
        const c = -(far + near) / (far - near);
        const d = -(2.0 * far * near) / (far - near);
        return fromRowMajor(.{
            @floatCast(2.0 * near / (right - left)), 0,                                       0,             0,
            0,                                       @floatCast(2.0 * near / (top - bottom)), 0,             0,
            @floatCast(a),                           @floatCast(b),                           @floatCast(c), @floatCast(d),
            0,                                       0,                                       -1,            0,
        });
    }

    pub fn ortho(left: f64, right: f64, bottom: f64, top: f64, near: f64, far: f64) Mat4 {
        const tx = -(right + left) / (right - left);
        const ty = -(top + bottom) / (top - bottom);
        const tz = -(far + near) / (far - near);
        return fromRowMajor(.{
            @floatCast(2.0 / (right - left)), 0,                                0,                               @as(f32, @floatCast(tx)),
            0,                                @floatCast(2.0 / (top - bottom)), 0,                               @as(f32, @floatCast(ty)),
            0,                                0,                                @floatCast(-2.0 / (far - near)), @as(f32, @floatCast(tz)),
            0,                                0,                                0,                               1,
        });
    }

    /// The upper-left 3x3 of the matrix
    pub fn upperLeft3(self: Mat4) Mat4 {
        return .{ .m = .{
            self.m[0], self.m[1], self.m[2],  0,
            self.m[4], self.m[5], self.m[6],  0,
            self.m[8], self.m[9], self.m[10], 0,
            0,         0,         0,          1,
        } };
    }
};
