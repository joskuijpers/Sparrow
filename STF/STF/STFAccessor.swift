//
//  STFAccessor.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation

class STFAccessor {
    let accessorIndex: Int
    let componentType: Int
    let type: String
    let offset: Int
    let count: Int
    var bufferView: STFBufferView
//    var valueRange: STFValueRange()
    
    init(index: Int, json: JSONAccessor, bufferView: STFBufferView) {
        accessorIndex = index
        componentType = json.componentType
        type = json.type
        offset = json.byteOffset ?? 0
        count = json.count
        self.bufferView = bufferView
    }
}
