//
//  STFAsset.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import MetalKit
import ModelIO.MDLMaterial

public class STFAsset {
    
    let url: URL?
    
    var scenes = [STFScene]()
    public private(set) var defaultScene: STFScene?
    
    public var nodes = [STFNode]()
////    var cameras: [STFCamera]
    var meshes = [STFMesh]()
    public var buffers = [STFBuffer]()
    var bufferViews = [STFBufferView]()
    var accessors = [STFAccessor]()
    
    private var materials = [JSONMaterial]()
    var textures = [JSONTexture]()
    var images = [JSONImage]()
//    var samplers: [STFSampler]
//    var skins: [STFSkin]
//    var animations: [STFAnimation]

    public init(url: URL, device: MTLDevice) throws {
        self.url = url
        
        let data = try Data(contentsOf: url)
        let model = try JSONDecoder().decode(JSONRoot.self, from: data)
        
        if let buffers = model.buffers {
            loadBuffers(json: buffers, url: url, device: device)
        }
        if let bufferViews = model.bufferViews {
            loadBufferViews(json: bufferViews)
        }
        if let accessors = model.accessors {
            loadAccessors(json: accessors)
        }
        if let materials = model.materials {
            loadMaterials(json: materials)
        }
        if let textures = model.textures {
            loadTextures(json: textures)
        }
        if let images = model.images {
            loadImages(json: images)
        }
//        loadSamplers()
        if let meshes = model.meshes {
            loadMeshes(json: meshes)
        }
        if let nodes = model.nodes {
            loadNodes(json: nodes)
        }
        
        if let scenes = model.scenes {
            loadScenes(json: scenes)
        }
        if let index = model.scene {
            defaultScene = scenes[index]
        }
        
        generateNodes()
        generateMesh(device: device)
        
        finalizeAsset()
    }
    
    /// Returns a Boolean value that indicates whether the STFAsset class can read asset data from files with the specified extension.
    public class func canImportFileExtension(_ ext: String) -> Bool {
        return ext == "stf" || ext == "gltf"
    }
    
    /// Returns a Boolean value that indicates whether the STFAsset class can write asset data as a file with the specified format extension.
    public class func canExportFileExtension(_ ext: String) -> Bool {
        return ext == "stf" || ext == "gltf"
    }
    
    //    func export(to: URL) {}
    
    /// Get the number of scenes in the asset
    public var sceneCount: Int {
        return scenes.count
    }
    
    /// Get the scene
    public func scene(at: Int) -> STFScene {
        return scenes[at]
    }
    
    /// Get the number of nodes in the asset
    var count: Int {
        return nodes.count
    }
    
    /// Get the node at given index
    func node(at: Int) -> STFNode {
        return nodes[at]
    }
    
    func mesh(at: Int) -> STFMesh {
        return meshes[at]
    }
    
    private func loadBuffers(json: [JSONBuffer], url: URL, device: MTLDevice) {
        print("LOAD BUFFERS \(json.count)")
        buffers.reserveCapacity(json.count)
        
        for bufferInfo in json {
            guard let uri = bufferInfo.uri else {
                fatalError("Buffer is missing a URI")
                continue
            }
            
            var data: Data?
            if uri.hasPrefix("data:application/octet-stream;base64,") {
                let firstComma = (uri.range(of: ",")?.lowerBound)!
                let encodedData = uri.suffix(from: uri.index(after: firstComma))
                
                data = Data(base64Encoded: String(encodedData), options: .ignoreUnknownCharacters)
            } else if uri.count > 0 {
                let fileURL = url.deletingLastPathComponent().appendingPathComponent(uri)
                print("Loading buffer from \(fileURL)")
                
                do {
                    data = try Data(contentsOf: fileURL)
                } catch let error {
                    fatalError(error.localizedDescription)
                }
            }
                
            let buffer = device.makeBuffer(length: bufferInfo.byteLength, options: [])!
            data!.withUnsafeBytes { (uint8Ptr: UnsafePointer<UInt8>) in
                let pointer = UnsafeRawPointer(uint8Ptr)
                memcpy(buffer.contents(), pointer, bufferInfo.byteLength)
            }
                
            buffers.append(STFBuffer(mtlBuffer: buffer))
            // buffersData.append(data)
        }
        
    }
    
