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
    float3 tangent      [[ attribute(VertexAttributeTangent) ]];
    float3 bitangent    [[ attribute(VertexAttributeBitangent) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
    float3 worldTangent;
    float3 worldBitangent;
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
    out.worldTangent = uniforms.normalMatrix * in.tangent;
    out.worldBitangent = uniforms.normalMatrix * in.bitangent;
    
    return out;
}

fragment float4 fragment_main(
                              VertexOut in [[ stage_in ]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms) ]],
                              constant Material &material [[ buffer(BufferIndexMaterials) ]],
                              texture2d<float> albedoTexture [[ texture(TextureAlbedo) ]],
                              texture2d<float> normalTexture [[ texture(TextureNormal) ]]
                              ) {
    constexpr sampler textureSampler(address::repeat, filter::linear, mip_filter::linear);
    
    // albedo = color
    float3 albedo = float3(0.5, 0.2, 0.5);
    
    
//    albedo = albedoTexture.sample(textureSampler, in.uv).rgb;
    albedo = material.albedo;
    
    // if hasALbedoTexture
        // albedo = sample
    float3 normal = normalTexture.sample(textureSampler, in.uv).xyz;
    normal = normal * 2 - 1;
    normal = normalize(normal);

    // normal = vetex normal
    // if hasNormalTexture
        // normal = sample
    
    //
    
    float materialShininess = material.shininess;
    float3 materialSpecularColor = material.specular;
    
    float3 diffuse = 0;
    float3 ambient = 0;
    float3 specular = 0;
    
    // Sun
//    float3 normalDirection = normalize(in.worldNormal);
    float3 normalDirection = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal) * normal;
    normalDirection = normalize(normalDirection);
    
    float3 lightDirection = normalize(-float3(1, 2, -2));
    float diffuseIntensity = saturate(-dot(lightDirection, normalDirection));
    diffuse += float3(1, 1, 1) * albedo * diffuseIntensity;
    if (diffuseIntensity > 0) {
        float3 reflection = reflect(lightDirection, normalDirection);
        float3 cameraDirection = normalize(in.worldPosition - fragmentUniforms.cameraPosition);
        float specularIntensity = pow(saturate(-dot(reflection, cameraDirection)), materialShininess);
        specular += float3(1, 1, 1) * materialSpecularColor * specularIntensity;
    }
    
    // Ambient
    diffuse += albedo * float3(1, 1, 1) * 0.1;
    
    float3 color = saturate(diffuse + ambient + specular);
    return float4(color, 1);
}
