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

    var lastFrameTime: CFAbsoluteTime!
    
    init(metalView: MTKView, device: MTLDevice) {
        guard
            let commandQueue = device.makeCommandQueue() else {
                fatalError("Metal GPU not available")
        }
        
        Renderer.device = device
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        Renderer.textureLoader = TextureLoader()
        
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
//        metalView.sampleCount = 4
        
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
    
        /*

         Scenario a) Single Command Buffer with Parallel Encoders
         1) Divide up the objects into groups e.g. 4 groups.
         2) Create MTLParallelRenderCommandEncoder and build renderCommandEncoder from it for each group.
         3) Create a encoding worker (NSOperation) for each group
         4) Create a NSOperationQueue (concurrent) and enqueue workers
         5) Wait for queue to complete, close all encoders and a commit
         This works beautifully, fps jumps 2-3x

         */
        
        
        buildScene()
    }
    
    // For testing
    func buildScene() {
        let camera = Nexus.shared().createEntity()
        camera.add(component: Transform())
        let cameraComp = camera.add(component: Camera())
        camera.add(behavior: DebugCameraBehavior())
        scene.camera = cameraComp
        
        
        let skyLight = Nexus.shared().createEntity()
        skyLight.add(component: Transform())
        let light = skyLight.add(component: Light(type: .directional))
        light.direction = float3(0, -5, 10)
        light.color = float3(0, 0, 0)
        
        
//        let helmet = Nexus.shared().createEntity()
//        let transform = helmet.add(component: Transform())
//        transform.position = float3(0, 0, 0)
//
//        helmet.add(component: MeshSelector(mesh: Mesh(name: "helmet.obj")))
//        helmet.add(component: MeshRenderer())
//        helmet.add(behavior: HelloWorldComponent())
//
//
//        let cube = Nexus.shared().createEntity()
//        cube.add(component: Transform())
//        cube.transform?.position = float3(0, 0, 3)
//        cube.add(component: MeshSelector(mesh: Mesh(name: "cube.obj")))
//        cube.add(component: MeshRenderer())
//        // cube.add(behavior: HelloWorldComponent())
//        Nexus.shared().addChild(cube, to: helmet)
        
        
        
        let sphereMesh = Mesh(name: "ironSphere.obj")
        let sphereMesh2 = Mesh(name: "grassSphere.obj")
        let c = 1000
        let q = Int(sqrtf(Float(c)))
        for i in 0...c {
            let sphere = Nexus.shared().createEntity()
            let transform = sphere.add(component: Transform())
            transform.position = [Float(i / q - q/2) * 3, 0, Float(i % q - q/2) * 3]
            
            if i % 2 == 0 {
                sphere.add(component: MeshSelector(mesh: sphereMesh))
            } else {
                sphere.add(component: MeshSelector(mesh: sphereMesh2))
            }
            sphere.add(component: MeshRenderer())
            sphere.add(behavior: HelloWorldComponent(seed: i))
        }
        
        let l = 80
        for i in 0...l {
            let light = Nexus.shared().createEntity()
            let transform = light.add(component: Transform())
            transform.position = [Float(i / 5) * 3, 2, Float(i % 5) * 3]
            
            let lightInfo = light.add(component: Light(type: .point))
            lightInfo.color = float3(min(0.01 * Float(l), 1), Float(0.1), 1 - min(0.01 * Float(l), 1))
            lightInfo.intensity = 1
        }
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
        // Calculate the frame duration for normalizing animations and gameplay.
        if lastFrameTime == nil {
            lastFrameTime = CFAbsoluteTimeGetCurrent() - 1.0 / Double(view.preferredFramesPerSecond)
        }
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = Float(currentTime - lastFrameTime!)
        lastFrameTime = currentTime
        
        guard let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
        }
        
        behaviorSystem.update(deltaTime: deltaTime)
        
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderSystem.render(renderEncoder: renderEncoder, irradianceCubeMap: irradianceCubeMap, scene: scene, dt: deltaTime)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

/**
 Render system. Renders lights and meshes.
 */
class RenderSystem {
    let lights = Nexus.shared().group(requires: Light.self)
    let meshes = Nexus.shared().group(requiresAll: MeshSelector.self, MeshRenderer.self)
    
    let renderSet = RenderSet()
    
