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

enum RenderPass {
    case depthPrePass
    case ssao
    case shadows
    case opaqueLighting
    case transparentLighting
    case postfx
}

class Renderer: NSObject {
    static var device: MTLDevice!
    static var library: MTLLibrary?
    static var textureLoader: TextureLoader!
    static var sampleCount = 1 // MSAA
    static var depthSampleCount = 1 // MSAA
    
    let commandQueue: MTLCommandQueue!

    
    
    
    
    
    var scene: Scene
    
    let irradianceCubeMap: MTLTexture;
    
    fileprivate static var nexus: Nexus!
    
    let rotatingBallSystem: RotatingBallSystem
    let cameraSystem: CameraSystem
    let meshRenderSystem: MeshRenderSystem
    let lightSystem: LightSystem
    
    
    
    var rootEntity: Entity!

    var lastFrameTime: CFAbsoluteTime!
    
    
    
    
    
    let lights: Group<Requires1<Light>>
    let meshes: Group<Requires2<MeshSelector, MeshRenderer>>
    var uniforms: Uniforms
    
    let cameraRenderSet = RenderSet()
    
    let depthPassDescriptor: MTLRenderPassDescriptor
    let lightCullComputeState: MTLComputePipelineState
    let lightingPassDescriptor: MTLRenderPassDescriptor
    let viewRenderPassDescriptor: MTLRenderPassDescriptor
    let finalPipelineState: MTLRenderPipelineState
    
    let depthStencilStateWrite: MTLDepthStencilState
    let depthStencilStateNoWrite: MTLDepthStencilState
    
    /// Depth map (private) with scene depth
    var depthTexture: MTLTexture!
    /// HDR Lighting target
    var lightingRenderTarget: MTLTexture!
    var lightsBuffer: MTLBuffer!
    var lightsBufferCount: UInt = 0
    /// List of lights per threadgroup
    var culledLightsBufferOpaque: MTLBuffer!
    var culledLightsBufferTransparent: MTLBuffer!
    
    /// Size of thread groups for compute kernels
    var threadgroupSize = MTLSizeMake(Int(LIGHT_CULLING_TILE_SIZE), Int(LIGHT_CULLING_TILE_SIZE), 1)
    
    /// Number of thread groups for compute kernels
    var threadgroupCount = MTLSize()
    
    
    init(metalView: MTKView, device: MTLDevice) {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal GPU not available")
        }
        
        Renderer.device = device
        Renderer.library = device.makeDefaultLibrary()
        Renderer.textureLoader = TextureLoader()
        
        // Configure view
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.sampleCount = Renderer.sampleCount
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        self.commandQueue = commandQueue
        
        /// RENDER STATE
    
        // Create pass descriptors
        depthPassDescriptor = Renderer.buildDepthPassDescriptor()
        
        lightCullComputeState = Renderer.buildLightCullComputeState(device: device)
        
        lightingPassDescriptor = Renderer.buildLightingPassDescriptor()
        
        viewRenderPassDescriptor = Renderer.buildViewRenderPassDescriptor()
        finalPipelineState = Renderer.buildFinalPipelineState(colorPixelFormat: metalView.colorPixelFormat)
        
        // Create stencil states
        depthStencilStateWrite = Renderer.buildWriteDepthStencilState(device: device)
        depthStencilStateNoWrite = Renderer.buildNoWriteDepthStencilState(device: device)
        
        
        irradianceCubeMap = Renderer.buildEnvironmentTexture(device: device, "garage_pmrem.ktx")

        
        
        
        
        
        /// SCENE AS LONG AS SCENE MANAGER DOES NOT EXIST
        
        Renderer.nexus = Nexus() // MOVE

        // Populate from nexus
        lights = Nexus.shared().group(requires: Light.self)
        meshes = Nexus.shared().group(requiresAll: MeshSelector.self, MeshRenderer.self)
        
        rotatingBallSystem = RotatingBallSystem(nexus: Nexus.shared())
        cameraSystem = CameraSystem(nexus: Nexus.shared())
        meshRenderSystem = MeshRenderSystem(nexus: Nexus.shared())
        lightSystem = LightSystem(nexus: Nexus.shared())
        
        scene = Scene(screenSize: metalView.drawableSize)
        
        
        /// RENDER UNIFORMS
        uniforms = Uniforms()
        
        
        super.init()
        
