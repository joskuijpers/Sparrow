//
//  RenderPass.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 10/06/2020.
//

/// Pass of the rendering process.
public enum RenderPass {
    /// Drawing all opaque meshes into the depth buffer.
    ///
    /// The depth buffer is used for light culling and SSAO
    case depthPrePass
    
    /// Ambient occlusion generation.
    case ssao
    
    /// Drawing of objects for shadows.
    case shadows
    
    /// Lighting of opaque materials.
    case opaqueLighting
    
    /// Lighting of transparent materials.
    case transparentLighting
    
    /// Post processing effects.
    case postfx
}
