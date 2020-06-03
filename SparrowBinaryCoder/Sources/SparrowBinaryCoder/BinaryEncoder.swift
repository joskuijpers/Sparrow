//
//  BinaryEncoder.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 09/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// A type that can encode itself to a binary representation.
public protocol BinaryEncodable: Encodable {
    
    /// Encodes this value into the given encoder.
    ///
    /// If the value fails to encode anything, `encoder` will encode an empty
    /// keyed container in its place.
    ///
    /// This function throws an error if any values are invalid for the given
    /// encoder's format.
    ///
    /// - Parameter encoder: The binary encoder to write data to.
    func binaryEncode(to encoder: BinaryEncoder) throws
}

extension BinaryEncodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try self.encode(to: encoder)
    }
}

/// An object that encodes instances of a data type as binary.
public class BinaryEncoder {
    fileprivate var data: [UInt8] = []
    
    /// Returns a binary representation of the object specified.
    ///
    /// - Parameter value: The object to encode into binary.
    public static func encode(_ value: BinaryEncodable) throws -> [UInt8] {
        let encoder = BinaryEncoder()
        try value.binaryEncode(to: encoder)
        return encoder.data
    }
    
    /// Errors that can be thrown by the encoder.
    public enum Error: Swift.Error {
        /// Type does not conform to binary encodable
        case typeNotConformingToBinaryEncodable(Encodable.Type)
        
        /// Type does not conform to encodable.
        case typeNotConformingToEncodable(Any.Type)
    }
    
    internal func appendBytes<T>(of: T) {
        var target = of
        withUnsafeBytes(of: &target) {
            data.append(contentsOf: $0)
        }
    }
    
    internal func appendBytes(in bytes: [UInt8]) {
        data.append(contentsOf: bytes)
    }
}

extension BinaryEncoder {
    private func encode(_ value: Float) {
        appendBytes(of: CFConvertFloatHostToSwapped(value))
    }
    
    private func encode(_ value: Double) {
        appendBytes(of: CFConvertDoubleHostToSwapped(value))
    }
    
    private func encode(_ value: Bool) throws {
        try encode(value ? 1 as UInt8 : 0 as UInt8)
    }
    
    func encode(_ encodable: Encodable) throws {
        switch encodable {
        case let v as Int:
            try encode(Int64(v))
        case let v as UInt:
            try encode(UInt64(v))
        case let v as Float:
            encode(v)
        case let v as Double:
            encode(v)
        case let v as Bool:
            try encode(v)
        case let binary as BinaryEncodable:
            try binary.binaryEncode(to: self)
        default:
            throw Error.typeNotConformingToBinaryEncodable(type(of: encodable))
        }
    }
    
    fileprivate func encodeIfPresent(_ encodable: Encodable?) throws {
        try encode(encodable != nil)
        if let value = encodable {
            try encode(value)
        }
    }
}

extension BinaryEncoder: Encoder {
    public var codingPath: [CodingKey] {
        return []
    }
    
    public var userInfo: [CodingUserInfoKey : Any] {
        return [:]
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer(encoder: self))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainer(encoder: self)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return UnkeyedContainer(encoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: BinaryEncoder
        
        // We are not using the keys
        var codingPath: [CodingKey] {
            return []
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            try encoder.encode(value)
        }

        mutating func encodeNil(forKey key: Key) throws {
            // This is never called
        }
        
        func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: String?, forKey key: Key) throws {
            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T : Encodable {
            try encoder.encodeIfPresent(value)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder.unkeyedContainer()
        }
        
        mutating func superEncoder() -> Encoder {
            return encoder
        }
        
        mutating func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }

    private struct UnkeyedContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
        var encoder: BinaryEncoder
        var codingPath: [CodingKey] {
            return []
        }
        
        var count: Int {
            return 0
        }
        
        mutating func encodeNil() throws {
            // If we add nil from an optional, we always put down false. A present optional is true
            try encoder.encode(false)
        }
        
        func encodeIfPresent<T>(_ value: T?) throws where T : Encodable {
            switch value {
            case .some(let unwrappedValue):
                try encoder.encode(true)
                try encoder.encode(unwrappedValue)
            case .none:
                try encoder.encode(false)
            }
        }
        
        func encode<T>(_ value: T) throws where T : Encodable {
            try encoder.encode(value)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return self
        }
        
        mutating func superEncoder() -> Encoder {
            return encoder
        }
    }
}
