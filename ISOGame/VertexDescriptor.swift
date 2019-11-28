//
//  VertexDescriptor.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

extension MDLVertexDescriptor {
    
    static var defaultVertexDescriptor: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        
        // Position
        let positionAttribute = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                   format: .float3,
                                                   offset: offset,
                                                   bufferIndex: 0)
        vertexDescriptor.attributes[Int(VertexAttributePosition.rawValue)] = positionAttribute
        offset += MemoryLayout<float3>.stride
        
        // Normal
        let normalAttribute = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                 format: .float3,
                                                 offset: offset,
                                                 bufferIndex: 0)
        vertexDescriptor.attributes[Int(VertexAttributeNormal.rawValue)] = normalAttribute
        offset += MemoryLayout<float3>.stride
        
        // UV
        let uvAttribute = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                             format: .float2,
                                             offset: offset,
                                             bufferIndex: 0)
        vertexDescriptor.attributes[Int(VertexAttributeUV.rawValue)] = uvAttribute
        offset += MemoryLayout<float2>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }()
    
}
