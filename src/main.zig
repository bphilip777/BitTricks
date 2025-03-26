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

pub fn isMult(comptime T: type, x: T, div: T) bool {
    return @mod(x, div) == 0;
}

test "Is Mult" {
    const is_even = isMult(u16, 80, 2);
    try std.testing.expect(is_even);

    const is_odd = !isMult(u16, 81, 2);
    try std.testing.expect(is_odd);
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

pub fn createMask(comptime T: type) type {
    return struct {
        mask: T,
        carry: bool,
    };
}

pub fn turnOnAllBits(comptime T: type) T {
    return @as(T, 0) -% @as(T, 1);
}

test "Turn On All Bits" {
    const a = turnOnAllBits(u64);
    const b = std.math.maxInt(u64);
    try std.testing.expect(a == b);
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

pub fn turnOffLastBit(comptime T: type, x: T) T {
    return x & (x -% 1);
}

test "Turn Off Bit" {
    const inputs = [_]u16{ 15, 3, 9, 11 };
    const expected_answers = [_]u16{ 14, 2, 8, 10 };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = turnOffLastBit(u16, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn indexOfRightmostBit(comptime T: type, n: T) T {
    switch (@typeInfo(T)) {
        .int => |int| {
            switch (int.signedness) {
                .signed => @compileError("Fn only accepts unsigned ints."),
                .unsigned => {},
            }
        },
        else => @compileError("Fn only accepts unsigned ints."),
    }
    if (n == 0) return 0;
    return @ctz(n) + 1;
}

test "Index Of Rightmost Bit" {
    const inputs = [_]u16{ 0b1010, 0b10, 0b1000 };
    const expected_answers = [_]u16{ 0b10, 0b10, 0b0100 };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = indexOfRightmostBit(u16, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn turnOnIndex(comptime T: type, x: T, idx: T) T {
    switch (@typeInfo(T)) {
        .int => |int| {
            switch (int.signedness) {
                .signed => @compileError("Fn only accepts unsigned ints."),
                .unsigned => {},
            }
        },
        else => @compileError("Fn only accepts unsigned ints."),
    }
    return x | @as(T, 1) << @truncate(idx);
}

test "Turn On Index" {
    // zero-idxed
    const inputs = [_]u16{ 0, 1, 2, 3, 4 };
    const expected_answers = [_]u16{ 1, 2, 4, 8, 16 };
    for (inputs, expected_answers) |input, expected_answer| {
        const answer = turnOnIndex(u16, 0, input);
        try std.testing.expect(answer == expected_answer);
    }
}

pub fn turnOnBitsBWPairsOfBits(
    comptime T: type,
    mask: createMask(T),
) createMask(T) {
    // Goal: turn on bits b/w every 2 bits, flip starting bit based on mask and carry
    // mask = struct containing mask and carry
    // - mask = unsigned int bitcasted from a vector - leftmost data = lsb = rightmost bit, rightmost data = msb = leftmost bit (given little endian)
    // - if mask doesnt come from bitcasted vector, must use @bitReverse
    // - carry = pairs of bits start from a previous loop to first bit

    // Cases:
    // 1. Mask = All 0's, Carry = True -> Mask = All 1's, Carry = True, regardless of # of bits
    // 2. Mask = All 1's, Carry = True -> Depends on # of turned on bits
    // 3. Mask = Mixed, Carry = True -> Depends on # of Bits

    // 4. Mask = 0, Carry = False -> Mask = 0, Carry = False, regardless of # of bits
    // 5. Mask = 1's, Carry = False -> Depends on # of turned on bits
    // 6. Mask = Mixed, Carry = False -> Depends on # of turned on Bits
    switch (@typeInfo(T)) {
        .int => |int| switch (int.signedness) {
            .signed => @compileError("T must be an unsigned int"),
            .unsigned => if (int.bits > 255) @compileError("T is too large, currently made to support up to but not including u256"),
        },
        else => @compileError("T must be an unsigned int"),
    }

    var temp: T = mask.mask;

    var new_mask: createMask(T) = .{
        .mask = 0,
        .carry = false,
    };

    const max_bit: T = @bitSizeOf(T);

    if (mask.carry) {
        const first_bit: T = 0;

        const second_bit: T = @ctz(temp);
        if (second_bit == max_bit) {
            new_mask.mask = ~new_mask.mask;
            new_mask.carry = true;
            return new_mask;
        }
        temp = turnOffLastBit(T, temp);

        // end inclusive
        for (first_bit..second_bit + 1) |i| {
            new_mask.mask |= @as(T, 1) << @truncate(max_bit - i - 1);
        }
    }

    while (temp > 0) {
        const first_bit = @ctz(temp);
        temp = turnOffLastBit(T, temp);

        const second_bit = @ctz(temp);
        if (second_bit == max_bit) {
            // end not inclusive
            for (first_bit..second_bit) |i| {
                new_mask.mask |= @as(T, 1) << @truncate(max_bit - i - 1);
            }
            new_mask.carry = true;
            return new_mask;
        }
        temp = turnOffLastBit(T, temp);

        // end inclusive
        for (first_bit..second_bit + 1) |i| {
            new_mask.mask |= @as(T, 1) << @truncate(max_bit - i - 1);
        }
    }

    return new_mask;
}

test "turnOnBitsBWPairsOfBits" {
    // Cases:
    // 1-3: Carry = True, 4-6 Carry = False;
    // # of bits
    // 1 + 4 = 0s, 2 + 5 = 1s, 3 + 6 = Mixed

    // 1. Mask = All 0's, Carry = True -> Mask = All 1's, Carry = True, regardless of # of bits
    {
        // 1a. Even # of bits
        const T1: type = u8;
        const mask1: createMask(T1) = .{
            .mask = 0,
            .carry = true,
        };
        const new_mask1 = turnOnBitsBWPairsOfBits(T1, mask1);
        try std.testing.expect(new_mask1.mask == std.math.maxInt(T1));
        try std.testing.expect(new_mask1.carry == true);

        // 1b. Odd # of bits
        const T2: type = u7;
        const mask2: createMask(T2) = .{
            .mask = 0,
            .carry = true,
        };
        const new_mask2 = turnOnBitsBWPairsOfBits(T2, mask2);
        try std.testing.expect(new_mask2.mask == std.math.maxInt(T2));
        try std.testing.expect(new_mask2.carry == true);
    }

    // 2. Mask = All 1's, Carry = True ->
    {
        // 2a. Even # of Bits -> All 1's, Carry = True,
        const T1: type = u8;
        const mask1: createMask(T1) = .{
            .mask = turnOnAllBits(T1),
            .carry = true,
        };
        const new_mask1 = turnOnBitsBWPairsOfBits(T1, mask1);
        try std.testing.expect(new_mask1.mask == std.math.maxInt(T1));
        try std.testing.expect(new_mask1.carry == true);

        // 2b. Odd # of Bits -> All 1's, Carry = False,
        const T2: type = u7;
        const mask2: createMask(T2) = .{
            .mask = turnOnAllBits(T2),
            .carry = true,
        };
        const new_mask2 = turnOnBitsBWPairsOfBits(T2, mask2);
        try std.testing.expect(new_mask2.mask == std.math.maxInt(T2));
        try std.testing.expect(new_mask2.carry == false);
    }

    // 3. Mask = Mixed, Carry = True ->
    {
        // 3a. Even # of Bits Turned On -> Mask = 0-first bit on + succeeding pairs are on; carry = true
        // 010010010010 -> 110011110011
        const T1: type = u16;
        const mask1: createMask(T1) = .{
            .mask = 0b0000_0000_1010_1010,
            .carry = true,
        };
        const new_mask1 = turnOnBitsBWPairsOfBits(T1, mask1);
        try std.testing.expect(new_mask1.mask == 0b1111111110111011);
        try std.testing.expect(new_mask1.carry == true);

        // 3b. Odd # of Bits Turned On -> Mask = 0-first bit on + succeeding pairs are on; carry  = false;
        // 000010010010 -> 000011110011
        const T2: type = u16;
        const mask2: createMask(T2) = .{
            .mask = 0b0100_0000_1001_0000,
            .carry = true,
        };
        const new_mask2 = turnOnBitsBWPairsOfBits(T2, mask2);
        try std.testing.expect(new_mask2.mask == 0b1100000011110000);
        try std.testing.expect(new_mask2.carry == false);
    }

    // 4. Mask = 0, Carry = False -> Mask = 0, Carry = False, regardless of # of bits
    {
        // 4a. Even # of bits
        const T1: type = u8;
        const mask1: createMask(T1) = .{
            .mask = 0,
            .carry = false,
        };
        const new_mask1 = turnOnBitsBWPairsOfBits(T1, mask1);
        try std.testing.expect(new_mask1.mask == 0 and new_mask1.carry == false);

        // 4b. Odd # of Bits
        const T2: type = u7;
        const mask2: createMask(T2) = .{
            .mask = 0,
            .carry = false,
        };
        const new_mask2 = turnOnBitsBWPairsOfBits(T2, mask2);
        try std.testing.expect(new_mask2.mask == 0 and new_mask2.carry == false);
    }

    // 5. Mask = 1's, Carry = False
    {
        // 5a. Even # of Bits -> Mask = All 1's, Carry = False
        const T1: type = u8;
        const mask1: createMask(T1) = .{
            .mask = turnOnAllBits(T1),
            .carry = false,
        };
        const new_mask1 = turnOnBitsBWPairsOfBits(T1, mask1);
        try std.testing.expect(new_mask1.mask == turnOnAllBits(T1) and new_mask1.carry == false);

        // 5b. Odd # of Bits -> Mask = All 1's, Carry = True
        const T2: type = u7;
        const mask2: createMask(T2) = .{
            .mask = turnOnAllBits(T2),
            .carry = false,
        };
        const new_mask2 = turnOnBitsBWPairsOfBits(T2, mask2);
        try std.testing.expect(new_mask2.mask == turnOnAllBits(T2) and new_mask2.carry == true);
    }

    // 6. Mask = Mixed, Carry = False
    {
        // 6a. Even # of Bits Turned On -> Mask = Every Other Pairs filled in, Carry = False
        const T1: type = u16;
        const mask1: createMask(T1) = .{
            .mask = 0b0000_0010_1001_0010,
            .carry = false,
        };
        const new_mask1 = turnOnBitsBWPairsOfBits(T1, mask1);
        try std.testing.expect(new_mask1.mask == 0b0000_0011_1001_1110);
        try std.testing.expect(new_mask1.carry == false);

        // 6b. Odd # of Bits Turned On -> Mask = Every other Pair filled in, Carry = True
        // 000010010010 -> 111110011110
        const T2: type = u16;
        const mask2: createMask(T2) = .{
            .mask = 0b0000_0000_1001_0010,
            .carry = false,
        };
        const new_mask2 = turnOnBitsBWPairsOfBits(T2, mask2);
        try std.testing.expect(new_mask2.mask == 0b0000_0000_1111_0011);
        try std.testing.expect(new_mask2.carry == true);
    }
}
