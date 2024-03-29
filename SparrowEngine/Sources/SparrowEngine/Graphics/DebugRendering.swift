//
//  DebugRendering.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 01/03/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

fileprivate struct DebugRenderVertex {
    let position: float3
    let color: float3
}

/// Debug rendering interface.
///
/// Keeps a buffer of colored line segments each frame. This buffer can be filled
/// using convenience function.
public class DebugRendering {
    public static let shared = DebugRendering()
    
    private var pipelineState: MTLRenderPipelineState?
    private var vertices = [DebugRenderVertex]()
    private var buffer: MTLBuffer!
    
    /// Creates a new debug rendering interface
    private init() {
        let count = max(vertices.count, 64)
        buffer = World.shared!.graphics.device.makeBuffer(bytes: &vertices, length: count * MemoryLayout<DebugRenderVertex>.stride, options: [.storageModeShared])!
    }

    /// Draw a box
    public func box(min: float3, max: float3, color: float3) {
        // 12 lines = 24 items
        vertices.append(DebugRenderVertex(position: float3(min.x, min.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, min.y, min.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(min.x, max.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, max.y, min.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(min.x, min.y, max.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, min.y, max.z), color: color))

        vertices.append(DebugRenderVertex(position: float3(min.x, max.y, max.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, max.y, max.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(min.x, min.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(min.x, max.y, min.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(max.x, min.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, max.y, min.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(min.x, min.y, max.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(min.x, max.y, max.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(max.x, min.y, max.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, max.y, max.z), color: color))

        vertices.append(DebugRenderVertex(position: float3(min.x, min.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(min.x, min.y, max.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(max.x, min.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, min.y, max.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(min.x, max.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(min.x, max.y, max.z), color: color))
        
        vertices.append(DebugRenderVertex(position: float3(max.x, max.y, min.z), color: color))
        vertices.append(DebugRenderVertex(position: float3(max.x, max.y, max.z), color: color))
    }
    
    public func sphere(center: float3, radius: Float, color: float3) {
        // TODO
    }
    
    /// Draw a gizmo with x, y and z axis indicators
    public func gizmo(position: float3) {
        // 3 lines = 6 items
        vertices.append(DebugRenderVertex(position: position, color: float3(1, 0, 0)))
        vertices.append(DebugRenderVertex(position: position + float3(1, 0, 0), color: float3(1, 0, 0)))
        
        vertices.append(DebugRenderVertex(position: position, color: float3(0, 1, 0)))
        vertices.append(DebugRenderVertex(position: position + float3(0, 1, 0), color: float3(0, 1, 0)))
        
        vertices.append(DebugRenderVertex(position: position, color: float3(0, 0, 1)))
        vertices.append(DebugRenderVertex(position: position + float3(0, 0, 1), color: float3(0, 0, 1)))
    }
    
    /// Draw a straight line between two points
    public func line(start: float3, end: float3, color: float3) {
        // 1 line = 2 items
        vertices.append(DebugRenderVertex(position: start, color: color))
        vertices.append(DebugRenderVertex(position: end, color: color))
    }
    
    /// Render all debug lines that were generated this frame
    public func render(renderEncoder: MTLRenderCommandEncoder) {
        if vertices.count == 0 {
            return
        }
        
        if pipelineState == nil {
            makePipelineState()
        }
        
        renderEncoder.setRenderPipelineState(pipelineState!)

        updateBuffer()
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count)
        
        // Clear buffer
        vertices.removeAll(keepingCapacity: true)
    }
    
    /// Update the vertex buffer with new contents. Make it larger if the vertices don't fit int he current size.
    ///
    /// - Note: Currently, the buffer never shrinks
    private func updateBuffer() {
        let size = vertices.count * MemoryLayout<DebugRenderVertex>.stride
        if buffer.allocatedSize < size {
            buffer = World.shared!.graphics.device.makeBuffer(bytes: &vertices, length: vertices.count * MemoryLayout<DebugRenderVertex>.stride, options: [.storageModeShared])!
        } else if max(size, 64) < buffer.allocatedSize / 2 {
//            print("TODO: SHRINK DEBUG VERTEX BUFFER")
            buffer.contents().copyMemory(from: &vertices, byteCount: size)
        } else {
            buffer.contents().copyMemory(from: &vertices, byteCount: size)
        }
    }

    /// Create a pipeline state with the debug shaders that simply draw colored vertices.
    private func makePipelineState() {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = World.shared!.graphics.library
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_debug")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_debug")

        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
//        pipelineDescriptor.sampleCount = 4
        
        pipelineState = try! World.shared!.graphics.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}
