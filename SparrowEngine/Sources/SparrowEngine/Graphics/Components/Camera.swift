//
//  Camera.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import CSparrowEngine
import SparrowECS
import simd

// TODO: did set any of the fov/near/far/aspect properties -> set uniforms dirty
/// Camera
public final class Camera: Component {
    
    /// Field of view in degrees
    public var fovDegrees: Float = 70 {
        didSet {
            uniformsDirty = true
        }
    }
    
    /// Field of view in radians
    public var fovRadians: Float {
        return fovDegrees.degreesToRadians
    }
    
    /// Aspect ratio.
    public var aspect: Float = 1 {
           didSet {
               uniformsDirty = true
           }
       }
    
    /// Near plane distance from camera.
    public var near: Float = 0.1 {
           didSet {
               uniformsDirty = true
           }
       }
    
    /// Far plane distance from camera.
    public var far: Float = 10000 {
           didSet {
               uniformsDirty = true
           }
       }
    
    /// The view matrix maps view space to homogenous coords
    public var projectionMatrix: float4x4 {
        return matrix_float4x4(perspectiveAspect: aspect, fovy: fovRadians, near: near, far: far)
    }
    
    /// The projection matrix maps world space to view space.
    public var viewMatrix: float4x4 = matrix_float4x4.identity()
    
    /// Frustum of the camera.
    public var frustum: Frustum?
    
    public var uniforms = CameraUniforms()
    public var uniformsDirty = true
    
    // TODO get rid of this stuff? ViewportSize?
    public var screenSize = (0,0)
}

extension Camera: Storable {
    // Only use non-calculated properties.
    // Ideally we would put all other properties into a private component...
    private enum CodingKeys: String, CodingKey {
        case fovDegrees, near, far
    }
}
