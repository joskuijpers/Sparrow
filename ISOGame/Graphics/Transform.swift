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
    var localPosition: float3 = .zero {
        didSet {
            modelMatrixDirty = true
            worldMatrixDirty = true
        }
    }
    
    /// Local rotation quaternion
    var localRotation = simd_quatf(angle: 0, axis: [0,1,0]) {
        didSet {
            modelMatrixDirty = true
            worldMatrixDirty = true
        }
    }
    
    /// Local scale
    var localScale: float3 = .one {
        didSet {
            modelMatrixDirty = true
            worldMatrixDirty = true
        }
    }

    /**
     Local Euler rotation. Setting this overwrites the rotation quaternion.
     
     It is not possible to get euler angles.
     */
    var eulerAngles: float3 {
        set {
            let rot = float4x4(rotation: newValue)
            localRotation = simd_quatf(rot)
        }
        get {
            fatalError("Not implemented: not possible to convert quaternion to euler angles")
        }
    }
    
    // MARK:- Transformation matrices
    
    /// The model matrix containing current local position, rotation and scaling transformations
    var modelMatrix: float4x4 {
        if modelMatrixDirty {
            let translateMatrix = float4x4(translation: localPosition)
            let rotateMatrix = float4x4(localRotation)
            let scaleMatrix = float4x4(scaling: localScale)
            
            _modelMatrix = translateMatrix * rotateMatrix * scaleMatrix
            
            modelMatrixDirty = false
            worldMatrixDirty = true
        }
        
        return _modelMatrix
    }
    private var _modelMatrix = matrix_identity_float4x4
    private var modelMatrixDirty = true
    
    /// Matrix that transforms a point from local space to world space.
    var localToWorldMatrix: float4x4 {
//        if worldMatrixDirty {
        if let parent = self.parent {
            _worldTransform = parent.localToWorldMatrix * modelMatrix
        } else {
            _worldTransform = modelMatrix
        }
//        }
        
        return _worldTransform
    }
    private var _worldTransform = matrix_identity_float4x4
    private var worldMatrixDirty = true
    
    /// Matrix that transforms a point from world space to local space.
    var worldToLocalMatrix: float4x4 {
        return localToWorldMatrix.inverse
    }
    
    // MARK: - Directional vectors with rotations applied.
    
    /**
     A normalized vector representing the red (right side) axis of the transform in world space.
     
     This vector has rotations applied. To get the right vector without rotations, use float3.right.
     */
    @inlinable
    var right: float3 {
//        return normalize((localToWorldMatrix * float4(1, 0, 0, 1)).xyz)
        return [forward.z, forward.y, -forward.x]
    }
    
    /**
    A normalized vector representing the blue (forward) axis of the transform in world space.
    
    This vector has rotations applied. To get the forward vector without rotations, use float3.forward.
    */
    @inlinable
    var forward: float3 {
//        return normalize((localToWorldMatrix * float4(0, 0, 1, 1)).xyz)
        return normalize([sin(eulerAngles.y), 0, cos(eulerAngles.y)])
    }
    
    /**
    A normalized vector representing the green (upwards) axis of the transform in world space.
    
    This vector has rotations applied. To get the up vector without rotations, use float3.up.
    */
    @inlinable
    var up: float3 {
        return normalize((localToWorldMatrix * float4(0, 1, 0, 1)).xyz)
    }
    
    /// The world space position of the Transform.
    @inlinable
    var position: float3 {
        get {
            localToWorldMatrix.columns.3.xyz
        }
        set {
            // TEMP: use parent localToWorldMatrix
            let parentWM = matrix_float4x4.identity().inverse
            
            localPosition = (parentWM * float4(newValue, 1)).xyz
        }
    }
    
    /// A Quaternion that stores the rotation of the Transform in world space.
    @inlinable
    var rotation: simd_quatf {
        // TODO: multiply with parent rotation if any
        return localRotation
    }
    
    // MARK: - Updating transform
    
    /**
     Moves the transform in the direction and distance of `translation`.
     
     - Parameter translation: Offset
     */
    func translate(_ translation: float3) {
        localPosition = localPosition + translation
    }
    
    // TODO: translate(x,y,z)
    // TODO: translate(float3, relativeTo: Transform)
    
    // TODO: rotate(axis:float3,angle:Float)
    // TODO: rotate(xAngle,yAngle,zAngle)
    // TODO: rotate(eulers:float3)
    
    // MARK: - Scene transform hierarchy
    
    /**
    Set the parent of the transform.
     - Parameters:
        - transform: The Transform to parent onto. If nil, the transform will move to root level without a parent.
        - worldPositionStays: If true, the parent-relative position, scale and rotation are modified such that the object keeps the same world space position, rotation and scale as before.
     */
    func setParent(_ transform: Transform?, worldPositionStays: Bool = true) {
        // Remove from current parent
        if let parent = parent, let index = parent.children.firstIndex(where: { $0 === self }) {
            parent.children.remove(at: index)
        }
        
        parent = transform
        
        if let newParent = transform {
            newParent.children.append(self)
        }
    }
    
    /// List of child transforms. Unordered.
    internal var children: [Transform] = []
    /// Parent of this transform, if any.
    internal weak var parent: Transform?
}
