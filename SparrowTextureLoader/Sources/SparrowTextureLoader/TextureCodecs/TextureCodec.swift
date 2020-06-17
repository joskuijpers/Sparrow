//
//  TextureCodec.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 16/06/2020.
//

import Foundation

// A decoder for a texture format.
protocol TextureCodec {
    /// Get whether the codec is used inside given data
    static func isContained(in data: Data) -> Bool

    /// Initialize a codec.
    init()
    
    /// Load a texture.
    func load(from data: Data) throws -> TextureDescriptor
}
