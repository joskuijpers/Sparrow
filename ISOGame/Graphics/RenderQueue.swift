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
struct RenderQueue: Sequence {
    typealias Element = RenderItem
    
    fileprivate var list = [RenderItem]()
    
    var count: Int {
        list.count
    }
    
    init() {
    }
    
    @inlinable public var isEmpty: Bool {
        list.isEmpty
    }
    
    /// Add a new renderable to the queue
    mutating func add(_ item: RenderItem) {
        list.append(item)
    }
    
    /// Clear the queue
    mutating func clear() {
        list.removeAll(keepingCapacity: true)
    }
    
    /// Sort the queue
    func sort() {
        
//        list.sort { (a, b) -> Bool in
//            return a.id < b.id
//        }
    }
    
    func makeIterator() -> RenderQueueIterator {
        return RenderQueueIterator(queue: self)
    }
}

struct RenderQueueIterator: IteratorProtocol {
    let queue: RenderQueue
    var current = 0
    
    mutating func next() -> RenderItem? {
        if current > queue.list.count - 1 {
            return nil
        }

        let item = queue.list[current]
        current += 1
        return item
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
    func add(_ item: RenderItem) {
//        switch (item.submesh.material.renderMode) {
//        case .opaque, .cutout:
//            opaque.add(renderable)
//        case .translucent:
//            translucent.add(renderable)
//        }
        
        opaque.add(item)
    }
    
    /// Clear the set
    func clear() {
        opaque.clear()
        translucent.clear()
    }
}

struct RenderItem {
    let transform: float4x4
    let depth: Float
    let vertexBuffers: [MTKMeshBuffer]
    let submesh: Submesh
    
    // let renderMode: RenderMode // .opaque, .alphaTest/cutout, .alphaBlend/translucent
    
    func render(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms, fragmentUniforms: FragmentUniforms) {
        var vUniforms = vertexUniforms
        
        vUniforms.modelMatrix = transform
        vUniforms.normalMatrix = transform.upperLeft
        
        renderEncoder.setVertexBytes(&vUniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))
        
        for (index, vertexBuffer) in vertexBuffers.enumerated() {
            renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
        }
        
        submesh.render(renderEncoder: renderEncoder)
    }
}
