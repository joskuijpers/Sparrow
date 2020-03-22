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

struct VertexIn {
    float3 position     [[ attribute(0) ]];
    float3 color        [[ attribute(1) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 color;
};

vertex VertexOut vertex_debug(
                              const constant VertexIn *vertexArray [[ buffer(0) ]],
                              unsigned int vid [[ vertex_id ]],
                              constant CameraUniforms &cameraUniforms [[ buffer(BufferIndexCameraUniforms) ]]
                              ) {
    VertexIn in = vertexArray[vid];
    VertexOut out;
    
    out.position = cameraUniforms.viewProjectionMatrix * float4(in.position, 1);
    out.color = in.color;
    
    return out;
}

fragment float4 fragment_debug(
                               VertexIn in [[ stage_in ]]
                               ) {
    return float4(in.color, 1);
}
