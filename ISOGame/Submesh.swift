//
//  Submesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

/**
 A submesh uses the vertex buffer from a mesh with its own index buffer. It has a single material.
 */
class Submesh {
    let mtkSubmesh: MTKSubmesh
    let pipelineState: MTLRenderPipelineState
    let depthPipelineState: MTLRenderPipelineState
    let material: Material
    let name: String
    
    /// List of textures available to the submesh
    struct Textures {
        let albedo: MTLTexture?
        let normal: MTLTexture?
        let roughness: MTLTexture?
        let metallic: MTLTexture?
        let emission: MTLTexture?
        let ambientOcclusion: MTLTexture?
    }
    
    let textures: Textures
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
        self.mtkSubmesh = mtkSubmesh
        self.name = mdlSubmesh.name

        print("Loading submesh \(name)")
    

//        let bounds = Bounds(minBounds: mdlMesh.boundingBox.minBounds, maxBounds: mdlMesh.boundingBox.maxBounds)
        
        textures = Textures(material: mdlSubmesh.material)
        material = Material(material: mdlSubmesh.material)
        
        // TODO: make only one and cache based on texture-list (used/not used) and material setup (alphatest/blend)
        let functionConstants = Submesh.makeFunctionConstants(textures: textures)
        pipelineState = Submesh.makePipelineState(functionConstants: functionConstants)
        depthPipelineState = Submesh.makeDepthPipelineState(functionConstants: functionConstants)
    }
}

// MARK: - State

private extension Submesh {
    /// Create a pipeline state for this submesh, using the vertex descriptor from the model
    // TODO: add configuration of vertex function for the model
    static func makePipelineState(functionConstants: MTLFunctionConstantValues) -> MTLRenderPipelineState {
        let library = Renderer.library
        
        let vertexFunction = library?.makeFunction(name: "vertex_main")!
        let fragmentFunction = try! library?.makeFunction(name: "fragment_main", constantValues: functionConstants)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Mesh.vertexDescriptor)
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
//        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
//        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
//        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
//        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        
        // We use a 32bit depth buffer
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.sampleCount = Renderer.sampleCount
        
        var pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        return pipelineState
    }
    
    /// Make a pipeline state for the depth prepass. This state uses the least amount of textures and smallest vertex size.
    static func makeDepthPipelineState(functionConstants: MTLFunctionConstantValues) -> MTLRenderPipelineState {
        let library = Renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        let hasAlphaTesting = true // TODO fill with appropriate data
        
        // Use a special setup when the material needs alpha testing, so for opaque materials
        // we can completely skip UV coords and fragment shader.
        if hasAlphaTesting {
            let vertexFunction = library?.makeFunction(name: "vertex_main_depth_alphatest")!
            let fragmentFunction = try! library?.makeFunction(name: "fragment_main_depth_alphatest", constantValues: functionConstants)
            
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
        } else {
            let vertexFunction = library?.makeFunction(name: "vertex_main_depth")!
            
            pipelineDescriptor.vertexFunction = vertexFunction
        }
        
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Mesh.vertexDescriptor)
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.sampleCount = Renderer.depthSampleCount
        
        var pipelineState: MTLRenderPipelineState
        do {
            pipelineState = try Renderer.device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        return pipelineState
    }
    
    /// Function constants that define whether a texture is used, or a fallback to the material
    static func makeFunctionConstants(textures: Textures) -> MTLFunctionConstantValues {
        let functionConstants = MTLFunctionConstantValues()
        
        var property = textures.albedo != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 0)
        
        property = textures.normal != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 1)
        
        property = textures.roughness != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 2)
        
        property = textures.metallic != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 3)
        
        property = textures.emission != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 4)
        
        property = textures.ambientOcclusion != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 5)
        
        return functionConstants
    }
}

private extension Submesh.Textures {
    
    /// Initialize a texture set using an MDLMaterial
    init(material: MDLMaterial?) {
        func property(with semantic: MDLMaterialSemantic) -> MTLTexture? {
            guard let property = material?.property(with: semantic),
                property.type == .string,
                let filename = property.stringValue,
                let texture = Renderer.textureLoader.load(imageName: filename)
            else {
                return nil
            }
            
            return texture.mtlTexture
        }
        
        albedo = property(with: .baseColor)
        normal = property(with: .tangentSpaceNormal)
        roughness = property(with: .roughness)
        metallic = property(with: .metallic)
        emission = property(with: .emission)
        ambientOcclusion = property(with: .ambientOcclusion)
    }
}

private extension Material {
    
    /// Initialiaze a Material structure using an MDLMaterial
    init(material: MDLMaterial?) {
        self.init()
        
        if let albedo = material?.property(with: .baseColor),
            albedo.type == .float3 {
            self.albedo = albedo.float3Value
        }

        if let roughness = material?.property(with: .roughness),
            roughness.type == .float {
            self.roughness = roughness.floatValue
        }
        
        if let metallic = material?.property(with: .metallic),
            metallic.type == .float {
            self.metallic = metallic.floatValue
        }
        
        // Gives weird values
//        if let emission = material?.property(with: .emission),
//            emission.type == .float3 {
//            self.emission = emission.float3Value
//        }
    }
}
