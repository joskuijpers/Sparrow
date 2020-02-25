//
//  Transform.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/**
 Component holding transform data.
 
 Holds position, rotation and scale. Has access to forward and right vectors, and transformation matrices
 generated from the properties.
 */
class Transform: Component {
    /// Local node position
    var position: float3 = .zero
    
    /// Local Euler rotation. Setting this overwrites the rotation quaternion
    var rotation: float3 = .zero {
        didSet {
            let rotationMatrix = float4x4(rotation: rotation)
            quaternion = simd_quatf(rotationMatrix)
        }
    }
    
    /// Local rotation quaternion
    var quaternion = simd_quatf()
    
    /// Local scale
    var scale: float3 = .one
    
    /// The model matrix containing current local position, rotation and scaling transformations
    var modelMatrix: float4x4 {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(quaternion)
        let scaleMatrix = float4x4(scaling: scale)
        
        return translateMatrix * rotateMatrix * scaleMatrix
    }
    
    /// World transform matrix containing current world position, rotation and scaling transformations to make model local space to world space
    var worldTransform: float4x4 {
        if let parent = entity?.parent, let parentTransform = parent.transform {
            return parentTransform.worldTransform * modelMatrix
        }
        return modelMatrix
    }
    
    /// World space right vector
    var right: float3 {
        return (float4(0, 0, 1, 1) * worldTransform).xyz
    }
    
    /// World space forward vector
    var forward: float3 {
        return (float4(1, 0, 0, 1) * worldTransform).xyz
    }
}

extension Component {
    /// Utility for getting the object transform, if available
    var transform: Transform? {
        guard let id = entityId else { return nil }
        return nexus?.get(component: Transform.identifier, for: id) as? Transform
    }
}

extension Entity {
    /// Utility for getting the object transform, if available
    var transform: Transform? {
        return nexus.get(component: Transform.identifier, for: identifier) as? Transform
    }
}
