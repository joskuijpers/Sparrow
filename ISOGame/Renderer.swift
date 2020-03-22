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
    case lighting
    case postfx
}

class Renderer: NSObject {
    static var device: MTLDevice!
    static var library: MTLLibrary?
    static var colorPixelFormat: MTLPixelFormat!
    static var textureLoader: TextureLoader!
    static var sampleCount = 1 // MSAA
    static var depthSampleCount = 1 // MSAA
    
    let commandQueue: MTLCommandQueue!

    
    
    
    
    
    var scene: Scene
    
    let irradianceCubeMap: MTLTexture;
    
    fileprivate static var nexus: Nexus!
    
    let behaviorSystem: BehaviorSystem
    var rootEntity: Entity!

    var lastFrameTime: CFAbsoluteTime!
    
    
    
    
    
    let lights: Group<Requires1<Light>>
    let meshes: Group<Requires2<MeshSelector, MeshRenderer>>
    var uniforms: Uniforms
    
    let renderSet = RenderSet()
    
    let depthPassDescriptor: MTLRenderPassDescriptor
    let lightCullComputeState: MTLComputePipelineState
    
    let depthStencilStateWrite: MTLDepthStencilState
    let depthStencilStateNoWrite: MTLDepthStencilState
    
    /// Depth map (private) with scene depth
    var depthMap: MTLTexture!
    var lightsBuffer: MTLBuffer!
    /// List of lights per threadgroup
    var culledLightsBuffer: MTLBuffer!
    
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
        Renderer.colorPixelFormat = metalView.colorPixelFormat
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
        
        // Create stencil states
        depthStencilStateWrite = Renderer.buildWriteDepthStencilState(device: device)
        depthStencilStateNoWrite = Renderer.buildNoWriteDepthStencilState(device: device)
        
        
        irradianceCubeMap = Renderer.buildEnvironmentTexture(device: device, "garage_pmrem.ktx")

        
        
        
        
        
        /// SCENE AS LONG AS SCENE MANAGER DOES NOT EXIST
        
        Renderer.nexus = Nexus() // MOVE

        // Populate from nexus
        lights = Nexus.shared().group(requires: Light.self)
        meshes = Nexus.shared().group(requiresAll: MeshSelector.self, MeshRenderer.self)
        
        behaviorSystem = BehaviorSystem() // MOVE
        
        scene = Scene(screenSize: metalView.bounds.size)
        
        
        /// RENDER UNIFORMS
        uniforms = Uniforms()
        
        
        super.init()
        
        // Must be done after self...
        metalView.delegate = self
    
        // Create textures
        resize(size: metalView.bounds.size)
        
        
        // DEBUG: create a scene
        buildScene()
    }
    
    // For testing
    private func buildScene() {
        let camera = Nexus.shared().createEntity()
        let t = camera.add(component: Transform())
        t.position = [0, 5, 0]
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
        
        let l = 250
        for i in 0...l {
            let light = Nexus.shared().createEntity()
            let transform = light.add(component: Transform())
            transform.position = [Float(i / 5) * 3, 2, Float(i % 5) * 3]
            
            let lightInfo = light.add(component: Light(type: .point))
            lightInfo.color = float3(min(0.01 * Float(l), 1), Float(0.1), 1 - min(0.01 * Float(l), 1))
            lightInfo.intensity = 1
        }
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
        
        descriptor.depthCompareFunction = .less
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
        
        // TODO
//        passDescriptor.colorAttachments
//        passDescriptor.depthAttachment
//        passDescriptor.
        
        return passDescriptor
    }
    
    func resize(size: CGSize) {
        let depthMapDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                          width: Int(size.width),
                                                                          height: Int(size.height),
                                                                          mipmapped: false)
        
        if Renderer.depthSampleCount > 1 {
            depthMapDescriptor.textureType = .type2DMultisample
        }
        depthMapDescriptor.storageMode = .private
        depthMapDescriptor.usage = [.renderTarget, .shaderRead]
        depthMapDescriptor.sampleCount = Renderer.depthSampleCount
        
        depthMap = Renderer.device.makeTexture(descriptor: depthMapDescriptor)
        depthMap?.label = "depthMap"
        
        // Update map
        depthPassDescriptor.depthAttachment.texture = depthMap

        // Update the buffer
        threadgroupCount.width  = (depthMap.width  + threadgroupSize.width -  1) / threadgroupSize.width;
        threadgroupCount.height = (depthMap.height + threadgroupSize.height - 1) / threadgroupSize.height;
        threadgroupCount.depth = 1

        // Space for every group, list of 256 lights
        let bufferSize = threadgroupCount.width * threadgroupCount.height * Int(MAX_LIGHTS_PER_TILE) * MemoryLayout<UInt16>.stride
        culledLightsBuffer = Renderer.device.makeBuffer(length: bufferSize, options: .storageModePrivate)
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
    
    /// Light culling pass: get all the lights we can possibly see, and cull them per tile.
    func doLightCullingPass(commandBuffer: MTLCommandBuffer) {
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Unable to create compute encoder for light culling pass")
        }
        computeEncoder.label = "LightCullingPass"

        // Cull lights to frustum
        var lightsData = [LightData]()
        let frustum = scene.camera!.frustum
        for light in lights {
            if frustum.intersects(bounds: light.bounds) != .outside {
                lightsData.append(light.build())
                DebugRendering.shared.gizmo(position: (float4(light.transform!.position, 1) * light.transform!.worldTransform).xyz)
            }
        }
        var lightCount = UInt(lightsData.count)
        
        // TODO: REUSE!
        lightsBuffer = Renderer.device.makeBuffer(bytes: &lightsData, length: MemoryLayout<LightData>.stride * Int(lightCount), options: .storageModeShared)