        // Must be done after self...
        metalView.delegate = self
    
        // Create textures
        resize(size: metalView.drawableSize)
        
        
        // DEBUG: create a scene
        buildScene()
    }
    
    // For testing
    private func buildScene() {
        let camera = Nexus.shared().createEntity()
        let t = camera.add(component: Transform())
        t.localPosition = [-12.5, 1.4, -0.5]
        t.eulerAngles = [0, Float(90.0).degreesToRadians, 0]
        let cameraComp = camera.add(component: Camera())
        scene.camera = cameraComp
        
        
        let skyLight = Nexus.shared().createEntity()
        skyLight.add(component: Transform())
        let light = skyLight.add(component: Light(type: .directional))
        light.direction = float3(0, -5, 10)
        light.color = float3(1, 1, 1)
        
        
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
        
        let sponza = Nexus.shared().createEntity()
        let sponzat = sponza.add(component: Transform())
        sponzat.localScale = [0.01, 0.01, 0.01]
        sponza.add(component: MeshSelector(mesh: try! Mesh(name: "ironSphere.spa")))
        sponza.add(component: MeshRenderer())
        
        
//        let boxGroup = Nexus.shared().createEntity()
//        let boxTransform = boxGroup.add(component: Transform())
//        boxGroup.add(component: RotationSpeed(seed: 100))
//
//        let sphereMesh = Mesh(name: "ironSphere.obj")
//        let sphereMesh2 = Mesh(name: "grassSphere.obj")
////        let c = 1000
//        let c = 10
//        let q = Int(sqrtf(Float(c)))
//        for i in 0...c {
//            let sphere = Nexus.shared().createEntity()
//            let transform = sphere.add(component: Transform())
//            transform.position = [Float(i / q - q/2) * 3, 0, Float(i % q - q/2) * 3]
//
//            if i % 2 == 0 {
//                sphere.add(component: MeshSelector(mesh: sphereMesh))
//            } else {
//                sphere.add(component: MeshSelector(mesh: sphereMesh2))
//            }
//            sphere.add(component: MeshRenderer())
////            sphere.add(component: RotationSpeed(seed: i))
//
//
//            if i > 510 && i < 520 {
//                transform.setParent(boxTransform)
//
//                transform.position = [Float(i / q - q/2) * 3, 2, Float(i % q - q/2) * 3]
//            }
//        }


//        for x in -5...5 {
//            for z in -5...5 {
//                for y in 0...1 {
//                    let light = Nexus.shared().createEntity()
//                    let transform = light.add(component: Transform())
//
//                    transform.position = [Float(x) * 2, Float(y) * 3 - 1.5, Float(z) * 2]
//
//                    let lightInfo = light.add(component: Light(type: .point))
//                    lightInfo.color = float3(min(0.01 * Float(x), 1), Float(0.1), 1 - min(0.01 * Float(z), 1))
//                    lightInfo.intensity = 1
//                }
//            }
//        }
    }
    
}

// MARK: - State building

