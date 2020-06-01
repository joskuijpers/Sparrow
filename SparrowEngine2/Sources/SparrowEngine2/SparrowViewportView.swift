//
//  SparrowViewportView.swift
//  
//
//  Created by Jos Kuijpers on 01/06/2020.
//

import AppKit
import MetalKit

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
