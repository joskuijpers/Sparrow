//
//  System.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 08/06/2020.
//

import Foundation

public protocol System {
    init(world: World, context: Context)
    
    //func update(dt: TimeInterval)
}
