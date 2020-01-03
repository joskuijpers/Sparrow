//
//  DebugShaders.metal
//  ISOGame
//
//  Created by Jos Kuijpers on 02/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderCommon.h"

vertex float4 vertex_debug_aabb(
                                const constant float3 *vertexArray [[ buffer(0) ]],
                                unsigned int vid [[ vertex_id ]],
                                constant float3 &minBounds [[ buffer(1) ]],
                                constant float3 &maxBounds [[ buffer(2) ]],
                                constant Uniforms &uniforms [[ buffer(BufferIndexUniforms) ]]
                                ) {
    float3 in = vertexArray[vid];
    
    // Adjust position based on lower/upper bounds. For every vertex at 0, use min
    // bound. Use max bound for vertices at 1
    float3 position = mix(minBounds, maxBounds, in);
    
    return uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * float4(position, 1);
}

fragment float4 fragment_debug_aabb(
                                    float4 in [[ stage_in ]],
                                    constant float3 &color [[ buffer(0) ]]
                                    ) {
    return float4(color, 1);
}