//        print("LIGHTS", lightCount)

        computeEncoder.setComputePipelineState(lightCullComputeState)

        // Camera
        computeEncoder.setBytes(&scene.camera!.uniforms,
                                     length: MemoryLayout<CameraUniforms>.stride,
                                     index: 1)
        
        // Input
        computeEncoder.setBuffer(lightsBuffer, offset: 0, index: 2)
        computeEncoder.setBytes(&lightCount, length: MemoryLayout<UInt>.stride, index: 3)
        computeEncoder.setTexture(depthMap, index: 0)
        
        // Output
        computeEncoder.setBuffer(culledLightsBuffer, offset: 0, index: 4)
        
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        
        computeEncoder.endEncoding()
    }
    
    /// Do the lighting pass: render all meshes and use mesh, culled lights and SSAO to create lighting result
    func doLightingPass(commandBuffer: MTLCommandBuffer, view: MTKView) {
        guard let passDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
            fatalError("Unable to create render encoder for lighting pass")
        }
        renderEncoder.label = "LighingPass"
        
        // Do not write to depth: we already have it
        renderEncoder.setDepthStencilState(depthStencilStateNoWrite)
        renderEncoder.setCullMode(.back)
        
        // Light data: all lights, culled light indices, and horizontal tile count for finding the tile per pixel.
        var count = UInt(threadgroupCount.width)
        renderEncoder.setFragmentBytes(&count, length: MemoryLayout<UInt>.stride, index: 15)
        renderEncoder.setFragmentBuffer(lightsBuffer, offset: 0, index: 16)
        renderEncoder.setFragmentBuffer(culledLightsBuffer, offset: 0, index: 17)
//        renderEncoder.setFragmentTexture(ssaoMap, index: 4)
        
        
        
        renderScene(onEncoder: renderEncoder, renderPass: .lighting)
        
        
        
        
        DebugRendering.shared.render(renderEncoder: renderEncoder)
        
        
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
        
        // Update all behavior
        behaviorSystem.update(deltaTime: deltaTime)
        
        
        let camera = scene.camera!
        camera.updateUniforms()

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
        }
        
        doDepthPrepass(commandBuffer: commandBuffer)
        doLightCullingPass(commandBuffer: commandBuffer)
        doLightingPass(commandBuffer: commandBuffer, view: view)
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// Render the scene on given render encoder for given pass.
    /// The pass determines the shaders used
    func renderScene(onEncoder renderEncoder: MTLRenderCommandEncoder, renderPass: RenderPass) {
//        print("render scene \(renderPass)")
        renderSet.clear()
        
        let camera = scene.camera!
        let frustum = camera.frustum
        
        
        for (_, meshRenderer) in meshes {
            meshRenderer.renderQueue(set: renderSet, renderPass: renderPass, frustum: frustum, viewPosition: camera.uniforms.cameraWorldPosition)
        }
        
        renderEncoder.setVertexBytes(&camera.uniforms,
                                     length: MemoryLayout<CameraUniforms>.stride,
                                     index: Int(BufferIndexCameraUniforms.rawValue))
        renderEncoder.setFragmentBytes(&camera.uniforms,
                                       length: MemoryLayout<CameraUniforms>.stride,
                                       index: Int(BufferIndexCameraUniforms.rawValue))
        
        for item in renderSet.opaque {
            item.mesh.render(renderEncoder: renderEncoder, renderPass: renderPass, uniforms: uniforms, submeshIndex: item.submeshIndex, worldTransform: item.worldTransform)
        }
    }
    

    /// Update uniforms
    func updateUniforms() {
//        AAPLCameraUniforms* cullUniforms = (AAPLCameraUniforms*)currentFrame.viewData[0].cullUniformBuffer.contents;
//        *cullUniforms = cullCamera.uniforms;
        
//        let buffer: MTLBuffer
//        var uniforms = buffer.contents() as! Uniforms
//        uniforms.modelMatrix =
        
        // Camera uniforms
        
        // Uniforms
        
        // Lights
        
        
    }
}



