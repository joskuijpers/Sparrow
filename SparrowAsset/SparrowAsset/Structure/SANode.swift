//
//  SANode.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import simd
import SparrowBinaryCoder

public struct SANode: BinaryCodable {
    public let name: String
    
    public var matrix: matrix_float4x4 = matrix_identity_float4x4
    public var children: [Int] = []
    
    public var mesh: Int? = nil
    public var camera: Int? = nil
    public var light: Int? = nil
    
    public init(name: String,
                matrix: matrix_float4x4,
                children: [Int],
                mesh: Int?,
                camera: Int?,
                light: Int?) {
        self.name = name
        self.matrix = matrix
        self.children = children
        self.mesh = mesh
        self.camera = camera
        self.light = light
    }
}

