// vim: sw=2 ts=2 expandtab smartindent

const Color = struct { r: f32, g: f32, b: f32, a: f32 };

const Rect = struct {
  x_min: f32,
  y_min: f32,
  x_max: f32,
  y_max: f32,

  pub fn w(self: @This()) f32 { return self.x_max - self.x_min; }
  pub fn h(self: @This()) f32 { return self.y_max - self.y_min; }

  pub fn xywh(x: f32, y: f32, _w: f32, _h: f32) Rect { // bltr?
    return .{ .x_min = x, .y_min = y, .x_max = x+_w, .y_max = y+_h };
  }

  pub fn cut_left(self: *@This(), a: f32) @This() {
    const x_min = self.x_min;
    self.x_min = @min(self.x_max, self.x_min + a);

    return .{ .x_min =      x_min, .x_max = self.x_min,
              .y_min = self.y_min, .y_max = self.y_max };
  }

  pub fn cut_right(self: *@This(), a: f32) @This() {
    const x_max = self.x_max;
    self.x_max = @max(self.x_min, self.x_max - a);

    return .{ .x_min = self.x_max, .x_max =      x_max,
              .y_min = self.y_min, .y_max = self.y_max };
  }

  pub fn cut_top(self: *@This(), a: f32) @This() {
    const y_max = self.y_max;
    self.y_max = @max(self.y_min, self.y_max - a);

    return .{ .y_min = self.y_max, .y_max =      y_max,
              .x_min = self.x_min, .x_max = self.x_max };
  }

  pub fn cut_bottom(self: *@This(), a: f32) @This() {
    const y_min = self.y_min;
    self.y_min = @min(self.y_max, self.y_min + a);

    return .{ .y_min =      y_min, .y_max = self.y_min,
              .x_min = self.x_min, .x_max = self.x_max };
  }

};
const Vertex = extern union {
  obj: extern struct {
    x: f32, y: f32, u: f32, v: f32,
    r: f32, g: f32, b: f32, a: f32,
  },
  arr: [8]f32
};
extern fn cpp_launch_window(draw: *const fn (vrt: [*]Vertex, idx: [*]u16) void) c_int;
extern fn cpp_set_font(widths: *[255]c_int) void;

var rcx: struct {
  char_widths: [255]c_int = undefined,
  vrt: [*]Vertex = undefined,
  idx: [*]u16 = undefined,
  vrt_i: u64 = 0,
  idx_i: u64 = 0,
  color: Color = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
  rect_scale: f32 = 2,

  pub fn rect(self: *@This(), rct: *const Rect) void {
    const vstart = @intCast(u16, self.vrt_i);

    const r = self.color.r;
    const g = self.color.g;
    const b = self.color.b;
    const a = self.color.a;

    const x_min = rct.x_min * self.rect_scale;
    const x_max = rct.x_max * self.rect_scale;
    const y_min = rct.y_min * self.rect_scale;
    const y_max = rct.y_max * self.rect_scale;

    self.vrt[self.vrt_i] = .{ .arr = .{ x_min, y_max,  0, 0,  r, g, b, a } }; self.vrt_i += 1;
    self.vrt[self.vrt_i] = .{ .arr = .{ x_max, y_min,  1, 1,  r, g, b, a } }; self.vrt_i += 1;
    self.vrt[self.vrt_i] = .{ .arr = .{ x_min, y_min,  0, 1,  r, g, b, a } }; self.vrt_i += 1;
    self.vrt[self.vrt_i] = .{ .arr = .{ x_max, y_max,  1, 0,  r, g, b, a } }; self.vrt_i += 1;

    self.idx[self.idx_i] = vstart+0; self.idx_i += 1;
    self.idx[self.idx_i] = vstart+1; self.idx_i += 1;
    self.idx[self.idx_i] = vstart+2; self.idx_i += 1;
    self.idx[self.idx_i] = vstart+0; self.idx_i += 1;
    self.idx[self.idx_i] = vstart+3; self.idx_i += 1;
    self.idx[self.idx_i] = vstart+1; self.idx_i += 1;
  }

  pub fn str(self: *@This(), chars: []const u8) void {
    const r = self.color.r;
    const g = self.color.g;
    const b = self.color.b;
    const a = self.color.a;

    const char_size = 12;
    const padding = char_size/2;

    var x: f32 = 100;
    var y: f32 = 100;
    for (chars) |i| {
      const vstart = @intCast(u16, self.vrt_i);

      const u = @intToFloat(f32, i % 16) * (char_size + 2*padding) + padding;
      const v = @intToFloat(f32, i / 16) * (char_size + 2*padding);
      const w = char_size + padding*2;
      const h = char_size + padding*2;

      self.vrt[self.vrt_i] = .{ .arr = .{  x,   h+y,   u,   v, r, g, b, a } }; self.vrt_i += 1;
      self.vrt[self.vrt_i] = .{ .arr = .{w+x,     y, w+u, h+v, r, g, b, a } }; self.vrt_i += 1;
      self.vrt[self.vrt_i] = .{ .arr = .{  x,     y,   u, h+v, r, g, b, a } }; self.vrt_i += 1;
      self.vrt[self.vrt_i] = .{ .arr = .{w+x,   h+y, w+u,   v, r, g, b, a } }; self.vrt_i += 1;

      self.idx[self.idx_i] = vstart+0; self.idx_i += 1;
      self.idx[self.idx_i] = vstart+1; self.idx_i += 1;
      self.idx[self.idx_i] = vstart+2; self.idx_i += 1;
      self.idx[self.idx_i] = vstart+0; self.idx_i += 1;
      self.idx[self.idx_i] = vstart+3; self.idx_i += 1;
      self.idx[self.idx_i] = vstart+1; self.idx_i += 1;

      x += @intToFloat(f32, self.char_widths[i]);
    }
  }
} = .{};

fn draw(vrt: [*]Vertex, idx: [*]u16) void {
  rcx.vrt = vrt;
  rcx.idx = idx;
  rcx.vrt_i = 0;
  rcx.idx_i = 0;

  var dkr: struct {
    i: f32 = 1,
    pub fn clr(self: *@This()) void {
      self.i -= 0.1;
      const i = self.i;
      rcx.color = .{ .r = i, .g = i, .b = i, .a = 1 };
    }
  } = .{};

  var bar = Rect.xywh(0, 0, 16*20, 9*20);

  // figure out coloring things
  // recreate WoW settings pane

  var top = bar.cut_top(16);
  dkr.clr(); rcx.rect(&top.cut_right(16));
  dkr.clr(); rcx.rect(&top.cut_right(16));
  dkr.clr(); rcx.rect(&top.cut_right(16));
  dkr.clr(); rcx.rect(&top);

  dkr.clr(); rcx.rect(&bar.cut_bottom(16));

  dkr.clr(); rcx.rect(&bar.cut_left(bar.w()/2));
  dkr.clr(); rcx.rect(&bar);

  dkr.clr(); rcx.str("sup nerds!");
}

pub fn main() !void {
  cpp_set_font(&rcx.char_widths);
  _ = cpp_launch_window(draw);
  @import("std").debug.print("1 + 1 = {}", .{1 + 1});
}
