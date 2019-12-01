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

constant bool hasAlbedoTexture [[ function_constant(0) ]];
constant bool hasNormalTexture [[ function_constant(1) ]];
// metallic
// roughness
// emission

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
    float3 worldTangent;
    float3 worldBitangent;
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
    out.worldTangent = uniforms.normalMatrix * in.tangent;
    out.worldBitangent = uniforms.normalMatrix * in.bitangent;
    
    return out;
}

fragment float4 fragment_main(
                              VertexOut in [[ stage_in ]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms) ]],
                              constant Material &material [[ buffer(BufferIndexMaterials) ]],
                              texture2d<float> albedoTexture [[ texture(TextureAlbedo), function_constant(hasAlbedoTexture) ]],
                              texture2d<float> normalTexture [[ texture(TextureNormal), function_constant(hasNormalTexture) ]]
                              ) {
    constexpr sampler textureSampler(address::repeat, filter::linear, mip_filter::linear);
    
    // albedo = color
    float3 albedo;
    if (hasAlbedoTexture) {
        albedo = albedoTexture.sample(textureSampler, in.uv).rgb;
    } else {
        albedo = material.albedo;
    }
    
    float3 normal;
    if (hasNormalTexture) {
        normal = normalTexture.sample(textureSampler, in.uv).xyz * 2.0 - 1.0;
    } else {
        normal = in.worldNormal;
    }
    normal = normalize(normal);
    
    float materialShininess = material.shininess;
    float3 materialSpecularColor = material.specularColor;
    
    float3 diffuse = 0;
    float3 ambient = 0;
    float3 specular = 0;
    
    // Sun
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
