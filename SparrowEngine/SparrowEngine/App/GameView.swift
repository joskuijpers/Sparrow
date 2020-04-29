//
//  GameView.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import AppKit
import MetalKit

class GameView: MTKView {
    override func keyDown(with event: NSEvent) {
        Input.shared.handle(event: event)
    }
    
    override func keyUp(with event: NSEvent) {
        Input.shared.handle(event: event)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
}
