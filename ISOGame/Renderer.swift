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

    let depthStencilState: MTLDepthStencilState
//    let lighting = Lighting()
    
    var scene: Scene
    var rotNode: Node!
    
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
        
        scene = Scene(screenSize: metalView.bounds.size)
        
        let camera = ArcballCamera()
        camera.distance = 4.3
        camera.target = [0, 1.2, 0]
        camera.rotation.x = Float(-10).degreesToRadians
        scene.add(node: camera)
        scene.currentCameraIndex = 1
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        metalView.delegate = self
        
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        
        rotNode = Node()
        rotNode.position = [5, 0, 0]
        scene.add(node: rotNode)
        
        for i in 0...4 {
            let sphere = Model(name: "ironSphere.obj")
            sphere.position = [Float(3 * i), 0, 0]
            scene.add(node: sphere, parent: rotNode)
        }

        for i in 0...4 {
            let sphere = Model(name: "goldSphere.obj")
            sphere.position = [Float(3 * i), 3, 0]
            scene.add(node: sphere, parent: rotNode)
        }

        for i in 0...4 {
            let sphere = Model(name: "plasticSphere.obj")
            sphere.position = [Float(3 * i), -3, 0]
            scene.add(node: sphere, parent: rotNode)
        }

        for i in 0...4 {
            let sphere = Model(name: "grassSphere.obj")
            sphere.position = [Float(3 * i), 6, 0]
            scene.add(node: sphere)
        }
        
        let cube = Model(name: "cube.obj")
        cube.position = [0, 0, 0]
        scene.add(node: cube)
        
        
        
        let helmet = Model(name: "helmet.obj")
        helmet.position = [-3, 0, 0]
        helmet.rotation = [0, Float(180).degreesToRadians, 0]
        scene.add(node: helmet)
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
        scene.screenSizeWillChange(to: size)
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        
        let deltaTime = 1.0 / Float(view.preferredFramesPerSecond)
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        scene.updateUniforms()
    
        renderEncoder.setFragmentBytes(&scene.fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        renderEncoder.setFragmentTexture(irradianceCubeMap, index: Int(TextureIrradiance.rawValue))
        
        
        rotNode.rotation += float3(0, Float(10).degreesToRadians * deltaTime, 0)
        
        for renderable in scene.renderables {
            renderEncoder.pushDebugGroup(renderable.name)
            
            renderable.render(renderEncoder: renderEncoder, vertexUniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
            
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
