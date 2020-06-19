//
//  SafeBinaryCodable.swift
//  SparrowSafeBinaryCoder
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation
import CBORCoding

fileprivate extension Encodable {
    
    func safeBinaryEncoded() throws -> Data {
        return try CBOREncoder().encode(self)
    }
}

fileprivate extension Decodable {
    
    static func safeBinaryDecoded(from data: Data) throws -> Self {
        return try CBORDecoder().decode(self, from: data)
    }
}

/// An object that encodes instances of a data type as binary.
public class SafeBinaryEncoder {
    
    /// Returns a binary representation of the object specified.
    ///
    /// - Parameter value: The object to encode into binary.
    public static func encode(_ value: Encodable) throws -> Data {
        return try value.safeBinaryEncoded()
    }
}

/// An object that decodes data into instance of a data type.
public class SafeBinaryDecoder {

    /// Returns a value of the type you specify, decoded from binary data.
    ///
    /// - Parameter type: The type to decode.
    /// - Parameter data: The data to decode.
    ///
    /// If the value is not a valid binary representation of given type, it throws one of the errors.
    public static func decode<T: Decodable>(_ type: T.Type, data: Data) throws -> T {
        return try type.safeBinaryDecoded(from: data)
    }
}
