//
//  Bounds+SparrowAsset.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 18/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowAsset

// MARK: - Conversion from SparrowAsset bounds
public extension Bounds {
    
    /// Initialize from Sparrow Asset bounds
    init(from saBounds: SABounds) {
        self.init(minBounds: saBounds.min, maxBounds: saBounds.max)
    }
    
}
