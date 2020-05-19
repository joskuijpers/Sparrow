//
//  MeshLoader.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 19/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 Loader of meshes.
 
 Gives fully built meshes. Might re-use resources when possible.
 */
class MeshLoader {
    private let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    /**
     Load a mesh with given name.
     */
    func load(name: String) throws -> Mesh {
        print("LOAD MESH FOR \(name)")
        
        // Get the asset -> SAAsset
        
        // Get first mesh or throw -> SAMesh
        
        // -----> createMesh()
        
        // Create MTL buffers -> [MTLBuffer]
        
        // Create vertex descriptor -> MTLVertexDescriptor
        
        // Create bounds -> Bounds
        
        // Create submeshes -> [Submesh] ----> createSubmesh()
            // Set name -> String
            // Set bounds -> Bounds
        
            // Get index buffer info (index (match with mtl buffer list), offset, numIndices = bufferLength/indexSize) -> Submesh.IndexBufferInfo
        
            // Create material -> Material -----> createMaterial()
                // Colors
                // Alpha mode
                // Textures (loaded into MTLTexture optional)
                // Shader name -> String (Enum with rawValue string)
        
            // Create ShaderMaterialInfo from Material -----> material.buildShaderInfo()
        
            // Submesh(name, bounds, indexBufferInfo, material)
        
            // When creating the submesh, this is updated automatically because the material changes:
            // Create functionConstants from Material ----> createFunctionConstants()
            // Create 2 pipeline states using Material + Function Constants
        
            
        // Create the mesh -> Mesh
        // Mesh(name:, buffers:, vertexDescriptor:, bounds:, submeshes: [])
     
        let m = try Mesh(name: name)
        return m
    }
    

    

    
//    private func createMesh() -> Mesh {
//
//    }
    
//    private func createSubmesh() -> Submesh {
//
//    }

//    private func createMaterial() -> Material {
//
//    }
    
    // TODO: this has to be used when the submesh material changes too....
    // So maybe put this in Submesh and call them from material{didSet{ constants = {}, build/build }}
//    private func createFunctionConstants(material: Material) -> MTLFunctionConstantValues {}
//    private func buildDepthPipelineState() {}
//    private func buildPipelineState() {}
}

/*
 
 Render code stays in the mesh/submesh class:
 
 - Mesh has addToQueue with frustum. Tests whether bounds are in frustum
    then forwards to submesh
 - Submesh tests for frustum too
    then adds to queue
    uses bounds for depth to camera (find closest point in bounds to camera) / use center until better solution
 
 - Mesh :render(submeshIndex, worldTransform, uniforms, renderEncoder, renderPass)
    - Set vertex buffers
    - Update and set uniform buffer
    
    - Submesh:render(renderEncoder, renderPass)
        - Set textures
        - Set pipeline state
        - Draw triangles
        
 
 
 */
