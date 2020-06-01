//
//  ViewController.swift
//  Game
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

        // Disable V-sync
        // (metalView.layer as! CAMetalLayer).displaySyncEnabled = false
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not available")
        }
        
        metalView.preferredFramesPerSecond = 60

        print("Using device: \(device.name)")
        
        renderer = Renderer(metalView: metalView, device: device)
    }
}
