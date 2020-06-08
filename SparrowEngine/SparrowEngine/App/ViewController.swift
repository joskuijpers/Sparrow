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
    
    var renderer: Renderer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let metalView = view as? MTKView else {
            fatalError("Metal view not set up in storyboard")
        }
        metalView.preferredFramesPerSecond = 60

        // Disable V-sync
        // (metalView.layer as! CAMetalLayer).displaySyncEnabled = false
        
        do {
            let app = try Engine.create(MyGame.self, options: [])
            print("Created app... calling it to test")
            
            app.initialize()
            
            renderer = Renderer(metalView: metalView, device: app.context.graphics.device, world: app.world, context: app.context)
        } catch {
            fatalError("Could not start engine: \(error)")
        }
        
        
    }
}

class MyGame: EngineApp {
    /**/let world: World
    /**/let context: Context
    
    let fooSystem: MyFooSystem
    
    required init(world: World, context: Context) throws {
        print("INIT MYGAME")
        
        self.world = world
        self.context = context
        
        // What do I want to do...
        
        
        
        // Load a model
//        let sponza = try! loadModel("sponza.sps")
        
        // Create camera
        let camera = world.n.createEntity()
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
        
        
        // Create systems
        fooSystem = MyFooSystem(world: world, context: context)
//        renderSystem = RenderSystem()
//        cameraSystem = CameraSystem()
    }
    
    func initialize() {
        print("CALLED initialize IN MYGAME")
    }
    
    func tick(timeInterval: TimeInterval) {
//        renderSystem.update(timeInterval)
        
        fooSystem.doStuff(timeInterval: timeInterval)
        
    }
    

}

class MyFooSystem: System {
    
    required init(world: World, context: Context) {
        print("[FOO] Created")
    }
    
    func doStuff(timeInterval: TimeInterval) {
        print("[FOO] Do stuff")
    }
}
