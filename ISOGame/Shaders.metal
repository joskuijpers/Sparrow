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

constant float pi = 3.1415926535897932384626433832795;

constant bool hasAlbedoTexture [[ function_constant(0) ]];
constant bool hasNormalTexture [[ function_constant(1) ]];
constant bool hasRoughnessTexture [[ function_constant(2) ]];
constant bool hasMetallicTexture [[ function_constant(3) ]];
//constant bool hasEmissionTexture [[ function_constant(4) ]];
constant bool hasAmbientOcclusionTexture [[ function_constant(5) ]];

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

/// Lighting calculation input,
typedef struct Lighting {
  float3 lightDirection;
  float3 viewDirection;
  float3 albedo;
  float3 normal;
  float metallic;
  float roughness;
  float ambientOcclusion;
  float3 lightColor;
} Lighting;


vertex VertexOut vertex_main(
                             const VertexIn in [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]
                             ) {
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    out.worldPosition = (uniforms.modelMatrix * in.position).xyz;
    out.worldNormal = uniforms.normalMatrix * in.normal;
    out.worldTangent = uniforms.normalMatrix * in.tangent;
    out.worldBitangent = uniforms.normalMatrix * in.bitangent;
    
    out.uv = in.uv;
    
    return out;
}

float3 fresnelSchlick(float cosTheta, float3 F0);
float DistributionGGX(float3 N, float3 H, float roughness);
float GeometrySmith(float3 N, float3 V, float3 L, float roughness);

fragment float4 fragment_main(
                              VertexOut in [[ stage_in ]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms) ]],
                              constant Material &material [[ buffer(BufferIndexMaterials) ]],
                              texture2d<float> albedoTexture [[ texture(TextureAlbedo), function_constant(hasAlbedoTexture) ]],
                              texture2d<float> normalTexture [[ texture(TextureNormal), function_constant(hasNormalTexture) ]],
                              texture2d<float> roughnessTexture [[ texture(TextureRoughness), function_constant(hasRoughnessTexture) ]],
                              texture2d<float> metallicTexture [[ texture(TextureMetallic), function_constant(hasMetallicTexture) ]],
//                              texture2d<float> emissionTexture [[ texture(TextureNormal), function_constant(hasEmissionTexture) ]]
                              texture2d<float> aoTexture [[ texture(TextureAmbientOcclusion), function_constant(hasAmbientOcclusionTexture) ]]
                              ) {
    constexpr sampler textureSampler(address::repeat, filter::linear, mip_filter::linear);
    
    // albedo = color
    float3 albedo;
    if (hasAlbedoTexture) {
        albedo = albedoTexture.sample(textureSampler, in.uv).rgb;
    } else {
        albedo = material.albedo;
    }
    
    float3 normalValue;
    if (hasNormalTexture) {
        normalValue = normalTexture.sample(textureSampler, in.uv).rgb * 2.0 - 1.0;
    } else {
        normalValue = in.worldNormal;
    }
    normalValue = normalize(normalValue);
    float3 normal = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal) * normalValue;
    
    float metallic;
    if (hasMetallicTexture) {
        metallic = metallicTexture.sample(textureSampler, in.uv).r;
    } else {
        metallic = material.metallic;
    }
    
    float roughness;
    if (hasRoughnessTexture) {
        roughness = roughnessTexture.sample(textureSampler, in.uv).r;
    } else {
        roughness = material.roughness;
    }
    
    float ambientOcclusion;
    if (hasAmbientOcclusionTexture) {
        ambientOcclusion = aoTexture.sample(textureSampler, in.uv).r;
    } else {
        ambientOcclusion = 1.0;
    }
    
    // DEF TODO:
    // read shading model identifier
    // 0 = default
    // 1 = SSS
    // ...

    float3 viewDirection = normalize(fragmentUniforms.cameraPosition - in.worldPosition);
    
    // Use a hardcoded 0.04 F0 for any nonmetals
    float3 F0 = float3(0.04);
    F0 = mix(F0, albedo, metallic);
    
    // For our sun light, until we support multiple lights
    float3 lightPosition = float3(0, -1, 10);
    float3 lightColor = float3(1, 1, 1);
    
    //https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    //https://learnopengl.com/PBR/Lighting
    //https://seblagarde.wordpress.com/2011/08/17/feeding-a-physical-based-lighting-mode/  specular colors (F0)
    //TODO add specular color image / property? no: https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf

    float3 lighting = float3(0.0);
    
    float3 envColor = float3(0.5, 0.5, 0.5);
    
