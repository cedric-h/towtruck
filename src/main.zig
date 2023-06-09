// vim: sw=2 ts=2 expandtab smartindent

const std = @import("std");
const windows = std.os.windows;
const kern32 = std.os.windows.kernel32;
const user32 = std.os.windows.user32;

const d3d11 = @import("zigwin32/win32.zig").graphics.direct3d11;
const direct3d = @import("zigwin32/win32.zig").graphics.direct3d;
const dxgi = @import("zigwin32/win32.zig").graphics.dxgi;
const com = @import("zigwin32/win32.zig").system.com;
const foundation = @import("zigwin32/win32.zig").foundation;

const zeroInit = @import("std").mem.zeroInit;


const GDI_RECT = extern struct {
  X: i32,
  Y: i32,
  Width: i32,
  Height: i32,
};
const GDI_BITMAP_DATA = extern struct {
  Width:       windows.UINT,
  Height:      windows.UINT,
  Stride:      c_int,
  PixelFormat: c_int ,
  Scan0:       ?*anyopaque,
  Reserved:    ?*windows.UINT,
};
pub extern "gdiplus" fn GdiplusStartup(
  token: *windows.ULONG,
  input: ?*anyopaque,
  output: ?*anyopaque
) callconv(windows.WINAPI) c_int;
pub extern "gdiplus" fn GdipCreateBitmapFromScan0(
  width : c_int,
  height: c_int,
  stride: c_int,
  format: c_int,
  scan0: ?[*]u8,
  bitmap: *?*anyopaque
) callconv(windows.WINAPI) c_int;
pub extern "gdiplus" fn GdipBitmapSetPixel(
  bitmap: ?*anyopaque,
  x: c_int,
  y: c_int,
  color: windows.DWORD
) callconv(windows.WINAPI) c_int;
pub extern "gdiplus" fn GdipBitmapLockBits(
  bitmap: ?*anyopaque,
  rect: *GDI_RECT,
  flags: windows.UINT,
  format: c_int,
  lockedBitmapData: *GDI_BITMAP_DATA
) callconv(windows.WINAPI) c_int;

var global_windowDidResize = false;