    private func loadBufferViews(json: [JSONBufferView]) {
        bufferViews.reserveCapacity(json.count)
        
        for (index, bufferViewInfo) in json.enumerated() {
            let bufferView = STFBufferView(index: index, json: bufferViewInfo)
            bufferViews.append(bufferView)
        }
    }
    
    private func loadAccessors(json: [JSONAccessor]) {
        accessors.reserveCapacity(json.count)
        
        for (index, accessorInfo) in json.enumerated() {
            let viewIndex = accessorInfo.bufferView ?? 0
            if viewIndex >= bufferViews.count {
                fatalError("Buffer view index out of bounds")
            }
            let view = bufferViews[viewIndex]
            
            // TODO: min values, max values
            
            let accessor = STFAccessor(index: index, json: accessorInfo, bufferView: view)
            
            accessors.append(accessor)
        }
    }
    
    private func loadMaterials(json: [JSONMaterial]) {
        materials = json
    }
    
    private func getImage(index: Int) -> String? {
        let textureInfo = textures[index]
        
        if let imageIndex = textureInfo.source {
            let imageInfo = images[imageIndex]
            
            if let imageName = imageInfo.uri {
                print("IMAGE NAME \(imageName)")
                return imageName
            } else if let mimeType = imageInfo.mimeType, let viewIndex = imageInfo.bufferView {
                let view = bufferViews[viewIndex]
                fatalError("TO IMPLEMENT")
            }
        }
        
        return nil
    }
    
    private func loadTextures(json: [JSONTexture]) {
        textures = json
    }
    
    private func loadImages(json: [JSONImage]) {
        images = json
    }
    
    private func loadSamplers() {
        
    }
    
    private func loadMeshes(json: [JSONMesh]) {
        meshes.reserveCapacity(json.count)
        
        for meshInfo in json {
            let mesh = STFMesh(json: meshInfo)
            
            for primitive in meshInfo.primitives {
                let submesh = STFSubmesh()
                
                let attributes = primitive.attributes
                var attributeAccessors = [String: STFAccessor]()
                
                // Define submesh attributes
                for attribute in attributes {
                    let name = attribute.key
                    let index = attribute.value
                    guard index < accessors.count else { continue }
                    
                    let accessor = accessors[index]
                    attributeAccessors[name] = accessor
                }
                submesh.accessorsForAttribute = attributeAccessors
                
                // Define material
                if let materialIndex = primitive.material {
                    submesh.material = createMaterial(index: materialIndex)
                }
                
                if let indexAccessorIndex = primitive.indices {
                    submesh.indexAccessor = accessors[indexAccessorIndex]
                    
                    if let mode = primitive.mode {
                        switch mode {
                        case 0:
                            submesh.primitiveType = .points
                        case 1:
                            submesh.primitiveType = .lines
                        case 3:
                            fatalError("Line strips are not supported in Metal")
                        case 4:
                            submesh.primitiveType = .triangles
                        case 5:
                            submesh.primitiveType = .triangleStrips
                        default:
                            fatalError("Unsupported submesh primitive type")
                        }
                    }
                } else {
                    fatalError("Currently only indexed meshes are supported")
                }
                
                mesh.submeshes.append(submesh)
            }

            meshes.append(mesh)
        }
    }
    
    /// Load all nodes into an array
    private func loadNodes(json: [JSONNode]) {
        nodes.reserveCapacity(json.count)
        
        for (index, nodeInfo) in json.enumerated() {
            let node = STFNode(index: index, json: nodeInfo)
            
            if let meshIndex = nodeInfo.mesh {
                node.mesh = meshes[meshIndex]
            }
            
            nodes.append(node)
        }
    }
    
    /// Load all scenes into an array
    private func loadScenes(json: [JSONScene]) {
        scenes.reserveCapacity(json.count)
        
        for sceneInfo in json {
            let scene = STFScene(json: sceneInfo)
            
            if let sceneNodes = sceneInfo.nodes {
                for nodeIndex in sceneNodes {
                    scene.nodes.append(nodes[nodeIndex])
                }
            }
            
            scenes.append(scene)
        }
    }
    
    private func generateNodes() {
        // Build node hierarchy
        for node in nodes {
            for index in node.childIndices {
                let childNode = nodes[index]
                childNode.parent = node
                node.children.append(childNode)
            }
        }
    }
    
