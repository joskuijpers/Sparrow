//
//  Optional+BinaryCodable.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation

/// Adds binary coding support.
///
/// This is a special case where, unlike with the supplied Codable support, we want to
/// write a value if the optional is `some` as well. That way, we always have one byte
/// to indicate whether there is a value or not.
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
