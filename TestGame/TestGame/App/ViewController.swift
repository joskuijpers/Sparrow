//
//  ViewController.swift
//  Game
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Cocoa
import SparrowEngine

class ViewController: NSViewController {
    
    var world: GameWorld?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? SparrowMetalView else {
            fatalError("Sparrow Metal viewport view not set up in storyboard")
        }
        metalView.preferredFramesPerSecond = 60
        // Disable V-sync
        // (metalView.layer as! CAMetalLayer).displaySyncEnabled = false
        
        do {
            let game = Engine.create(GameWorld.self)
            try game.initialize(view: metalView)
            
            world = game
        } catch {
            fatalError("Could not start engine: \(error)")
        }
    }
}
