const std = @import("std");
const testing = std.testing;

const CHAR_BIT = 8; // # of bits per byte - assume 8

pub export fn sign(comptime T: type, x: T) T {
    switch (@typeInfo(@TypeOf(T))) {
        .int, .float => {},
        else => @compileError("Incorrect Type - accepts ints/floats"),
    }

    if (@typeInfo(@TypeOf(T)).int.signedness == .unsigned) return 0;

    return (x > 0) - (x < 0);
}

pub export fn isOppSign(comptime T: type, x: T, y: T) bool {
    return (x ^ y) < 0;
}

pub export fn intAbs(comptime T: type, x: T) T {
    const mask = x >> @sizeOf(x) - CHAR_BIT;
    return (x + mask) ^ mask;
}

pub export fn minBranchless(comptime T: type, x: T, y: T) T {
    return y ^ ((x ^ y) & -(x < y));
}

pub export fn maxBranchless(comptime T: type, x: T, y: T) T {
    return x ^ ((x ^ y) & -(x < y));
}

// unsigned int
pub export fn isPow2(comptime T: type, x: T) bool {
    return x and !(x & (x -% 1));
}

pub export fn getMaxBits(comptime T: type) T {
    switch (T) {
        .int, .float => |int| {
            const n_bits = int.bits;
            return if (@typeInfo(@TypeOf(n_bits)).int.bits > n_bits) @truncate(n_bits) else n_bits;
        },
        .bool => return 1,
    }
}

pub export fn reverse(comptime T: type, x: T) T {
    const max_bits: T = @bitSizeOf(x);
    var mask: T = 0;
    for (0..max_bits) |i| {
        mask |= ((@as(T, 1) << max_bits - i - 1) & x);
    }
}

pub export fn turnOnBitsBW2Bits(
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
