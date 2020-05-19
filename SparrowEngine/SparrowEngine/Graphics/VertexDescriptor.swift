//
//  VertexDescriptor.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal
import SparrowAsset

class VertexDescriptor {

    /// Build a vertex descriptor using a list of Sparrow Asset vertex attributes. Order of the attributes defines position within the interleaved buffer.
    class func build(from attributes: [SAVertexAttribute]) -> MTLVertexDescriptor {
        let descriptor = MTLVertexDescriptor()
        
        print("BUILD VD FROM \(attributes)")
        
        var offset = 0
        
        for attribute in attributes {
            switch attribute {
            case .position:
                let index = Int(VertexAttributePosition.rawValue)
                
                descriptor.attributes[index].format = .float3
                descriptor.attributes[index].bufferIndex = 0 // TODO: allow more?
                descriptor.attributes[index].offset = offset
                
                // Do not use float3 stride! That is unpacked
                offset += MemoryLayout<Float>.size * 3
                
            case .normal:
                let index = Int(VertexAttributeNormal.rawValue)
                
                descriptor.attributes[index].format = .float3
                descriptor.attributes[index].bufferIndex = 0 // TODO: allow more?
                descriptor.attributes[index].offset = offset
                
                // Do not use float3 stride! That is unpacked
                offset += MemoryLayout<Float>.size * 3
                
            case .tangent:
                let index = Int(VertexAttributeTangent.rawValue)
                
                descriptor.attributes[index].format = .float3
                descriptor.attributes[index].bufferIndex = 0 // TODO: allow more?
                descriptor.attributes[index].offset = offset
                
                // Do not use float3 stride! That is unpacked
                offset += MemoryLayout<Float>.size * 3
                
            case .bitangent:
                let index = Int(VertexAttributeBitangent.rawValue)
                
                descriptor.attributes[index].format = .float3
                descriptor.attributes[index].bufferIndex = 0 // TODO: allow more?
                descriptor.attributes[index].offset = offset
                
                // Do not use float3 stride! That is unpacked
                offset += MemoryLayout<Float>.size * 3

            case .uv0:
                let index = Int(VertexAttributeUV0.rawValue)
                
                descriptor.attributes[index].format = .float2
                descriptor.attributes[index].bufferIndex = 0
                descriptor.attributes[index].offset = offset
                
                // Do not use float2 stride! That is unpacked
                offset += MemoryLayout<Float>.size * 2
                
            default:
                print("Unsupported attribute \(attribute)")
            }
        }
        
        print("TOTAL VERTEX SIZE \(offset)")
        
        descriptor.layouts[0].stride = offset
        
        return descriptor
    }
}
