//
//  RenderQueue.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 13/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/**
 A queue of renderables
 */
class RenderQueue {
    private var list = [Bool]()
    
    init() {
    }
    
    @inlinable public var isEmpty: Bool {
        list.isEmpty
    }
    
    /// Add a new renderable to the queue
    func add(_ renderable: Bool) {
        list.append(renderable)
    }
    
    /// Clear the queue
    func clear() {
        list.removeAll(keepingCapacity: true)
    }
    
    /// Sort the queue
    func sort() {
        
//        list.sort { (a, b) -> Bool in
//            return a.id < b.id
//        }
    }
}

/**
 A set of render queues for a specific projection.
 For example, the player camera, or a light (for shadow mapping)
 */
class RenderSet {
    /// Render queue of renderabels that have no translucency, but can have cutouts
    var opaque = RenderQueue()
    
    /// Render queue of translucent renderables
    var translucent = RenderQueue()
    
    /// Add a new renderable to the set. Will be put in the appropriate queue.
    func add(_ renderable: Bool) {
        // TODO: depends on the material. Every submesh can have material... ?????
//        switch (renderable.renderMode) {
//        case .opaque, .cutout:
//            opaque.add(renderable)
//        case .translucent:
//            translucent.add(renderable)
//        }
        
        opaque.add(renderable)
    }
    
    /// Clear the set
    func clear() {
        opaque.clear()
        translucent.clear()
    }
}
