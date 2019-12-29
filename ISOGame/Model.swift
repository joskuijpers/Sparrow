//
//  Model.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit
import STF

class Model: Node {
    
    let meshes: [Mesh]
    
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor
    
    init(name: String) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetUrl,
                             vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor,
                             bufferAllocator: allocator)
        
        var mtkMeshes: [MTKMesh] = []
        let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
        _ = mdlMeshes.map { mdlMesh in
            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                    tangentAttributeNamed: MDLVertexAttributeTangent,
                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
            Model.vertexDescriptor = mdlMesh.vertexDescriptor
            mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
        }

        meshes = zip(mdlMeshes, mtkMeshes).map {
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
        }
        
        super.init()
        self.name = name
    }
}



class Model2: Node {
//    let meshes: [Mesh2]
    
    init(name: String) {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil) else {
            fatalError("Model: \(name) not found")
        }
        
        let asset = try? STFAsset(url: assetUrl, device: Renderer.device)
        
//        buffers = asset.buffers
//        meshNodes = asset?.scene(at: 0).meshNodes
//        nodes = asset.scenes[0].nodes
        
//        let scene = asset?.defaultScene
//        guard let node = scene?.node(at: 0) else { fatalError() }
//
//        let stfMesh = node.mesh
//
////            mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
////                                    tangentAttributeNamed: MDLVertexAttributeTangent,
////                                    bitangentAttributeNamed: MDLVertexAttributeBitangent)
////            Model.vertexDescriptor = mdlMesh.vertexDescriptor
//
//        let mtkMEsh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
//
//        meshes = zip(mdlMeshes, mtkMeshes).map {
//            Mesh(mdlMesh: $0.0, mtkMesh: $0.1)
//        }
        
        super.init()
        self.name = name
    }
    
}
