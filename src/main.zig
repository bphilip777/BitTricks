const std = @import("std");
const testing = std.testing;

const CHAR_BIT: u8 = 8;

pub fn sign(comptime T: type, x: T) i8 {
    switch (@typeInfo(T)) {
        .int, .float => {},
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }

    if (@typeInfo(T).int.signedness == .unsigned) return 0;

    return @as(i8, @intFromBool(x > 0)) - @as(i8, @intFromBool(x < 0));
}

test "Sign" {
    const inputs = [_]i32{ 100, -100, 0 };
    const expected_answers = [_]i8{ 1, -1, 0 };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = sign(i32, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn isOppSign(comptime T: type, x: T, y: T) bool {
    switch (@typeInfo(T)) {
        .int, .float => {},
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }
    return (x ^ y) < 0;
}

test "Is Opp Sign" {
    const input_xs = [_]i32{ 100, 100, -50, -100 };
    const input_ys = [_]i32{ 50, -50, 100, -50 };
    const expected_answers = [_]bool{ false, true, true, false };
    for (input_xs, input_ys, expected_answers) |x, y, expected_answer| {
        const answer = isOppSign(i32, x, y);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn absWOBranching(comptime T: type, x: T) T {
    switch (@typeInfo(T)) {
        .int => |int| {
            if (int.signedness == .unsigned) return x;
        },
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }
    const mask = x >> @sizeOf(T) * CHAR_BIT - 1;
    return (x + mask) ^ mask;
}

test "Abs w/o branching" {
    const inputs = [_]i32{ 100, 0, -100 };
    const expected_answers = [_]i32{ 100, 0, 100 };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = absWOBranching(i32, input);
        try std.testing.expect(expected_answer == answer);
    }
}

pub fn minBranchless(comptime T: type, x: T, y: T) T {
    switch (@typeInfo(T)) {
        .int, .float => {},
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }
    return y ^ ((x ^ y) & -@as(T, @intFromBool(x < y)));
}

test "Min Branchless" {
    const input_xs = [_]i32{ 100, -100 };
    const input_ys = [_]i32{ -100, 100 };
    const expected_answers = [_]i32{ -100, -100 };
    for (input_xs, input_ys, expected_answers) |x, y, expected_answer| {
        const answer = minBranchless(i32, x, y);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn maxBranchless(comptime T: type, x: T, y: T) T {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }
    return x ^ ((x ^ y) & -@as(T, @intFromBool(x < y)));
}

test "Max Branchless" {
    const input_xs = [_]i32{ 100, -100 };
    const input_ys = [_]i32{ -100, 100 };
    const expected_answers = [_]i32{ 100, 100 };
    for (input_xs, input_ys, expected_answers) |x, y, expected_answer| {
        const answer = maxBranchless(i32, x, y);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn isPow2(comptime T: type, x: T) bool {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }
    return (x > 0) and (x & (x -% 1)) == 0;
}

test "Is Power of 2" {
    const inputs = [_]u64{ 100, 128, 50 };
    const expected_answers = [_]bool{ false, true, false };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = isPow2(u64, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn getMaxBits(comptime T: type) T {
    switch (@typeInfo(T)) {
        .int => |int| {
            const n_bits: u16 = int.bits; // u16
            return if (@typeInfo(@TypeOf(n_bits)).int.bits > n_bits) @as(T, @truncate(n_bits)) else @as(T, n_bits);
        },
        .float => |float| {
            const n_bits: u16 = float.bits; // u16
            return if (@typeInfo(@TypeOf(n_bits)).int.bits > n_bits) @as(T, @truncate(n_bits)) else @as(T, @floatFromInt(n_bits));
        },
        .bool => return 1,
        else => @compileError("Fn only accepts ints/floats/bools"),
    }
}

test "Get Max Bits" {
    const expected_answer: u16 = 32;
    const answer = getMaxBits(i32);
    try std.testing.expect(expected_answer == answer);
}

pub fn setBitsConditional(comptime T: type, f: bool, m: T, w: T) T {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Incorrect input type. Fn only accepts unsigned ints."),
    }
    return (w & ~m) | (@as(T, @intFromBool(!f)) & m);
}

pub fn mergeBitsFrom2Values(comptime T: type, a: T, b: T, m: T) T {
    // a = value to merge in non-masked bits
    // b = value to merge in masked bits
    // m = 1 where bits come from b, 0 where bits come from a
    switch (@typeInfo(T)) {
        .int => |int| {
            switch (int.signedness) {
                .unsigned => {},
                else => @compileError("Fn Accepts only unsigned ints."),
            }
        },
        else => @compileError("Fn accepts only unsigned ints."),
    }
    return a ^ ((a ^ b) & m);
}

pub fn countBits(comptime T: type, v: T) T {
    // Brian Kernighan's way
    switch (@typeInfo(T)) {
        .int => |int| {
            switch (int.signedness) {
                .unsigned => {},
                .signed => @compileError("Fn only accepts unsigned int."),
            }
        },
        else => @compileError("Fn only accepts unsigned int."),
    }

    var c: T = 0;
    var v1: T = v;
    while (v1 > 0) : (c += 1) {
        v1 &= v1 - 1;
    }
    return c;
}

test "Count Bits" {
    const inputs = [_]u16{ 65535, 255 };
    const expected_answers = [_]u16{ 16, 8 };

    for (inputs, expected_answers) |input, expected_answer| {
        const answer = countBits(u16, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn reverse(comptime T: type, x: T) T {
    switch (@typeInfo(T)) {
        .int => |int| {
            switch (int.signedness) {
                .unsigned => {},
                .signed => @compileError("Incorrect Type - fn only accepts unsigned ints."),
            }
        },
        else => @compileError("Incorrect Type - fn only accepts unsigned ints."),
    }

    const max_bits = @typeInfo(T).int.bits;
    var y = x;
    var r = x;
    for (0..max_bits) |_| {
        r <<= 1;
        r |= y & 1;
        y >>= 1;
    }
    return r;
}

test "Reverse" {
    const inputs = [_]u16{ 1 << 15, 1 << 0 };
    const expected_answers = [_]u16{ 1 << 0, 1 << 15 };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = reverse(u16, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn swapXOR(comptime T: type, a: *T, b: *T) void {
    a.* ^= b.*;
    b.* ^= a.*;
    a.* ^= b.*;
}

test "Swap XOR" {
    var a: i32 = 100;
    var b: i32 = 50;
    swapXOR(i32, &a, &b);
    try std.testing.expect(a == 50 and b == 100);
}

pub fn turnOnBitsBW2Bits(
    comptime T: type,
    value: T,
    prev_carry: bool,
) struct { mask: T, carry: bool } {
    switch (@typeInfo(T)) {
        .int => |int| switch (int.signedness) {
            .signed => @compileError("T must be an unsigned int"),
            else => {},
        },
        else => @compileError("T must be an unsigned int"),
    }

    var temp: T = @bitReverse(value);
    var mask: T = value;

    const max_bit: T = @bitSizeOf(T);

    if (prev_carry) {
        const first_bit = @ctz(temp);
        temp ^= @as(T, 1) << @truncate(first_bit);
        for (0..first_bit) |i| {
            mask |= @as(T, 1) << @truncate(max_bit - i - 1);
        }
    }

    var carry: bool = false;
    while (temp > 0) {
        const first_bit = @ctz(temp);
        temp ^= @as(T, 1) << @truncate(first_bit);

        const second_bit = @ctz(temp);
        if (second_bit == max_bit) {
            carry = true;
        } else {
            temp ^= @as(T, 1) << @truncate(second_bit);
        }

        for (first_bit..second_bit) |i| {
            mask |= @as(T, 1) << @truncate(max_bit - i - 1);
        }
    }

    return .{
        .mask = mask,
        .carry = carry,
    };
}

test "turnOnBitsBW2Bits" {
    const T: type = u8;
    const input_masks = [_]T{ 8, 66, 66, 74, 0, 255, 255 };
    const input_carries = [_]bool{ false, false, true, true, true, false, true };
    const expected_masks = [_]T{ 15, 126, 195, 206, 255, 255, 255 };
    const expected_carries = [_]bool{ true, false, true, false, true, false, true };

    for (input_masks, input_carries, expected_masks, expected_carries, 0..) |imask, icarry, emask, ecarry, i| {
        _ = i;
        const mask, const carry = blk: {
            const mask = turnOnBitsBW2Bits(T, imask, icarry);
            break :blk .{ mask.mask, mask.carry };
        };
        try std.testing.expect(mask == emask and carry == ecarry);
    }

    try std.testing.expect(true);
}

fn doubleType(comptime T: type) type {
    switch (@typeInfo(T)) {
        .int => |int| {
            switch (int.signedness) {
                .unsigned => {
                    return @Type(.{ .int = .{ .bits = @typeInfo(T).int.bits * 2, .signedness = .unsigned } });
                },
                .signed => @compileError("Incorrect Type - fn only takes unsigned int."),
            }
        },
        else => @compileError("Incorrect Type - fn only takes unsigned int."),
    }
}

// returns a type at double the size
pub fn interleave(comptime T: type, x: T, y: T) doubleType(T) {
    // interleave bits of x and y, x is even positions, y is odd positions
    const max_bits = @typeInfo(T).int.bits;
    const T2: type = doubleType(T);

    var z: T2 = 0;
    for (0..max_bits) |i| {
        z |= (x & @as(T, 1) << @truncate(i)) << @truncate(i) | (y & @as(T, 1) << @truncate(i)) << @truncate(i + 1);
    }

    return z;
}

test "Interleave" {
    const x_inputs = [_]u16{ 1, 7, 5 };
    const y_inputs = [_]u16{ 1, 7, 3 };
    const expected_answers = [_]u16{ 3, 63, 27 };
    for (x_inputs, y_inputs, expected_answers) |x, y, expected_answer| {
        const answer = interleave(u16, x, y);
        try std.testing.expect(answer == expected_answer);
        try std.testing.expect(@TypeOf(answer) == u32);
    }
}