    private func generateMesh(device: MTLDevice) {
        for mesh in meshes {
            for submesh in mesh.submeshes {
                let vertexDescriptor = createVertexDescriptor(submesh: submesh)
                
//                hasJoints = false
//                hasNormal = false
//                hasTangent = false
//                hasWeights = false
                
                let mtkVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!
                submesh.pipelineState = createPipelineState(vertexDescriptor: mtkVertexDescriptor, device: device)
                
                let indexAccessor = submesh.indexAccessor!
                let bufferView = indexAccessor.bufferView
                let indexCount = indexAccessor.count
                print("buffer id \(bufferView.bufferIndex) \(buffers.count)")
                let indexBuffer = buffers[bufferView.bufferIndex]
                let indexBufferOffset = bufferView.byteOffset + indexAccessor.offset
                
                submesh.indexCount = indexCount
                submesh.indexBuffer = indexBuffer.mtlBuffer
                submesh.indexBufferOffset = indexBufferOffset
                
                for attribute in submesh.accessorsForAttribute {
                    guard let key = STFAttribute(rawValue: attribute.key) else {
                        continue
                    }
                    let index = key.bufferIndex()
                    let accessor = attribute.value
                    let bufferView = accessor.bufferView
                    let bufferIndex = bufferView.bufferIndex
                    let offset = accessor.offset + bufferView.byteOffset
                    
                    var attrib = Attributes()
                    attrib.name = attribute.key
                    attrib.index = index
                    attrib.bufferIndex = bufferIndex
                    attrib.offset = offset
                    submesh.attributes.append(attrib)
                }

                mesh.submeshes.append(submesh)
            }
        }
    }
    
    private func createMaterial(index: Int) -> MDLMaterial {
        let material = MDLMaterial()
        let json = materials[index]
        
        if let occlusionTexture = json.occlusionTexture {
            if let imageName = getImage(index: occlusionTexture.index) {
                material.setProperty(MDLMaterialProperty(name: "occlusion", semantic: .ambientOcclusion, string: imageName))
            }
            
            if let strength = occlusionTexture.strength {
                material.setProperty(MDLMaterialProperty(name: "occlusionStrength", semantic: .ambientOcclusionScale, float: strength))
            }
        }
        
        if let normalTexture = json.normalTexture {
            if let imageName = getImage(index: normalTexture.index) {
                material.setProperty(MDLMaterialProperty(name: "normal", semantic: .tangentSpaceNormal, string: imageName))
            }
            
            if let _ = normalTexture.scale {
                print("Warning: normal scale not supported.")
            }
        }
        
//        if let emissiveFactor = json.emissiveFactor {
//            material.setProperty(MDLMaterialProperty(name: "emission", semantic: .emission, float: emissiveFactor))
//        }
        
        if let emissiveTexture = json.emissiveTexture,
            let imageName = getImage(index: emissiveTexture.index) {
            material.setProperty(MDLMaterialProperty(name: "emission", semantic: .emission, string: imageName))
        }
        
        if let pbr = json.pbrMetallicRoughness {
            if let albedoColorArray = pbr.baseColorFactor {
                let color = float4(array: albedoColorArray)
                material.setProperty(MDLMaterialProperty(name: "albedo", semantic: .baseColor, float3: [color.x, color.y, color.z]))
            }
            
            if let metallicFactor = pbr.metallicFactor {
                material.setProperty(MDLMaterialProperty(name: "metallic", semantic: .metallic, float: metallicFactor))
            }
            
            if let roughnessFactor = pbr.roughnessFactor {
                material.setProperty(MDLMaterialProperty(name: "roughness", semantic: .roughness, float: roughnessFactor))
            }
            
            if let albedoTexture = pbr.baseColorTexture,
                let imageName = getImage(index: albedoTexture.index) {
                material.setProperty(MDLMaterialProperty(name: "albedo", semantic: .baseColor, string: imageName))
            }
            
            if let mrTexture = pbr.metallicRoughnessTexture,
                let imageName = getImage(index: mrTexture.index) {
                material.setProperty(MDLMaterialProperty(name: "metallicRoughness", semantic: .userDefined, string: imageName))
            }
        }

        return material
    }
    
