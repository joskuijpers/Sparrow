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
    
    // TODO, maybe: static Camera.main -> Camera { SceneManager.current.camera }
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
    }
}
