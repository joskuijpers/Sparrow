//
//  Renderer.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit
import SparrowECS
import SparrowEngine2

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
    static var meshLoader: MeshLoader!
    static var sampleCount = 1 // MSAA
    static var depthSampleCount = 1 // MSAA
    
    let commandQueue: MTLCommandQueue!

    
    
    
    
    
    var scene: Scene
    
    let irradianceCubeMap: MTLTexture;
    
    fileprivate static var nexus: Nexus!
    
    let rotatingBallSystem: RotatingBallSystem
    let cameraUpdateSystem: CameraUpdateSystem
    let playerCameraSystem: PlayerCameraSystem
    let meshRenderSystem: MeshRenderSystem
    let lightSystem: LightSystem
    
    
    
    var rootEntity: Entity!

    var lastFrameTime: CFAbsoluteTime!
    
    
    
    
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
    
    
    init(metalView: MTKView, device: MTLDevice, world: World, context: Context) {
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal GPU not available")
        }
        
        Renderer.device = device
        Renderer.library = device.makeDefaultLibrary()
        Renderer.textureLoader = TextureLoader(device: device)
        Renderer.meshLoader = MeshLoader(device: device, textureLoader: Renderer.textureLoader)
        
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
        
        Renderer.nexus = world.n

        rotatingBallSystem = RotatingBallSystem(world: world, context: context)
        cameraUpdateSystem = CameraUpdateSystem(world: world, context: context)
        playerCameraSystem = PlayerCameraSystem(world: world, context: context)
        meshRenderSystem = MeshRenderSystem(nexus: Nexus.shared())
        lightSystem = LightSystem(nexus: Nexus.shared(), device: device)
        
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
        let tlight = skyLight.add(component: Transform())
        tlight.rotation = simd_quatf(angle: Float(70).degreesToRadians, axis: [1, 0, 0])
        let light = skyLight.add(component: Light(type: .directional))
        light.color = float3(1, 1, 1)
        
        
        let sponza = Nexus.shared().createEntity()
        sponza.add(component: Transform())
        
//        let sponzaMesh = try! Renderer.meshLoader.load(name: "Sponza/sponza.spa")
        let sponzaMesh = try! Renderer.meshLoader.load(name: "ironSphere/ironSphere.spm")
        sponza.add(component: RenderMesh(mesh: sponzaMesh))
        sponza.add(component: RotationSpeed(seed: 1))
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
            let textureURL = AssetLoader.url(forAsset: name)
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
        renderEncoder.setFrontFacing(.clockwise)
        
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
        // START BUILTIN PRE-LOOP
        
        // Calculate the frame duration for normalizing animations and gameplay.
        if lastFrameTime == nil {
            lastFrameTime = CFAbsoluteTimeGetCurrent() - 1.0 / Double(view.preferredFramesPerSecond)
        }
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = Float(currentTime - lastFrameTime!)
        lastFrameTime = currentTime
        
        // END BUILTIN PRE-LOOP
        
        // START UPDATE
        
        playerCameraSystem.update(deltaTime: deltaTime)
        rotatingBallSystem.update(deltaTime: deltaTime)
        cameraUpdateSystem.updateCameras()
        lightsBuffer = lightSystem.updateLightBuffer(buffer: lightsBuffer, lightsCount: &lightsBufferCount)

        // END UPDATE
        
        // START RENDER
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
        
        // END RENDER
        
        // START BUILTIN POST-LOOP
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        // END BUILTIN POST-LOOP
    }
  
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


class MeshRenderSystem {
    let meshes: Group<Requires2<Transform, RenderMesh>>
    
    init(nexus: Nexus) {
        meshes =  nexus.group(requiresAll: Transform.self, RenderMesh.self)
    }
    
    /**
     Build the render queue by filling it with the appropriate meshes
     */
    func buildQueue(set: RenderSet, renderPass: RenderPass, frustum: Frustum, viewPosition: float3) {
        for (transform, renderer) in meshes {
            guard let mesh = renderer.mesh else {
                continue
            }
            
            if renderPass == .shadows && !renderer.castShadows {
                continue
            }
            
            mesh.addToRenderSet(set: set,
                                viewPosition: viewPosition,
                                worldTransform: transform.localToWorldMatrix,
                                frustum: frustum)
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
