//
//  Submesh.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Submesh {
    let mtkSubmesh: MTKSubmesh
    let pipelineState: MTLRenderPipelineState
    let material: Material
    
    struct Textures {
        let albedo: MTLTexture?
        let normal: MTLTexture?
        let roughness: MTLTexture?
        let metallic: MTLTexture?
//        let emissive: MTLTexture?
        let ambientOcclusion: MTLTexture?
    }
    
    let textures: Textures
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
        self.mtkSubmesh = mtkSubmesh
        
        textures = Textures(material: mdlSubmesh.material)
        pipelineState = Submesh.makePipelineState(textures: textures)
        material = Material(material: mdlSubmesh.material)
    }
}

private extension Submesh {
    /// Create a pipeline state for this submesh, using the vertex descriptor from the model
    // TODO: add configuration of vertex function for the model
    static func makePipelineState(textures: Textures) -> MTLRenderPipelineState {
        let library = Renderer.library
        
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        
        let functionConstants = makeFunctionConstants(textures: textures)
        let fragmentFunction: MTLFunction?
        do {
            fragmentFunction = try library?.makeFunction(name: "fragment_main", constantValues: functionConstants)
        } catch {
            print(functionConstants)
            fatalError("No Metal function exists")
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(Model.vertexDescriptor)
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = Renderer.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
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
        
//        property = textures.emissive != nil
//        functionConstants.setConstantValue(&property, type: .bool, index: 4)
        
        property = textures.ambientOcclusion != nil
        functionConstants.setConstantValue(&property, type: .bool, index: 5)
        
        return functionConstants
    }
}

extension Submesh: Texturable {

}

private extension Submesh.Textures {
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
//        emissive = property(with: .emissive)
        ambientOcclusion = property(with: .ambientOcclusion)
    }
}

private extension Material {
    init(material: MDLMaterial?) {
        self.init()
        
        if let albedo = material?.property(with: .baseColor),
            albedo.type == .float3 {
            self.albedo = albedo.float3Value
        }
        
//        if let specular = material?.property(with: .specular),
//            specular.type == .float3 {
//            self.specularColor = specular.float3Value
//        }
        
//        if let shininess = material?.property(with: .specularExponent),
//            shininess.type == .float {
//            self.shininess = shininess.floatValue
//        }

        if let roughness = material?.property(with: .roughness),
            roughness.type == .float {
            self.roughness = roughness.floatValue
        }
        
        if let metallic = material?.property(with: .metallic),
            metallic.type == .float {
            self.metallic = metallic.floatValue
        }
        
//        if let emission = material?.property(with: .emission),
//            emission.type == .float {
//            self.emission = emission.floatValue
//        }
    }
}
