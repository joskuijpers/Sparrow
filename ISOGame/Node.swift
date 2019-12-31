//
//  Node.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
  Scene graph node
 */
class Node {
    var name: String = "untitled";
    
    var children: [Node] = []
    var parent: Node?
    
    var position: float3 = [0, 0, 0]
    var rotation: float3 = [0, 0, 0]
    var scale: float3 = [1, 1, 1]
    
    /// The model matrix containing current position, rotation and scaling transformations
    var modelMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(rotation: rotation)
        let scaleMatrix = float4x4(scaling: scale)
        
        return translateMatrix * rotateMatrix * scaleMatrix
    }
    
    func add(childNode: Node) {
        
    }
    
    func remove(childNode: Node) {
        
    }
}
