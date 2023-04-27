// vim: sw=2 ts=2 expandtab smartindent

const Color = struct {
  r: f32, g: f32, b: f32, a: f32,
  pub fn rgba(r: f32, g: f32, b: f32, a: f32) Color {
    return .{ .r = r, .g = g, .b = b, .a = a };
  }
};

const Rect = struct {
  x_min: f32, y_min: f32,
  x_max: f32, y_max: f32,

  pub fn w(self: @This()) f32 { return self.x_max - self.x_min; }
  pub fn h(self: @This()) f32 { return self.y_max - self.y_min; }

  pub fn xywh(x: f32, y: f32, _w: f32, _h: f32) Rect { // bltr?
    return .{ .x_min = x, .y_min = y, .x_max = x+_w, .y_max = y+_h };
  }

  pub fn centered(self: @This(), in: Rect) Rect {
    const dw = (in.w() - self.w())/2;
    const dh = (in.h() - self.h())/2;

    var ret = self;
    ret.x_max = in.x_min + self.w() + dw;
    ret.y_max = in.y_min + self.h() + dh;
    ret.x_min = in.x_min + dw;
    ret.y_min = in.y_min + dh;
    return ret;
  }

  pub fn shrunk(self: @This(), amt: f32) Rect {
    var ret = self;
    ret.x_min += amt;
    ret.x_max -= amt;
    ret.y_min += amt;
    ret.y_max -= amt;
    return ret;
  }
  pub fn scaled(self: @This(), amt: f32) Rect {
    var ret = self;
    ret.x_min *= amt;
    ret.x_max *= amt;
    ret.y_min *= amt;
    ret.y_max *= amt;
    return ret;
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
extern fn cpp_set_font(font_size: u16, widths: *[255]u16) void;
extern fn cpp_window_wh(width: *u16, height: *u16) void;

var rcx: struct {
  char_widths: [255]u16 = undefined,
  vrt: [*]Vertex = undefined,
  idx: [*]u16 = undefined,
  vrt_i: u64 = 0,
  idx_i: u64 = 0,
  color: Color = .{ .r = 1, .g = 1, .b = 1, .a = 1 },
  font_size: f32 = 16,

  pub fn rect(self: *@This(), rct: Rect) void {
    const vstart = @intCast(u16, self.vrt_i);

    const r = self.color.r;
    const g = self.color.g;
    const b = self.color.b;
    const a = self.color.a;

    const x_min = @round(rct.x_min);
    const x_max = @round(rct.x_max);
    const y_min = @round(rct.y_min);
    const y_max = @round(rct.y_max);

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

  pub fn bbox(self: *@This(), rct: Rect) void {
    const b4: Color = self.color;
    self.color = Color.rgba(0, 0, 0, 1);
    self.rect(rct.scaled(self.font_size).shrunk(-1));
    self.color = Color.rgba(1, 1, 1, 1);
    self.rect(rct.scaled(self.font_size));
    self.color = b4;
  }

  pub fn str(self: *@This(), _rect: Rect, chars: []const u8) void {
    const r = self.color.r;
    const g = self.color.g;
    const b = self.color.b;
    const a = self.color.a;

    const char_size = rcx.font_size;
    const padding = char_size/2;

    var str_width: f32 = 0;
    for (chars) |i| {
      str_width += @intToFloat(f32, self.char_widths[i]);
    }
    const str_rect = Rect
      .xywh(0, 0, str_width, rcx.font_size)
      .centered(_rect.scaled(rcx.font_size));

    var x: f32 = @round(str_rect.x_min);
    var y: f32 = @round(str_rect.y_min - padding + 4);
    for (chars) |i| {
      const vstart = @intCast(u16, self.vrt_i);

      const u = @round(@intToFloat(f32, i % 16) * (char_size + 2*padding) + padding);
      const v = @round(@intToFloat(f32, i / 16) * (char_size + 2*padding));
      const w = @round(char_size + padding*2);
      const h = @round(char_size + padding*2);

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

  // ui tex debug
  if (false) {
    const vstart = @intCast(u16, rcx.vrt_i);

    const r: f32 = 1;
    const g: f32 = 1;
    const b: f32 = 1;
    const a: f32 = 1;

    const char_size = rcx.font_size;
    const padding = char_size/2;
    const tex_size = (padding*2 + char_size)*16;
    const tW = tex_size;
    const tH = tex_size;

    const x_min = 0;
    const x_max = tex_size;
    const y_min = 0;
    const y_max = tex_size;

    rcx.vrt[rcx.vrt_i] = .{ .arr = .{ x_min, y_max,  0, 0,  r, g, b, a } }; rcx.vrt_i += 1;
    rcx.vrt[rcx.vrt_i] = .{ .arr = .{ x_max, y_min, tW,tH,  r, g, b, a } }; rcx.vrt_i += 1;
    rcx.vrt[rcx.vrt_i] = .{ .arr = .{ x_min, y_min,  0,tH,  r, g, b, a } }; rcx.vrt_i += 1;
    rcx.vrt[rcx.vrt_i] = .{ .arr = .{ x_max, y_max, tW, 0,  r, g, b, a } }; rcx.vrt_i += 1;

    rcx.idx[rcx.idx_i] = vstart+0; rcx.idx_i += 1;
    rcx.idx[rcx.idx_i] = vstart+1; rcx.idx_i += 1;
    rcx.idx[rcx.idx_i] = vstart+2; rcx.idx_i += 1;
    rcx.idx[rcx.idx_i] = vstart+0; rcx.idx_i += 1;
    rcx.idx[rcx.idx_i] = vstart+3; rcx.idx_i += 1;
    rcx.idx[rcx.idx_i] = vstart+1; rcx.idx_i += 1;
  }

  else {

    // recreate WoW settings pane
    // slider
    // combo box
    // checkbox
    // tabbed window

    if (false) {
      var screen = lbl: {
        var width : u16 = 0;
        var height: u16 = 0;
        cpp_window_wh(&width, &height);
        const fwidth  = @round(@intToFloat(f32, width ) / rcx.font_size);
        const fheight = @round(@intToFloat(f32, height) / rcx.font_size);
        break :lbl Rect.xywh(0, 0, fwidth, fheight);
      };
      var window = Rect.xywh(0, 0, 16*3, 12*3).centered(screen);
      rcx.color = Color.rgba(0, 0, 0, 1); 

      rcx.bbox(window.shrunk(-0.5));

      var optsbar = window.cut_left(11);
      rcx.bbox(optsbar.shrunk(0.5));

      const display = window.cut_top(13).shrunk(0.5);
      rcx.bbox(display);
      rcx.str(display, "x");

      const area_specific = window.shrunk(0.5);
      rcx.bbox(area_specific);
      rcx.str(area_specific, "Base Settings");
    } else {
      var win = Rect.xywh(1, 1, 16*2, 9*2);
      rcx.color = Color.rgba(0, 0, 0, 1); 
      // rcx.color = Color.rgba(1, 1, 1, 1); 

      var top = win.cut_top(1.3);

      const exs = top.cut_right(1.3); rcx.bbox(exs); rcx.str(exs, "x" );
      const min = top.cut_right(1.3); rcx.bbox(min); rcx.str(min, "[]");
      const max = top.cut_right(1.3); rcx.bbox(max); rcx.str(max, "-" );

      rcx.bbox(top); rcx.str(top, "sup nerds!");

      const btm = win.cut_bottom(2); rcx.bbox(btm); rcx.str(btm, "bottom stuff here owo");

      const left = win.cut_left(win.w()/2);
      rcx.bbox(left); rcx.str(left, "Left window!");
      const right = win;
      rcx.bbox(right); rcx.str(right, "Right window!");
    }
  }
}

pub fn main() !void {
  cpp_set_font(@floatToInt(u16, rcx.font_size), &rcx.char_widths);
  _ = cpp_launch_window(draw);
  @import("std").debug.print("1 + 1 = {}", .{1 + 1});
}
