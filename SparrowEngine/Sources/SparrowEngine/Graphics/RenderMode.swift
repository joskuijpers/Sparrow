//
//  RenderMode.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 06/06/2020.
//

/// The mesh render mode.
///
/// Determines when and how the mesh is rendered.
public enum RenderMode {
    /// Opaque. Pixels always show.
    ///
    /// Rendered in both the Z prepass and lighting pass.
    case opaque
    
    /// Alpha testing. Pixels either show or do not show.
    ///
    /// Rendered in both the Z prepass and lighting pass.
    case cutOut
    
    /// Translucency, also named alpha blending. Pixels can have partial alpha.
    ///
    /// Only rendered in a second lighting pass just for translucent materials.
    case translucent
}