fileprivate extension Renderer {
    /// Create a simple depth stencil state that writes to the depth buffer
    static func buildWriteDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        
        return device.makeDepthStencilState(descriptor: descriptor)!
    }
    
    /// Build a depth state that does not weite to the depth buffer anymore and is just used for comparing.
    static func buildNoWriteDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
        let descriptor = MTLDepthStencilDescriptor()
        
        descriptor.depthCompareFunction = .lessEqual // might want to use equal for opaque and lessEqual for translucent
        descriptor.isDepthWriteEnabled = false
        
        return device.makeDepthStencilState(descriptor: descriptor)!
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
    
    /// Build the pass descriptor for the depth prepass
    static func buildDepthPassDescriptor() -> MTLRenderPassDescriptor {
        let passDescriptor = MTLRenderPassDescriptor()
        
        passDescriptor.depthAttachment.clearDepth = 1.0
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .store
        passDescriptor.depthAttachment.slice = 0

        return passDescriptor
    }
    
    static func buildLightCullComputeState(device: MTLDevice) -> MTLComputePipelineState {
        guard let function = Renderer.library!.makeFunction(name: "lightculling") else {
            fatalError("Light culling kernel does not exist")
        }
        
        return try! device.makeComputePipelineState(function: function)
    }
    
    /// Build the pass descriptor for the lighting pass.
    static func buildLightingPassDescriptor() -> MTLRenderPassDescriptor {
        let passDescriptor = MTLRenderPassDescriptor()
        
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store
        
        passDescriptor.depthAttachment.loadAction = .load
        passDescriptor.depthAttachment.storeAction = .store
        passDescriptor.depthAttachment.slice = 0
        
        return passDescriptor
    }
    
    /// Build a pass to render to the drawable
    static func buildViewRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let passDescriptor = MTLRenderPassDescriptor()
        
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
//        passDescriptor.colorAttachments[1].loadAction = .clear
//        passDescriptor.colorAttachments[1].storeAction = .dontCare
        
        passDescriptor.depthAttachment.loadAction = .clear
        passDescriptor.depthAttachment.storeAction = .dontCare
        passDescriptor.depthAttachment.clearDepth = 1.0
        
        passDescriptor.stencilAttachment.loadAction = .clear
        passDescriptor.stencilAttachment.storeAction = .dontCare
        passDescriptor.stencilAttachment.clearStencil = 0
        
        if Renderer.sampleCount > 1 {
            passDescriptor.colorAttachments[0].storeAction = .multisampleResolve
        } else {
            passDescriptor.colorAttachments[0].storeAction = .store
        }
        
        return passDescriptor
    }
    
    static func buildFinalPipelineState(colorPixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.label = "FinalPipelineState"
        descriptor.sampleCount = 1
        descriptor.vertexFunction = Renderer.library!.makeFunction(name: "FSQuadVertexShader")
        descriptor.fragmentFunction = Renderer.library!.makeFunction(name: "resolveShader")
        descriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        
        return try! Renderer.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func resize(size: CGSize) {
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                          width: Int(size.width),
                                                                          height: Int(size.height),
                                                                          mipmapped: false)
        
        if Renderer.depthSampleCount > 1 {
            depthTextureDescriptor.textureType = .type2DMultisample
        }
        depthTextureDescriptor.storageMode = .private
        depthTextureDescriptor.usage = [.renderTarget, .shaderRead]
        depthTextureDescriptor.sampleCount = Renderer.depthSampleCount
        
        depthTexture = Renderer.device.makeTexture(descriptor: depthTextureDescriptor)
        depthTexture?.label = "DepthTexture"
        
        let hdrLightingDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                             width: Int(size.width),
                                                                             height: Int(size.height),
                                                                             mipmapped: false)
        if Renderer.sampleCount > 1 {
            depthTextureDescriptor.textureType = .type2DMultisample
        }
        hdrLightingDescriptor.storageMode = .private
        hdrLightingDescriptor.usage = [.renderTarget, .shaderRead]
        hdrLightingDescriptor.sampleCount = Renderer.sampleCount
        
        lightingRenderTarget = Renderer.device.makeTexture(descriptor: hdrLightingDescriptor)
        lightingRenderTarget?.label = "HDRLighting"
        
        // Update passes
        depthPassDescriptor.depthAttachment.texture = depthTexture
        lightingPassDescriptor.depthAttachment.texture = depthTexture
        lightingPassDescriptor.colorAttachments[0].texture = lightingRenderTarget

        // Update the buffer
        threadgroupCount.width  = (depthTexture.width  + threadgroupSize.width -  1) / threadgroupSize.width;
        threadgroupCount.height = (depthTexture.height + threadgroupSize.height - 1) / threadgroupSize.height;
        threadgroupCount.depth = 1

        // Space for every group, list of 256 lights
        let bufferSize = threadgroupCount.width * threadgroupCount.height * Int(MAX_LIGHTS_PER_TILE) * MemoryLayout<UInt16>.stride
        culledLightsBufferOpaque = Renderer.device.makeBuffer(length: bufferSize, options: .storageModePrivate)
        culledLightsBufferOpaque.label = "opaqueLightIndices"
        culledLightsBufferTransparent = Renderer.device.makeBuffer(length: bufferSize, options: .storageModePrivate)
        culledLightsBufferTransparent.label = "transparentLightIndices"
    }
}

