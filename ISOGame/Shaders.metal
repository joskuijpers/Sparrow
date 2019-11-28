//
//  Shaders.metal
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderCommon.h"

struct VertexIn {
    float4 position     [[ attribute(VertexAttributePosition) ]];
    float3 normal       [[ attribute(VertexAttributeNormal) ]];
    float2 uv           [[ attribute(VertexAttributeUV) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
};

vertex VertexOut vertex_main(
                             const VertexIn in [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]
                             ) {
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    out.worldPosition = (uniforms.modelMatrix * in.position).xyz;
    out.worldNormal = uniforms.normalMatrix * in.normal;
    out.uv = in.uv;
    
    return out;
}

fragment float4 fragment_main(
                              VertexOut in [[ stage_in ]],
                              texture2d<float> albedoTexture [[ texture(TextureAlbedo) ]]
                              ) {
    constexpr sampler textureSampler(address::repeat, filter::linear, mip_filter::linear);
    
    // albedo = color
    float3 albedo = float3(0.5, 0.2, 0.5);
    
    albedo = albedoTexture.sample(textureSampler, in.uv).rgb;
    
    // if hasALbedoTexture
        // albedo = sample

    // normal = vetex normal
    // if hasNormalTexture
        // normal = sample
    
    //
    
    
    float3 diffuse = 0;
    
    // Sun
    float3 normalDirection = normalize(in.worldNormal);
    
    float3 lightDirection = normalize(-float3(1, 2, -2));
    float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
    diffuse += float3(1, 1, 1) * albedo * diffuseIntensity;
    
    // Ambient
    diffuse += albedo * float3(1, 1, 1) * 0.1;
    
    return float4(diffuse, 1);
}