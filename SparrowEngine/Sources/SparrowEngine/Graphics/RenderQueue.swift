//
//  RenderQueue.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 13/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 A render queue with optimized render item storage.
 */
public struct RenderQueue {
    var store: ContiguousArray<RenderQueueItem>
    let growSize: Int
    var nextIndex: Int = 0
    
    init(initialSize: Int = 128) {
        growSize = initialSize
        
        store = ContiguousArray<RenderQueueItem>(repeating: RenderQueueItem(), count: initialSize)
    }
    
    mutating func clear() {
        nextIndex = 0
    }
    
    mutating func getNextIndex() -> Int {
        if nextIndex + 1 > store.count {
            store += ContiguousArray<RenderQueueItem>(repeating: RenderQueueItem(), count: growSize)
        }
        
        let index = nextIndex
        nextIndex += 1
        
        return index
    }
    
    /// Number of (active) items in this queue.
    var count: Int {
        nextIndex
    }
}

/// Special iterator that stops at empty items
extension RenderQueue {
    func allItems() -> AnyIterator<RenderQueueItem> {
        var index = 0
        
        return AnyIterator({
            if index >= self.nextIndex {
                return nil
            }
            
            let item = self.store[index]
            index += 1
            
            return item
        })
    }
}

/**
 A set of render queues for a specific projection.
 
 For example, the player camera, or a light (for shadow mapping)
 */
public class RenderSet {
    /// Render queue of renderabels that have no translucency, but can have cutouts
    public var opaque = RenderQueue()
    
    /// Render queue of translucent meshes (alpha blending)
    public var translucent = RenderQueue()
    
    /// Create a new renderset with empty queues.
    public init() {}
    
    /// Clear the queues of the set.
    public func clear() {
        opaque.clear()
        translucent.clear()
    }
    
    /// Add a  new render item using an inout closure to prevent copying of structures.
    func add(_ mode: RenderMode, _ cb: (_ item: inout RenderQueueItem) -> Void) {
        switch mode {
        case .opaque, .cutOut:
            let index = opaque.getNextIndex()
            cb(&(opaque.store[index]))
        case .translucent:
            let index = translucent.getNextIndex()
            cb(&(translucent.store[index]))
        }
    }
}

/// An item to render
struct RenderQueueItem {
    public var depth: Float = 0
    public unowned var mesh: Mesh!
    public var submeshIndex: uint16 = 0
    public var worldTransform: float4x4 = .identity()
    public var pipelineState: MetalSubmeshPipelineState!
    public var material: Material!
}
