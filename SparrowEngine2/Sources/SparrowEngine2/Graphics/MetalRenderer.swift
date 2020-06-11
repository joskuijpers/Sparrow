//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 09/06/2020.
//

import MetalKit

/// Metal backed renderer.
///
/// Creates pipelines, render textures, and everything else needed to render an empty frame.
///
public final class MetalRenderer {
    private let context: Context
    
    init(context: Context) {
        self.context = context
    }
}

// MARK: - Adjusting the rendering process

extension MetalRenderer {
    
    // set/get debug options
        // albedo/normals/metal/rough/ao
        // wireframe
    
}

// MARK: - Creating GPU state

extension MetalRenderer {
    // Building state
}

// MARK: - Rendering a frame

extension MetalRenderer {

    /// Render a single frame into the view.
    func renderFrame(view: MTKView) {
    }
}
