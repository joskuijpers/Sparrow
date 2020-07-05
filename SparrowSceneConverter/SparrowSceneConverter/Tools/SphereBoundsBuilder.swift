//
//  SphereBoundsBuilder.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 05/07/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import simd
import SparrowMesh

public class SPMSphereBoundsBuilder {
    var points: [SIMD3<Float>] = []
    
    public init() {}
    
    public func add(_ point: SIMD3<Float>) {
        points.append(point)
    }
    
    public func compute() -> SPMSphereBounds {
        return SPMSphereBounds.containing(points)
    }
}
