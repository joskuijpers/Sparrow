//
//  SABuffer.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

struct SABuffer: BinaryCodable {
    var size: Int
    var data: Data
}
