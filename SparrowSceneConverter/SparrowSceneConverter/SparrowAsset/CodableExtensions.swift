//
//  CodableExtensions.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 07/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

extension matrix_float4x4: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self = matrix_float4x4(
            try container.decode(SIMD4<Float>.self),
            try container.decode(SIMD4<Float>.self),
            try container.decode(SIMD4<Float>.self),
            try container.decode(SIMD4<Float>.self)
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        
        try container.encode(self.columns.0)
        try container.encode(self.columns.1)
        try container.encode(self.columns.2)
        try container.encode(self.columns.3)
    }
}
