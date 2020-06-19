//
//  Game.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 11/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine
import SparrowECS
import Foundation

/// Testgame!
class GameWorld: World {
    var renderer: MetalRenderer!
    
    // Systems
    var playerCameraSystem: PlayerCameraSystem!
    var rotatingSystem: RotatingSystem!
    
    
    var spheres: [Entity] = []
    
    func initialize(view: SparrowMetalView) throws {
        Nexus.register(component: RotationSpeed.self)
        
        // Create renderer. Also creates devices needed for loading GPU assets
        renderer = try MetalRenderer(for: view)
        try renderer.load(world: self)
        
        // Create initial entities
        loadScene()
        
        // Create systems
        playerCameraSystem = PlayerCameraSystem(world: self)
        rotatingSystem = RotatingSystem(world: self)
        
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("testscene.sps")
            print("URL \(url)")
            
            let coding = SceneCoding()
            
//            303kb
            
            try coding.save(entities: spheres, in: self, to: url)
            
//            for entity in spheres {
//                nexus.destroy(entity: entity)
//            }

//            let outputEntities = try coding.load(from: url, into: self)
//            print("DECODED \(outputEntities.count) \(outputEntities.reduce(0) {$0 + $1.numComponents})")
        } catch {
            print("CODING ERROR \(error)")
        }
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

        let objMesh = try! meshLoader.load(name: "ironSphere/ironSphere.spm")

        for x in -10..<10 {
            for z in -10..<10 {
                let obj = nexus.createEntity()
                let t = obj.add(component: Transform())
                t.position = [Float(x) * 3, 0, Float(z) * 3]
                obj.add(component: RenderMesh(mesh: objMesh))
                obj.add(component: RotationSpeed(seed: 22 * x + z))
                
                spheres.append(obj)
            }
        }
        
        let obj = nexus.createEntity()
        let transform = obj.add(component: Transform())
        transform.position = [0, 5, 0]
        obj.add(component: RenderMesh(mesh: objMesh))
        obj.add(component: RotationSpeed(speed: 40))

        spheres.append(obj)
    }
    
    override func update() {
        playerCameraSystem.update(world: self)
        rotatingSystem.update(world: self)
    }
}