// MARK: - Render passes
extension Renderer {
    /// Do a prepass my rending all meshes for depth only.
    func doDepthPrepass(commandBuffer: MTLCommandBuffer) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthPassDescriptor) else {
            fatalError("Unable to create render encoder for depth prepass")
        }
        renderEncoder.label = "DepthPrepass"
        
        renderEncoder.setDepthStencilState(depthStencilStateWrite)
        renderEncoder.setCullMode(.back)
        
        renderScene(onEncoder: renderEncoder, renderPass: .depthPrePass)
        
        renderEncoder.endEncoding()
    }
    
    /**
     Light culling pass
     
     Using a list of lights and the scene depth, divide the screen into tiles and determine which
     tiles have which lights.
     */
    func doLightCullingPass(commandBuffer: MTLCommandBuffer) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Unable to create compute encoder for light culling pass")
        }
        computeEncoder.label = "LightCulling"

        computeEncoder.setComputePipelineState(lightCullComputeState)
        
        computeEncoder.setBytes(&scene.camera!.uniforms,
                                length: MemoryLayout<CameraUniforms>.stride,
                                index: 1)
        
        computeEncoder.setBuffer(lightsBuffer, offset: 0, index: 2)
        computeEncoder.setBytes(&lightsBufferCount, length: MemoryLayout<UInt>.stride, index: 3)
        computeEncoder.setTexture(depthTexture, index: 0)
        
        computeEncoder.setBuffer(culledLightsBufferOpaque, offset: 0, index: 4)
        computeEncoder.setBuffer(culledLightsBufferTransparent, offset: 0, index: 5)
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        
        computeEncoder.endEncoding()
    }

    /**
     Lighting pass
     
     Render all meshes with textures. Opaque first, then transparent.
     */
    func doLightingPass(commandBuffer: MTLCommandBuffer) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: lightingPassDescriptor) else {
            fatalError("Unable to create render encoder for lighting pass")
        }
        renderEncoder.label = "Lighting"
        
        // Do not write to depth: we already have it
        renderEncoder.setDepthStencilState(depthStencilStateNoWrite)
        renderEncoder.setCullMode(.back)
        renderEncoder.setFrontFacing(.clockwise)
        
        // Light data: all lights, culled light indices, and horizontal tile count for finding the tile per pixel.
        var count = UInt(threadgroupCount.width)
        renderEncoder.setFragmentBytes(&count, length: MemoryLayout<UInt>.stride, index: 15)
        renderEncoder.setFragmentBuffer(lightsBuffer, offset: 0, index: 16)

//        renderEncoder.setFragmentTexture(ssaoTexture, index: 4)

        renderEncoder.setFragmentBuffer(culledLightsBufferOpaque, offset: 0, index: 17)
        renderScene(onEncoder: renderEncoder, renderPass: .opaqueLighting)

        renderEncoder.setFragmentBuffer(culledLightsBufferTransparent, offset: 0, index: 17)
        renderScene(onEncoder: renderEncoder, renderPass: .transparentLighting)
        
        DebugRendering.shared.render(renderEncoder: renderEncoder)
        
        renderEncoder.endEncoding()
    }
    
    func doResolvePass(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let drawable = view.currentDrawable else {
            fatalError("Unable to get drawable")
        }
        
        viewRenderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: viewRenderPassDescriptor) else {
            fatalError("Unable to create render encoder for resolve pass")
        }
        renderEncoder.label = "Resolve"
        
        renderEncoder.setRenderPipelineState(finalPipelineState)
        renderEncoder.setFragmentTexture(lightingRenderTarget, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        renderEncoder.endEncoding()
    }
    
    // renderShadows using shadowRenderPass   [encoder setDepthBias:0.0f slopeScale:2.0f clamp:0];, draw scene
}

