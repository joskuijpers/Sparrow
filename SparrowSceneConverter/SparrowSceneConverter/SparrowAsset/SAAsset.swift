//
//  SAAsset.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SAAsset {
    var generator: String
    var origin: String
    var version: Int
    
    var materials: [SAMaterial] = []
    var nodes: [SANode] = []
    var meshes: [SAMesh] = []
    var textures: [SATexture] = []
    var scenes: [SAScene] = []
    var buffers: [SABuffer] = []
    var bufferViews: [SABufferView] = []
    var lights: [SALight] = []
}
