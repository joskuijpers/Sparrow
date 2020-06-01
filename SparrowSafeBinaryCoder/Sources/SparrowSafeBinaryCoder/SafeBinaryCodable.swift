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

public class SafeBinaryEncoder {
    
    public static func encode(_ v: Encodable) throws -> [UInt8] {
        return try v.safeBinaryEncoded()
    }
    
}

public class SafeBinaryDecoder {

    public static func decode<T: Decodable>(_ type: T.Type, data: [UInt8]) throws -> T? {
        return try type.safeBinaryDecoded(from: data)
    }
    
}
