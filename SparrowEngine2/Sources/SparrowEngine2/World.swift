//
//  World.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//

import SparrowECS

public final class World {
    public let n: Nexus
    
    init() {
        n = Nexus()
    }
    
    // We could also put the contexts here....
    // And the deltaTime and frameNumber
    // Then we only ened to pass around the World everywhere
}
