//! error.zig
//! OpenGL error handling

const std = @import("std");

/// The codes reported by GetError.
pub const ErrorCode = enum(u32) {
    no_error = 0x00000000,
    invalid_enum = 0x00000500,
    invalid_value = 0x00000501,
    invalid_operation = 0x00000502,
    stack_overflow = 0x00000503,
    stack_underflow = 0x00000504,
    out_of_memory = 0x00000505,
};

/// Records the most recently detected error.
pub const ErrorHandler = struct {
    pending: ?ErrorCode = null,

    /// Returns the pending error (if any) and clears it.
    pub fn get(self: *ErrorHandler) ErrorCode {
        const pending = self.pending orelse return .no_error;
        self.pending = null;
        return pending;
    }

    /// Records an error; does not clear a previously pending error.
    pub fn set(self: *ErrorHandler, code: ErrorCode) void {
        self.pending = code;
    }

    /// Discards any pending error.
    pub fn clear(self: *ErrorHandler) void {
        self.pending = null;
    }
};

/// The error handler of the current context.
pub var gErrorHandler = ErrorHandler{};
