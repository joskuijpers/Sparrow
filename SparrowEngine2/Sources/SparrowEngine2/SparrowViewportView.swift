//
//  SparrowViewportView.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 01/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import AppKit
import MetalKit
import CSparrowEngine

/// A view the Sparrow renderer can render into.
open class SparrowViewportView: MTKView {
    override open func keyDown(with event: NSEvent) {
        Input.shared.handle(event: event)
    }
    
    override open func keyUp(with event: NSEvent) {
        Input.shared.handle(event: event)
    }
    
    override open var acceptsFirstResponder: Bool {
        return true
    }
}

@objc public class TestClass: NSObject {
    @objc public func hello() -> CameraUniforms {
        print("HELLO")
        
        return CameraUniforms()
    }
}