//    for each light
//    {
        float3 lightDirection;
        float attenuation;
    
//        if directionalLight {
            lightDirection = normalize(-lightPosition);
            attenuation = 1.0;
//        } else { // point light
//            lightDirection = normalize(lightPosition - in.worldPosition);
//            float distance = length(lightPosition - in.worldPosition); // point light
//            attenuation = 1.0 / (distance * distance);
//        }
        
        float3 halfwayVector = normalize(viewDirection + lightDirection);
        float NdotL = max(dot(normal, lightDirection), 0.0);

        float3 radiance = lightColor * attenuation;
    
        float NDF = DistributionGGX(normal, halfwayVector, roughness);
        float G = GeometrySmith(normal, viewDirection, lightDirection, roughness);
        float3 F = fresnelSchlick(max(dot(halfwayVector, viewDirection), 0.0), F0);
        
        float3 kS = F; // specular contribution
        float3 kD = 1.0 - kS; // diffuse contribution
        kD *= float(1.0 - metallic); // metallic does not have diffuse, so clear it (metallic=1 gives kD=0)
        
        // Calculate Cook-Torrance BRDF
        float3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(normal, viewDirection), 0.0) * NdotL;
        float3 specular = numerator / (denominator + 0.001);

        // Lambertian BRDF lighting (Cdiff / pi) where Cdiff is fraction of light reflected (diffuse) which is kD*albedo.
        float3 lambert = kD * albedo * 0.31830988618; // division by pi, approx.
        // FinalColor = c_diff * c_light * dot(n, l)
    
        lighting += (lambert + specular) * radiance * NdotL;
    
    
    
        //Translucency https://github.com/gregouar/VALAG/blob/master/Valag/shaders/lighting/lighting.frag
        //float t         = fragRmt.b;
        //lighting.rgb   -= (kD * fragAlbedo.rgb*0.31830988618) * radiance * min(dot(fragNormal.xyz, lightDirection), 0.0)*t* occlusion;

//    }
    
    // Create an improvised Ambient term
    float3 ambient = float3(0.03) * albedo * ambientOcclusion;
    float3 color = ambient + lighting;
    
    // HDR Tone mapping
    color = color / (color + float3(1.0));
    // Gamma correction
    color = pow(color, float3(1.0 / 2.2));
    
    return float4(color, 1.0);
}

/// Normal distribution function (NDF) from Disney GGX/Trowbridge-Reitz
inline float DistributionGGX(float3 N, float3 H, float roughness)
{
    float a      = roughness * roughness;
    float a2     = a * a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = pi * denom * denom;
    
    return num / denom;
}

/// Gs1 where h=roughness.
inline float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r * r) * 0.125;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    
    return num / denom;
}

/// Gs(l, v, h): h=roughness, Disney version
float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
    
    return ggx1 * ggx2;
}

/// Calculate ratio between specular and diffuse reflection
/// @param F0 Specular at normal incidence
float3 fresnelSchlick(float cosTheta, float3 F0)
{
    // Using a replaced power for performance (Spherical Gaussian approximation)
//    return F0 + (1.0 - F0) * pow(2.0, -5.55473 * cosTheta - 6.98316 * cosTheta);
    //Apple seems to clamp the 1.0-cosTheta to 0-1
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}
