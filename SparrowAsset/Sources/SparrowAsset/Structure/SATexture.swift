//
//  SATexture.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

public struct SATexture: BinaryCodable {
    public let relativePath: String
    
    public init(relativePath: String) {
        self.relativePath = relativePath
    }
}
