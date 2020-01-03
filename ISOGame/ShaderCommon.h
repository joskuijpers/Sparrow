//
//  ShaderCommon.h
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

#ifndef ShaderCommon_h
#define ShaderCommon_h

#import <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
    
    
//    time uniforms->frameTime = (float) -[_baseTime timeIntervalSinceNow];
//    uniforms->screenSize    = float2{(float)_mainViewWidth, (float)_mainViewHeight};
//    uniforms->invScreenSize = 1.0f / uniforms->screenSize;
    
} Uniforms;

typedef struct {
    vector_float3 cameraPosition;
} FragmentUniforms;

typedef enum {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 11,
    BufferIndexFragmentUniforms = 13,
    BufferIndexMaterials = 14,
} BufferIndex;

typedef enum {
    VertexAttributePosition = 0,
    VertexAttributeNormal = 1,
    VertexAttributeUV = 2,
    VertexAttributeTangent = 3,
    VertexAttributeBitangent = 4
} VertexAttributes;

typedef enum {
    TextureAlbedo = 0,
    TextureNormal = 1,
    TextureSpecular = 2,
    TextureRoughness = 3,
    TextureMetallic = 4,
    TextureEmissive = 5,
    TextureAmbientOcclusion = 6,
    
    TextureIrradiance = 10
} Textures;

typedef struct {
    vector_float3 albedo;
    float shininess;
    float metallic;
    float roughness;
    vector_float3 emission;
} Material;

typedef enum {
    LightTypeDirectional = 0,
    LightTypeSpot = 1,
    LightTypePoint = 2
} LightType;

typedef struct {
    vector_float4 position;
    vector_float3 color;
//    float intensity;
//    vector_float3 attenuation;
    LightType type;
} LightData;

#endif /* ShaderCommon_h */
