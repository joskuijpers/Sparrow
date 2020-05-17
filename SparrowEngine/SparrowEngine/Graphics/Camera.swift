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
 
 TODO: did set any of the fov/near/far/aspect properties -> set uniforms dirty
 */
final class Camera: Component {
    
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
    var far: Float = 10000
    
    internal var screenSize = CGSize.zero
    
    /// The view matrix maps view space to homogenous coords
    var projectionMatrix: float4x4 {
        return matrix_float4x4(perspectiveAspect: aspect, fovy: fovRadians, near: near, far: far)
    }
    
    /// The projection matrix maps world space to view space.
    var viewMatrix: float4x4 = matrix_float4x4.identity()
    
    /// Frustum of the camera.
    var frustum: Frustum?
    
    var uniforms = CameraUniforms()
    var uniformsDirty = true
    
    /// Screen size changed. Updates the aspect ratio
    func onScreenSizeWillChange(to size: CGSize) {
        aspect = Float(size.width / size.height)
        screenSize = size
        uniformsDirty = true
    }
    
    // TODO, maybe: static Camera.main -> Camera { SceneManager.current.camera }

}
