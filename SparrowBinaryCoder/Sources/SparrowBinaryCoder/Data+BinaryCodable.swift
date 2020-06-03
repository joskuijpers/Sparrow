//
//  Data+BinaryCodable.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import Foundation

/// Adds binary encoding support.
///
/// Optimizes by writing all data directly to the output instead of as array of UInt8.
extension Data: BinaryCodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.count)
        encoder.appendBytes(in: [UInt8](self))
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        let count = try decoder.decode(Int.self)
        self.init(count: count)
        
        try withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            try decoder.read(count, into: ptr.baseAddress!)
        }
    }
}
