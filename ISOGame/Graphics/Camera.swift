//
//  Camera.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Camera: Component {
    
    var fovDegrees: Float = 70
    var fovRadians: Float {
        return fovDegrees.degreesToRadians
    }
    var aspect: Float = 1
    var near: Float = 0.001
    var far: Float = 1000
    
    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: fovRadians,
                        near: near,
                        far: far,
                        aspect: aspect)
    }
    
    var viewMatrix: float4x4 {
        guard let transform = self.transform else {
            fatalError("Camera needs a transform")
        }
        
        let translateMatrix = float4x4(translation: transform.position)
        let rotateMatrix = float4x4(rotation: transform.rotation)
        let scaleMatrix = float4x4(scaling: transform.scale)
        
        return (translateMatrix * scaleMatrix * rotateMatrix).inverse
    }
    
    func screenSizeWillChange(to size: CGSize) {
        aspect = Float(size.width / size.height)
    }
}

// TODO: This whole camera should be a Behavior bound to Input system
class ArcballCamera: Component {
    
    var fovDegrees: Float = 70
    var fovRadians: Float {
        return fovDegrees.degreesToRadians
    }
    var aspect: Float = 1
    var near: Float = 0.001
    var far: Float = 1000
    
    var target: float3 = [0, 0, 0] {
        didSet {
            viewMatrixDirty = true
        }
    }
    
    var distance: Float = 0 {
        didSet {
            viewMatrixDirty = true
        }
    }
    
    /// Get the projection matrix
    var projectionMatrix: float4x4 {
        return float4x4(projectionFov: fovRadians,
                        near: near,
                        far: far,
                        aspect: aspect)
    }
    
    /// Get an up to date view matrix
    var viewMatrix: float4x4 {
        if viewMatrixDirty {
            guard let transform = self.transform else {
                fatalError("Camera needs a transform")
            }
            
            let translateMatrix = float4x4(translation: [target.x, target.y, target.z - distance])
            let rotateMatrix = float4x4(rotationYXZ: [-transform.rotation.x, transform.rotation.y, 0])
            _viewMatrix = (rotateMatrix * translateMatrix).inverse
            transform.position = rotateMatrix.upperLeft * -_viewMatrix.columns.3.xyz
            
            viewMatrixDirty = false
        }
        
        return _viewMatrix
    }
    private var _viewMatrix = float4x4.identity()
    private var viewMatrixDirty = true
    
    func screenSizeWillChange(to size: CGSize) {
        aspect = Float(size.width / size.height)
    }
    
    /// Zoom towards the lookat point
    func zoom(delta: Float) {
        let sensitivity: Float = 0.05
        distance -= delta * sensitivity
        viewMatrixDirty = true
    }
    
    /// Rotate around the lookat point.
    func rotate(delta: float2) {
        guard let transform = self.transform else {
            fatalError("Camera needs a transform")
        }
        
        let sensitivity: Float = 0.005
        var rotation = transform.rotation
        
        rotation.y += delta.x * sensitivity
        rotation.x += delta.y * sensitivity
        rotation.x = max(-Float.pi/2, min(rotation.x, Float.pi/2))
        
        transform.rotation = rotation
        
        viewMatrixDirty = true
    }
}
