//
//  Depth.metal
//  ISOGame
//
//  Created by Jos Kuijpers on 26/04/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderCommon.h"

constant bool hasAlbedoTexture [[ function_constant(0) ]];

/// Default in-vertex
struct VertexIn {
    float4 position     [[ attribute(VertexAttributePosition) ]];
    float3 normal       [[ attribute(VertexAttributeNormal) ]];
    float2 uv           [[ attribute(VertexAttributeUV0) ]];
    float3 tangent      [[ attribute(VertexAttributeTangent) ]];
    float3 bitangent    [[ attribute(VertexAttributeBitangent) ]];
};

/// Vertex attributes for a depth-only pass
struct VertexDepthOnlyOut {
    float4 position [[ position ]];
};

/// Vertex attributes for a depth-only pass with alpha testing.
struct VertexDepthUVOut {
    float4 position [[ position ]];
    float2 uv;
};

/// Depth only vertex function: only calculates vertex position
vertex VertexDepthOnlyOut vertex_main_depth(
                                            const VertexIn in [[ stage_in ]],
                                            constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]],
                                            constant CameraUniforms &cameraUniforms [[ buffer(BufferIndexCameraUniforms) ]]
                                            ) {
    VertexDepthOnlyOut out;
    
    out.position = cameraUniforms.viewProjectionMatrix * uniforms.modelMatrix * in.position;
    
    return out;
}

/// Depth only vertex function with alpha testing: only calculates vertex position and UV coordinates
vertex VertexDepthUVOut vertex_main_depth_alphatest(
                                                    const VertexIn in [[ stage_in ]],
                                                    constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]],
                                                    constant CameraUniforms &cameraUniforms [[ buffer(BufferIndexCameraUniforms) ]]
                                                    ) {
    VertexDepthUVOut out;
    
    out.position = cameraUniforms.viewProjectionMatrix * uniforms.modelMatrix * in.position;
    out.uv = in.uv;
    
    return out;
}

/// A fragment shader that discards fragments from alpha
fragment void fragment_main_depth_alphatest(VertexDepthUVOut in [[ stage_in ]],
                                            texture2d<float> albedoTexture [[ texture(TextureAlbedo), function_constant(hasAlbedoTexture) ]]) {
    if (hasAlbedoTexture) {
        constexpr sampler linearSampler(mip_filter::linear, mag_filter::linear, min_filter::linear);
        float alpha = albedoTexture.sample(linearSampler, in.uv).a;
        if (alpha < 0.5) {
            discard_fragment();
        }
    }
}
