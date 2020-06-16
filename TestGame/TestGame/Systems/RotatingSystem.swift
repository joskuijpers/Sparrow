//
//  RotatingMeshSystem.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine
import SparrowECS

/// Behavior test
final class RotatingSystem: System {
    let entities: Group<Requires2<Transform, RotationSpeed>>
    
    required init(world: World) {
        entities =  world.nexus.group(requiresAll: Transform.self, RotationSpeed.self)
    }
    
    func update(world: World) {
        let deltaTime = world.time.deltaTime
        
        for (transform, rotationSpeed) in entities {
            let q = simd_quatf(angle: rotationSpeed.speed.degreesToRadians * deltaTime * 0.5, axis: [0, 1, 0])
            transform.localRotation = transform.localRotation * q
        }
    }
}