    func render(renderEncoder: MTLRenderCommandEncoder, irradianceCubeMap: MTLTexture, scene: Scene, dt: Float) {
//        let scene = SceneManager.activeScene
        
        scene.updateUniforms()
        
        // Build list of visible lights
        // For each visible light with shadow mapping: build render queue
        // For camera: build render queue
        
        
        // PASS: Depth prepass
        //  Only do VertexShader, unless AlphaTest: then use fragment shader (function constant)
        //  Output: depth only
        // ENDPASS: Depth prepass
        
        // PASS: Shadows (RenderEncoder)
        //  Depth only like depth prepass
        //  Output: texture(s)
        // END PASS: Shadows
        
        // PASS: SSAO (ComputeEncoder)
        //  Supply: depth
        //  Output: texture
        // END PASS: SSAO
        
        // PASS: Light culling (ComputeEncoder)
        //  Supply: depth buffer, lights buffer (in), culled lights buffer (out)
        //  Output: buffer
        // END PASS: Light Culling
        
        // PASS: Lighting (RenderEncoder)
        //  Supply: ssao, culled lights buffer, lights buffer
        //  Adjust: depth writing off, compare less
        //  Draw: all visible geometry
        //  Output: Rendertexture, float
        // END PASS: Lighting
        
        // PASS: Bloom (ComputeEncoder)
        //  Supply: lighting
        //  Do: MPS Test > X => MPS Blur => MPS add to lighting texture
        // END PASS: Bloom
        
        // PASS: ToneMapping
        //  Input: lighting render texture
        //  Output: drawable
        // END PASS: Tonemapping
        
        // PASS: Debug
        //  Draw: debug stuff
        // END PASS: Debug
        
//        renderEncoder.setDepthStencilState(depthStencilState)
        
        
        
        renderSet.clear()
        let frustum = scene.camera!.frustum
        
        
        // START BUILD LIGHTS
        // todo: limit with Bounds... culling...
        var lightsData = [LightData]()
        for light in lights {
            if frustum.intersects(bounds: light.bounds) != .outside {
                lightsData.append(light.build())
                DebugRendering.shared.gizmo(position: (float4(light.transform!.position, 1) * light.transform!.worldTransform).xyz)
            }
        }
        var lightCount = lightsData.count
        
        
        
        renderEncoder.setFragmentBytes(&lightCount, length: MemoryLayout<Int>.stride, index: 15)
        renderEncoder.setFragmentBytes(&lightsData, length: MemoryLayout<LightData>.stride * lightCount, index: 16)
        
        
        // END BUILD LIGHTS
        
        
        // Build a small render queue by adding all items to it
        // TODO: sorting
        for (_, meshRenderer) in meshes {
            
            // TODO:
            // we need to add to any shadow queue and current camera queue
            
            meshRenderer.renderQueue(set: renderSet, frustum: frustum, viewPosition: scene.fragmentUniforms.cameraPosition)
        }
        
        renderEncoder.setCullMode(.back)
//        renderEncoder.setTriangleFillMode(.lines) // Wireframe debugging
        
        // Update fragment uniforms if possible here
        renderEncoder.setFragmentBytes(&scene.fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        // Set irradiance texture
        renderEncoder.setFragmentTexture(irradianceCubeMap, index: Int(TextureIrradiance.rawValue))

        for item in renderSet.opaque {
//            renderEncoder.pushDebugGroup(meshSelector.mesh!.name)

            item.mesh.render(renderEncoder: renderEncoder, vertexUniforms: scene.uniforms, fragmentUniforms: scene.fragmentUniforms, submeshIndex: item.submeshIndex, worldTransform: item.worldTransform)

//            renderEncoder.popDebugGroup()
        }
        
        // Render all debug things.
        DebugRendering.shared.render(renderEncoder: renderEncoder, vertexUniforms: scene.uniforms)

        // Easy testing
        NSApplication.shared.mainWindow?.title = String(format: "Drawn meshes: %i, lights: %i", renderSet.opaque.count, lightCount)
    }
    
}





/// Behavior test
class HelloWorldComponent: Behavior {
    let rotationSpeed: Float
    
    init(seed: Int = 0) {
        rotationSpeed = (Float(seed) * 35972.326365396643).truncatingRemainder(dividingBy: 180)
    }
    override func onUpdate(deltaTime: Float) {
        if let rotation = transform?.rotation {
            transform!.rotation = rotation + float3(0, rotationSpeed.degreesToRadians * deltaTime, 0)
        }
    }
}
