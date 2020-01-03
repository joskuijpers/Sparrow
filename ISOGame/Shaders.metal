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
constant float pi_inv = 0.31830988618;

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
struct LightingParams {
    float3 albedo;
    float3 normal;
    float ambientOcclusion;
    float metallic;
    float roughness;
    
    float3 viewDirection;
    
    float3 lightDirection;
    float3 diffuseLightColor;
    
    float3 halfVector;
    float3 reflectedVector;
    float NdotL;
    float NdotH;
    float NdotV;
    float HdotL;
    
    float3 irradiatedColor;
};


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

float3 diffuseTerm(LightingParams params);
float3 specularTerm(LightingParams params);

fragment float4 fragment_main(
                              VertexOut in [[ stage_in ]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms) ]],
                              constant Material &material [[ buffer(BufferIndexMaterials) ]],
                              texture2d<float> albedoTexture [[ texture(TextureAlbedo), function_constant(hasAlbedoTexture) ]],
                              texture2d<float> normalTexture [[ texture(TextureNormal), function_constant(hasNormalTexture) ]],
                              texture2d<float> roughnessTexture [[ texture(TextureRoughness), function_constant(hasRoughnessTexture) ]],
                              texture2d<float> metallicTexture [[ texture(TextureMetallic), function_constant(hasMetallicTexture) ]],
//                              texture2d<float> emissionTexture [[ texture(TextureNormal), function_constant(hasEmissionTexture) ]]
                              texture2d<float> aoTexture [[ texture(TextureAmbientOcclusion), function_constant(hasAmbientOcclusionTexture) ]],
                              texturecube<float> irradianceMap [[ texture(TextureIrradiance) ]],
                              
                              constant LightData *lights [[ buffer(16) ]],
                              constant int &lightsCount [[ buffer(15) ]]
                              ) {
    constexpr sampler linearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
    constexpr sampler mipSampler(min_filter::linear, mag_filter::linear, mip_filter::linear);
    
    float3 albedo;
    if (hasAlbedoTexture) {
        albedo = albedoTexture.sample(linearSampler, in.uv).rgb;
    } else {
        albedo = material.albedo;
    }
    
    float3 normalValue;
    if (hasNormalTexture) {
        normalValue = normalTexture.sample(linearSampler, in.uv).rgb * 2.0 - 1.0;
    } else {
        normalValue = in.worldNormal;
    }
    float3x3 TBN = float3x3(in.worldTangent, in.worldBitangent, in.worldNormal);
    float3 normal = normalize(TBN * normalValue);
    
    float metallic;
    if (hasMetallicTexture) {
        metallic = metallicTexture.sample(linearSampler, in.uv).r;
    } else {
        metallic = material.metallic;
    }
    
    float roughness;
    if (hasRoughnessTexture) {
        roughness = roughnessTexture.sample(linearSampler, in.uv).r;
    } else {
        roughness = material.roughness;
    }
    
    float ambientOcclusion;
    if (hasAmbientOcclusionTexture) {
        ambientOcclusion = aoTexture.sample(linearSampler, in.uv).r;
    } else {
        ambientOcclusion = 1.0;
    }
    
    float3 emissiveColor = material.emission;
    
    // DEF TODO:
    // read shading model identifier
    // 0 = default
    // 1 = SSS
    // ...
    
    //https://seblagarde.wordpress.com/2012/01/08/pi-or-not-to-pi-in-game-lighting-equation/
    //https://learnopengl.com/PBR/Lighting
    //https://seblagarde.wordpress.com/2011/08/17/feeding-a-physical-based-lighting-mode/  specular colors (F0)
    //TODO add specular color image / property? no: https://blog.selfshadow.com/publications/s2013-shading-course/karis/s2013_pbs_epic_notes_v2.pdf
    
    float3 lighting = float3(0.0);
    
    LightingParams parameters;
    parameters.albedo = albedo;
    parameters.normal = normal;
    parameters.ambientOcclusion = ambientOcclusion;
    parameters.metallic = metallic;
    parameters.roughness = roughness;
    parameters.viewDirection = normalize(fragmentUniforms.cameraPosition - in.worldPosition);
    parameters.NdotV = saturate(dot(parameters.normal, parameters.viewDirection));

    for (int i = 0; i < lightsCount; ++i) {
        LightData light = lights[i];
        
        float3 lightDirection = float3(1, 0, 0);
        float attenuation = 1.0;
        
        float3 lightColor = light.color;
    
        if (light.type == LightTypeDirectional) {
            lightDirection = normalize(-light.position);
            attenuation = 1.0;
        } else if (light.type == LightTypePoint) {
            lightDirection = normalize(light.position - in.worldPosition);
            float distance = length(light.position - in.worldPosition);
            attenuation = 1.0 / (distance * distance);
        }

        parameters.lightDirection = lightDirection;
        parameters.diffuseLightColor = lightColor * attenuation;
        parameters.halfVector = normalize(parameters.lightDirection + parameters.viewDirection);
        parameters.reflectedVector = reflect(-parameters.viewDirection, parameters.normal);
        parameters.NdotL = saturate(dot(parameters.normal, parameters.lightDirection));
        parameters.NdotH = saturate(dot(parameters.normal, parameters.halfVector));
        parameters.HdotL = saturate(dot(parameters.lightDirection, parameters.halfVector));
    
        float mipLevel = parameters.roughness * irradianceMap.get_num_mip_levels();
        parameters.irradiatedColor = irradianceMap.sample(mipSampler, parameters.reflectedVector, level(mipLevel)).rgb;

        lighting += diffuseTerm(parameters) + specularTerm(parameters);

        //Translucency https://github.com/gregouar/VALAG/blob/master/Valag/shaders/lighting/lighting.frag
        //float t         = fragRmt.b;
        //lighting.rgb   -= (kD * fragAlbedo.rgb*0.31830988618) * radiance * min(dot(fragNormal.xyz, lightDirection), 0.0)*t* occlusion;
    }
    
    // Create an improvised Ambient term
    float3 ambient = float3(0.03) * albedo * ambientOcclusion;
    float3 color = ambient + lighting + emissiveColor;
    
    // HDR Tone mapping
    color = color / (color + float3(1.0));
    // Gamma correction
    color = pow(color, float3(1.0 / 2.2));
    
    return float4(color, 1.0);
}



