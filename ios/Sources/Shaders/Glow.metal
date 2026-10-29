#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float lh(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static float ln(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(lh(i), lh(i + float2(1, 0)), f.x),
               mix(lh(i + float2(0, 1)), lh(i + float2(1, 1)), f.x), f.y);
}

static float lfbm(float2 p) {
    float v = 0.0;
    float s = 0.5;
    for (int i = 0; i < 4; i++) {
        v += s * ln(p);
        p *= 2.03;
        s *= 0.5;
    }
    return v;
}

// Fundo vivo: gradiente em movimento, luz de glória no alto e brasa da sarça embaixo.
[[ stitchable ]] half4 lumiGlow(float2 pos, half4 color, float2 size, float time,
                                half4 ca, half4 cb, half4 cc) {
    float2 uv = float2(pos.x / size.x, 1.0 - pos.y / size.y);
    float k = size.x / size.y;
    float2 p = float2(uv.x * k, uv.y);
    float tt = time * 0.045;

    float2 q = float2(lfbm(p * 1.5 + tt), lfbm(p * 1.5 - tt + 3.1));
    float f = lfbm(p * 1.2 + q * 1.9 + tt * 0.7);

    float3 A = float3(ca.rgb);
    float3 B = float3(cb.rgb);
    float3 C = float3(cc.rgb);

    float3 col = mix(A, B, smoothstep(0.2, 0.9, f));
    col = mix(col, A, smoothstep(0.55, 1.0, 1.0 - uv.y) * 0.35);

    float2 L = float2(0.12 * k, 1.08);
    float d = length(p - L);
    float ang = atan2(p.y - L.y, p.x - L.x);
    float rays = pow(0.5 + 0.5 * sin(ang * 11.0 + tt * 5.0 + lfbm(float2(ang * 2.0, tt * 2.0)) * 5.0), 4.0) * exp(-d * 1.15);
    col += C * (exp(-d * 1.7) * 0.32 + rays * 0.13);

    float e = exp(-length(p - float2(0.88 * k, 0.02)) * 2.2);
    col += C * e * (0.24 + 0.06 * sin(time * 1.9));

    col *= 0.8 + 0.2 * smoothstep(1.25, 0.15, length(uv - float2(0.5, 0.6)));
    col += (lh(pos + fract(time)) - 0.5) * 0.04;

    return half4(half3(clamp(col, 0.0, 1.0)), 1.0h);
}
