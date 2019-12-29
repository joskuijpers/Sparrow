//
//  BufferView.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import Metal

class STFBufferView {
    var bufferViewIndex: Int = 0
    var byteLength: Int = 0
    var byteStride: Int = 0
    var byteOffset: Int = 0
    var target: Int = 0
    var buffer: MTLBuffer!
    var bufferIndex: Int = 0
    
    init(index: Int, json: JSONBufferView) {
        bufferViewIndex = index
        byteLength = json.byteLength
        byteStride = json.byteStride ?? 0
        byteOffset = json.byteOffset
        target = json.target ?? 0
        bufferIndex = json.buffer
    }
}
