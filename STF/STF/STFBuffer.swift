//
//  STFBuffer.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import Metal

public class STFBuffer {
    public let mtlBuffer: MTLBuffer
    
    init(mtlBuffer: MTLBuffer) {
        self.mtlBuffer = mtlBuffer
    }
}
