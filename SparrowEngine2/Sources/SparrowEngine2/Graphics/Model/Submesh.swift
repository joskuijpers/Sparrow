//
//  Submesh.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 A submesh uses the vertex buffer from a mesh with its own index buffer. It has a single material.
 */
public struct Submesh {
    /// Name of the submesh for debugging
    public let name: String
    
    /// Submesh bounds. Used for culling.
    public let bounds: Bounds
    
    /// Material of the mesh. Passed to the shader as uniform.
    public var material: Material {
        didSet {
            onMaterialChanged()
        }
    }
    
    /// Info on the index buffer
    struct IndexBufferInfo {
        /// Index in the buffer list of the mesh
        let bufferIndex: Int
        
        /// Byte-offset into the buffer
        let offset: Int
        
        /// Num indices in this buffer.
        let numIndices: Int
        
        /// Format of an index
        let indexType: MTLIndexType
    }
    
    /// Info on the index buffer
    let indexBufferInfo: IndexBufferInfo
    
    /// Vertex descriptor from the mesh
    private let vertexDescriptor: MTLVertexDescriptor
    
    private var shaderMaterialData: ShaderMaterialData!
    private var pipelineState: MTLRenderPipelineState!
    
    /// Pipeline state for the depth prepass. Not available for translucent materials.
    private var depthPipelineState: MTLRenderPipelineState?

    /// Initialize a new submesh. This is called from Meshloader only.
    init(name: String, bounds: Bounds, material: Material, vertexDescriptor: MTLVertexDescriptor, indexBufferInfo: IndexBufferInfo) {
        self.name = name
        self.bounds = bounds
        self.material = material
        self.vertexDescriptor = vertexDescriptor
        self.indexBufferInfo = indexBufferInfo
        
        // DidSet is not called on initialization
        onMaterialChanged()
    }
}

// MARK: - GPU state
private extension Submesh {

    /// Called when the material changed, either on init or during runtime.
    private mutating func onMaterialChanged() {
        shaderMaterialData = material.buildShaderData()
        
        do {
            let gfx = World.shared!.graphics!
            try rebuildPipelineState(device: gfx.device, library: gfx.library)
        } catch {
            fatalError("Unable to regenerate pipeline state for new material \(material.name) in submesh \(name): \(error.localizedDescription)")
        }
    }
    
    /// Rebuild the pipeline state. Used when render properties change or when the mesh material changes.
    private mutating func rebuildPipelineState(device: MTLDevice, library: MTLLibrary) throws {
        let functionConstants = buildFunctionConstants()
        
        depthPipelineState = try buildDepthPipelineState(device: device, library: library, functionConstants: functionConstants)
        pipelineState = try buildPipelineState(device: device, library: library, functionConstants: functionConstants)
    }
    
    /// Function constants are used for function specialization
    private func buildFunctionConstants() -> MTLFunctionConstantValues {
        let functionConstants = MTLFunctionConstantValues()
        
        var property = material.albedoTexture != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 0)
        
        property = material.normalTexture != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 1)
        
        property = material.roughnessMetalnessOcclusionTexture != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 2)
        
        property = material.emissionTexture != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 3)
        
        return functionConstants
    }
    
    private func buildDepthPipelineState(device: MTLDevice, library: MTLLibrary, functionConstants: MTLFunctionConstantValues) throws -> MTLRenderPipelineState? {
        var vertexFunction: MTLFunction?
        var fragmentFunction: MTLFunction?
        
        // Note: for translucency we can't run the depth pre-pass so we ignore them here.
        if material.renderMode == .translucent {
            return nil
        } else if material.renderMode == .cutOut {
            vertexFunction = library.makeFunction(name: "vertex_main_depth_alphatest")
            fragmentFunction = try library.makeFunction(name: "fragment_main_depth_alphatest", constantValues: functionConstants)
        } else {
            vertexFunction = library.makeFunction(name: "vertex_main_depth")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.sampleCount = 1//Renderer.depthSampleCount

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    private func buildPipelineState(device: MTLDevice, library: MTLLibrary, functionConstants: MTLFunctionConstantValues) throws -> MTLRenderPipelineState {
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = try library.makeFunction(name: "fragment_main", constantValues: functionConstants)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.sampleCount = 1//Renderer.sampleCount

        // This might be useful for some dynamic data injection
//        var reflection: MTLRenderPipelineReflection?
//        let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor, options: .bufferTypeInfo, reflection: &reflection)
//        print(reflection as Any)
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

// MARK: - Rendering
extension Submesh {
    /// Ask the mesh to add to the render set if within frustum.
    func addToRenderSet(set: RenderSet, viewPosition: float3, worldTransform: float4x4, frustum: Frustum, mesh: Mesh, submeshIndex: Int) {
        let bounds = self.bounds * worldTransform
        if frustum.intersects(bounds: bounds) == .outside {
            // Submesh is not in frustum
            return
        }
        
        // Calculate approximate depth, used for render sorting
        let depth: Float = distance(viewPosition, bounds.center)
        
        set.add(material.renderMode) { item in
            item.depth = depth
            item.mesh = mesh
            item.submeshIndex = UInt16(submeshIndex)
            item.worldTransform = worldTransform
        }
    }
    
    /// Render the submesh. Mesh-wide state is already set.
    func render(renderEncoder: MTLRenderCommandEncoder, renderPass: RenderPass, buffers: [MTLBuffer]) {
        let useDepthOnly = (renderPass == .depthPrePass || renderPass == .shadows) && depthPipelineState != nil
        if useDepthOnly {
            renderEncoder.setRenderPipelineState(depthPipelineState!)
        } else {
            renderEncoder.setRenderPipelineState(pipelineState)
        }
        
        // Set textures
        if useDepthOnly && material.renderMode == .cutOut {
            renderEncoder.setFragmentTexture(material.albedoTexture, index: Int(TextureAlbedo.rawValue))
        }

        if !useDepthOnly {
            renderEncoder.setFragmentTexture(material.albedoTexture, index: Int(TextureAlbedo.rawValue))
            renderEncoder.setFragmentTexture(material.normalTexture, index: Int(TextureNormal.rawValue))
            renderEncoder.setFragmentTexture(material.roughnessMetalnessOcclusionTexture, index: Int(TextureRoughnessMetalnessOcclusion.rawValue))
            renderEncoder.setFragmentTexture(material.emissionTexture, index: Int(TextureEmissive.rawValue))
        }
        
        if material.doubleSided {
            renderEncoder.setCullMode(.none)
        } else {
            renderEncoder.setCullMode(.back)
        }

        // Update material constants
        var materialData = shaderMaterialData
        renderEncoder.setFragmentBytes(&materialData,
                                       length: MemoryLayout<ShaderMaterialData>.size,
                                       index: Int(BufferIndexMaterials.rawValue))

        // Render primitives
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indexBufferInfo.numIndices,
                                            indexType: indexBufferInfo.indexType,
                                            indexBuffer: buffers[indexBufferInfo.bufferIndex],
                                            indexBufferOffset: indexBufferInfo.offset)
    }
    
}
