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

public class STFSubmesh {
    var material: MDLMaterial?
    var primitiveType: MDLGeometryType = .triangles
    var indexAccessor: STFAccessor!
    var accessorsForAttribute = [String: STFAccessor]()
    
    var indexCount: Int = 0
    var indexBuffer: MTLBuffer?
    var indexBufferOffset: Int = 0
    
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
