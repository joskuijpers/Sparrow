//
//  BinaryDecoder.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 09/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

public protocol BinaryDecodable: Decodable {
    init(fromBinary decoder: BinaryDecoder) throws
}

extension BinaryDecodable {
    /// Convenience implementation
    public init(fromBinary decoder: BinaryDecoder) throws {
        try self.init(from: decoder)
    }
}

public class BinaryDecoder {
    fileprivate let data: [UInt8]
    fileprivate var cursor = 0
    
    public init(data: [UInt8]) {
        self.data = data
    }
    
    public static func decode<T: BinaryDecodable>(_ type: T.Type, data: [UInt8]) throws -> T {
        let decoder = BinaryDecoder(data: data)
        let value = try decoder.decode(T.self)
        
        if decoder.cursor != data.count {
            throw Error.prematureEndOfDecoding
        }
        
        return value
    }
    
    enum Error: Swift.Error {
        case prematureEndOfData
        
        case typeNotConformingToBinaryDecodable(Decodable.Type)
        
        case intOutOfRange(Int64)
        case uintOutOfRange(UInt64)
        
        /// The encoded boolean value is not in a valid range (0-1)
        case boolOutOfRange(UInt8)
        
        /// String could not be created as the data is invalid UTF8
        case invalidUTF8([UInt8])
        
        /// The decoding ended but not all data was used yet. This can indicate a decoding with too small data type.
        case prematureEndOfDecoding
    }
    
    internal func read(_ byteCount: Int, into: UnsafeMutableRawPointer) throws {
        if cursor + byteCount > data.count {
            throw Error.prematureEndOfData
        }
        
        data.withUnsafeBytes {
            let from = $0.baseAddress! + cursor
            memcpy(into, from, byteCount)
        }
        
        cursor += byteCount
    }
    
    internal func read<T>(into: inout T) throws {
        try read(MemoryLayout<T>.size, into: &into)
    }
}

extension BinaryDecoder {
    private func decode(_ type: Float.Type) throws -> Float {
        var swapped = CFSwappedFloat32()
        try read(into: &swapped)
        return CFConvertFloatSwappedToHost(swapped)
    }
    
    private func decode(_ type: Double.Type) throws -> Double {
        var swapped = CFSwappedFloat64()
        try read(into: &swapped)
        return CFConvertDoubleSwappedToHost(swapped)
    }
    
    private func decode(_ type: Bool.Type) throws -> Bool {
        switch try decode(UInt8.self) {
        case 0: return false
        case 1: return true
        case let value: throw Error.boolOutOfRange(value)
        }
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        switch type {
        case is Int.Type:
            let v = try decode(Int64.self)
            if let v = Int(exactly: v) {
                return v as! T
            } else {
                throw Error.intOutOfRange(v)
            }
        case is UInt.Type:
            let v = try decode(UInt64.self)
            if let v = UInt(exactly: v) {
                return v as! T
            } else {
                throw Error.uintOutOfRange(v)
            }

        case is Float.Type:
            return try decode(Float.self) as! T
        case is Double.Type:
            return try decode(Double.self) as! T
            
        case is Bool.Type:
            return try decode(Bool.self) as! T
            
        case let binaryT as BinaryDecodable.Type:
            return try binaryT.init(fromBinary: self) as! T
            
        default:
            throw Error.typeNotConformingToBinaryDecodable(type)
        }
    }
    
    func decodeIfPresent<T: Decodable>(_ type: T.Type) throws -> T? {
        let present = try decode(Bool.self)
        if present {
            return try decode(type)
        }
        
        return nil
    }
}

extension BinaryDecoder: Decoder {
    public var codingPath: [CodingKey] {
        return []
    }
    
    public var userInfo: [CodingUserInfoKey : Any] {
        return [:]
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return UnkeyedContainer(decoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var decoder: BinaryDecoder
        
        var codingPath: [CodingKey] {
            return []
        }
        
        var allKeys: [Key] {
            return []
        }
        
        func contains(_ key: Key) -> Bool {
            return true
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            return try decoder.decode(T.self)
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            print("DECODING NIL1")
            return true
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            return try decoder.unkeyedContainer()
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
        
        func superDecoder(forKey key: Key) throws -> Decoder {
            return decoder
        }
        
        func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
            return try decoder.decodeIfPresent(type)
        }
    }
    
    private struct UnkeyedContainer: UnkeyedDecodingContainer, SingleValueDecodingContainer {
        
        var decoder: BinaryDecoder
        
        var codingPath: [CodingKey] {
            return []
        }
        
        var count: Int? {
            return nil
        }
        
        var currentIndex: Int {
            return 0
        }
        
        var isAtEnd: Bool {
            return false
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            return try decoder.decode(type)
        }
        
        func decodeNil() -> Bool {
            print("DECODING NIL2")
            return true
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            return try decoder.container(keyedBy: type)
        }
        
        func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
            return self
        }
        
        func superDecoder() throws -> Decoder {
            return decoder
        }
    }
    
}
