//
//  BinaryCodableExtensions.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 09/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import CoreFoundation
import simd

//MARK:- Integers

extension FixedWidthInteger where Self: BinaryEncodable {
    public func binaryEncode(to encoder: BinaryEncoder) {
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: BinaryDecodable {
    public init(fromBinary binaryDecoder: BinaryDecoder) throws {
        var v = Self.init()
        try binaryDecoder.read(into: &v)
        self.init(bigEndian: v)
    }
}

// Add support for binary decoding and encoding to every fixed width integer
extension Int8: BinaryCodable {}
extension UInt8: BinaryCodable {}
extension Int16: BinaryCodable {}
extension UInt16: BinaryCodable {}
extension Int32: BinaryCodable {}
extension UInt32: BinaryCodable {}
extension Int64: BinaryCodable {}
extension UInt64: BinaryCodable {}
extension Int: BinaryCodable {}
extension UInt: BinaryCodable {}

//MARK:- Strings

extension String: BinaryCodable {
    
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try Array(self.utf8).binaryEncode(to: encoder)
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        let utf8: [UInt8] = try Array(fromBinary: decoder)
        if let str = String(bytes: utf8, encoding: .utf8) {
            self = str
        } else {
            throw BinaryDecoder.Error.invalidUTF8(utf8)
        }
    }
    
}

//MARK:- Arrays

extension Array: BinaryCodable where Element: Codable {

    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.count)
        for element in self {
            // Prefer custom binaryEncode over encode so that we use the Optional
            // binaryEncode for optionals
            if let binaryElement = element as? BinaryEncodable {
                try binaryElement.binaryEncode(to: encoder)
            } else {
                try element.encode(to: encoder)
            }
        }
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        let count = try decoder.decode(Int.self)
        self.init()
        self.reserveCapacity(count)

        for _ in 0..<count {
            let decoded = try Element.init(from: decoder)
            self.append(decoded)
        }
    }
}

//MARK:- Optional

extension Optional: BinaryEncodable where Wrapped: Encodable {
    
    // Special version
    // The default encoding puts the value if there is any, and nil if there is none
    // However, as we need to write down if there is no value to decode it, we need to add just that.
    @inlinable
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .none: try container.encodeNil()
        case .some(let wrapped):
            try container.encode(true) // custom part: mark as present
            try container.encode(wrapped)
        }
    }
    
}

//MARK:- Data

// Optimized implementation of Data (array of UInt8) by copying all data at once instead of byte-by-byte
extension Data: BinaryCodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.count)
        encoder.appendBytes(in: [UInt8](self))
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        let count = try decoder.decode(Int.self)
        self.init(count: count)
        
        try withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            try decoder.read(count, into: ptr.baseAddress!)
        }
    }
}

//MARK:- Vectors

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

