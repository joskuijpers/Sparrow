//
//  STFUtilities.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import ModelIO
import Metal

func STFGetVertexFormat(componentType: Int, type: String) -> MDLVertexFormat {
    var dataType = MDLVertexFormat.invalid
    switch componentType {
    case 5120 where type == "SCALAR":
        dataType = .char
    case 5120 where type == "VEC2":
        dataType = .char2
    case 5120 where type == "VEC3":
        dataType = .char3
    case 5120 where type == "VEC4":
        dataType = .char4
    case 5121 where type == "SCALAR":
        dataType = .uChar
    case 5121 where type == "VEC2":
        dataType = .uChar2
    case 5121 where type == "VEC3":
        dataType = .uChar3
    case 5121 where type == "VEC4":
        dataType = .uChar4
    case 5122 where type == "SCALAR":
        dataType = .short
    case 5122 where type == "VEC2":
        dataType = .short2
    case 5122 where type == "VEC3":
        dataType = .short3
    case 5122 where type == "VEC4":
        dataType = .short4
    case 5123 where type == "SCALAR":
        dataType = .uShort
    case 5123 where type == "VEC2":
        dataType = .uShort2
    case 5123 where type == "VEC3":
        dataType = .uShort3
    case 5123 where type == "VEC4":
        dataType = .uShort4
    case 5125 where type == "SCALAR":
        dataType = .uInt
    case 5125 where type == "VEC2":
        dataType = .uInt2
    case 5125 where type == "VEC3":
        dataType = .uInt3
    case 5125 where type == "VEC4":
        dataType = .uInt4
    case 5126 where type == "SCALAR":
        dataType = .float
    case 5126 where type == "VEC2":
        dataType = .float2
    case 5126 where type == "VEC3":
        dataType = .float3
    case 5126 where type == "VEC4":
        dataType = .float4
    default: break
    }
    return dataType
}

func STFStrideOf(vertexFormat: MDLVertexFormat) -> Int {
    switch vertexFormat {
    case .float2:
        return MemoryLayout<Float>.stride * 2
    case .float3:
        return MemoryLayout<Float>.stride * 3
    case .float4:
        return MemoryLayout<Float>.stride * 4
    case .uShort4:
        return MemoryLayout<ushort>.stride * 4
    default:
        fatalError("MDLVertexFormat: \(vertexFormat.rawValue) not supported")
    }
}

enum STFAttribute: String {
    case position = "POSITION",
    normal = "NORMAL",
    texCoord = "TEXCOORD_0",
    //    joints = "JOINTS_0",
    //    weights = "WEIGHTS_0",
    tangent = "TANGENT",
    bitangent = "BITANGENT",
    color = "COLOR_0"
    
    func bufferIndex() -> Int {
        switch self {
        case .position:
            return 0
        case .normal:
            return 1
        case .texCoord:
            return 2
            //        case .joints:
            //            return 3
            //        case .weights:
        //            return 4
        case .tangent:
            return 5
        case .bitangent:
            return 6
        case .color:
            return 7
        }
    }
}

func STFMakeVertexDescriptor() -> MDLVertexDescriptor {
    let descriptor = MDLVertexDescriptor()
    (descriptor.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
    (descriptor.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
    (descriptor.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
    (descriptor.attributes[3] as! MDLVertexAttribute).name = MDLVertexAttributeTangent
    (descriptor.attributes[4] as! MDLVertexAttribute).name = MDLVertexAttributeBitangent
    (descriptor.attributes[5] as! MDLVertexAttribute).name = MDLVertexAttributeColor
//    (descriptor.attributes[6] as! MDLVertexAttribute).name = MDLVertexAttributeJointIndices
//    (descriptor.attributes[7] as! MDLVertexAttribute).name = MDLVertexAttributeJointWeights
    return descriptor
}
