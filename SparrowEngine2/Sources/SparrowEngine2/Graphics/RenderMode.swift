//
//  RenderMode.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 06/06/2020.
//

/// The mesh render mode.
public enum RenderMode {
    /// Opaque. Pixels always show.
    case opaque
    /// Alpha testing. Pixels either show or do not show.
    case cutOut
    /// Translucency, also named alpha blending. Pixels can have partial alpha.
    case translucent
}
