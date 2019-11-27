//
//  Shaders.metal
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertexIn [[ stage_in ]]) {
    return vertexIn.position;
}

fragment float4 fragment_main() {
    return float4(1, 0, 0, 1);
}
