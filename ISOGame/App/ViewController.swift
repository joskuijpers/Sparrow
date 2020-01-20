//
//  ViewController.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("Metal view not set up in storyboard")
        }
        
        renderer = Renderer(metalView: metalView)
        addGestureRecognizers(to: metalView)
    }
    
    func addGestureRecognizers(to view: NSView) {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func handlePan(gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let delta = float2(Float(translation.x),
                           Float(translation.y))
        
        renderer?.scene.camera.rotate(delta: delta)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    override func scrollWheel(with event: NSEvent) {
        renderer?.scene.camera.zoom(delta: Float(event.deltaY))
    }
}

