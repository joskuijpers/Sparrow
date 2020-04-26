//
//  RenderQueue.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 13/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
 A render queue with optimized render item storage.
 */
struct RenderQueue {
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
class RenderSet {
    /// Render queue of renderabels that have no translucency, but can have cutouts
    var opaque = RenderQueue()
    
    /// Render queue of translucent meshes (alpha blending)
    var translucent = RenderQueue()
    
    /// Clear the set
    func clear() {
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

/**
 An item to render
 */
struct RenderQueueItem {
    var depth: Float = 0
    unowned var mesh: Mesh!
    var submeshIndex: uint8 = 0
    var worldTransform: float4x4 = .identity()

    // numTextures
    // textures: [TextureIdentifier] = [MAX TEXTURES]
    
    // shaderIdentifier
}
