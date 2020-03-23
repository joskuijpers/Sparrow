//
//  Resolve.metal
//  ISOGame
//
//  Created by Jos Kuijpers on 23/03/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;




struct SimpleTexVertexOut
{
    float4 position [[position]];
    float2 texCoord;
};

vertex SimpleTexVertexOut FSQuadVertexShader(uint vid [[vertex_id]])
{
    SimpleTexVertexOut out;
    
    out.texCoord = float2((vid << 1) & 2, vid & 2);
    out.position = float4(out.texCoord * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f), 1.0f, 1.0f);
    
    return out;
}

fragment half4 resolveShader(
                              SimpleTexVertexOut in [[ stage_in ]],
                              texture2d<half, access::sample> hdrLightingTexture [[ texture(0) ]]
                              ) {
    constexpr sampler readSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_zero, coord::pixel);
    
    float2 screenPos = in.position.xy;
    
    half3 hdr = hdrLightingTexture.sample(readSampler, screenPos).rgb;
    
    // TODO: Tone mapping
    half3 result = hdr;
    
    // TODO: Gamma correction
    
    return half4(result, 0);
}
