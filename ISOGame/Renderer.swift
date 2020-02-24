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
    
    var scene: Scene
    var rotNode: Node!
    
    let irradianceCubeMap: MTLTexture;
    
    static var nexus: Nexus!
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
        
        let camera = ArcballCamera()
        camera.distance = 4.3
        camera.target = [0, 1.2, 0]
        camera.rotation.x = Float(-10).degreesToRadians
        scene.add(node: camera)
        scene.currentCameraIndex = 1
        
        Renderer.nexus = Nexus()
        renderSystem = RenderSystem(nexus: Renderer.nexus)
        behaviorSystem = BehaviorSystem(nexus: Renderer.nexus)
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        metalView.delegate = self
        
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        
//        rotNode = Node()
//        rotNode.position = [5, 0, 0]
//        scene.add(node: rotNode)
//
//        for i in 0...4 {
//            let sphere = Model(name: "ironSphere.obj")
//            sphere.position = [Float(3 * i), 0, 0]
//            scene.add(node: sphere, parent: rotNode)
//        }
//
//        for i in 0...4 {
//            let sphere = Model(name: "goldSphere.obj")
//            sphere.position = [Float(3 * i), 3, 0]
//            scene.add(node: sphere, parent: rotNode)
//        }
//
//        for i in 0...4 {
//            let sphere = Model(name: "plasticSphere.obj")
//            sphere.position = [Float(3 * i), -3, 0]
//            scene.add(node: sphere, parent: rotNode)
//        }
//
//        for i in 0...4 {
//            let sphere = Model(name: "grassSphere.obj")
//            sphere.position = [Float(3 * i), 6, 0]
//            scene.add(node: sphere)
//        }
        
        let cube = Mesh(name: "cube.obj")
//        cube.position = [0, 0, 0]
//        scene.add(node: cube)
        
        let helmet = Mesh(name: "helmet.obj")
//        helmet.position = [-3, 0, 0]
//        helmet.rotation = [0, Float(180).degreesToRadians, 0]
//        scene.add(node: helmet)
        
        
        let lightObject = Renderer.nexus.createEntity()
        lightObject.add(component: TransformComponent())
        lightObject.add(component: LightComponent(type: .directional))
        lightObject.get(component: LightComponent.self)?.direction = float3(0, -5, 10)
        lightObject.get(component: LightComponent.self)?.color = float3(2, 2, 2)
        
        // maybe better api, but needs required init() or something.
//        skyLight.add(component: TransformComponent.self)
//        let light = skyLight.add(component: Light.self)
//        light.color = float3(1, 1, 0)
        
        let entity = Renderer.nexus.createEntity()
        entity.add(component: TransformComponent())
        entity.transform?.position = float3(0, 0, 0)
        entity.add(component: MeshSelector(mesh: helmet))
        entity.add(component: MeshRenderer())
        
        entity.add(behavior: HelloWorldComponent())
        
        rootEntity = entity
        
        
        
        let child = Renderer.nexus.createEntity()
        child.add(component: TransformComponent())
        child.transform?.position = float3(0, 0, 3)
        child.add(component: MeshSelector(mesh: cube))
        child.add(component: MeshRenderer())
//        child.add(behavior: HelloWorldComponent())
        
        Renderer.nexus.addChild(child, to: entity)
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
    override func onStart() {
        print("START HELLO WORLD")
    }
    
    override func onUpdate(deltaTime: TimeInterval) {
//        print("UPDATE \(deltaTime)")
        
        transform.rotation = transform.rotation + float3(0, Float(30).degreesToRadians * Float(deltaTime), 0)
    }
}

class RenderSystem {
    let nexus: Nexus
    let lights: Family<Requires1<LightComponent>>
    let meshes: Family<Requires2<MeshSelector, MeshRenderer>>
    
    init(nexus: Nexus) {
        self.nexus = nexus
        
        lights = nexus.family(requires: LightComponent.self)
        meshes = nexus.family(requiresAll: MeshSelector.self, MeshRenderer.self)
    }
    
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
    }
    
}
