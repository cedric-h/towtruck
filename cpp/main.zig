// vim: sw=2 ts=2 expandtab smartindent

extern fn cpp_launch_window(draw: *const fn (vrt: [*]f32, idx: [*]u16) void) c_int;

fn draw(vrt: [*]f32, idx: [*]u16) void {
  var vrt_i: u64 = 0;
  var idx_i: u64 = 0;

  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 99; vrt_i += 1;
  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;

  vrt[vrt_i] = 99; vrt_i += 1;
  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;

  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;

  vrt[vrt_i] = 99; vrt_i += 1;
  vrt[vrt_i] = 99; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 0; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;
  vrt[vrt_i] = 1; vrt_i += 1;

  idx[idx_i] = 0; idx_i += 1;
  idx[idx_i] = 1; idx_i += 1;
  idx[idx_i] = 2; idx_i += 1;
  idx[idx_i] = 0; idx_i += 1;
  idx[idx_i] = 3; idx_i += 1;
  idx[idx_i] = 1; idx_i += 1;
}


//   struct Vert { float x, y, u, v,   r, g, b, a; };
//   typedef uint16_t u16;
//   Vert *verts = (Vert *)vertsMapped.pData;
//   u16  * idxs = (u16  *)indxsMapped.pData;
// 
//   char *str = "sup nerds []!";
//   float x = 0;
//   float y = 50;
//   do {
//     int i = *str;
//     uint16_t vstart = verts - (Vert *)vertsMapped.pData;
// 
//     float u = (i % 16) * (charSize + 2*padding) + padding;
//     float v = (i / 16) * (charSize + 2*padding);
//     float w = charSize + padding*2;
//     float h = charSize + padding*2;
// 
//     *verts++ = Vert{  x,   h+y,   u,   v, 1, 1, 1, 1};
//     *verts++ = Vert{w+x,     y, w+u, h+v, 1, 1, 1, 1};
//     *verts++ = Vert{  x,     y,   u, h+v, 1, 1, 1, 1};
//     *verts++ = Vert{w+x,   h+y, w+u,   v, 1, 1, 1, 1};
// 
//     *idxs++ = vstart+0; *idxs++ = vstart+1; *idxs++ = vstart+2;
//     *idxs++ = vstart+0; *idxs++ = vstart+3; *idxs++ = vstart+1;
// 
//     x += charWidths[i];
//   } while (str++, *str);
// 
//   enum ColorKind { ColorKind_Window, ColorKind_WindowTop, ColorKind_COUNT };
//   struct { float r, g, b, a; } palette[ColorKind_COUNT];
//   palette[ColorKind_Window   ] = { 1.0, 0.1, 1.0, 1 };
//   palette[ColorKind_WindowTop] = { 0.8, 0.1, 0.8, 1 };
// 
//   auto Rect = [&vertsMapped, &palette, &charWidths, &verts, &idxs](
//       float x, float y, float w, float h, ColorKind ck
//   ) {
//       uint16_t vstart = verts - (Vert *)vertsMapped.pData;
// 
//       float u = 0;
//       float v = 0;
//       float uv_w = 1;
//       float uv_h = 1;
// 
//       float r = palette[ck].r;
//       float g = palette[ck].g;
//       float b = palette[ck].b;
//       float a = palette[ck].a;
// 
//       *verts++ = Vert{  x,   h+y,      u,      v, r, g, b, a};
//       *verts++ = Vert{w+x,     y, uv_w+u, uv_h+v, r, g, b, a};
//       *verts++ = Vert{  x,     y,      u, uv_h+v, r, g, b, a};
//       *verts++ = Vert{w+x,   h+y, uv_w+u,      v, r, g, b, a};
// 
//       *idxs++ = vstart+0; *idxs++ = vstart+1; *idxs++ = vstart+2;
//       *idxs++ = vstart+0; *idxs++ = vstart+3; *idxs++ = vstart+1;
//  };
//  Rect(
//      viewport.Width /2,
//      viewport.Height/2,
//      300,
//      100,
//      ColorKind_Window
//  );
//  Rect(
//      viewport.Width /2,
//      viewport.Height/2 + (100 - 20),
//      300,
//       20,
//      ColorKind_WindowTop
//  );
// 
// }

pub fn main() !void {
  _ = cpp_launch_window(draw);
  @import("std").debug.print("1 + 1 = {}", .{1 + 1});
}
