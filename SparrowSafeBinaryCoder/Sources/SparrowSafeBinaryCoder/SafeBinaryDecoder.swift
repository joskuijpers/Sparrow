//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation

public protocol SafeBinaryDecodable: Decodable {
    init(fromBinary decoder: SafeBinaryDecoder) throws
}

extension SafeBinaryDecodable {
    /// Convenience implementation
    public init(fromBinary decoder: SafeBinaryDecoder) throws {
        try self.init(from: decoder)
    }
}

public class SafeBinaryDecoder {
    fileprivate let data: [UInt8]
    fileprivate var cursor = 0
    
    public init(data: [UInt8]) {
        self.data = data
    }
    
    public static func decode<T: SafeBinaryDecodable>(_ type: T.Type, data: [UInt8]) throws -> T {
        let decoder = SafeBinaryDecoder(data: data)
        let value = try decoder.decode(T.self)
        
        if decoder.cursor != data.count {
            throw Error.prematureEndOfDecoding
        }
        
        return value
    }
    
    enum Error: Swift.Error {
        case prematureEndOfData
        
        case typeNotConformingToBinaryDecodable(Decodable.Type)
        
        /// Value was out of range for an integer, or a reasonable integer was expected but not received. Always indicates structure mismatch.
        case intOutOfRange(Int64)
        case uintOutOfRange(UInt64)
        
        /// The encoded boolean value is not in a valid range (0-1)
        case boolOutOfRange(UInt8)
        
        /// String could not be created as the data is invalid UTF8
        case invalidUTF8([UInt8])
        
        /// The decoding ended but not all data was used yet. This can indicate a decoding with too small data type.
        case prematureEndOfDecoding
        
        case unknownTag(UInt8)
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
    
    internal func readTag() throws -> SafeBinaryEncoder.Tag {
        var byte: UInt8 = 0
        try read(into: &byte)
        
        guard let tag = SafeBinaryEncoder.Tag.init(rawValue: byte) else {
            throw Error.unknownTag(byte)
        }
        return tag
    }
}

extension SafeBinaryDecoder {
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
            
        case let binaryT as SafeBinaryDecodable.Type:
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

extension SafeBinaryDecoder: Decoder {
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
        return SingleValueContainer(decoder: self)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
        var decoder: SafeBinaryDecoder
        
        var codingPath: [CodingKey] {
            return []
        }
        
        var allKeys: [Key] {
            return []
        }
        
        func contains(_ key: Key) -> Bool {
            print("TEST CONTAINS KEY \(key)")
            return true
        }
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            print("DECODE KEYED \(type) \(key)")
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
    
    private struct UnkeyedContainer: UnkeyedDecodingContainer {
        var decoder: SafeBinaryDecoder
        
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
            print("DECODE UNKEYED \(type)")
            return try decoder.decode(type)
        }
        
        func decodeNil() -> Bool {
            print("DECODE NIL UNKEYED")
            let isOptionalPresent = try! decoder.decode(Bool.self)
            return !isOptionalPresent
        }
        
        func decodeIfPresent(_ type: Int.Type) throws -> Int? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int8.Type) throws -> Int8? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int16.Type) throws -> Int16? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int32.Type) throws -> Int32? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Int64.Type) throws -> Int64? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt.Type) throws -> UInt? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt8.Type) throws -> UInt8? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt16.Type) throws -> UInt16? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt32.Type) throws -> UInt32? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: UInt64.Type) throws -> UInt64? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Bool.Type) throws -> Bool? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Float.Type) throws -> Float? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: Double.Type) throws -> Double? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent(_ type: String.Type) throws -> String? {
            return try decoder.decodeIfPresent(type)
        }
        
        func decodeIfPresent<T>(_ type: T.Type) throws -> T? where T : Decodable {
            return try decoder.decodeIfPresent(type)
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
    
    private struct SingleValueContainer: SingleValueDecodingContainer {
        var decoder: SafeBinaryDecoder
        var codingPath: [CodingKey] {
            return []
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            print("DECODE SINGLE \(type)")
            return try decoder.decode(type)
        }
        
        func decodeNil() -> Bool {
            print("DECODE SINGLE NIL")
            let isOptionalPresent = try! decoder.decode(Bool.self)
            return !isOptionalPresent
        }
    }
    
}
