//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 08/06/2020.
//

import SparrowECS
import Foundation.NSDate

// Simple camera behavior
public final class CameraUpdateSystem: System {

    let cameras: Group<Requires2<Transform, Camera>>
    
    public init(world: World) {
        cameras = world.nexus.group(requiresAll: Transform.self, Camera.self)
    }
    
    /// Update camera with new uniform data and frustums.
    func updateCameras() {
        for (transform, camera) in cameras {
            let newViewMatrix = transform.worldToLocalMatrix
            
            if newViewMatrix != camera.viewMatrix {
                camera.viewMatrix = newViewMatrix
                camera.uniformsDirty = true
            }

            if camera.uniformsDirty {
                camera.frustum = Frustum(viewProjectionMatrix: camera.projectionMatrix * camera.viewMatrix)
                
                updateCameraUniforms(camera: camera, transform: transform, uniforms: &camera.uniforms)
                
                camera.uniformsDirty = false
            }
        }
    }
    
    /// Update uniform structure with camera data
    private func updateCameraUniforms(camera: Camera, transform: Transform, uniforms: inout CameraUniforms) {
        uniforms.viewMatrix = camera.viewMatrix
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.cameraWorldPosition = transform.position
        
        // Derived
        uniforms.viewProjectionMatrix = uniforms.projectionMatrix * uniforms.viewMatrix
        
        uniforms.invProjectionMatrix = simd_inverse(uniforms.projectionMatrix)
        uniforms.invViewProjectionMatrix = simd_inverse(uniforms.viewProjectionMatrix)
        uniforms.invViewMatrix = simd_inverse(uniforms.viewMatrix)
        
        uniforms.physicalSize = [Float(camera.screenSize.0), Float(camera.screenSize.1)]
        
        // Inverse column
        uniforms.invProjectionZ = [ uniforms.invProjectionMatrix.columns.2.z, uniforms.invProjectionMatrix.columns.2.w,
                                    uniforms.invProjectionMatrix.columns.3.z, uniforms.invProjectionMatrix.columns.3.w ]
        
        let bias = -camera.near
        let invScale = camera.far - camera.near
        uniforms.invProjectionZNormalized = [uniforms.invProjectionZ.x + (uniforms.invProjectionZ.y * bias),
                                             uniforms.invProjectionZ.y * invScale,
                                             uniforms.invProjectionZ.z + (uniforms.invProjectionZ.w * bias),
                                             uniforms.invProjectionZ.w * invScale]
        
    }

    /// Update viewport size of cameras. Assumes all cameras are for sceen use only.
    func updateViewportSize(to size: CGSize) {
        let aspect = Float(size.width / size.height)
        let pixelSize = (Int(size.width), Int(size.height))
        
        for (_, camera) in cameras {
            camera.aspect = aspect
            camera.screenSize = pixelSize
        }
    }
}

/*
 
 
 Current Camera (transform and projection matrix)
    -> Turn into CameraUniforms (if dirty?)
    -> do not store in Camera
 
 
 RENDER(camera, viewportSize
 
 Prepare
    build lights
    build camera uniforms -> with viewpoerSize as aspect?
    object culling
 
 Render
    for object in culled result
        render
 
 
 
 
 
 
 */
