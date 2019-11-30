//
//  Renderer.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Renderer: NSObject {
    static var device: MTLDevice!
    static var library: MTLLibrary?
    static var colorPixelFormat: MTLPixelFormat!
    
    let commandQueue: MTLCommandQueue!
    
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    
    let depthStencilState: MTLDepthStencilState
//    let lighting = Lighting()
    
    
    lazy var camera: Camera = {
        let camera = ArcballCamera()
        
        camera.distance = 4.3
        camera.target = [0, 1.2, 0]
        camera.rotation.x = Float(-10).degreesToRadians
        
        return camera
    }()
    
    // List of models
    var models: [Model] = []
    
    
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
                fatalError("Metal GPU not available")
        }
        
        Renderer.device = device
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        self.commandQueue = commandQueue
        
        depthStencilState = Renderer.buildDepthStencilState()!
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        metalView.delegate = self
        
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        
        
        
        
        let house = Model(name: "lowpoly-house.obj")
        house.position = [0, 0, 0]
        house.rotation = [0, Float(45).degreesToRadians, 0]
        models.append(house)
        
        let house2 = Model(name: "cottage1.obj")
        house2.position = [0, 0, 4]
        house2.rotation = [0, Float(45).degreesToRadians, 0]
        models.append(house2)
        
        let house3 = Model(name: "cottage2.obj")
        house3.position = [8, 0, 4]
        house3.rotation = [0, Float(45).degreesToRadians, 0]
        models.append(house3)
        
        let house4 = Model(name: "chest.obj")
        house4.position = [-4, 0, 8]
        house4.rotation = [0, Float(45).degreesToRadians, 0]
        models.append(house4)
    }
    
    
    /// Create a simple depth stencil state that writes to the depth buffer
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
}

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.aspect = Float(view.bounds.width) / Float(view.bounds.height)
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position
    
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        for model in models {
            renderEncoder.pushDebugGroup(model.name)
            
            uniforms.modelMatrix = model.modelMatrix
            uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
            
            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride,
                                         index: Int(BufferIndexUniforms.rawValue))
            
            for mesh in model.meshes {
                for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated() {
                    renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
                }
                
                
                for submesh in mesh.submeshes {
                    renderEncoder.setRenderPipelineState(submesh.pipelineState)
                    
                    renderEncoder.setFragmentTexture(submesh.textures.albedo, index: Int(TextureAlbedo.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(TextureNormal.rawValue))
                    
                    let mtkSubmesh = submesh.mtkSubmesh
                    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                        indexCount: mtkSubmesh.indexCount,
                                                        indexType: mtkSubmesh.indexType,
                                                        indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                                        indexBufferOffset: mtkSubmesh.indexBuffer.offset)
                }
            }
            
            renderEncoder.popDebugGroup()
        }
        
        
        
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}
