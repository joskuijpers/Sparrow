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
        
        scene.add(node: DirectionalLight(color: float3(2, 2, 2), direction: float3(0, -5, 10)))
        
        let pl = PointLight(color: float3(0, 0, 1), intensity: 10)
        pl.position = [4, 0, 0]
        scene.add(node: pl, parent: rotNode)
        
        
//        let helmetE = scene.createGameObject()
//        let mesh = MeshComp(name: "helmet.obj")
//        // mesh options
//        helmetE.addComponent(mesh)
//
//        let transform = Transform()
//        transform.position = [10, 0, 0]
//        helmetE.addComponent(transform)
        
        let entity = Renderer.nexus.createEntity()
        let meshComp = MeshComponent()
        entity.addComponent(meshComp)
        meshComp.meshName = "hello world"
        
        entity.add(behavior: HelloWorldComponent())
        entity.addComponent(TransformComponent())
        
//        entity.addComponent(BehaviorComponent())
        
        rootEntity = entity
        
        
        let child = Renderer.nexus.createEntity()
        let meshComp2 = MeshComponent()
        child.addComponent(meshComp2)
        meshComp2.meshName = "foobar"
        
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
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        scene.updateUniforms()
        
        fillRenderQueues()

        // Replace with render queue
        var lights = [LightData]()
        for light in scene.lights {
            lights.append(light.build())
        }
        var lightCount = lights.count
        
        
        renderEncoder.setFragmentBytes(&lightCount, length: MemoryLayout<Int>.stride, index: 15)
        renderEncoder.setFragmentBytes(&lights, length: MemoryLayout<LightData>.stride * lightCount, index: 16)
        
        
        renderEncoder.setFragmentBytes(&scene.fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        renderEncoder.setFragmentTexture(irradianceCubeMap, index: Int(TextureIrradiance.rawValue))
        
        // Testing
        rotNode.rotation += float3(0, Float(30).degreesToRadians * Float(deltaTime), 0)
        
        for renderable in scene.renderables {
            renderEncoder.pushDebugGroup(renderable.name)
            
            renderable.render(renderEncoder: renderEncoder, pass: RenderPass.gbuffer, vertexUniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
            
            renderEncoder.popDebugGroup()
        }
        
        behaviorSystem.update(deltaTime: deltaTime)
        renderSystem.render()
        
        
//        for object in scene.objects {
//            if let mesh = object.component(ofType: MeshComp.self) {
//                renderEncoder.pushDebugGroup(object.name)
//
//                mesh.render(renderEncoder: renderEncoder, pass: RenderPass.gbuffer, vertexUniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms)
//                
//                renderEncoder.popDebugGroup()
//            }
//        }
        
//        for node in scene.nodes {
//            node.drawBoundingBox(renderEncoder: renderEncoder, vertexUniforms: scene.uniforms)
//        }
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}


class MeshComponent: Component {
    var meshName: String = ""
    
    
}

class BehaviorComponent: Component {
    var behaviors = [Behavior]()
    
    func update(deltaTime: TimeInterval) {
        for behavior in behaviors {
            behavior.onUpdate(deltaTime: deltaTime)
        }
    }
    
    func add(behavior: Behavior) {
        behavior.entityId = entityId
        behavior.nexus = nexus
        behaviors.append(behavior)
    }
}

class Behavior {
    internal var entityId: EntityIdentifier!
    internal var nexus: Nexus!
    
    func onStart() {}
    func onUpdate(deltaTime: TimeInterval) {}
    
    var transform: TransformComponent {
        nexus.get(component: TransformComponent.identifier, for: entityId) as! TransformComponent
    }
    
    /// The entity of this component.
    var entity: Entity {
        return nexus.get(entity: entityId)!
    }
    
    /// Get a sibling component.
    public func get<C>() -> C? where C: Component {
        return nexus.get(for: entityId)
    }

    /// Get a sibling component.
    public func get<A>(component compType: A.Type = A.self) -> A? where A: Component {
        return nexus.get(for: entityId)
    }
}

class HelloWorldComponent: Behavior {
    override func onStart() {
        print("START HELLO WORLD")
    }
    
    override func onUpdate(deltaTime: TimeInterval) {
        print("UPDATE \(deltaTime)")
        
        if let transform = get(component: TransformComponent.self) {
            print("SET ROT \(entity)")
            transform.rotation += float3(0, Float(30).degreesToRadians * Float(deltaTime), 0)
        }
        
        print(transform.rotation)
    }
}

class TransformComponent: Component {
    var rotation: float3 = .zero
}

extension Component {
    /// Utility for getting the object transform, if available
    var transform: TransformComponent? {
        guard let id = entityId else { return nil }
        return nexus?.get(component: TransformComponent.identifier, for: id) as? TransformComponent
    }
}

extension Entity {
    /// Utility for getting the object transform, if available
    var transform: TransformComponent? {
        return nexus.get(component: TransformComponent.identifier, for: identifier) as? TransformComponent
    }
    
    func add(behavior: Behavior) {
        var comp: BehaviorComponent? = getComponent()
        if comp == nil {
            comp = BehaviorComponent()
            addComponent(comp!)
        }
        
        comp?.add(behavior: behavior)
    }
}




class RenderSystem {
    let nexus: Nexus
    let family: Family<Requires1<MeshComponent>>
    
    init(nexus: Nexus) {
        self.nexus = nexus
        
        family = nexus.family(requires: MeshComponent.self)
    }
    
    func render() {
        family.forEach { (mesh: MeshComponent) in
//            print("RENDER MESH", mesh, mesh.meshName)
        }
    }
    
}

class BehaviorSystem {
    let nexus: Nexus
    let family: Family<Requires1<BehaviorComponent>>
    
    init(nexus: Nexus) {
        self.nexus = nexus

        family = nexus.family(requires: BehaviorComponent.self)
    }
    
    func update(deltaTime: TimeInterval) {
        family.forEach { (behavior: BehaviorComponent) in
            behavior.update(deltaTime: deltaTime)
        }
    }
}
