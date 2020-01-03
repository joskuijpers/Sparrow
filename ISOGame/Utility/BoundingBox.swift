//
//  BoundingBox.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 02/01/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation
import Metal

struct AxisAlignedBoundingBox {
    let minBounds: float3
    let maxBounds: float3
    
    public init() {
        minBounds = float3(repeating: 0)
        maxBounds = float3(repeating: 0)
    }
    
    public init(minBounds: float3, maxBounds: float3) {
        self.minBounds = minBounds
        self.maxBounds = maxBounds
    }
}

// MARK: - Math

extension AxisAlignedBoundingBox {
    func union(other: AxisAlignedBoundingBox) -> AxisAlignedBoundingBox {
        let minimum = min(self.minBounds, other.minBounds)
        let maximum = max(self.maxBounds, other.maxBounds)
        
        return AxisAlignedBoundingBox(minBounds: minimum, maxBounds: maximum)
    }
}

// MARK: - Rendering

extension AxisAlignedBoundingBox {
    static private var renderPipelineState: MTLRenderPipelineState?
    static private var renderBuffer: MTLBuffer?
    
    /**
     Build the state for the AABB drawing, with a special vertex shader that adjusts a normalize cube vertices to min and max bounds.
     */
    static func buildRenderingState() {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = Renderer.library!
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_debug_aabb")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_debug_aabb")
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        AxisAlignedBoundingBox.renderPipelineState = try! Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        // Cube, normalized. Will be matching the aabb bounds in the vertex shader
        var verts = [float3]()
        
        verts.append(float3(0, 0, 0))
        verts.append(float3(1, 0, 0))
        
        verts.append(float3(0, 1, 0))
        verts.append(float3(1, 1, 0))
        
        verts.append(float3(0, 0, 1))
        verts.append(float3(1, 0, 1))
        
        verts.append(float3(0, 1, 1))
        verts.append(float3(1, 1, 1))
        
        
        verts.append(float3(0, 0, 0))
        verts.append(float3(0, 1, 0))
        
        verts.append(float3(1, 0, 0))
        verts.append(float3(1, 1, 0))
        
        verts.append(float3(0, 0, 1))
        verts.append(float3(0, 1, 1))
        
        verts.append(float3(1, 0, 1))
        verts.append(float3(1, 1, 1))
        
        
        verts.append(float3(0, 0, 0))
        verts.append(float3(0, 0, 1))
        
        verts.append(float3(1, 0, 0))
        verts.append(float3(1, 0, 1))
        
        verts.append(float3(0, 1, 0))
        verts.append(float3(0, 1, 1))
        
        verts.append(float3(1, 1, 0))
        verts.append(float3(1, 1, 1))
        
        AxisAlignedBoundingBox.renderBuffer = Renderer.device.makeBuffer(bytes: &verts, length: verts.count * MemoryLayout<float3>.stride, options: [])!
    }
    
    /**
     Render the bounding box using a special bounding box shader. For debug use only.
     */
    func render(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms, worldTransform: float4x4) {
        if AxisAlignedBoundingBox.renderBuffer == nil || AxisAlignedBoundingBox.renderPipelineState == nil {
            AxisAlignedBoundingBox.buildRenderingState()
        }
        
        // Set special state with custom vertex shader
        renderEncoder.setRenderPipelineState(AxisAlignedBoundingBox.renderPipelineState!)

        var vUniforms = vertexUniforms
        vUniforms.modelMatrix = worldTransform
        renderEncoder.setVertexBytes(&vUniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))

        renderEncoder.setVertexBuffer(AxisAlignedBoundingBox.renderBuffer, offset: 0, index: 0)
        
        // Set special vertex options: it will move the vertices accoridng to the min and max bounds
        var minBounds = self.minBounds
        renderEncoder.setVertexBytes(&minBounds, length: MemoryLayout<float3>.stride, index: 1)
        var maxBounds = self.maxBounds
        renderEncoder.setVertexBytes(&maxBounds, length: MemoryLayout<float3>.stride, index: 2)
        
        var color = float3(1, 0, 0)
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<float3>.stride, index: 0)

        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 24)
    }
}
