//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation
import CBORCoding

fileprivate extension Encodable {
    
    func safeBinaryEncoded() throws -> [UInt8] {
        let data = try CBOREncoder().encode(self)
        return [UInt8](data)
    }
}

fileprivate extension Decodable {
    
    static func safeBinaryDecoded(from: [UInt8]) throws -> Self {
        return try CBORDecoder().decode(self, from: Data(from))
    }
}

/// An object that encodes instances of a data type as binary.
public class SafeBinaryEncoder {
    
    /// Returns a binary representation of the object specified.
    ///
    /// - Parameter value: The object to encode into binary.
    public static func encode(_ value: Encodable) throws -> [UInt8] {
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
    public static func decode<T: Decodable>(_ type: T.Type, data: [UInt8]) throws -> T? {
        return try type.safeBinaryDecoded(from: data)
    }
}
