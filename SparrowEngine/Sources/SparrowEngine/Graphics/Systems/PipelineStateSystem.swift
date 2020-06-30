//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 21/06/2020.
//

import SparrowECS
import CSparrowEngine
import Metal

final class PipelineStateSystem: System {
    let renderers: Group<Requires2<RenderMesh, MetalMeshPipelineState>>
    let graphics: GraphicsContext
    
    init(world: World) {
        renderers =  world.nexus.group(requiresAll: RenderMesh.self, MetalMeshPipelineState.self)
        graphics = world.graphics
    }
    
    func update() {
        for (renderMesh, meshPipelineState) in renderers {
            guard renderMesh.isPipelineStateDirty else {
                continue
            }
            
            guard let mesh = renderMesh.mesh, let materials = renderMesh.materials else {
                continue
            }
            
            print("A pipeline has a mesh and is dirty... building new state")
            
            do {
                meshPipelineState.pipelineStates = try buildPipelineStates(mesh: mesh, materials: materials)
            } catch {
                fatalError("Unable to build pipeline state for mesh \(mesh.name): \(error)")
            }
            renderMesh.isPipelineStateDirty = false
        }
    }
    
    private func buildPipelineStates(mesh: Mesh, materials: [Material]) throws -> [MetalSubmeshPipelineState] {
        let device = graphics.device
        let library = graphics.library
        
        return try mesh.submeshes.enumerated().map { (index, submesh) -> MetalSubmeshPipelineState in
            let material = materials[index]
            
            let functionConstants = buildFunctionConstants(material: material)
            
            let pipelineState = try buildPipelineState(device: device,
                                                       library: library,
                                                       renderMode: material.renderMode,
                                                       vertexDescriptor: mesh.vertexDescriptor,
                                                       functionConstants: functionConstants)
            
            let depthPipelineState = try buildDepthPipelineState(device: device,
                                                                 library: library,
                                                                 renderMode: material.renderMode,
                                                                 vertexDescriptor: mesh.vertexDescriptor,
                                                                 functionConstants: functionConstants)
            
            return MetalSubmeshPipelineState(shaderMaterialData: buildShaderData(material: material),
                                             pipelineState: pipelineState,
                                             depthPipelineState: depthPipelineState)
        }
    }
}

// MARK: - Building new state

extension PipelineStateSystem {
    /// Build the shader uniform data for a material.
    private func buildShaderData(material: Material) -> ShaderMaterialData {
        ShaderMaterialData(albedo: material.albedo,
                           emission: material.emission,
                           metallic: material.metalness,
                           roughness: material.roughness)
    }

    /// Function constants are used for function specialization
    private func buildFunctionConstants(material: Material) -> MTLFunctionConstantValues {
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

    private func buildDepthPipelineState(device: MTLDevice,
                                         library: MTLLibrary,
                                         renderMode: RenderMode,
                                         // Shader
                                         vertexDescriptor: MTLVertexDescriptor,
                                         functionConstants: MTLFunctionConstantValues) throws -> MTLRenderPipelineState? {
        var vertexFunction: MTLFunction?
        var fragmentFunction: MTLFunction?

        // Note: for translucency we can't run the depth pre-pass so we ignore them here.
        if renderMode == .translucent {
            return nil
        } else if renderMode == .cutOut {
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

    private func buildPipelineState(device: MTLDevice,
                                    library: MTLLibrary,
                                    renderMode: RenderMode,
                                    // Shader
                                    vertexDescriptor: MTLVertexDescriptor,
                                    functionConstants: MTLFunctionConstantValues) throws -> MTLRenderPipelineState {
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
