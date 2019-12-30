//
//  STFScene.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation

public class STFScene {
//    private weak var asset: STFAsset?
    public var nodes = [STFNode]()
    public let name: String
    public var meshNodes = [STFNode]()
    
    init(json: JSONScene) {
        self.name = json.name ?? "untitled"
    }
    
    /// Get the number of children in this scene
    public var count: Int {
        return nodes.count
    }
    
    /// Get the child at given index
    public func node(at: Int) -> STFNode {
        return nodes[at]
    }
}
