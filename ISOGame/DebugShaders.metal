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
    
    if (in.x == 0) {
        in.x = minBounds.x;
    } else if (in.x == 1) {
        in.x = maxBounds.x;
    }
    
    if (in.y == 0) {
        in.y = minBounds.y;
    } else if (in.y == 1) {
        in.y = maxBounds.y;
    }
    
    if (in.z == 0) {
        in.z = minBounds.z;
    } else if (in.z == 1) {
        in.z = maxBounds.z;
    }
    
    return uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * float4(in, 1);
}

fragment float4 fragment_debug_aabb(
                                    float4 in [[ stage_in ]],
                                    constant float3 &color [[ buffer(0) ]]
                                    ) {
    return float4(color, 1);
}
