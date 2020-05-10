//
//  SAScene.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowBinaryCoder

public struct SAScene: BinaryCodable {
    public let nodes: [Int]
    
    public init(nodes: [Int]) {
        self.nodes = nodes
    }
}
