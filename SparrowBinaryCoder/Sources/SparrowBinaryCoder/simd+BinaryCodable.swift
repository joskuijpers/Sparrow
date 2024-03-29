//
//  simd+BinaryCodable.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import simd

//MARK:- Vectors

/// Adds binary encoding support.
///
/// No containers needed.
extension SIMD3: BinaryCodable where Scalar == Float {
    
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.x)
        try encoder.encode(self.y)
        try encoder.encode(self.z)
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        self.init(x: try decoder.decode(Float.self),
                  y: try decoder.decode(Float.self),
                  z: try decoder.decode(Float.self))
    }
    
}

/// Adds binary encoding support.
///
/// No containers needed.
extension SIMD4: BinaryCodable where Scalar == Float {
    
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.x)
        try encoder.encode(self.y)
        try encoder.encode(self.z)
        try encoder.encode(self.w)
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        self.init(x: try decoder.decode(Float.self),
                  y: try decoder.decode(Float.self),
                  z: try decoder.decode(Float.self),
                  w: try decoder.decode(Float.self))
    }
    
}

//MARK:- Matrices

/// Adds binary encoding support.
///
/// No containers needed.
extension simd_float4x4: BinaryCodable {
    
    enum Error: Swift.Error {
        case notSupported
    }
    
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try columns.0.binaryEncode(to: encoder)
        try columns.1.binaryEncode(to: encoder)
        try columns.2.binaryEncode(to: encoder)
        try columns.3.binaryEncode(to: encoder)
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        self.init(
            try decoder.decode(SIMD4<Float>.self),
            try decoder.decode(SIMD4<Float>.self),
            try decoder.decode(SIMD4<Float>.self),
            try decoder.decode(SIMD4<Float>.self)
        )
    }
    
    // Needed to supress compiler error about Codable
    public func encode(to encoder: Encoder) throws {
        // Currently unknown whether to used keyed/unkeyed storage when JSON is used
        throw Error.notSupported
    }
    
    // Needed to supress compiler error about Codable
    public init(from decoder: Decoder) throws {
        // Currently unknown whether to used keyed/unkeyed storage when JSON is used
        throw Error.notSupported
    }
    
}


//MARK:- Quaternions

/// Adds binary encoding support.
///
/// No containers needed.
extension simd_quatf: BinaryCodable {

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
