//
//  STFObject.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

public class STFNode {
    let nodeIndex: Int
    public let name: String
    
    
    
    // Hierarchy
    let childIndices: [Int]
    public var children = [STFNode]()
    public weak var parent: STFNode?
    
    var mesh: STFMesh?
    
    var rotationQuaternion = simd_quatf()
    var scale = float3(repeating: 1)
    var translation = float3(repeating: 0)
    var matrix: float4x4?
    
    
    init(index: Int, json: JSONNode) {
        self.name = json.name ?? "untitled"
        self.nodeIndex = index
        
        childIndices = json.children ?? []
    
        if let rotationArray = json.rotation {
            rotationQuaternion = simd_quatf(array: rotationArray)
        }
        if let translationArray = json.translation {
            translation = float3(array: translationArray)
        }
        if let scaleArray = json.scale {
            scale = float3(array: scaleArray)
        }
        if let matrixArray = json.matrix {
            matrix = float4x4(array: matrixArray)
        }
    }
    
    public var localTransform: float4x4 {
        if let matrix = matrix {
            return matrix
        }
        
        let T = float4x4(translation: translation)
        let R = float4x4(rotationQuaternion)
        let S = float4x4(scaling: scale)
        
        return T * R * S
    }
    
    public var globalTransform: float4x4 {
        if let parent = parent {
            return parent.globalTransform * self.localTransform
        }
        return localTransform
    }
}
