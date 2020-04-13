//
//  Camera.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
 Camera
 */
class Camera: Component {
    
    /// Field of view in degrees
    var fovDegrees: Float = 70
    
    /// Field of view in radians
    var fovRadians: Float {
        return fovDegrees.degreesToRadians
    }
    
    /// Aspect ratio.
    var aspect: Float = 1
    
    /// Near plane distance from camera.
    var near: Float = 0.1
    
    /// Far plane distance from camera.
    var far: Float = 100
    
    private var screenSize = CGSize.zero
    
    /// The view matrix maps view space to homogenous coords
    var projectionMatrix: float4x4 {
        return matrix_float4x4(perspectiveAspect: aspect, fovy: fovRadians, near: near, far: far)
    }
    
    /// The projection matrix maps world space to view space.
    var viewMatrix: float4x4 {
        guard let transform = self.transform else {
            fatalError("Camera needs a transform")
        }

        return transform.modelMatrix.inverse
    }
    
    /// Frustum of the camera.
    var frustum: Frustum {
        return Frustum(viewProjectionMatrix: projectionMatrix * viewMatrix)
    }
    
    var uniforms = CameraUniforms()
    var uniformsDirty = true
    
    /// Screen size changed. Updates the aspect ratio
    func onScreenSizeWillChange(to size: CGSize) {
        aspect = Float(size.width / size.height)
        screenSize = size
    }
    
    // TODO, maybe: static Camera.main -> Camera { SceneManager.current.camera }
    
    /// Update camera uniforms with new data
    func updateUniforms() {
        uniforms.viewMatrix = self.viewMatrix
        uniforms.projectionMatrix = self.projectionMatrix
        uniforms.cameraWorldPosition = self.transform!.worldPosition
        
        // Derived
        uniforms.viewProjectionMatrix = uniforms.projectionMatrix * uniforms.viewMatrix
        
        uniforms.invProjectionMatrix = simd_inverse(uniforms.projectionMatrix)
        uniforms.invViewProjectionMatrix = simd_inverse(uniforms.viewProjectionMatrix)
        uniforms.invViewMatrix = simd_inverse(uniforms.viewMatrix)
        
        uniforms.physicalSize = [Float(screenSize.width), Float(screenSize.height)]
        
        // Inverse column
        uniforms.invProjectionZ = [ uniforms.invProjectionMatrix.columns.2.z, uniforms.invProjectionMatrix.columns.2.w,
                                    uniforms.invProjectionMatrix.columns.3.z, uniforms.invProjectionMatrix.columns.3.w ]
        
        let bias = -near
        let invScale = far - near
        uniforms.invProjectionZNormalized = [uniforms.invProjectionZ.x + (uniforms.invProjectionZ.y * bias),
                                             uniforms.invProjectionZ.y * invScale,
                                             uniforms.invProjectionZ.z + (uniforms.invProjectionZ.w * bias),
                                             uniforms.invProjectionZ.w * invScale]
        
        uniformsDirty = false
    }
}

/// Simple debug camera with keyboard movement
class DebugCameraBehavior: Behavior {
    override func onUpdate(deltaTime: Float) {
        guard let transform = self.transform else { return }
        
        var diff = float3.zero
        let speed: Float = 5.0
        
        if Input.shared.getKey(.w) {
            diff = diff + float3(0, 0, 1) * deltaTime * speed
        } else if Input.shared.getKey(.s) {
            diff = diff - float3(0, 0, 1) * deltaTime * speed
        }
        
        if Input.shared.getKey(.a) {
            diff = diff - float3(1, 0, 0) * deltaTime * speed
        } else if Input.shared.getKey(.d) {
            diff = diff + float3(1, 0, 0) * deltaTime * speed
        }
        
        if Input.shared.getKey(.q) {
            diff = diff + float3(0, 1, 0) * deltaTime * speed
        } else if Input.shared.getKey(.e) {
            diff = diff - float3(0, 1, 0) * deltaTime * speed
        }
        
        transform.translate(diff)
        
        var rot: Float = 0
        if Input.shared.getKey(.leftArrow) {
            rot = rot + deltaTime * Float(-20).degreesToRadians
        }
        if Input.shared.getKey(.rightArrow) {
            rot = rot + deltaTime * Float(20).degreesToRadians
        }
        transform.rotate(float3(0, rot, 0))
        
        var rotX: Float = 0
        if Input.shared.getKey(.upArrow) {
            rotX = rotX + deltaTime * Float(-20).degreesToRadians
        }
        if Input.shared.getKey(.downArrow) {
            rotX = rotX + deltaTime * Float(20).degreesToRadians
        }
        transform.rotate(float3(rotX, 0, 0))
        
        
    }
}
