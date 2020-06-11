//
//  Game.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 11/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine2

/// Testgame!
class GameWorld: World {
    var renderer: MetalRenderer!
    
    // Systems
    var playerCameraSystem: PlayerCameraSystem!
    var rotatingSystem: RotatingSystem!
    
    func initialize(view: SparrowMetalView) throws {
        // Create renderer. Also creates devices needed for loading GPU assets
        renderer = try MetalRenderer(for: view)
        try renderer.load(world: self)
        
        // Create initial entities
        loadScene()
        
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
//        t.localPosition = [0, 0, 2]
        t.localPosition = [-12.5, 1.4, -0.5]
        t.eulerAngles = [0, Float(90.0).degreesToRadians, 0]
        camera.add(component: Camera())
        
        self.camera = camera
        
        //        scene.camera = cameraComp
        
        let skyLight = nexus.createEntity()
        let tlight = skyLight.add(component: Transform())
        tlight.rotation = simd_quatf(angle: Float(70).degreesToRadians, axis: [1, 0, 0])
        let light = skyLight.add(component: Light(type: .directional))
        light.color = float3(1, 1, 1)

        
        let device = self.graphics.device
        let textureLoader = TextureLoader(device: device)
        let meshLoader = MeshLoader(device: device, textureLoader: textureLoader)

        let sponza = nexus.createEntity()
        sponza.add(component: Transform())
        let sponzaMesh = try! meshLoader.load(name: "ironSphere/ironSphere.spm")
        sponza.add(component: RenderMesh(mesh: sponzaMesh))
        
    }
    
    override func update() {
        playerCameraSystem.update(world: self)
        rotatingSystem.update(world: self)
    }
}
