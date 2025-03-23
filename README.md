# BitTricks

- Implementing Bit Twiddling Hacks by Sean Eron Anderson
  url: https://graphics.stanford.edu/~seander/bithacks.html
- Implementing Hacker's Delight's algos

## Getting Started

Add `BitTricks` to your `build.zig.zon` .dependencies with:

```
zig fetch --save git+https://github.com/bphilip777/BitTricks.git
```

and in your `build.zig` add:

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable();

    const bittricks = b.dependency("BitTricks", .{});
    exe.root_module.addImport("bittricks", bittricks.module(""));
}
```

Now in your code, you may import `bittricks`.

```zig
const bittricks = @Import("bittricks");

var x: u8 = 66;
const y = bittricks.reverse(u8, x);
std.debug.print("{}={},{}\n", .{x,y, x == y});
```