//        let scene = SceneManager.activeScene
        
        
        
//        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
//        renderEncoder.setDepthStencilState(depthStencilState)
        
        
        // Build list of visible lights
        // For each visible light with shadow mapping: build render queue
        // For camera: build render queue
        
        // Shaders: defaultShader, defaultDepthShader (for prepass and shadows. vertices position only. If also alphaTesting, add UVs and read albedo in fragment shader)
        
        
        // PASS: Depth prepass ([Parallel]RenderEncoder)
        //  Only do VertexShader, unless AlphaTest: then use fragment shader (function constant)
        //  DepthStencilState: write=true, compare: less
        //  Output: depth only
        // ENDPASS: Depth prepass
        
        // PASS: Shadows (RenderEncoder)
        //  Depth only like depth prepass
        //  DepthStencilState: write=true, compare: less
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
        
        // PASS: Lighting ([Parallel]RenderEncoder)
        //  Supply: ssao, culled lights buffer, lights buffer
        //  DepthStencilState: write=false, compare: lessEqual
        //  Adjust: depth writing off, compare less
        //  Draw: all visible geometry
        //  Output: Rendertexture, float
        // END PASS: Lighting
        
        // PASS: PostFX (ComputeEncoder -> MPS)
        //  Supply: lighting
        //  Do: MPS Test > X => MPS Blur => MPS add to lighting texture
        // END PASS: PostFX
        
        // PASS: ToneMapping (ComputeEncoder)
        //  Input: lighting render texture
        //  Output: ldrTexture
        // END PASS: Tonemapping
        
        // PASS: Debug
        //  Input: ldrTexture
        //  Draw: debug stuff
        //  Output: ldrTexture
        // END PASS: Debug
        
        // PASS: Blit (BlitEncoder)
        //  Input: ldrTexture
        //  Draw to drawable texture
        //  Should this be done in Debug or ToneMapping?
        // END PASS: Blit
        
