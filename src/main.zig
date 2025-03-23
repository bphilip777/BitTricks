const std = @import("std");
const testing = std.testing;

const CHAR_BIT: u8 = 8;

pub fn sign(comptime T: type, x: T) i8 {
    switch (@typeInfo(T)) {
        .int, .float => {},
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }

    if (@typeInfo(@TypeOf(T)).int.signedness == .unsigned) return 0;

    return @as(i8, x > 0) - @as(i8, x < 0);
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
    const expected_answers = [_]i32{ false, true, true, false };
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
    const mask = x >> @sizeOf(x) * CHAR_BIT - 1;
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
    return y ^ ((x ^ y) & -(x < y));
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
    return x ^ ((x ^ y) & -(x < y));
}

test "Max Branchless" {
    const input_xs = [_]i32{ 100, -100 };
    const input_ys = [_]i32{ -100, 100 };
    const expected_answers = [_]i32{ 100, 100 };
    for (input_xs, input_ys, expected_answers) |x, y, expected_answer| {
        const answer = minBranchless(i32, x, y);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn isPow2(comptime T: type, x: T) bool {
    switch (@typeInfo(T)) {
        .int => |int| {
            if (int.signedness == .signed) @compileError("Incorrect Type - fn accepts floats/ints.");
        },
        else => @compileError("Incorrect Type - fn accepts floats/ints."),
    }
    return x and !(x & (x -% 1));
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
        .int, .float => |t| {
            const n_bits = t.bits;
            return if (@typeInfo(@TypeOf(n_bits)).int.bits > n_bits) @truncate(n_bits) else n_bits;
        },
        .bool => return 1,
    }
}

test "Get Max Bits" {
    const expected_answers = 
    const answer = getMaxBits(i32);
}

pub fn reverse(comptime T: type, x: T) T {
    switch (@typeInfo(T)) {
        .int => {},
        else => @compileError("Incorrect Type - fn accepts ints."),
    }
    const max_bits: T = @bitSizeOf(x);
    var mask: T = 0;
    for (0..max_bits) |i| {
        mask |= ((@as(T, 1) << max_bits - i - 1) & x);
    }
}

pub fn swapXOR(comptime T: type, a: *T, b: *T) void {
    a.* ^= b.*;
    b.* ^= a.*;
    a.* ^= b.*;
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
