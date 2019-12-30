//
//  STFPrimitive.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import ModelIO
import Metal

public struct Attributes {
  var name = " "
  public var index: Int = 0
  public var bufferIndex: Int = 0
  public var offset: Int = 0
}

public class STFSubmesh {
    public var material: MDLMaterial?
    public var primitiveType: MDLGeometryType = .triangles
    public var indexAccessor: STFAccessor!
    public var accessorsForAttribute = [String: STFAccessor]()
    
    public var indexCount: Int = 0
    public var indexBuffer: MTLBuffer?
    public var indexBufferOffset: Int = 0
    public var indexType: MTLIndexType {
        let vertexFormat = STFGetVertexFormat(componentType: indexAccessor.componentType,
                                               type: "SCALAR")
        if vertexFormat == .uInt {
            return MTLIndexType.uint32
        }
        return MTLIndexType.uint16
    }
    public var attributes = [Attributes]()
    public var pipelineState: MTLRenderPipelineState?
    
//    public var pipelineState: MTLRenderPipelineState?
//    public var indexType: MTLIndexType {
//        let vertexFormat = STFGetVertexFormat(componentType: indexAccessor.componentType, type: "SCALAR")
//        if vertexFormat == .uInt {
//            return MTLIndexType.uint32
//        }
//        return MTLIndexType.uint16
//    }
    
//    init(json: JSONPrimitive) {
//
////        json.attributes
////        json.indices
////        json.material
////        json.mode
//
//        print("BUILD PRIMITIVE \(json)")
//    }
}
