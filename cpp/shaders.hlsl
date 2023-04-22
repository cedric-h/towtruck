cbuffer constants : register(b0) {
    float2 screen_res;
    float2 tex_res;
};

struct VS_Input {
    float2 pos : POS;
    float2 uv : TEX;
};

struct VS_Output {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD;
};

Texture2D    mytexture : register(t0);
SamplerState mysampler : register(s0);

VS_Output vs_main(VS_Input input) {
    VS_Output output;
    float2 normalized = (input.pos/screen_res)*2.0f - 1.0f;
    output.pos = float4(normalized, 0.0f, 1.0f);
    output.uv  = input.uv / tex_res;
    return output;
}

float4 ps_main(VS_Output input) : SV_Target {
    return mytexture.Sample(mysampler, input.uv);   
}
