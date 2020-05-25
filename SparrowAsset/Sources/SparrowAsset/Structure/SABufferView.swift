//
//  SABufferView.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 03/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

public struct SABufferView: BinaryCodable {
    public let buffer: Int
    public let offset: Int
    public let length: Int
    
    public init(buffer: Int, offset: Int, length: Int) {
        self.buffer = buffer
        self.offset = offset
        self.length = length
    }
}
