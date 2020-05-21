//
//  Submesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit
import SparrowAsset

/**
 A submesh uses the vertex buffer from a mesh with its own index buffer. It has a single material.
 */
class Submesh {
    /// Name of the submesh for debugging
    let name: String
    
    /// Submesh bounds. Used for culling.
    let bounds: Bounds
    
    /// Material of the mesh. Passed to the shader as uniform.
    var material: Material {
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
    
    
    /*private*/ var shaderMaterialData: ShaderMaterialData!
    /*private*/ var pipelineState: MTLRenderPipelineState!
    
    /// Pipeline state for the depth prepass. Not available for translucent materials.
    /*private*/ var depthPipelineState: MTLRenderPipelineState?
    

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


private extension Submesh {

    /// Called when the material changed, either on init or during runtime.
    private func onMaterialChanged() {
        shaderMaterialData = material.buildShaderData()
        
        do {
            try rebuildPipelineState()
        } catch {
            fatalError("Unable to regenerate pipeline state for new material \(material.name) in submesh \(name): \(error.localizedDescription)")
        }
    }
    
    /// Rebuild the pipeline state. Used when render properties change or when the mesh material changes.
    private func rebuildPipelineState() throws {
        let library = Renderer.library!
        let device = Renderer.device!
        
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
        pipelineDescriptor.sampleCount = Renderer.depthSampleCount

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
        pipelineDescriptor.sampleCount = Renderer.sampleCount

        // This might be useful for some dynamic data injection
//        var reflection: MTLRenderPipelineReflection?
//        let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor, options: .bufferTypeInfo, reflection: &reflection)
//        print(reflection as Any)
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}
