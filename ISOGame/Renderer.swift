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
    static var textureLoader: TextureLoader!
    
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
    
    let irradianceCubeMap: MTLTexture;
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
                fatalError("Metal GPU not available")
        }
        
        Renderer.device = device
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        Renderer.textureLoader = TextureLoader()
        
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        self.commandQueue = commandQueue
        
        depthStencilState = Renderer.buildDepthStencilState()!
        
        irradianceCubeMap = Renderer.buildEnvironmentTexture(device: device, "garage_pmrem.ktx")
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        metalView.delegate = self
        
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        

        for i in 1...5 {
            let sphere = Model(name: "ironSphere.obj")
            sphere.position = [Float(1 + 3 * i), 0, 0]
            models.append(sphere)
        }

        for i in 1...5 {
            let sphere = Model(name: "goldSphere.obj")
            sphere.position = [Float(1 + 3 * i), 3, 0]
            models.append(sphere)
        }

        for i in 1...5 {
            let sphere = Model(name: "plasticSphere.obj")
            sphere.position = [Float(1 + 3 * i), -3, 0]
            models.append(sphere)
        }

        for i in 1...5 {
            let sphere = Model(name: "grassSphere.obj")
            sphere.position = [Float(1 + 3 * i), 6, 0]
            models.append(sphere)
        }
        
        let cube = Model(name: "cube.obj")
        cube.position = [0, 0, 0]
        models.append(cube)
        
        
        
        let helmet = Model(name: "helmet.obj")
        helmet.position = [-3, 0, 0]
        helmet.rotation = [0, Float(180).degreesToRadians, 0]
        models.append(helmet)
    }
    
    
    /// Create a simple depth stencil state that writes to the depth buffer
    static func buildDepthStencilState() -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
    
    static func buildEnvironmentTexture(device: MTLDevice, _ name: String) -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option : Any] = [:]
        
        do {
            let textureURL = Bundle.main.url(forResource: name, withExtension: nil)!
            let texture = try textureLoader.newTexture(URL: textureURL, options: options)
            
            return texture
        } catch {
            fatalError("Could not load irradiance map: \(error)")
        }
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
        renderEncoder.setFragmentTexture(irradianceCubeMap, index: Int(TextureIrradiance.rawValue))
        
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
                    renderEncoder.setFragmentTexture(submesh.textures.roughness, index: Int(TextureRoughness.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.metallic, index: Int(TextureMetallic.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.ambientOcclusion, index: Int(TextureAmbientOcclusion.rawValue))
//                    renderEncoder.setFragmentTexture(submesh.textures.emissive, index: Int(TextureEmission.rawValue))
                    
                    var material = submesh.material
                    renderEncoder.setFragmentBytes(&material,
                                                   length: MemoryLayout<Material>.stride,
                                                   index: Int(BufferIndexMaterials.rawValue))
                    
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
