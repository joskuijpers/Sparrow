//
//  System.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//

import SparrowECS

/// A system.
public protocol System {
    
    /// Initialize a new system inside given world.
    ///
    /// `world` must _not_ be stored with a strong reference!
    init(world: World)
}
