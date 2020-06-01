//
//  Array+BinaryCodable.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation

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
        
        // Value can never be this high. if it is, we did read a byte too few
        // before and a high bit was set for the count.
        if count > UInt32.max {
            throw BinaryDecoder.Error.intOutOfRange(Int64(count))
        }
        
        self.reserveCapacity(count)

        for _ in 0..<count {
            let decoded = try Element.init(from: decoder)
            self.append(decoded)
        }
    }
}
