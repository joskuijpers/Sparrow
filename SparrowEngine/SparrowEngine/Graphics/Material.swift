//
//  Material.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 21/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Metal

/**
 A graphical material.
 */
struct Material {
    /// Name of the material for debugging.
    let name: String
    
    /// Render mode decides whether to use alpha texture.
    let renderMode: RenderMode
    
    
    func buildShaderData() -> ShaderMaterialData {
        ShaderMaterialData(albedo: [1,0,0],
                           emission: [0,0,0],
                           metallic: 0,
                           roughness: 1)
    }
}
