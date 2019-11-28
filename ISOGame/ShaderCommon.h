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
} Uniforms;


typedef enum {
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1
} BufferIndex;

typedef enum {
    VertexAttributePosition = 0,
    VertexAttributeNormal = 1,
    VertexAttributeUV = 2
} VertexAttributes;

typedef enum {
    TextureAlbedo = 0,
    TextureNormal = 1,
    TextureSpecular = 2,
} Textures;


#endif /* ShaderCommon_h */