// MARK: - Render loop

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        scene.screenSizeWillChange(to: size)
        resize(size: size)
    }
    
    func draw(in view: MTKView) {
        // Calculate the frame duration for normalizing animations and gameplay.
        if lastFrameTime == nil {
            lastFrameTime = CFAbsoluteTimeGetCurrent() - 1.0 / Double(view.preferredFramesPerSecond)
        }
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = Float(currentTime - lastFrameTime!)
        lastFrameTime = currentTime
        
        
        cameraSystem.onUpdate(deltaTime: deltaTime)
        rotatingBallSystem.onUpdate(deltaTime: deltaTime)
        cameraSystem.updateCameras()
        lightsBuffer = lightSystem.updateLightBuffer(buffer: lightsBuffer, lightsCount: &lightsBufferCount)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
        }
        
        // Fill render sets
        fillRenderSets()
        
        // Render into depth first, used for culling and AO
        doDepthPrepass(commandBuffer: commandBuffer)

        // Cull the lights
        doLightCullingPass(commandBuffer: commandBuffer)
        
        // Perform lighting with culled lights
        doLightingPass(commandBuffer: commandBuffer)
        
        // Resolve HDR buffer with tone mapping and gamma correction and draw to screen
        doResolvePass(commandBuffer: commandBuffer, view: view)
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /**
     1: only once do a render queue filling
     2: look into the light list building
     */
    
    /// Fill the render sets with meshes.
    func fillRenderSets() {
        cameraRenderSet.clear()
        
        let camera = scene.camera!
        let frustum = camera.frustum!
        
        meshRenderSystem.buildQueue(set: cameraRenderSet, renderPass: .opaqueLighting, frustum: frustum, viewPosition: camera.uniforms.cameraWorldPosition)
    }
    
    /**
     Render the scene on given render encoder for given pass.
     
     - Parameter renderPass: Pass determines the render queue to use.
    */
    func renderScene(onEncoder renderEncoder: MTLRenderCommandEncoder, renderPass: RenderPass) {
        var cameraUniforms = scene.camera!.uniforms
        renderEncoder.setVertexBytes(&cameraUniforms,
                                     length: MemoryLayout<CameraUniforms>.stride,
                                     index: Int(BufferIndexCameraUniforms.rawValue))
        renderEncoder.setFragmentBytes(&cameraUniforms,
                                       length: MemoryLayout<CameraUniforms>.stride,
                                       index: Int(BufferIndexCameraUniforms.rawValue))
        
        var renderQueue: RenderQueue!
        switch renderPass {
        case .opaqueLighting, .depthPrePass:
            renderQueue = cameraRenderSet.opaque
        case .transparentLighting:
            renderQueue = cameraRenderSet.translucent
        default:
            fatalError("Cannot render scene for render pass \(renderPass)")
        }
        
        for item in renderQueue.allItems() {
            item.mesh.render(renderEncoder: renderEncoder, renderPass: renderPass, uniforms: uniforms, submeshIndex: item.submeshIndex, worldTransform: item.worldTransform)
        }
    }
}

class RotationSpeed: Component {
    let speed: Float
    
    init(seed: Int = 0) {
        speed = (Float(seed) * 35972.326365396643).truncatingRemainder(dividingBy: 180)
    }
}

/// Behavior test
class RotatingBallSystem {
    let entities: Group<Requires2<Transform, RotationSpeed>>
    
    init(nexus: Nexus) {
        entities =  nexus.group(requiresAll: Transform.self, RotationSpeed.self)
    }
    
    func onUpdate(deltaTime: Float) {
        for (transform, rotationSpeed) in entities {
            let q = simd_quatf(angle: rotationSpeed.speed.degreesToRadians * deltaTime * 0.5, axis: [0, 1, 0])
            transform.localRotation = transform.localRotation * q
        }
    }
}

// Simple camera behavior
class CameraSystem {
    let cameras: Group<Requires2<Transform, Camera>>
    
    init(nexus: Nexus) {
        cameras =  nexus.group(requiresAll: Transform.self, Camera.self)
    }
    
    func onUpdate(deltaTime: Float) {
        for (transform, _) in cameras {
            var diff = float3.zero
            let speed: Float = 10.0
            let rotSpeed: Float = 70.0

            if Input.shared.getKey(.w) {
                diff = diff + transform.forward * deltaTime * speed
            } else if Input.shared.getKey(.s) {
                diff = diff - transform.forward * deltaTime * speed
            }
            
            if Input.shared.getKey(.a) {
                diff = diff - transform.right * deltaTime * speed
            } else if Input.shared.getKey(.d) {
                diff = diff + transform.right * deltaTime * speed
            }
            
            if Input.shared.getKey(.q) {
                diff = diff + float3(0, 1, 0) * deltaTime * speed
            } else if Input.shared.getKey(.e) {
                diff = diff - float3(0, 1, 0) * deltaTime * speed
            }
            
            transform.translate(diff)
            
            var rot: Float = 0
            if Input.shared.getKey(.leftArrow) {
                rot = rot + deltaTime * -rotSpeed.degreesToRadians
            }
            if Input.shared.getKey(.rightArrow) {
                rot = rot + deltaTime * rotSpeed.degreesToRadians
            }
            
            var rotX: Float = 0
            if Input.shared.getKey(.upArrow) {
                rotX = rotX + deltaTime * -rotSpeed.degreesToRadians
            }
            if Input.shared.getKey(.downArrow) {
                rotX = rotX + deltaTime * rotSpeed.degreesToRadians
            }

            let qy = simd_quatf(angle: rot, axis: [0, 1, 0])
            let qx = simd_quatf(angle: rotX, axis: [1, 0, 0])
            
            transform.localRotation = qy * transform.localRotation * qx
        }
    }
    
