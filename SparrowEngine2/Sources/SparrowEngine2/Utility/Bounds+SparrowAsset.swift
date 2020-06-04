//
//  Bounds+SparrowAsset.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 18/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowMesh

// MARK: - Conversion from SparrowAsset bounds
public extension Bounds {
    
    /// Initialize from Sparrow Asset bounds
    init(from spmBounds: SPMBounds) {
        self.init(minBounds: spmBounds.min, maxBounds: spmBounds.max)
    }
    
}
