//
//  SABufferView.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 03/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import SparrowBinaryCoder

struct SABufferView: BinaryCodable {
    var buffer: Int
    var offset: Int
    var length: Int
}
