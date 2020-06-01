//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation

public protocol SafeBinaryEncodable: Encodable {
    func safeBinaryEncode(to encoder: SafeBinaryEncoder) throws
}

extension SafeBinaryEncodable {
    public func safeBinaryEncode(to encoder: SafeBinaryEncoder) throws {
        try self.encode(to: encoder)
    }
}

public class SafeBinaryEncoder {
    fileprivate var data: [UInt8] = []
    fileprivate var keyTable: [String] = []
    
    /// Encoder a value with a binary encoder
    public static func encode(_ value: Encodable) throws -> [UInt8] {
        let encoder = SafeBinaryEncoder()
        try value.encode(to: encoder)
        
        print("KEYS \(encoder.keyTable)")
        
        // Write out key table
        var keyData: [UInt8] = []
        var numKeys = encoder.keyTable.count
        if numKeys > 0 {
            // Keys
            keyData.append(1)
            
            withUnsafeBytes(of: &numKeys) {
                keyData.append(contentsOf: $0)
            }
            
            for key in encoder.keyTable {
                var bytes = Array(key.utf8)
                
                var k = bytes.count
                withUnsafeBytes(of: &k) {
                    keyData.append(contentsOf: $0)
                }
                
                withUnsafeBytes(of: &bytes) {
                    keyData.append(contentsOf: $0)
                }
            }
        } else {
            // No keys
            keyData.append(0)
        }
        
        return keyData + encoder.data
    }
    
    enum Error: Swift.Error {
        /// Type does not conform to binary encodable
        case typeNotConformingToSafeBinaryEncodable(Encodable.Type)
        /// Type does not conform to encodable.
        case typeNotConformingToEncodable(Any.Type)
    }
    
    enum Tag: UInt8 {
        case optional
        
        case uint
        case int
        case float
        case bool
        case array
        case dictionary
        case string
        case data
        case url
        
        case matrix
        case vector
    }
    
    internal func appendTag(_ tag: Tag) {
        appendBytes(of: tag.rawValue)
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

extension SafeBinaryEncoder {
    private func encode(_ value: Float) {
        appendTag(.float)
        appendBytes(of: UInt8(4))
        appendBytes(of: CFConvertFloatHostToSwapped(value))
    }

    private func encode(_ value: Double) {
        appendTag(.float)
        appendBytes(of: UInt8(8))
        appendBytes(of: CFConvertDoubleHostToSwapped(value))
    }

    private func encode(_ value: Bool) throws {
        appendTag(.bool)
        appendBytes(of: UInt8(1))
        appendBytes(of: UInt8(value ? 1 as UInt8 : 0 as UInt8))
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
        case let safeBinary as SafeBinaryEncodable:
            try safeBinary.safeBinaryEncode(to: self)
        default:
            throw Error.typeNotConformingToSafeBinaryEncodable(type(of: encodable))
        }
    }
    
    func encodeKey(_ key: String) throws {
        if let index = keyTable.firstIndex(of: key) {
            appendBytes(of: UInt16(index).bigEndian)
            return
        }

        keyTable.append(key)
        appendBytes(of: UInt16(keyTable.count - 1).bigEndian)
    }
//
//    func encodeIfPresent(_ encodable: Encodable?) throws {
//        try encode(encodable != nil)
//        if let value = encodable {
//            try encode(value)
//        }
//    }
}

extension SafeBinaryEncoder: Encoder {
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
        return SingleValueContainer(encoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: SafeBinaryEncoder
        
        // We are not using the keys
        var codingPath: [CodingKey] {
            return []
        }
        
        mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            print("KEYED \(key) ENCODE \(value)")
//            try encoder.encode(value)
            try encoder.encodeKey(key.stringValue)
            try encoder.encode(value)
        }

        mutating func encodeNil(forKey key: Key) throws {
            // This is never called
        }
        
        func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Int8?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: Int16?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Int32?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Int64?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: UInt?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: Bool?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: Float?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent(_ value: Double?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }
        
        func encodeIfPresent(_ value: String?, forKey key: Key) throws {
//            try encoder.encodeIfPresent(value)
        }

        func encodeIfPresent<T>(_ value: T?, forKey key: Key) throws where T : Encodable {
//            try encoder.encodeIfPresent(value)
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

    private struct UnkeyedContainer: UnkeyedEncodingContainer {
        var encoder: SafeBinaryEncoder
        var codingPath: [CodingKey] {
            return []
        }
        
        var count: Int {
            return 0
        }
        
        mutating func encodeNil() throws {
            // If we add nil from an optional, we always put down false. A present optional is true
//            try encoder.encode(false)
            print("ENCODE UNKEYED NIL")
            
            encoder.appendTag(.optional)
            encoder.appendBytes(of: UInt8(0))
        }
        
        func encodeIfPresent<T>(_ value: T?) throws where T : Encodable {
            print("ENCODE UNKEYED OPTIONAL \(value)")
//            switch value {
//            case .some(let unwrappedValue):
//                try encoder.encode(true)
//                try encoder.encode(unwrappedValue)
//            case .none:
//                try encoder.encode(false)
//            }
        }
        
        func encode<T>(_ value: T) throws where T : Encodable {
//            try encoder.encode(value)
            print("ENCODE UNKEYED \(value)")
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
    
    private struct SingleValueContainer: SingleValueEncodingContainer {
        var encoder: SafeBinaryEncoder
        
        var codingPath: [CodingKey] {
            return []
        }
        
        var count: Int {
            return 0
        }
        
        mutating func encodeNil() throws {
            print("SINGLE ENCODE NIL")
            encoder.appendTag(.optional)
            encoder.appendBytes(of: UInt8(0))
        }
        
        mutating func encode<T>(_ value: T) throws where T : Encodable {
            try encoder.encode(value)
        }
        
        mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        mutating func superEncoder() -> Encoder {
            return encoder
        }
        
    }
}
