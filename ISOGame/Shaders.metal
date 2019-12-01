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
    out.uv = in.uv;
    out.worldTangent = uniforms.normalMatrix * in.tangent;
    out.worldBitangent = uniforms.normalMatrix * in.bitangent;
    
    return out;
}

float3 render(Lighting lighting);

fragment float4 fragment_main(
                              VertexOut in [[ stage_in ]],
                              constant FragmentUniforms &fragmentUniforms [[ buffer(BufferIndexFragmentUniforms) ]],
                              constant Material &material [[ buffer(BufferIndexMaterials) ]],
                              texture2d<float> albedoTexture [[ texture(TextureAlbedo), function_constant(hasAlbedoTexture) ]],
                              texture2d<float> normalTexture [[ texture(TextureNormal), function_constant(hasNormalTexture) ]],
                              texture2d<float> roughnessTexture [[ texture(TextureRoughness), function_constant(hasRoughnessTexture) ]],
                              texture2d<float> metallicTexture [[ texture(TextureMetallic), function_constant(hasMetallicTexture) ]]
//                              texture2d<float> emissionTexture [[ texture(TextureNormal), function_constant(hasEmissionTexture) ]]
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
    
    float3 viewDirection = normalize(fragmentUniforms.cameraPosition - in.worldPosition);
    
    // Hardcoded sun
    float3 lightDirection = normalize(-float3(1, 2, -2));
    float3 lightColor = float3(1, 1, 1);
    
    Lighting lighting;
    lighting.lightDirection = lightDirection;
    lighting.viewDirection = viewDirection;
    lighting.albedo = albedo;
    lighting.normal = normal;
    lighting.metallic = metallic;
    lighting.roughness = roughness;
    lighting.ambientOcclusion = 1.0;
    lighting.lightColor = lightColor;
    

    float3 specularOutput = render(lighting);
    
    // compute Lambertian diffuse
    float nDotl = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
    
    // rescale from -1 : 1 to 0.4 - 1 to lighten shadows
    nDotl = ((nDotl + 1) / (1 + 1)) * (1 - 0.3) + 0.3;

    float3 diffuseColor = lightColor * albedo * nDotl * lighting.ambientOcclusion;
    diffuseColor *= 1.0 - metallic;

    float4 finalColor = float4(specularOutput + diffuseColor, 1.0);

    return finalColor;
}









/*
PBR.metal rendering equation from Apple's LODwithFunctionSpecialization sample code is under Copyright © 2017 Apple Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


float3 render(Lighting lighting) {
  // Rendering equation courtesy of Apple et al.
  float nDotl = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
  float3 halfVector = normalize(lighting.lightDirection + lighting.viewDirection);
  float nDoth = max(0.001, saturate(dot(lighting.normal, halfVector)));
  float nDotv = max(0.001, saturate(dot(lighting.normal, lighting.viewDirection)));
  float hDotl = max(0.001, saturate(dot(lighting.lightDirection, halfVector)));
  
  // specular roughness
  float specularRoughness = lighting.roughness * (1.0 - lighting.metallic) + lighting.metallic;
  
  // Distribution
  float Ds;
  if (specularRoughness >= 1.0) {
    Ds = 1.0 / pi;
  }
  else {
    float roughnessSqr = specularRoughness * specularRoughness;
    float d = (nDoth * roughnessSqr - nDoth) * nDoth + 1;
    Ds = roughnessSqr / (pi * d * d);
  }
  
  // Fresnel
  float3 Cspec0 = float3(1.0);
  float fresnel = pow(clamp(1.0 - hDotl, 0.0, 1.0), 5.0);
  float3 Fs = float3(mix(float3(Cspec0), float3(1), fresnel));
  
  
  // Geometry
  float alphaG = (specularRoughness * 0.5 + 0.5) * (specularRoughness * 0.5 + 0.5);
  float a = alphaG * alphaG;
  float b1 = nDotl * nDotl;
  float b2 = nDotv * nDotv;
  float G1 = (float)(1.0 / (b1 + sqrt(a + b1 - a*b1)));
  float G2 = (float)(1.0 / (b2 + sqrt(a + b2 - a*b2)));
  float Gs = G1 * G2;
  
  float3 specularOutput = (Ds * Gs * Fs * lighting.lightColor) * (1.0 + lighting.metallic * lighting.albedo) + lighting.metallic * lighting.lightColor * lighting.albedo;
  specularOutput = specularOutput * lighting.ambientOcclusion;
  
  return specularOutput;
}

