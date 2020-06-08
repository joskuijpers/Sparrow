//
//  PlayerCameraSystem.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine2
import SparrowECS

// Simple camera behavior
public final class PlayerCameraSystem: System {
    let cameras: Group<Requires2<Transform, Camera>>
    
    public init(world: World, context: Context) {
        cameras =  world.n.group(requiresAll: Transform.self, Camera.self)
    }
    
    func update(deltaTime: Float) {
        for (transform, _) in cameras {
            var diff = float3.zero
            let speed: Float = 10.0
            let rotSpeed: Float = 70.0

            if Input.shared.getKey(.w) {
                diff = diff + transform.forward * deltaTime * speed
            } else if Input.shared.getKey(.s) {
                diff = diff - transform.forward * deltaTime * speed
            }
            
            if Input.shared.getKey(.a) {
                diff = diff - transform.right * deltaTime * speed
            } else if Input.shared.getKey(.d) {
                diff = diff + transform.right * deltaTime * speed
            }
            
            if Input.shared.getKey(.q) {
                diff = diff + float3(0, 1, 0) * deltaTime * speed
            } else if Input.shared.getKey(.e) {
                diff = diff - float3(0, 1, 0) * deltaTime * speed
            }
            
            transform.translate(diff)
            
            var rot: Float = 0
            if Input.shared.getKey(.leftArrow) {
                rot = rot + deltaTime * -rotSpeed.degreesToRadians
            }
            if Input.shared.getKey(.rightArrow) {
                rot = rot + deltaTime * rotSpeed.degreesToRadians
            }
            
            var rotX: Float = 0
            if Input.shared.getKey(.upArrow) {
                rotX = rotX + deltaTime * -rotSpeed.degreesToRadians
            }
            if Input.shared.getKey(.downArrow) {
                rotX = rotX + deltaTime * rotSpeed.degreesToRadians
            }

            let qy = simd_quatf(angle: rot, axis: [0, 1, 0])
            let qx = simd_quatf(angle: rotX, axis: [1, 0, 0])
            
            transform.localRotation = qy * transform.localRotation * qx
        }
    }

}
