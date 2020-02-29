//
//  RenderQueue.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 13/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
 A queue of renderables
 */
//struct RenderQueue: Sequence {
//    typealias Element = RenderQueueItem
//    fileprivate var store = ContiguousArray<RenderQueueItem?>()
//
//    /// Total number of active items
//    private(set) var size = 0
//
//    init(minCount: Int = 256) {
//        store = ContiguousArray<RenderQueueItem?>(repeating: nil, count: minCount)
//    }
//
//    @inlinable public var isEmpty: Bool {
//        size == 0
//    }
//
//    /// Add a new renderable to the queue
//    mutating func add(_ item: RenderQueueItem) {
//        store.add(item)
//    }
//
//    /// Clear the queue
//    mutating func clear() {
//        store.removeAll(keepingCapacity: true)
//        size = 0
//    }
//
//    /// Sort the queue
//    func sort() {
////        list.sort { (a, b) -> Bool in
////            return a.id < b.id
////        }
//    }
//
//    func makeIterator() -> RenderQueueIterator {
//        return RenderQueueIterator(queue: self)
//    }
//}

//struct RenderQueueIterator: IteratorProtocol {
//    let queue: RenderQueue
//    var current = 0
//
//    mutating func next() -> RenderQueueItem? {
//        if current > queue.size - 1 {
//            return nil
//        }
//
//        let item = queue.store[current]
//        current += 1
//        return item
//    }
//}

/**
 A set of render queues for a specific projection.
 For example, the player camera, or a light (for shadow mapping)
 */
class RenderSet {
    private var pool = [RenderQueueItem]()
    
    /// Render queue of renderabels that have no translucency, but can have cutouts
    var opaque = ContiguousArray<RenderQueueItem>()//RenderQueue()
    
    /// Render queue of translucent meshes (alpha blending)
//    var translucent = RenderQueue()
    
    /// Clear the set
    func clear() {
        for item in opaque {
            pool.append(item)
        }
        
        opaque.removeAll(keepingCapacity: true)
    }
    
    /// Acquire a render queue item to fill
    func acquire() -> RenderQueueItem {
        if pool.count > 0 {
            return pool.remove(at: 0)
        }

        return RenderQueueItem()
    }
    
    /// Add an item to the queue
    func add(_ item: RenderQueueItem) {
        opaque.append(item)
    }
}

enum RenderMode {
    case opaque
    case cutOut // alphaTest
    case translucent // alphaBlend
}

/**
 An item to render
 */
struct RenderQueueItem {
    var depth: Float
    unowned var mesh: Mesh!
    var submeshIndex: uint8
    var worldTransform: float4x4

    init() {
        depth = 0
        mesh = nil
        submeshIndex = 0
        worldTransform = float4x4.identity()
    }
    
    mutating func set(depth: Float, mesh: Mesh, submeshIndex: uint8, worldTransform: float4x4) {
//        print("SETTING ITEM", depth, mesh, submeshIndex, worldTransform)
        
        self.depth = depth
        self.mesh = mesh
        self.submeshIndex = submeshIndex
        self.worldTransform = worldTransform
    }
    // numTextures
    // textures: [TextureIdentifier] = [MAX TEXTURES]
    
    // shaderIdentifier
}
