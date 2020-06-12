//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 09/06/2020.
//

import MetalKit

/// Metal backed renderer.
///
/// Creates pipelines, render textures, and everything else needed to render an empty frame.
///
public final class MetalRenderer {
    /// Graphics context
    private let context: GraphicsContext
    
    /// View we're drawing into
    private let view: SparrowMetalView
    
    /// View delegate to get draw events
    private var delegate: MetalRendererDelegate?
    
    private let commandQueue: MTLCommandQueue!
    
    enum Error: Swift.Error {
        /// Could not create a command queue
        case commandQueueUnavailable
    }
    
    public init(for view: SparrowMetalView) throws {
        context = try GraphicsContext()

        guard let commandQueue = context.device.makeCommandQueue() else {
            throw Error.commandQueueUnavailable
        }
        self.commandQueue = commandQueue
        
        self.view = view
    }
    
    
    private var depthStencilStateWriteLess: MTLDepthStencilState!
    private var depthStencilStateReadLessEqual: MTLDepthStencilState!
    private var depthPassDescriptor: MTLRenderPassDescriptor!
    private var depthTexture: MTLTexture!
    
    private var lightingRenderTarget: MTLTexture!
    private var resolvePipelineState: MTLRenderPipelineState!
    private var resolvePassDescriptor: MTLRenderPassDescriptor!
    
    private var cameraRenderSet = RenderSet()
    private var uniforms = Uniforms()
    
    
    /// Load the renderer for given world.
    ///
    /// The graphics context of this renderer will be assigned to the world.
    public func load(world: World) throws {
        world.graphics = context
        
        delegate = MetalRendererDelegate(renderer: self, world: world)
        view.delegate = delegate
        view.device = context.device
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 1
        view.clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        // Create the state by calling the state functions
        let device = context.device
        
        do {
            let descriptor = MTLDepthStencilDescriptor()
            
            descriptor.depthCompareFunction = .less
            descriptor.isDepthWriteEnabled = true
            
            depthStencilStateWriteLess = device.makeDepthStencilState(descriptor: descriptor)!
            
            descriptor.depthCompareFunction = .lessEqual
            descriptor.isDepthWriteEnabled = false
            
            depthStencilStateReadLessEqual = device.makeDepthStencilState(descriptor: descriptor)!
        }
        
        buildDepthPassDescriptor()
        
//        buildLightCullComputeState(device: device)
//        buildLightingPassDescriptor(device: device)
//        buildViewRenderPassDescriptor(device: device)
//        buildResolvePassPipelineState(device: device)
//
//        buildDepthStencilStateWrite(device: device)
//        buildDepthStencilStateRead(device: device)
        
        buildResolveRenderPassDescriptor()
        try buildResolvePipelineState(device: device, library: context.library)
        
        // Update render target textures
        viewSizeChanged(to: view.frame.size)
    }
    
    private func buildDepthPassDescriptor() {
        let descriptor = MTLRenderPassDescriptor()
        
        descriptor.depthAttachment.clearDepth = 1.0
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        descriptor.depthAttachment.slice = 0
        
        self.depthPassDescriptor = descriptor
    }
    
    private func buildResolveRenderPassDescriptor() {
        let descriptor = MTLRenderPassDescriptor()
        
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
        
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
        descriptor.depthAttachment.clearDepth = 1.0
        
        descriptor.stencilAttachment.loadAction = .clear
        descriptor.stencilAttachment.storeAction = .dontCare
        descriptor.stencilAttachment.clearStencil = 0
        
        descriptor.colorAttachments[0].storeAction = .store
        
        self.resolvePassDescriptor = descriptor
    }
    
    private func buildResolvePipelineState(device: MTLDevice, library: MTLLibrary) throws {
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.label = "ResolvePipelineState"
        descriptor.sampleCount = 1
        descriptor.vertexFunction = library.makeFunction(name: "FSQuadVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "resolveShader")
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat

        self.resolvePipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    }
}

// MARK: - Adjusting the rendering process

extension MetalRenderer {
    
    // set/get debug options
        // albedo/normals/metal/rough/ao
        // wireframe
    
    
    func viewSizeChanged(to size: CGSize) {
        let device = context.device
        
        updateRenderTargets(device: device)
        updateScreenSpaceProperties(device: device)
    }
}

// MARK: - Creating GPU state

extension MetalRenderer {
    // Building state
    
    
    /// Update render targets.
    func updateRenderTargets(device: MTLDevice) {
        let width = Int(view.frame.size.width)
        let height = Int(view.frame.size.height)
        
        do {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
            
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = [.renderTarget, .shaderRead]
            textureDescriptor.sampleCount = 1
            
            depthTexture = device.makeTexture(descriptor: textureDescriptor)!
            depthTexture.label = "SceneDepth"
            
            // Updates passes that use the texture
            depthPassDescriptor.depthAttachment.texture = depthTexture
//            lightingPassDescriptor.depthAttachment.texture = depthTexture
        }
        
        do {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float,
                                                                             width: width,
                                                                             height: height,
                                                                             mipmapped: false)
            
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = [.renderTarget, .shaderRead]
            textureDescriptor.sampleCount = 1
            
            lightingRenderTarget = device.makeTexture(descriptor: textureDescriptor)
            lightingRenderTarget.label = "SceneHDRLighting"
            
//            lightingPassDescriptor.colorAttachments[0].texture = lightingRenderTarget
        }
        
    }
    
    /// Update the properties that rely on screen size, such as compute settings and buffers.
    func updateScreenSpaceProperties(device: MTLDevice) {
        print("Update SSPs")
    }
}

