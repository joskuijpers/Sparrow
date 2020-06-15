//
//  RenderMesh.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowECS

/// Renders meshes inserted by MeshSelector.
public final class RenderMesh: Component {
    /// The mesh to render
    public var mesh: Mesh?

    /// Whether the mesh casts shadows
    public var castShadows: Bool = false
    
    /// Whether the mesh received shadows
    public var receiveShadows: Bool = false
    
    // enabled (Renderer)
    
    // Mesh resource name: used for coding.
    private var meshResource: String = "<none>"
    
    /// Init with a mesh
    public init(mesh: Mesh) {
        self.mesh = mesh
    }
    
    public override init() {
        self.mesh = nil
    }

}

extension RenderMesh: Codable {
    // Omit the mesh parameter
    private enum CodingKeys: String, CodingKey {
        case castShadows, receiveShadows
        case meshResource
    }
}

extension RenderMesh: NexusStorable, CustomComponentConvertable {

    public static var stableIdentifier: StableIdentifier {
        return 4
    }

    public func willEncode(from world: World) throws {
        meshResource = "ironSphere/ironSphere.spm"//"res://sponza.spm"
    }

    public func didDecode(into world: World) throws {
        print("DID DECODE RenderMesh, LOAD \(meshResource)")
        
        let device = world.graphics.device
        let textureLoader = TextureLoader(device: device)
        let meshLoader = MeshLoader(device: device, textureLoader: textureLoader)

        self.mesh = try meshLoader.load(name: meshResource)
    }
}
