//
//  SABuffer.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

public struct SABuffer: BinaryCodable {
    public let size: Int
    public let data: Data
    
    public init(data: Data) {
        self.data = data
        self.size = data.count
    }
}