    private func createVertexDescriptor(submesh: STFSubmesh) -> MDLVertexDescriptor {
//        let vertexDescriptor = STFMakeVertexDescriptor()
//
//        let layouts = NSMutableArray(capacity: 8)
//        for _ in 0..<8 {
//          layouts.add(MDLVertexBufferLayout(stride: 0))
//        }
//
//        for accessorAttribute in submesh.accessorsForAttribute {
//            let accessor = accessorAttribute.value
//            var attributeName = "Untitled"
//
//            var layoutIndex = 0
//            guard let key = STFAttribute(rawValue: accessorAttribute.key) else {
//                print("WARNING! = Attribute \(accessorAttribute.key) not supported")
//                continue
//            }
//
//            switch key {
//            case .position:
//                attributeName = MDLVertexAttributePosition
////                vertexCount = accessor.count
//            case .normal:
//                attributeName = MDLVertexAttributeNormal
//            case .texCoord:
//                attributeName = MDLVertexAttributeTextureCoordinate
//            case .tangent:
//                attributeName = MDLVertexAttributeTangent
//            case .bitangent:
//                attributeName = MDLVertexAttributeBitangent
////            case .color:
////                attributeName = MDLVertexAttributeColor
//            }
//            layoutIndex = key.bufferIndex()
//
//            let bufferView = accessor.bufferView
//            let format: MDLVertexFormat = STFGetVertexFormat(componentType: accessor.componentType, type: accessor.type)
//
//            let offset = 0
//            let attribute = MDLVertexAttribute(name: attributeName,
//                                               format: format,
//                                               offset: offset,
//                                               bufferIndex: layoutIndex)
//            vertexDescriptor.addOrReplaceAttribute(attribute)
//
//            // Update the layout
//            var stride = bufferView.byteStride
//            if stride <= 0 {
//                stride = STFStrideOf(vertexFormat: format)
//            }
//            layouts[layoutIndex] = MDLVertexBufferLayout(stride: stride)
//        }
//
//        vertexDescriptor.layouts = layouts
//
//        return vertexDescriptor
//
//
        
        
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        
        // Position
        let positionAttribute = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                   format: .float3,
                                                   offset: offset,
                                                   bufferIndex: 0)
        vertexDescriptor.attributes[0] = positionAttribute
        offset += MemoryLayout<float3>.stride
        
        // Normal
        let normalAttribute = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                 format: .float3,
                                                 offset: offset,
                                                 bufferIndex: 0)
        vertexDescriptor.attributes[1] = normalAttribute
        offset += MemoryLayout<float3>.stride
        
        // UV
//        let uvAttribute = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
//                                             format: .float2,
//                                             offset: offset,
//                                             bufferIndex: 0)
//        vertexDescriptor.attributes[2] = uvAttribute
//        offset += MemoryLayout<float2>.stride
//        
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
    
    /// Collect mesh nodes for each scene
    private func finalizeAsset() {
        for scene in scenes {
            for node in scene.nodes {
                scene.meshNodes = flatten(root: node, children: { $0.children }).filter( { $0.mesh != nil })
            }
        }
    }
    
    private func flatten<STFNode>(root: STFNode, children: (STFNode) -> [STFNode]) -> [STFNode] {
        return [root] + children(root).flatMap({
            flatten(root: $0, children: children)
        })
    }
    
    func createPipelineState(vertexDescriptor: MTLVertexDescriptor, device: MTLDevice) -> MTLRenderPipelineState{
        let functionConstants = buildFunctionConstants()
        let pipelineState: MTLRenderPipelineState
        do {
            let library = device.makeDefaultLibrary()
            let vertexFunction = try library?.makeFunction(name: "vertex_main", constantValues: functionConstants)
            let fragmentFunction =  try library?.makeFunction(name: "fragment_main", constantValues: functionConstants)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.vertexDescriptor = vertexDescriptor
            descriptor.depthAttachmentPixelFormat = .depth32Float
            try pipelineState = device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return pipelineState
    }
    
    func buildFunctionConstants() -> MTLFunctionConstantValues {
        let functionConstants = MTLFunctionConstantValues()
        
        var property = false
        functionConstants.setConstantValue(&property, type: .bool, index: 0)
        
        property = false
        functionConstants.setConstantValue(&property, type: .bool, index: 1)
        
        property = false
        functionConstants.setConstantValue(&property, type: .bool, index: 2)
        
        property = false
        functionConstants.setConstantValue(&property, type: .bool, index: 3)
        
        //        property = textures.emissive != nil
        //        functionConstants.setConstantValue(&property, type: .bool, index: 4)
        
        property = false
        functionConstants.setConstantValue(&property, type: .bool, index: 5)
        
        return functionConstants
    }
}