    /// Update camera with new data
    func updateCameras() {
        for (transform, camera) in cameras {
            // View matrix changes whenever position or orientation of the camera changes
//            let translateMatrix = float4x4(translation: transform.position)
//            let rotateMatrix = float4x4(transform.quaternion)
            
            // TODO if has parent, take parent WorldMatrix and multiply
//            let newViewMatrix = rotateMatrix * translateMatrix
            let newViewMatrix = transform.worldToLocalMatrix
            
            if newViewMatrix != camera.viewMatrix {
                camera.viewMatrix = newViewMatrix
                camera.uniformsDirty = true
            }

            if camera.uniformsDirty {
                camera.frustum = Frustum(viewProjectionMatrix: camera.projectionMatrix * camera.viewMatrix)
                
                updateCameraUniforms(camera: camera, transform: transform, uniforms: &camera.uniforms)
                
                camera.uniformsDirty = false
            }
        }
    }
    
    /// Update uniform structure with camera data
    func updateCameraUniforms(camera: Camera, transform: Transform, uniforms: inout CameraUniforms) {
        uniforms.viewMatrix = camera.viewMatrix
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.cameraWorldPosition = transform.position
        
        // Derived
        uniforms.viewProjectionMatrix = uniforms.projectionMatrix * uniforms.viewMatrix
        
        uniforms.invProjectionMatrix = simd_inverse(uniforms.projectionMatrix)
        uniforms.invViewProjectionMatrix = simd_inverse(uniforms.viewProjectionMatrix)
        uniforms.invViewMatrix = simd_inverse(uniforms.viewMatrix)
        
        uniforms.physicalSize = [Float(camera.screenSize.width), Float(camera.screenSize.height)]
        
        // Inverse column
        uniforms.invProjectionZ = [ uniforms.invProjectionMatrix.columns.2.z, uniforms.invProjectionMatrix.columns.2.w,
                                    uniforms.invProjectionMatrix.columns.3.z, uniforms.invProjectionMatrix.columns.3.w ]
        
        let bias = -camera.near
        let invScale = camera.far - camera.near
        uniforms.invProjectionZNormalized = [uniforms.invProjectionZ.x + (uniforms.invProjectionZ.y * bias),
                                             uniforms.invProjectionZ.y * invScale,
                                             uniforms.invProjectionZ.z + (uniforms.invProjectionZ.w * bias),
                                             uniforms.invProjectionZ.w * invScale]
        
    }

}

class LightSystem {
    let lights: Group<Requires2<Transform, Light>>
    
    init(nexus: Nexus) {
        lights =  nexus.group(requiresAll: Transform.self, Light.self)
    }
    
    func updateLightBuffer(buffer: MTLBuffer!, lightsCount: inout UInt) -> MTLBuffer? {
        var buffer = buffer
        
        lightsCount = UInt(lights.count)
        
        // Reallocate if needed
        // TODO: proper sizing with spare-size (blocks), and down sizing. Maybe some ManagedMTLBuffer class?
        let bufferSizeRequired = lights.count * MemoryLayout<LightData>.stride
        if buffer == nil || buffer!.allocatedSize < bufferSizeRequired {
            buffer = Renderer.device.makeBuffer(length: bufferSizeRequired, options: .storageModeShared)
        }

        for (index, (transform, light)) in lights.enumerated() {
            let ptr = buffer!.contents().advanced(by: index * MemoryLayout<LightData>.stride)
            let lightPtr = ptr.assumingMemoryBound(to: LightData.self)

            switch (light.type) {
            case .directional:
                lightPtr.pointee.type = LightTypeDirectional
                lightPtr.pointee.color = light.color
                lightPtr.pointee.position = light.direction // TODO: replace direction with transform rotation
                lightPtr.pointee.range = Float.infinity
            case .point:
                lightPtr.pointee.type = LightTypePoint
                lightPtr.pointee.color = light.color
                lightPtr.pointee.position = transform.position
                lightPtr.pointee.range = 5
            }
        }
        
        return buffer
    }
}

