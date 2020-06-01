//
//  FixedWidthInteger+SafeBinaryCodable.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation

extension FixedWidthInteger where Self: SafeBinaryEncodable, Self: UnsignedInteger {
    public func safeBinaryEncode(to encoder: SafeBinaryEncoder) {
        encoder.appendTag(.uint)
        encoder.appendBytes(of: UInt8(MemoryLayout<Self>.size))
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: SafeBinaryEncodable, Self: SignedInteger {
    public func safeBinaryEncode(to encoder: SafeBinaryEncoder) {
        encoder.appendTag(.int)
        encoder.appendBytes(of: UInt8(MemoryLayout<Self>.size))
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: SafeBinaryDecodable, Self: UnsignedInteger {
    public init(fromBinary binaryDecoder: SafeBinaryDecoder) throws {
        var v = Self.init()
        
        // Read tag
        // Read size
        try binaryDecoder.readTag()
        
        var size: UInt8 = 0
        try binaryDecoder.read(into: &size)
        
        try binaryDecoder.read(into: &v)
        
        self.init(bigEndian: v)
    }
}

extension FixedWidthInteger where Self: SafeBinaryDecodable, Self: SignedInteger {
    public init(fromBinary binaryDecoder: SafeBinaryDecoder) throws {
        var v = Self.init()
        
        // Read tag
        // Read size
        try binaryDecoder.readTag()
        
        var size: UInt8 = 0
        try binaryDecoder.read(into: &size)
        
        try binaryDecoder.read(into: &v)
        
        self.init(bigEndian: v)
    }
}

// Add support for binary decoding and encoding to every fixed width integer
extension Int8: SafeBinaryCodable {}
extension UInt8: SafeBinaryCodable {}
extension Int16: SafeBinaryCodable {}
extension UInt16: SafeBinaryCodable {}
extension Int32: SafeBinaryCodable {}
extension UInt32: SafeBinaryCodable {}
extension Int64: SafeBinaryCodable {}
extension UInt64: SafeBinaryCodable {}
extension Int: SafeBinaryCodable {}
extension UInt: SafeBinaryCodable {}
