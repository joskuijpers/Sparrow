//
//  SPMBuffer.swift
//  SparrowMesh
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

/// A buffer containing data.
public struct SPMBuffer: BinaryCodable {
    /// Total byte-size of the buffer.
    public let size: Int
    
    /// The data inside the buffer.
    public let data: Data
    
    /// Create a new buffer.
    public init(data: Data) {
        self.data = data
        self.size = data.count
    }
}