class MeshRenderSystem {
    let meshes: Group<Requires3<Transform, MeshSelector, MeshRenderer>>
    
    init(nexus: Nexus) {
        meshes =  nexus.group(requiresAll: Transform.self, MeshSelector.self, MeshRenderer.self)
    }
    
    /**
     Build the render queue by filling it with the appropriate meshes
     */
    func buildQueue(set: RenderSet, renderPass: RenderPass, frustum: Frustum, viewPosition: float3) {
        for (transform, selector, renderer) in meshes {
            guard let mesh = selector.mesh else {
                continue
            }
            
            if renderPass == .shadows && !renderer.castShadows {
                continue
            }
            
            let wt = transform.localToWorldMatrix
            let bounds = mesh.bounds * wt
            
            if frustum.intersects(bounds: bounds) == .outside {
                continue
            }
            
            // if mesh.bounds inside frustum
            mesh.addToRenderSet(set: set, viewPosition: viewPosition, worldTransform: wt)
        }
    }
}


/*
 
 MESH RENDERING
 
 FunctionConstants gTransparent, gUseAlphaMask
 
 // Default vertex type.
 struct AAPLVertex
 {
     float3 position     [[attribute(AAPLVertexAttributePosition)]];
     xhalf3 normal       [[attribute(AAPLVertexAttributeNormal)]];
     xhalf3 tangent      [[attribute(AAPLVertexAttributeTangent)]];
     float2 texCoord     [[attribute(AAPLVertexAttributeTexcoord)]];
 };

 // Output from the main rendering vertex shader.
 struct AAPLVertexOutput
 {
     float4 position [[position]];
     float4 frozenPosition;
     xhalf3 viewDir;
     xhalf3 normal;
     xhalf3 tangent;
     float2 texCoord;
     float3 wsPosition;
 };
 
 struct AAPLDepthOnlyVertex
 {
     float3 position [[attribute(AAPLVertexAttributePosition)]];
 };

 // Depth only vertex output type.
 struct AAPLDepthOnlyVertexOutput
 {
     float4 position [[position]];
 };
 
 
 
 // Depth only vertex type with texcoord for alpha mask.
 struct AAPLDepthOnlyAlphaMaskVertex
 {
     float3 position [[attribute(AAPLVertexAttributePosition)]];
     float2 texCoord [[attribute(AAPLVertexAttributeTexcoord)]];
 };

 // Depth only vertex output type with texcoord for alpha mask.
 struct AAPLDepthOnlyAlphaMaskVertexOutput
 {
     float4 position [[position]];
     float2 texCoord;
 };
 
 
 
 // Converts a depth from the depth buffer into a view space depth.
 inline float linearizeDepth(constant AAPLCameraUniforms & cameraUniforms, float depth)
 {
     return dot(float2(depth,1), cameraUniforms.invProjZ.xz) / dot(float2(depth,1), cameraUniforms.invProjZ.yw);
 }
 
 
 getPixelSurfaceData(vertexOut, material) -> SurfaceData
 
 
 
 vertex shader: depth only(in, cameraUniforms) -> viewProj matrix on position
 
 
 fragment shader: depth only -> none
 
 vertex shader: depthonly + alpha(in, cameraUniforms) -> viewproj matrix on position, tex
 fragment shader: depthonly + alpga -> cutout -> sample albedo,, compare alpha to cutout for the material, discard
 
 
 SurfaceData {
 normal, albedo, f0, occlusion, emissive, metalness, roughness, alpha
 }
 
 
 Uniforms
    time
 CameraUniforms
 
 GlobalTextures
    depth2d_array<float>    shadowMap           [[ id(AAPLGlobalTextureIndexShadowMap) ]];
    texturecube<xhalf>      envMap              [[ id(AAPLGlobalTextureIndexEnvMap) ]];
    texture2d<float, access::read>  blueNoise   [[ id(AAPLGlobalTextureIndexBlueNoise) ]];
    texture3d<float, access::read>  perlinNoise [[ id(AAPLGlobalTextureIndexPerlinNoise) ]];
    texture2d<xhalf, access::read> ssao
 
 
 */
