//
//  ViewController.swift
//  Game
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Cocoa
import MetalKit
import SparrowEngine2

class ViewController: NSViewController {
    
    var world: MyGameWorld?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? SparrowMetalView else {
            fatalError("Sparrow Metal viewport view not set up in storyboard")
        }
        metalView.preferredFramesPerSecond = 60
        // Disable V-sync
        // (metalView.layer as! CAMetalLayer).displaySyncEnabled = false
        
        do {
            let game = Engine.create(MyGameWorld.self)
            try game.initialize(view: metalView)
            
            world = game
        } catch {
            fatalError("Could not start engine: \(error)")
        }
    }
}

/// TestGame!
class MyGameWorld: World {
    var renderer: MetalRenderer!
    
    // Systems
    var playerCameraSystem: PlayerCameraSystem!
    var rotatingSystem: RotatingSystem!
    
    func initialize(view: SparrowMetalView) throws {
        
        // Create initial entities
        loadScene()
        
        renderer = try MetalRenderer(for: view)
        try renderer.load(world: self)
        
        // Create systems
        playerCameraSystem = PlayerCameraSystem(world: self)
        rotatingSystem = RotatingSystem(world: self)
    }
    
    private func loadScene() {
        // Load a model
        //        let sponza = try! loadModel("sponza.sps")
        
        // Create camera
        let camera = nexus.createEntity()
        let t = camera.add(component: Transform())
        t.localPosition = [-12.5, 1.4, -0.5]
        t.eulerAngles = [0, Float(90.0).degreesToRadians, 0]
        camera.add(component: Camera())
        //        scene.camera = cameraComp
        
        //        let skyLight = world.n.createEntity()
        //        let tlight = skyLight.add(component: Transform())
        //        tlight.rotation = simd_quatf(angle: Float(70).degreesToRadians, axis: [1, 0, 0])
        //        let light = skyLight.add(component: Light(type: .directional))
        //        light.color = float3(1, 1, 1)
        //
        
        //        let sponza = world.n.createEntity()
        //        sponza.add(component: Transform())
        //        let sponzaMesh = try! Renderer.meshLoader.load(name: "ironSphere/ironSphere.spm")
        //        sponza.add(component: RenderMesh(mesh: sponzaMesh))
        
    }
    
    override func update() {
        playerCameraSystem.update(world: self)
        rotatingSystem.update(world: self)
    }
}
