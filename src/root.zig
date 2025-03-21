const std = @import("std");
const testing = std.testing;

const CHAR_BIT = 8; // # of bits per byte - assume 8

export fn sign(comptime T: type, x: T) T {
    switch (@typeInfo(@TypeOf(T))) {
        .int => {},
        else => @compileError("Incorrect type"),
    }

    if (@typeInfo(@TypeOf(T)).int.signedness == .unsigned) return 0;

    return (x > 0) - (x < 0);
}

test "sign" {}

export fn isOppSign(comptime T: type, x: T, y: T) bool {
    return (x ^ y) < 0;
}

export fn intAbs(comptime T: type, x: T) T {
    const mask = v >> @sizeOf(v) - CHAR_BIT;
    return (x + mask) ^ mask;
}

export fn minBranchless(comptime T: type, x: T, y: T) T {
    return y ^ ((x ^ y) & -(x < y));
}

export fn maxBranchless(comptime T: type, x: T, y: T) T {
    return x ^ ((x ^ y) & -(x < y));
}

// unsigned int
export fn isPow2(comptime T: type, x: T) bool {
    return v and !(v & (v -% 1));
}

export fn reverse(comptime T: type, x: T) T {}

test "Reverse Bits" {}