// MARK: - Rendering a frame
extension MetalRenderer {

    /// Render a single frame using given world.
    fileprivate func renderFrame(world: World) {
        let time = world.time
        
        print("renderFrame \(time.frameIndex)")
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        // Fill the render sets for this frame
        fillRenderSets(world: world)
        
        // Do passes
        doDepthPrepass(commandBuffer: commandBuffer)
        
        // lightCulling
        // lightingOpaque
        // lightingTranslucent
        // resolve
        
        doResolvePass(commandBuffer: commandBuffer)
        
        
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// Run the depth prepass render pass.
    ///
    /// Sets up a render encoder and renders the opaque scene into it.
    private func doDepthPrepass(commandBuffer: MTLCommandBuffer) {
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: depthPassDescriptor) else {
            fatalError("Unable to create render encoder for depth prepass")
        }
        
        renderEncoder.label = "Depth"

        renderEncoder.setDepthStencilState(depthStencilStateWriteLess)
        renderEncoder.setFrontFacing(.clockwise)

        renderScene(on: renderEncoder, renderPass: .depthPrePass)

        renderEncoder.endEncoding()
    }
    
    /// Resolve the final image by working on the generated textures. Output to the screen.
    private func doResolvePass(commandBuffer: MTLCommandBuffer) {
        guard let drawable = view.currentDrawable else {
            return
        }
        
        resolvePassDescriptor.colorAttachments[0].texture = drawable.texture
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: resolvePassDescriptor) else {
            fatalError("Unable to create render encoder for resolve pass")
        }
        
        renderEncoder.label = "Resolve"
        
        renderEncoder.setRenderPipelineState(resolvePipelineState)
        renderEncoder.setFragmentTexture(lightingRenderTarget, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        renderEncoder.endEncoding()
    }
    
    /// Get the scene camera
    private func getCamera(world: World) -> Camera {
        guard let cameraEntity = world.camera else {
            fatalError("No camera set for the viewport")
        }

        return world.nexus.get(unsafeComponentFor: cameraEntity.identifier)
    }
    
    /// Fill the render sets with items to render this frame.
    // TODO: Ideally, we would go over _all_ meshes once, and add them to any set needed. We can then split
    //  this full mesh list in N for parallel processing. Need to make RenderSet threadsafe for that. We always
    //  only need to add an item to a renderset once. But a renderset could be for shadows or for a camera.
    //  for shadows we thus need a mapping: [ShadowInfo], [RenderSet], where ShadowInfo is position and frustum
    //  We also need some way to support rendering of non Meshes I think, like 3D Text.
    private func fillRenderSets(world: World) {
        let camera = getCamera(world: world)
        let frustum = camera.frustum!
        
        cameraRenderSet.clear()
        
        world.fillRenderSet(frustum: frustum, renderSet: cameraRenderSet, viewPosition: camera.uniforms.cameraWorldPosition)
    }
    
    private func renderScene(on encoder: MTLRenderCommandEncoder, renderPass: RenderPass) {
        // TODO: wtf? And what when we want to render for shadow?
        let camera = getCamera(world: World.shared!)
        var cameraUniforms = camera.uniforms
        
        encoder.setVertexBytes(&cameraUniforms,
                               length: MemoryLayout<CameraUniforms>.stride,
                               index: Int(BufferIndexCameraUniforms.rawValue))
        encoder.setFragmentBytes(&cameraUniforms,
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
            item.mesh.render(renderEncoder: encoder, renderPass: renderPass, uniforms: uniforms, submeshIndex: item.submeshIndex, worldTransform: item.worldTransform)
        }
    }
}

// MARK: - View delegate (getting events)

/// Delegate class.
///
/// A separate class because it has to subclass NSObject which causes a costly ObjC bridge.
/// Any screen size changes are forwarded to the renderer. A game tick is instead forwarded
/// to the game first, then is rendered after.
private final class MetalRendererDelegate: NSObject, MTKViewDelegate {
    private unowned let renderer: MetalRenderer
    private unowned let world: World
    
    var lastFrameTime: CFAbsoluteTime!
    
    /// Creates a new renderer delegate
    init(renderer: MetalRenderer, world: World) {
        self.renderer = renderer
        self.world = world
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.viewSizeChanged(to: size)
    }
    
    func draw(in view: MTKView) {
        // Calculate the frame duration for normalizing animations and gameplay.
        if lastFrameTime == nil {
            lastFrameTime = CFAbsoluteTimeGetCurrent() - 1.0 / Double(view.preferredFramesPerSecond)
        }
        let currentTime = CFAbsoluteTimeGetCurrent()

        let deltaTime = Float(currentTime - lastFrameTime)
        lastFrameTime = currentTime
        
        world.tick(deltaTime: deltaTime)
        
        renderer.renderFrame(world: world)
    }
}

// MARK: - Graphics context (library and device store)

/// Graphics context for Metal.
public final class GraphicsContext {
    /**/ public let device: MTLDevice
    /**/ public let library: MTLLibrary
    
    enum Error: Swift.Error {
        /// Could not create a Metal device
        case noDevice
        
        /// Could not load the default library
        case invalidLibrary
    }
    
    init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw Error.noDevice
        }
        
        guard let library = device.makeDefaultLibrary() else {
            throw Error.invalidLibrary
        }
        
        self.device = device
        self.library = library
    }

    /// Make a new texture given the descriptor
    func make(texture descriptor: MTLTextureDescriptor) -> MTLTexture? {
        return device.makeTexture(descriptor: descriptor)
    }
}
