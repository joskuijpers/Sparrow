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
    
    /// Child nodes in the hierarchy
    var children: [Node] = []
    /// Parent of this node in the hiearchy. Can be nil.
    var parent: Node?
    
    /// Local node position
    var position: float3 = [0, 0, 0]
    /// Local Euler rotation. Setting this overwrites the rotation quaternion
    var rotation: float3 = [0, 0, 0] {
        didSet {
            let rotationMatrix = float4x4(rotation: rotation)
            quaternion = simd_quatf(rotationMatrix)
        }
    }
    /// Local rotation quaternion
    var quaternion = simd_quatf()
    /// Local scale
    var scale: float3 = [1, 1, 1]
    
    /// The model matrix containing current local position, rotation and scaling transformations
    var modelMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(quaternion)
        let scaleMatrix = float4x4(scaling: scale)
        
        return translateMatrix * rotateMatrix * scaleMatrix
    }
    
    /// World transform matrix containing current world position, rotation and scaling transformations to make model local space to world space
    var worldTransform: float4x4 {
        if let parent = parent {
            return parent.worldTransform * modelMatrix
        }
        return modelMatrix
    }
    
    /// Axis aligned bounding box of the node with its children, local (??? local ???)
    // TODO something about calculating it using min/max of submeshes
    var boundingBox = AxisAlignedBoundingBox()
    var size: float3 {
        return boundingBox.maxBounds - boundingBox.minBounds
    }
    
    /**
     Add a node below this node
     */
    func add(childNode: Node) {
        children.append(childNode)
        childNode.parent = self
    }
    
    /**
     Remove child node and move its children to this node. (Warning: this might not be the desired behavior)
     */
    func remove(childNode: Node) {
        for child in childNode.children {
            child.parent = self
            children.append(child)
        }
        
        childNode.children = []
        if let index = (children.firstIndex { $0 === childNode }) {
            children.remove(at: index)
        }
        
        childNode.parent = nil
    }
    
    /**
     Remove this node from its parent, keeping the child hiararchy intact
     */
    func unlink() {
        if let parent = parent {
            if let index = (parent.children.firstIndex { $0 === self }) {
                parent.children.remove(at: index)
            }
            self.parent = nil
        }
    }
    
    func drawBoundingBox(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms) {
        boundingBox.render(renderEncoder: renderEncoder, vertexUniforms: vertexUniforms, worldTransform: worldTransform)
    }
}
