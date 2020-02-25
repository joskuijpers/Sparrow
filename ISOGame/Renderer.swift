//
//  Renderer.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

extension Nexus {
    static func shared() -> Nexus {
        return Renderer.nexus
    }
}

class Renderer: NSObject {
    static var device: MTLDevice!
    static var library: MTLLibrary?
    static var colorPixelFormat: MTLPixelFormat!
    static var textureLoader: TextureLoader!
    
    let commandQueue: MTLCommandQueue!

    let depthStencilState: MTLDepthStencilState
    
    var scene: Scene
    
    let irradianceCubeMap: MTLTexture;
    
    fileprivate static var nexus: Nexus!
    let renderSystem: RenderSystem
    let behaviorSystem: BehaviorSystem
    var rootEntity: Entity!
    
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

        
        
        Renderer.nexus = Nexus()
        renderSystem = RenderSystem()
        behaviorSystem = BehaviorSystem()
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        metalView.delegate = self
        
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)

        
        buildScene()
    }
    
    // For testing
    func buildScene() {
        let camera = Nexus.shared().createEntity()
        camera.add(component: Transform())
        let cameraComp = camera.add(component: ArcballCamera())
        cameraComp.distance = 4.3
        cameraComp.target = [0, 1.2, 0]
        if var r = cameraComp.transform?.rotation {
            r.x = Float(-10).degreesToRadians
            cameraComp.transform?.rotation = r
        }
//        camera.add(component: Camera())
//        camera.add(behavior: ArcBallCamera(distance: 4.3, target: [0, 1.2, 0]))
        
        
        scene.camera = cameraComp
        
        
        let skyLight = Nexus.shared().createEntity()
        skyLight.add(component: Transform())
        
        let light = skyLight.add(component: Light(type: .directional))
        light.direction = float3(0, -5, 10)
        light.color = float3(2, 2, 2)
        
        
        let helmet = Nexus.shared().createEntity()
        let transform = helmet.add(component: Transform())
        transform.position = float3(0, 0, 0)
        
        helmet.add(component: MeshSelector(mesh: Mesh(name: "helmet.obj")))
        helmet.add(component: MeshRenderer())
        helmet.add(behavior: HelloWorldComponent())
        
        
        let cube = Nexus.shared().createEntity()
        cube.add(component: Transform())
        cube.transform?.position = float3(0, 0, 3)
        cube.add(component: MeshSelector(mesh: Mesh(name: "cube.obj")))
        cube.add(component: MeshRenderer())
        // cube.add(behavior: HelloWorldComponent())
        Nexus.shared().addChild(cube, to: helmet)
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
    
    func fillRenderQueues() {
//        renderQueue.clear()
        
        // RenderQueue<Renderable>
        // RenderQueue<LightData>
            // .count
        
        // Walk through whole scene graph
            // if node is visible in frustrum
                // if is renderable
                    // if has alpha blending
                        // Fill transparency queue
                    // else
                        // Fill opaque queue
                // if node is a light
                    // add to lights list
    }
    
    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        
        /*
         
         behaviorSystem.update(dt)
         
         renderSystem.render()
            split into the passes as needed, e.g. filling queue first
         */
        
//        Renderer.nexus.walkSceneGraph(root: self.rootEntity) { (entity, parent) -> Nexus.SceneGraphWalkAction in
//            print("ENTITY", entity, "PARENT", parent ?? "none")
//              this could update all transforms (if dirty), and active-ness. all entities need to have an up-to-date state of active/visible/worldTRANSFORM before rendering
//            return .walkChildren
        
//        }
        /*
        renderSystem.render()
           split into the passes as needed, e.g. filling queue first, with frustrum culling
            then do the passes from these queues
        */
        
        let deltaTime = TimeInterval(1.0 / Double(view.preferredFramesPerSecond))
        behaviorSystem.update(deltaTime: deltaTime)
        
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        scene.updateUniforms()
        
//        fillRenderQueues()
    
        renderSystem.render(renderEncoder: renderEncoder, irradianceCubeMap: irradianceCubeMap, scene: scene)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}

/// Behavior test
class HelloWorldComponent: Behavior {
    override func onUpdate(deltaTime: TimeInterval) {
        if let rotation = transform?.rotation {
            transform?.rotation = rotation + float3(0, Float(30).degreesToRadians * Float(deltaTime), 0)
        }
    }
}

class RenderSystem {
    let lights = Nexus.shared().group(requires: Light.self)
    let meshes = Nexus.shared().group(requiresAll: MeshSelector.self, MeshRenderer.self)
    
    func render(renderEncoder: MTLRenderCommandEncoder, irradianceCubeMap: MTLTexture, scene: Scene) {
//        let scene = SceneManager.activeScene
        
        // START BUILD LIGHTS
        // todo: limit with Bounds... culling...
        var lightsData: [LightData] = lights.map { $0.build() }
        var lightCount = lightsData.count
        
        renderEncoder.setFragmentBytes(&lightCount, length: MemoryLayout<Int>.stride, index: 15)
        renderEncoder.setFragmentBytes(&lightsData, length: MemoryLayout<LightData>.stride * lightCount, index: 16)
        // END BUILD LIGHTS
        
        // Update fragment uniforms if possible here
        
        renderEncoder.setFragmentBytes(&scene.fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        // Set irradiance texture
        renderEncoder.setFragmentTexture(irradianceCubeMap, index: Int(TextureIrradiance.rawValue))

        
        for (meshSelector, meshRenderer) in meshes {
            renderEncoder.pushDebugGroup(meshSelector.mesh!.name)

            meshRenderer.render(renderEncoder: renderEncoder, pass: RenderPass.gbuffer, vertexUniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
            
            renderEncoder.popDebugGroup()
        }

        // Easy testing
        NSApplication.shared.mainWindow?.title = "Drawn meshes: \(meshes.count)"
    }
    
}
