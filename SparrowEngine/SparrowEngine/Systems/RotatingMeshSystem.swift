//
//  RotatingMeshSystem.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine2
import SparrowECS

final class RotationSpeed: Component {
    let speed: Float
    
    init(seed: Int = 0) {
        speed = (Float(seed) * 35972.326365396643).truncatingRemainder(dividingBy: 180)
    }
}

/// Behavior test
final class RotatingBallSystem: System {
    let entities: Group<Requires2<Transform, RotationSpeed>>
    
    required init(world: World) {
        entities =  world.nexus.group(requiresAll: Transform.self, RotationSpeed.self)
    }
    
    func update(deltaTime: Float) {
        for (transform, rotationSpeed) in entities {
            let q = simd_quatf(angle: rotationSpeed.speed.degreesToRadians * deltaTime * 0.5, axis: [0, 1, 0])
            transform.localRotation = transform.localRotation * q
        }
    }
}
