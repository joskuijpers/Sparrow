//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 15/06/2020.
//

import simd

//MARK:- Quaternions

/// Adds binary encoding support.
///
/// No containers needed.
extension simd_quatf: Codable {

    // Needed to supress compiler error about Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(angle)
        try container.encode(axis.x.isNaN ? 0 : axis.x)
        try container.encode(axis.y.isNaN ? 0 : axis.y)
        try container.encode(axis.z.isNaN ? 0 : axis.z)
    }
    
    // Needed to supress compiler error about Codable
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.init(angle: try container.decode(Float.self),
                  axis: SIMD3<Float>(try container.decode(Float.self),
                                     try container.decode(Float.self),
                                     try container.decode(Float.self)))
    }
}

