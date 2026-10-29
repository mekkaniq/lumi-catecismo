#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

static float lh(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Fundo vivo e limpo: gradiente em camadas que respira devagar, uma luz dourada
// atrás da Lumi e raios suaves vindos do canto. Sem ruído, para parecer luz e não sujeira.
[[ stitchable ]] half4 lumiGlow(float2 pos, half4 color, float2 size, float time,
                                half4 ca, half4 cb, half4 cc) {
    float2 uv = float2(pos.x / size.x, 1.0 - pos.y / size.y);
    float k = size.x / size.y;
    float2 p = float2(uv.x * k, uv.y);
    float t = time;

    float3 A = float3(ca.rgb);
    float3 B = float3(cb.rgb);
    float3 C = float3(cc.rgb);

    // base: escuro no topo, mais vivo embaixo
    float v = 1.0 - smoothstep(0.0, 0.95, uv.y);
    float3 col = mix(A * 0.9, B * 0.85, v);

    // manchas de cor que flutuam bem devagar
    float2 c1 = float2(k * (0.22 + 0.10 * sin(t * 0.13)), 0.55 + 0.10 * cos(t * 0.11));
    float2 c2 = float2(k * (0.82 + 0.08 * cos(t * 0.09)), 0.28 + 0.12 * sin(t * 0.12));
    float2 c3 = float2(k * (0.50 + 0.18 * sin(t * 0.07 + 1.0)), 0.88 + 0.05 * cos(t * 0.10));
    float g1 = exp(-dot(p - c1, p - c1) * 4.5);
    float g2 = exp(-dot(p - c2, p - c2) * 4.0);
    float g3 = exp(-dot(p - c3, p - c3) * 6.0);
    float3 lift = B * 1.25;
    col = mix(col, lift, g1 * 0.45);
    col = mix(col, lift, g2 * 0.50);
    col = mix(col, A * 0.7, g3 * 0.35);

    // luz dourada atrás da Lumi
    float2 L = float2(k * 0.60, 0.33);
    float d = length(p - L);
    float pulse = 0.5 + 0.5 * sin(t * 0.55);
    col += C * exp(-d * d * 6.5) * (0.30 + 0.06 * pulse);
    col += C * exp(-d * 2.4) * 0.10;

    // raios suaves vindos do canto superior esquerdo
    float2 R = float2(k * 0.04, 1.12);
    float2 dr = p - R;
    float ang = atan2(dr.y, dr.x);
    float rays = pow(0.5 + 0.5 * sin(ang * 9.0 + t * 0.12), 3.0) * exp(-length(dr) * 1.25);
    col += C * rays * 0.085;
    col += C * exp(-length(dr) * 2.0) * 0.13;

    // vinheta leve
    col *= 0.84 + 0.16 * smoothstep(1.3, 0.2, length(uv - float2(0.5, 0.55)));

    // meio-tom mínimo só para evitar faixas no degradê
    col += (lh(pos) - 0.5) * (1.5 / 255.0);

    return half4(half3(clamp(col, 0.0, 1.0)), 1.0h);
}