inline float fresnelSchlick(float dotProduct);
static float GeometrySchlickGGX(float NdotV, float alphaG);
static float TrowbridgeReitzNDF(float NdotH, float roughness);

/// Lambertian BRDF lighting (Cdiff/pi) for non-metallic surfaces
float3 diffuseTerm(LightingParams params) {
    float3 diffuseColor = (params.albedo * pi_inv) * (1.0 - params.metallic);
    return diffuseColor * params.NdotL * params.diffuseLightColor;
}


float3 specularTerm(LightingParams params) {
    float specularRoughness = params.roughness * (1.0 - params.metallic) + params.metallic;
    
    float D = TrowbridgeReitzNDF(params.NdotH, specularRoughness);
    
    float F0 = 0.04;
    float3 F = mix(F0, 1, fresnelSchlick(params.HdotL));
    
    float alphaG = powr(specularRoughness * 0.5 + 0.5, 2);
    float G = GeometrySchlickGGX(params.NdotL, alphaG) * GeometrySchlickGGX(params.NdotV, alphaG);
    
    // https://github.com/warrenm/GLTFKit/blob/ec24ca8d822dfb29fc8f413d54b6276581b47374/GLTFViewer/Resources/Shaders/pbr.metal#L396
    float3 specularOutput = (D * F * G * params.irradiatedColor)
        * (1.0 + params.metallic * params.albedo)
        + params.irradiatedColor * params.metallic * params.albedo;
    
    return specularOutput;
}

/// Normal distribution function (NDF) from Disney GGX/Trowbridge-Reitz
static float TrowbridgeReitzNDF(float NdotH, float roughness) {
    if (roughness >= 1.0) {
        return pi_inv;
    }

    float roughnessSqr = roughness * roughness;

    float d = (NdotH * roughnessSqr - NdotH) * NdotH + 1;
    return roughnessSqr / (pi * d * d);
}

static float GeometrySchlickGGX(float NdotV, float alphaG) {
    float a = alphaG * alphaG;
    float b = NdotV * NdotV;
    
    return 1.0 / (NdotV + sqrt(a + b - a * b));
}

/// Calculate ratio between specular and diffuse reflection
/// @param F0 Specular at normal incidence
inline float fresnelSchlick(float dotProduct) {
    return pow(clamp(1.0 - dotProduct, 0.0, 1.0), 5.0);
    
    // Using a replaced power for performance (Spherical Gaussian approximation)
//    return pow(2.0, -5.55473 * dotProduct - 6.98316 * dotProduct);
}