//        renderEncoder.setDepthStencilState(depthStencilState)
        
        /*
         
    Make RenderPass struct / protocol
         
         DepthPrePass
         SSAOPass
         ShadowPass
         LightingPass
         BloomPass
         ToneMappingPass
         DebugRenderPass
         FinalPass
         
         all have render(commandQueue)
         their init(device) will create pipeline states, buffers, etc.
         we can pass buffers from 1 to the other in their render() ??
         
         examples:
         func SSAO.perform(commandBuffer, depth: MTLBuffer) -> (ssao: MTLBuffer) {}
         func PostFX.perform(commandBuffer, hdrLighting: MTLBuffer) -> (hdrLighting: MTLBuffer) {}
         
         */






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
 
 
 
 // Indices for buffer bindings.
 typedef NS_ENUM(NSInteger, AAPLBufferIndex)
 {
     AAPLBufferIndexUniforms = 0,
     AAPLBufferIndexCameraUniforms,
 #if SUPPORT_RASTERIZATION_RATE
     AAPLBufferIndexRasterizationRateUniforms,
 #endif
     AAPLBufferIndexCommonCount,

     AAPLBufferIndexVertexMeshPositions = AAPLBufferIndexCommonCount,
     AAPLBufferIndexVertexMeshGenerics,
     AAPLBufferIndexVertexMeshNormals,
     AAPLBufferIndexVertexMeshTangents,
     AAPLBufferIndexVertexCount,

     AAPLBufferIndexFragmentMaterial = AAPLBufferIndexCommonCount,
     AAPLBufferIndexFragmentGlobalTextures,
     AAPLBufferIndexFragmentLightParams,
     AAPLBufferIndexFragmentChunkViz,
     AAPLBufferIndexFragmentCount,

     AAPLBufferIndexPointLights = AAPLBufferIndexFragmentCount,
     AAPLBufferIndexSpotLights,
     AAPLBufferIndexLightCount,
     AAPLBufferIndexPointLightIndices,
     AAPLBufferIndexSpotLightIndices,

     AAPLBufferIndexComputeEncodeArguments = AAPLBufferIndexCommonCount,
     AAPLBufferIndexComputeCullCameraUniforms,
     AAPLBufferIndexComputeUniforms,
     AAPLBufferIndexComputeMaterial,
     AAPLBufferIndexComputeChunks,
     AAPLBufferIndexComputeChunkViz,
     AAPLBufferIndexComputeExecutionRange,
     AAPLBufferIndexComputeCount,
     
     AAPLBufferIndexVertexDepthOnlyICBBufferCount            = AAPLBufferIndexVertexMeshPositions+1,
     AAPLBufferIndexVertexDepthOnlyICBAlphaMaskBufferCount   = AAPLBufferIndexVertexMeshGenerics+1,
     AAPLBufferIndexVertexICBBufferCount                     = AAPLBufferIndexVertexCount,
     
     AAPLBufferIndexFragmentICBBufferCount                   = AAPLBufferIndexFragmentCount,
     AAPLBufferIndexFragmentDepthOnlyICBAlphaMaskBufferCount = AAPLBufferIndexFragmentMaterial+1,
 };
 
 
 // Enum to index the members of the AAPLEncodeArguments argument buffer.
 typedef NS_ENUM(NSInteger, AAPLEncodeArgsIndex)
 {
     AAPLEncodeArgsIndexCommandBuffer,
     AAPLEncodeArgsIndexCommandBufferDepthOnly,
     AAPLEncodeArgsIndexIndexBuffer,
     AAPLEncodeArgsIndexVertexBuffer,
     AAPLEncodeArgsIndexVertexNormalBuffer,
     AAPLEncodeArgsIndexVertexTangentBuffer,
     AAPLEncodeArgsIndexUVBuffer,
     AAPLEncodeArgsIndexUniformBuffer,
     AAPLEncodeArgsIndexGlobalTexturesBuffer,
     AAPLEncodeArgsIndexLightParamsBuffer,
 };
 
 // Indices for vertex attributes.
 typedef NS_ENUM(NSInteger, AAPLVertexAttribute)
 {
     AAPLVertexAttributePosition = 0,
     AAPLVertexAttributeNormal   = 1,
     AAPLVertexAttributeTangent  = 2,
     AAPLVertexAttributeTexcoord = 3,
 };
 
 typedef struct AAPLCameraUniforms
 {
     // Standard camera matrices.
     simd::float4x4      viewMatrix;
     simd::float4x4      projectionMatrix;
     simd::float4x4      viewProjectionMatrix;
     
     // Inverse matrices.
     simd::float4x4      invViewMatrix;
     simd::float4x4      invProjectionMatrix;
     simd::float4x4      invViewProjectionMatrix;
     
     simd::float4        worldFrustumPlanes[6]; // Frustum planes in world space.
     
     simd::float4        invProjZ;           // A float4 containing the lower right 2x2 z,w block of inv projection matrix (column Major) ; viewZ = (X * projZ + Z) / (Y * projZ + W)
     simd::float4        invProjZNormalized; // Same as invProjZ but the result is a Z from 0...1 instead of N...F; effectively linearizes Z for easy visualization/storage
 } AAPLCameraUniforms;

 
 
 
 
 typedef struct AAPLUniforms
 {
     // Screen resolution and inverse for texture sampling.
     simd::float2        screenSize;
     simd::float2        invScreenSize;
     
     // Physical resolution and inverse for adjusting between screen and physical space.
     simd::float2        physicalSize;
     simd::float2        invPhysicalSize;
     
     // Lighting environment
//     float               exposure;
     
     simd::float3        globalNoiseOffset;
     
     // Frame counter and time for varying values over frames and time.
     uint                frameCounter;
     float               frameTime;
} AAPLUniforms;
 
 
 Renderer.updateUniforms
 
 
 drawInMTKView: ++framecounter
 frameTime = deltaT
 
 
 */
