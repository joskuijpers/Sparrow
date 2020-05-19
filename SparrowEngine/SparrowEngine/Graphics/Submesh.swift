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
    
    let pipelineState: MTLRenderPipelineState
    let depthPipelineState: MTLRenderPipelineState
    
    /// Material of the mesh. Passed to the shader as uniform.
    let material: Material
    
    /// Submesh bounds. Used for culling.
    let bounds: Bounds
    
    
    let saSubmesh: SASubmesh
    
    
    /// List of textures available to the submesh
    struct Textures {
        let albedo: MTLTexture?
        let normal: MTLTexture?
        let roughnessMetalnessOcclusion: MTLTexture?
        let emission: MTLTexture?
    }
    
    let textures: Textures
    
    init(saAsset: SAAsset, saSubmesh: SASubmesh, vertexDescriptor: MTLVertexDescriptor) {
        name = saSubmesh.name

//        print("[mesh] Loading submesh \(name)")
        
        self.saSubmesh = saSubmesh
    

//        let bounds = Bounds(minBounds: mdlMesh.boundingBox.minBounds, maxBounds: mdlMesh.boundingBox.maxBounds)
        
        let saMaterial = saAsset.materials[saSubmesh.material]
        
        textures = Textures(saMaterial: saMaterial, saAsset: saAsset)
        material = Material(saMaterial: saMaterial, saAsset: saAsset)
        
        // TODO: make only one and cache based on texture-list (used/not used) and material setup (alphatest/blend)
        let functionConstants = Submesh.makeFunctionConstants(textures: textures)
        pipelineState = Submesh.makePipelineState(functionConstants: functionConstants, vertexDescriptor: vertexDescriptor, alphaMode: saMaterial.alphaMode)
        depthPipelineState = Submesh.makeDepthPipelineState(functionConstants: functionConstants, vertexDescriptor: vertexDescriptor, alphaMode: saMaterial.alphaMode)
        
        bounds = Bounds(from: saSubmesh.bounds)
    }
}

// MARK: - State

private extension Submesh {
    /// Create a pipeline state for this submesh, using the vertex descriptor from the model
    // TODO: add configuration of vertex function for the model
    static func makePipelineState(functionConstants: MTLFunctionConstantValues, vertexDescriptor: MTLVertexDescriptor, alphaMode: SAAlphaMode) -> MTLRenderPipelineState {
        let library = Renderer.library
        
        let vertexFunction = library?.makeFunction(name: "vertex_main")!
        let fragmentFunction = try! library?.makeFunction(name: "fragment_main", constantValues: functionConstants)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
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
    static func makeDepthPipelineState(functionConstants: MTLFunctionConstantValues, vertexDescriptor: MTLVertexDescriptor, alphaMode: SAAlphaMode) -> MTLRenderPipelineState {
        let library = Renderer.library
        let pipelineDescriptor = MTLRenderPipelineDescriptor()

        // Use a special setup when the material needs alpha testing, so for opaque materials
        // we can completely skip UV coords and fragment shader.
        if alphaMode == .mask {
            let vertexFunction = library?.makeFunction(name: "vertex_main_depth_alphatest")!
            let fragmentFunction = try! library?.makeFunction(name: "fragment_main_depth_alphatest", constantValues: functionConstants)
            
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
        } else {
            let vertexFunction = library?.makeFunction(name: "vertex_main_depth")!
            
            pipelineDescriptor.vertexFunction = vertexFunction
        }
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
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
        
        property = textures.roughnessMetalnessOcclusion != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 2)

        property = textures.emission != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 3)
        
        return functionConstants
    }
}

private extension Submesh.Textures {
    
    /// Initialize a texture set using an MDLMaterial
    init(saMaterial: SAMaterial, saAsset: SAAsset) {
        func property(_ property: SAMaterialProperty) -> MTLTexture? {
            switch property {
            case .texture(let textureId):
                let path = saAsset.textures[textureId].relativePath
                
                // TODO: need to use path relative to the asset
//                print("[mesh] Acquiring texture \(path)")
                guard let texture = Renderer.textureLoader.load(imageName: path) else {
                    fatalError("Unable to load texture \(path)")
                }

                return texture.mtlTexture
            default:
                return nil
            }
        }

        albedo = property(saMaterial.albedo)
        normal = property(saMaterial.normals)
        roughnessMetalnessOcclusion = property(saMaterial.roughnessMetalnessOcclusion)
        emission = property(saMaterial.emissive)
    }
}

private extension Material {
    
    /// Initialiaze a Material structure using an MDLMaterial
    init(saMaterial: SAMaterial, saAsset: SAAsset) {
        self.init()
        
        func property(_ property: SAMaterialProperty) -> float4? {
            switch property {
            case .color(let color):
                return color;
            default:
                return nil
            }
        }
        
        if let color = property(saMaterial.albedo) {
            albedo = color.xyz // TODO add alpha
        }
        
        if let rma = property(saMaterial.roughnessMetalnessOcclusion) {
            metallic = rma.x
            roughness = rma.y
        }
        
        if let color = property(saMaterial.emissive) {
            emission = color.xyz
        }
    }
}