pub fn main() !void {
  const name = ") string bean ^.^";
  const hInstance: windows.HINSTANCE = @ptrCast(
    *const windows.HINSTANCE,
    &(kern32.GetModuleHandleW(null) orelse unreachable)
  ).*;

  _ = user32.RegisterClassExA(&zeroInit(user32.WNDCLASSEXA, .{
    .lpfnWndProc = winproc,
    .hInstance = hInstance,
    .lpszClassName = name
  }));

  const hwnd = user32.CreateWindowExA(
    0, name, name,
    user32.WS_OVERLAPPEDWINDOW,
    user32.CW_USEDEFAULT,
    user32.CW_USEDEFAULT,
    40 * 12, // user32.CW_USEDEFAULT,
    40 *  9, // user32.CW_USEDEFAULT,
    null, null, hInstance, null
  );

  var d3d11_device: ?*d3d11.ID3D11Device1 = undefined;
  var d3d11_device_ctx: ?*d3d11.ID3D11DeviceContext1 = undefined;
  {
    var base_device:     ?*d3d11.ID3D11Device        = undefined;
    var base_device_ctx: ?*d3d11.ID3D11DeviceContext = undefined;
    _ = d3d11.D3D11CreateDevice(
      null, .HARDWARE, null, .BGRA_SUPPORT,
      &[1]direct3d.D3D_FEATURE_LEVEL{ direct3d.D3D_FEATURE_LEVEL_11_0 }, 1,
      d3d11.D3D11_SDK_VERSION,
      &base_device, null, &base_device_ctx
    );
    defer _ = base_device    .?.IUnknown_Release();
    defer _ = base_device_ctx.?.IUnknown_Release();

    _ = base_device    .?.IUnknown_QueryInterface(
      d3d11.IID_ID3D11Device1,
      @ptrCast(?*?*anyopaque, &d3d11_device)
    );
    _ = base_device_ctx.?.IUnknown_QueryInterface(
      d3d11.IID_ID3D11DeviceContext1,
      @ptrCast(?*?*anyopaque, &d3d11_device_ctx)
    );
  }

  // Create Swap Chain
  var d3d11_swap_chain: ?*dxgi.IDXGISwapChain1 = undefined;
  {
    // Get DXGI Factory (needed to create Swap Chain)
    var dxgi_factory: ?*dxgi.IDXGIFactory2 = undefined;
    {
      var dxgi_device: ?*dxgi.IDXGIDevice1 = undefined;
      _ = d3d11_device.?.IUnknown_QueryInterface(
        dxgi.IID_IDXGIDevice1, @ptrCast(?*?*anyopaque, &dxgi_device));

      var dxgi_adapter: ?*dxgi.IDXGIAdapter = undefined;
      _ = dxgi_device.?.IDXGIDevice_GetAdapter(&dxgi_adapter);
      _ = dxgi_device.?.IUnknown_Release();

      var adapter_desc: dxgi.DXGI_ADAPTER_DESC = undefined;
      _ = dxgi_adapter.?.IDXGIAdapter_GetDesc(&adapter_desc);

      // OutputDebugStringA("Graphics Device: ");
      // OutputDebugStringW(adapterDesc.Description);

      _ = dxgi_adapter.?.IDXGIObject_GetParent(dxgi.IID_IDXGIFactory2, @ptrCast(?*?*anyopaque, &dxgi_factory));
      _ = dxgi_adapter.?.IUnknown_Release();
    }
    
    const d3d11_swap_chain_desc = dxgi.DXGI_SWAP_CHAIN_DESC1{
      .Width = 0, // use window width
      .Height = 0, // use window height
      .Format = .B8G8R8A8_UNORM_SRGB,
      .SampleDesc= .{ .Count = 1, .Quality = 0 },
      .BufferUsage = dxgi.DXGI_USAGE_RENDER_TARGET_OUTPUT,
      .BufferCount = 2,
      .Scaling = .STRETCH,
      .SwapEffect = .DISCARD,
      .AlphaMode = .UNSPECIFIED,
      .Flags = 0,
      .Stereo = 0,
    };

    _ = dxgi_factory.?.IDXGIFactory2_CreateSwapChainForHwnd(
      @ptrCast(?*com.IUnknown, d3d11_device),
      @ptrCast(foundation.HWND, hwnd),
      &d3d11_swap_chain_desc, null, null, &d3d11_swap_chain
    );

    _ = dxgi_factory.?.IUnknown_Release();
  }
    
  // Create Framebuffer Render Target
  var d3d11_framebuffer_view: ?*d3d11.ID3D11RenderTargetView = undefined;
  {
    var d3d11_framebuffer: ?*d3d11.ID3D11Texture2D = undefined;
    _ = d3d11_swap_chain.?.IDXGISwapChain_GetBuffer(
      0,
      d3d11.IID_ID3D11Texture2D,
      @ptrCast(?*?*anyopaque, &d3d11_framebuffer)
    );

    _ = d3d11_device.?.ID3D11Device_CreateRenderTargetView(
      @ptrCast(?*d3d11.ID3D11Resource, d3d11_framebuffer),
      null, &d3d11_framebuffer_view
    );
    _ = d3d11_framebuffer.?.IUnknown_Release();
  }

  // Create Vertex Shader
  var vs_blob: ?*direct3d.ID3DBlob = undefined;
  var vertex_shader: ?*d3d11.ID3D11VertexShader = undefined;
  {
    var shader_compile_errors_blob: ?*direct3d.ID3DBlob = undefined;
    _ = direct3d.fxc.D3DCompileFromFile(
      @import("std").unicode.utf8ToUtf16LeStringLiteral("shaders.hlsl"),
      null, null, "vs_main",
      "vs_5_0", 0, 0, &vs_blob, &shader_compile_errors_blob
    );

    // if (x) {
    //   const char* errorString = NULL;
    //   if (hResult == HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND))
    //       errorString = "Could not compile shader; file not found";
    //   else if (shader_compile_errors_blob){
    //       errorString = (const char*)shader_compile_errors_blob.GetBufferPointer();
    //       shader_compile_errors_blob.IUnknown_Release();
    //   }
    //   MessageBoxA(0, errorString, "Shader Compiler Error", MB_ICONERROR | MB_OK);
    //   return 1;
    // }

    _ = d3d11_device.?.ID3D11Device_CreateVertexShader(
      @ptrCast([*]const u8, vs_blob.?.ID3DBlob_GetBufferPointer()),
      vs_blob.?.ID3DBlob_GetBufferSize(),
      null,
      &vertex_shader
    );
  }

    // Create Pixel Shader
  var pixel_shader: ?*d3d11.ID3D11PixelShader = undefined;
  {
    var ps_blob: ?*direct3d.ID3DBlob = undefined;
    var shader_compile_errors_blob: ?*direct3d.ID3DBlob = undefined;
    _ = direct3d.fxc.D3DCompileFromFile(
      @import("std").unicode.utf8ToUtf16LeStringLiteral("shaders.hlsl"),
      null, null, "ps_main",
      "ps_5_0", 0, 0, &ps_blob, &shader_compile_errors_blob
    );

    // if(FAILED(hResult))
    // {
    //     const char* errorString = NULL;
    //     if(hResult == HRESULT_FROM_WIN32(ERROR_FILE_NOT_FOUND))
    //         errorString = "Could not compile shader; file not found";
    //     else if(shader_compile_errors_blob){
    //         errorString = (const char*)shader_compile_errors_blob.GetBufferPointer();
    //         shader_compile_errors_blob.IUnknown_Release();
    //     }
    //     MessageBoxA(0, errorString, "Shader Compiler Error", MB_ICONERROR | MB_OK);
    //     return 1;
    // }

    _ = d3d11_device.?.ID3D11Device_CreatePixelShader(
      @ptrCast([*]const u8, ps_blob.?.ID3DBlob_GetBufferPointer()),
      ps_blob.?.ID3DBlob_GetBufferSize(),
      null,
      &pixel_shader
    );
    _ = ps_blob.?.IUnknown_Release();
  }

  // Create Input Layout
  var input_layout: ?*d3d11.ID3D11InputLayout = undefined;
  {
    const inputElementDesc = [_]d3d11.D3D11_INPUT_ELEMENT_DESC{
      .{
        .SemanticName         = "POS",
        .SemanticIndex        = 0,
        .Format               = .R32G32_FLOAT,
        .InputSlot            = 0,
        .AlignedByteOffset    = 0,
        .InputSlotClass       = d3d11.D3D11_INPUT_PER_VERTEX_DATA,
        .InstanceDataStepRate = 0
      },
      .{
        .SemanticName         = "TEX",
        .SemanticIndex        = 0,
        .Format               = .R32G32_FLOAT,
        .InputSlot            = 0,
        .AlignedByteOffset    = d3d11.D3D11_APPEND_ALIGNED_ELEMENT,
        .InputSlotClass       = d3d11.D3D11_INPUT_PER_VERTEX_DATA,
        .InstanceDataStepRate = 0
      },
    };

    const vs_blob_buf_ptr: ?*anyopaque = vs_blob.?.ID3DBlob_GetBufferPointer();
    _ = d3d11_device.?.ID3D11Device_CreateInputLayout(
      &inputElementDesc,
      inputElementDesc.len,
      @ptrCast([*]const u8, vs_blob_buf_ptr),
      vs_blob.?.ID3DBlob_GetBufferSize(),
      &input_layout
    );
    _ = vs_blob.?.IUnknown_Release();
  }

  // Create Vertex Buffer
  var vertex_buffer: ?*d3d11.ID3D11Buffer = undefined;
  var numVerts: windows.UINT = undefined;
  var stride  : windows.UINT = undefined;
  var offset  : windows.UINT = undefined;
  {
    const vertex_data = [_]f32{ // x, y, u, v
      -0.5,  0.5, 0.0, 0.0,
       0.5, -0.5, 1.0, 1.0,
      -0.5, -0.5, 0.0, 1.0,
      -0.5,  0.5, 0.0, 0.0,
       0.5,  0.5, 1.0, 0.0,
       0.5, -0.5, 1.0, 1.0
    };
    stride = 4 * @sizeOf(f32);
    numVerts = @sizeOf(@TypeOf(vertex_data)) / stride;
    offset = 0;

    var vertexBufferDesc = d3d11.D3D11_BUFFER_DESC{
      .ByteWidth = @sizeOf(@TypeOf(vertex_data)),
      .Usage     = d3d11.D3D11_USAGE_IMMUTABLE,
      .BindFlags = @enumToInt(d3d11.D3D11_BIND_VERTEX_BUFFER),
      .CPUAccessFlags = 0,
      .MiscFlags = 0,
      .StructureByteStride = 0,
    };

    var vertexSubresourceData = d3d11.D3D11_SUBRESOURCE_DATA{
      .pSysMem = @ptrCast(?*const anyopaque, &vertex_data),
      .SysMemPitch = 0,
      .SysMemSlicePitch = 0,
    };

    _ = d3d11_device.?.ID3D11Device_CreateBuffer(&vertexBufferDesc, &vertexSubresourceData, &vertex_buffer);
  }

  var sampler_state: ?*d3d11.ID3D11SamplerState = undefined;
  {
    const sampler_desc = zeroInit(d3d11.D3D11_SAMPLER_DESC, .{
      .Filter         = d3d11.D3D11_FILTER_MIN_MAG_MIP_POINT,
      .AddressU       = d3d11.D3D11_TEXTURE_ADDRESS_BORDER,
      .AddressV       = d3d11.D3D11_TEXTURE_ADDRESS_BORDER,
      .AddressW       = d3d11.D3D11_TEXTURE_ADDRESS_BORDER,
      .BorderColor    = .{ 1, 1, 1, 1},
      .ComparisonFunc = d3d11.D3D11_COMPARISON_NEVER,
    });

    _ = d3d11_device.?.ID3D11Device_CreateSamplerState(&sampler_desc, &sampler_state);
  }

  var texture:      ?*d3d11.ID3D11Texture2D          = undefined;
  var texture_view: ?*d3d11.ID3D11ShaderResourceView = undefined;
  {
    const tex_desc = zeroInit(d3d11.D3D11_TEXTURE2D_DESC, .{
      .Width              = 2,
      .Height             = 2,
      .MipLevels          = 1,
      .ArraySize          = 1,
      .Format             = .R8G8B8A8_UNORM_SRGB,
      .SampleDesc         = .{ .Count = 1 },
      .Usage              = d3d11.D3D11_USAGE_IMMUTABLE,
      .BindFlags          = d3d11.D3D11_BIND_SHADER_RESOURCE,
    });

    var test_tex_bytes = [2*2*4]u8{
        0,   0, 255, 255,
      255,   0,   0, 255,
      255,   0,   0, 255,
        0,   0, 255, 255
    };

    var token: windows.ULONG = undefined;
    _ = GdiplusStartup(&token, null, null);
    var bitmap: ?*anyopaque = null;
    const format = @intCast(c_int, @enumToInt(tex_desc.Format));
    const img_bytes = @ptrCast(?[*]u8, &test_tex_bytes);
    _ = GdipCreateBitmapFromScan0(2, 2, 0, format, img_bytes, &bitmap);
    _ = GdipBitmapSetPixel(bitmap, 0, 0, 0xFFFF00FF);

    var locked_data = zeroInit(GDI_BITMAP_DATA, .{});
    var rect = GDI_RECT { .X = 0, .Y = 0, .Width = 2, .Height = 2 };
    _ = GdipBitmapLockBits(bitmap, &rect, 1, format, &locked_data);

    @breakpoint();
    const tex_subresource_data = zeroInit(d3d11.D3D11_SUBRESOURCE_DATA, .{
      .pSysMem = &test_tex_bytes,
      .SysMemPitch = 4 * tex_desc.Width,
    });

    _ = d3d11_device.?.ID3D11Device_CreateTexture2D(&tex_desc, &tex_subresource_data, &texture);
    const tex_as_resource = @ptrCast(?*d3d11.ID3D11Resource, texture);
    _ = d3d11_device.?.ID3D11Device_CreateShaderResourceView(tex_as_resource, null, &texture_view);
  }

  _ = user32.ShowWindow(hwnd.?, 1);
  var msg: user32.MSG = undefined;

  gameloop: while (true) {
    while (user32.PeekMessageA(&msg, null, 0, 0, user32.PM_REMOVE) > 0) {
      if (msg.message == user32.WM_QUIT)
        break :gameloop;

      _ = user32.TranslateMessage(&msg);
      _ = user32.DispatchMessageA(&msg);
    }

    if (global_windowDidResize) {
      _ = d3d11_device_ctx.?.ID3D11DeviceContext_OMSetRenderTargets(0, null, null);
      _ = d3d11_framebuffer_view.?.IUnknown_Release();

      _ = d3d11_swap_chain.?.IDXGISwapChain_ResizeBuffers(0, 0, 0, .UNKNOWN, 0);
      
      var d3d11_framebuffer: ?*d3d11.ID3D11Texture2D = undefined;
      _ = d3d11_swap_chain.?.IDXGISwapChain_GetBuffer(
        0,
        d3d11.IID_ID3D11Texture2D,
        @ptrCast(?*?*anyopaque, &d3d11_framebuffer)
      );
      _ = d3d11_device.?.ID3D11Device_CreateRenderTargetView(
        @ptrCast(?*d3d11.ID3D11Resource, d3d11_framebuffer),
        null, &d3d11_framebuffer_view
      );
      _ = d3d11_framebuffer.?.IUnknown_Release();

      global_windowDidResize = false;
    }

    const bg_clr = [4]f32{ 0.1, 0.2, 0.6, 1.0 };
    d3d11_device_ctx.?.ID3D11DeviceContext_ClearRenderTargetView(
      d3d11_framebuffer_view,
      @ptrCast(?*const f32, &bg_clr)
    );

    var winRect: @import("zigwin32/win32.zig").everything.RECT = undefined;
    _ = @import("zigwin32/win32.zig").everything.GetClientRect(@ptrCast(foundation.HWND, hwnd), &winRect);
    var viewport = d3d11.D3D11_VIEWPORT{
      .TopLeftX = 0.0,
      .TopLeftY = 0.0,
      .Width = @intToFloat(f32, winRect.right - winRect.left),
      .Height = @intToFloat(f32, winRect.bottom - winRect.top),
      .MinDepth = 0.0,
      .MaxDepth = 1.0
    };
    d3d11_device_ctx.?.ID3D11DeviceContext_RSSetViewports(
      1,
      @ptrCast([*]d3d11.D3D11_VIEWPORT, &viewport)
    );

    d3d11_device_ctx.?.ID3D11DeviceContext_OMSetRenderTargets(
      1,
      @ptrCast(?[*]?*d3d11.ID3D11RenderTargetView, &d3d11_framebuffer_view),
      null
    );

    d3d11_device_ctx.?.ID3D11DeviceContext_IASetPrimitiveTopology(._PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    d3d11_device_ctx.?.ID3D11DeviceContext_IASetInputLayout(input_layout);

    d3d11_device_ctx.?.ID3D11DeviceContext_VSSetShader(vertex_shader, null, 0);
    d3d11_device_ctx.?.ID3D11DeviceContext_PSSetShader(pixel_shader, null, 0);

    d3d11_device_ctx.?.ID3D11DeviceContext_PSSetShaderResources(
      0, 1,
      @ptrCast(?[*]?*d3d11.ID3D11ShaderResourceView, &texture_view)
    );
    d3d11_device_ctx.?.ID3D11DeviceContext_PSSetSamplers(
      0, 1,
      @ptrCast(?[*]?*d3d11.ID3D11SamplerState, &sampler_state)
    );

    d3d11_device_ctx.?.ID3D11DeviceContext_IASetVertexBuffers(
      0, 1,
      @ptrCast(?[*]?*d3d11.ID3D11Buffer, &vertex_buffer),
      @ptrCast(?[*]const u32, &stride),
      @ptrCast(?[*]const u32, &offset)
    );

    d3d11_device_ctx.?.ID3D11DeviceContext_Draw(numVerts, 0);
    
    _ = d3d11_swap_chain.?.IDXGISwapChain_Present(1, 0);
  }
}

export fn winproc(
  hwnd: windows.HWND,
  msg: windows.UINT,
  w_param: windows.WPARAM,
  l_param: windows.LPARAM,
) callconv(windows.WINAPI) windows.LRESULT {
  switch (msg) {
    user32.WM_KEYDOWN => {
      if (w_param == @enumToInt(@import("zigwin32/win32.zig").everything.VK_ESCAPE))
        _ = user32.DestroyWindow(hwnd);
      return 0;
    },
    user32.WM_DESTROY => {
      user32.PostQuitMessage(0);
      return 0;
    },
    user32.WM_SIZE => {
      global_windowDidResize = true;
      return 0;
    },
    else => {}
  }
  return user32.DefWindowProcA(hwnd, msg, w_param, l_param);
}
