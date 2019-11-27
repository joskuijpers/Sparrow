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

struct VertexIn {
    float4 position     [[ attribute(0) ]];
    float3 normal       [[ attribute(1) ]];
    float2 uv           [[ attribute(2) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float3 worldPosition;
    float3 worldNormal;
    float2 uv;
};

vertex VertexOut vertex_main(const VertexIn in [[ stage_in ]],
                             constant Uniforms &uniforms [[ buffer(1) ]]) {
    VertexOut out;
    
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * in.position;
    out.worldPosition = (uniforms.modelMatrix * in.position).xyz;
    out.worldNormal = uniforms.normalMatrix * in.normal;
    out.uv = in.uv;
    
    return out;
}

fragment float4 fragment_main(VertexOut in [[ stage_in ]]) {
    return float4(in.worldPosition, 1);
}
