//
//  RotatingSpeed.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 11/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowECS

final class RotationSpeed: Component {
    let speed: Float
    
    init(seed: Int = 0) {
        speed = (Float(seed) * 35972.326365396643).truncatingRemainder(dividingBy: 180)
    }
    
    init(speed: Float) {
        self.speed = speed
    }
}

extension RotationSpeed: Codable, NexusStorable {
    public static var stableIdentifier: StableIdentifier {
        return 1001
    }
}
