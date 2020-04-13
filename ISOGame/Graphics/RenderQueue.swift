//
//  RenderQueue.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 13/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
 A set of render queues for a specific projection.
 For example, the player camera, or a light (for shadow mapping)
 */
class RenderSet {
    private var pool = [RenderQueueItem]()
    
    /// Render queue of renderabels that have no translucency, but can have cutouts
    var opaque = ContiguousArray<RenderQueueItem>()
    
    /// Render queue of translucent meshes (alpha blending)
    var translucent = ContiguousArray<RenderQueueItem>()
    
    /// Clear the set
    func clear() {
        for item in opaque {
            pool.append(item)
        }
        for item in translucent {
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
        // TODO: add translusency
        
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
        self.depth = depth
        self.mesh = mesh
        self.submeshIndex = submeshIndex
        self.worldTransform = worldTransform
    }
    // numTextures
    // textures: [TextureIdentifier] = [MAX TEXTURES]
    
    // shaderIdentifier
}
