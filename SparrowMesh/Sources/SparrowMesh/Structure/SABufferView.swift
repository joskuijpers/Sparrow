//
//  SABufferView.swift
//  SparrowAsset
//
//  Created by Jos Kuijpers on 03/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

/// A view into a buffer.
public struct SABufferView: BinaryCodable {
    /// Index of the buffer.
    public let buffer: Int
    
    /// Byte offset into the buffer.
    public let offset: Int
    
    /// Byte-length of the view.
    public let length: Int
    
    /// Create a new buffer view.
    public init(buffer: Int, offset: Int, length: Int) {
        self.buffer = buffer
        self.offset = offset
        self.length = length
    }
}
