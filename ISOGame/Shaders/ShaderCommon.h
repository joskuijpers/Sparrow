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

#define MAX_LIGHTS_PER_TILE 256
#define LIGHT_CULLING_TILE_SIZE 16

/// Model uniforms
typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
} Uniforms;

/// Camera uniforms.
typedef struct {
    vector_float3 cameraWorldPosition;
    
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewProjectionMatrix;
    matrix_float4x4 invProjectionMatrix;
    matrix_float4x4 invViewProjectionMatrix;
    matrix_float4x4 invViewMatrix;
    
//    time uniforms->frameTime = (float) -[_baseTime timeIntervalSinceNow];
//    uniforms->screenSize    = float2{(float)_mainViewWidth, (float)_mainViewHeight};
//    uniforms->invScreenSize = 1.0f / uniforms->screenSize;
    
    vector_float2 physicalSize;
    
    vector_float4 invProjectionZ;           // A float4 containing the lower right 2x2 z,w block of inv projection matrix (column Major) ; viewZ = (X * projZ + Z) / (Y * projZ + W)
    vector_float4 invProjectionZNormalized; // Same as invProjZ but the result is a Z from 0...1 instead of N...F; effectively linearizes Z for easy visualization/storage
} CameraUniforms;

typedef enum {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 11,
    BufferIndexCameraUniforms = 13,
    BufferIndexMaterials = 14,
} BufferIndex;

typedef enum {
    VertexAttributePosition = 0,
    VertexAttributeNormal = 1,
    VertexAttributeUV = 2,
    VertexAttributeTangent = 3,
    VertexAttributeBitangent = 4
} VertexAttributes;

/// Texture attribute positions
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

/// Material definition
typedef struct {
    vector_float3 albedo;
    float shininess;
    float metallic;
    float roughness;
    vector_float3 emission;
} Material;

/// Type of the light
typedef enum {
    LightTypeDirectional = 0,
    LightTypeSpot = 1,
    LightTypePoint = 2
} LightType;

/// Data pertaining lights that is transferred from CPU to GPU
typedef struct {
    vector_float3 position;
    vector_float3 color;
    float range;
//    float intensity;
//    vector_float3 attenuation;
    LightType type;
} LightData;













#endif /* ShaderCommon_h */
