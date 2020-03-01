//
//  DebugRendering.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 01/03/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import MetalKit

fileprivate struct DebugRenderVertex {
    let position: float3
    let color: float3
}

public class DebugRendering {
    static let shared = DebugRendering()
    
    private var pipelineState: MTLRenderPipelineState?
    private var vertices = [DebugRenderVertex]()
    private var buffer: MTLBuffer!
    
    private init() {
        let count = max(vertices.count, 64)
        buffer = Renderer.device.makeBuffer(bytes: &vertices, length: count * MemoryLayout<DebugRenderVertex>.stride, options: [.storageModeShared])!
    }

    /// Draw a box
    func box(min: float3, max: float3, color: float3) {
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
    
    func sphere(center: float3, radius: Float, color: float3) {
        // TODO
    }
    
    /// Draw a gizmo with x, y and z axis indicators
    func gizmo(position: float3) {
        // 3 lines = 6 items
        vertices.append(DebugRenderVertex(position: position, color: float3(1, 0, 0)))
        vertices.append(DebugRenderVertex(position: position + float3(1, 0, 0), color: float3(1, 0, 0)))
        
        vertices.append(DebugRenderVertex(position: position, color: float3(0, 1, 0)))
        vertices.append(DebugRenderVertex(position: position + float3(0, 1, 0), color: float3(0, 1, 0)))
        
        vertices.append(DebugRenderVertex(position: position, color: float3(0, 0, 1)))
        vertices.append(DebugRenderVertex(position: position + float3(0, 0, 1), color: float3(0, 0, 1)))
    }
    
    /// Draw a straight line between two points
    func line(start: float3, end: float3, color: float3) {
        // 1 line = 2 items
        vertices.append(DebugRenderVertex(position: start, color: color))
        vertices.append(DebugRenderVertex(position: end, color: color))
    }
    
    /// Render all debug lines that were generated this frame
    internal func render(renderEncoder: MTLRenderCommandEncoder, vertexUniforms: Uniforms) {
        if pipelineState == nil {
            makePipelineState()
        }
        
        renderEncoder.setRenderPipelineState(pipelineState!)

        // Needed for project/view matrix
        var vUniforms = vertexUniforms
        renderEncoder.setVertexBytes(&vUniforms,
                                     length: MemoryLayout<Uniforms>.stride,
                                     index: Int(BufferIndexUniforms.rawValue))
        
        updateBuffer()
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count)
        
        // Clear buffer
        vertices.removeAll(keepingCapacity: true)
    }
    
    private func updateBuffer() {
        let size = vertices.count * MemoryLayout<DebugRenderVertex>.stride
        if buffer.allocatedSize < size {
            buffer = Renderer.device.makeBuffer(bytes: &vertices, length: (vertices.count + 64) * MemoryLayout<DebugRenderVertex>.stride, options: [.storageModeShared])!
        } else {
            buffer.contents().copyMemory(from: &vertices, byteCount: size)
        }
    }

    private func makePipelineState() {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let library = Renderer.library!
        
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_debug")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_debug")

        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        pipelineState = try! Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}
