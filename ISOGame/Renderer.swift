//
//  Renderer.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

class Renderer: NSObject {
    
    
    init(metalView: MTKView) {
        
        
        super.init()
        
        metalView.clearColor = MTLClearColor(red: 1, green: 1, blue: 0, alpha: 1)
        metalView.delegate = self
        
        mtkView(metalView, drawableSizeWillChange: metalView.frame.size)
    }
    
}

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {

    }
    
}
