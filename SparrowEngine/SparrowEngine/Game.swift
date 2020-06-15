//
//  Game.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 11/06/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import SparrowEngine2

import SparrowECS

/// Testgame!
class GameWorld: World {
    var renderer: MetalRenderer!
    
    // Systems
    var playerCameraSystem: PlayerCameraSystem!
    var rotatingSystem: RotatingSystem!
    
    
    var sphere: Entity!
    
    func initialize(view: SparrowMetalView) throws {
        // Create renderer. Also creates devices needed for loading GPU assets
        renderer = try MetalRenderer(for: view)
        try renderer.load(world: self)
        
        // Create initial entities
        loadScene()
        
        // Create systems
        playerCameraSystem = PlayerCameraSystem(world: self)
        rotatingSystem = RotatingSystem(world: self)
        
        
        let myTest = nexus.createEntity()
        myTest.add(component: Transform())

        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("testscene.sps")
            print("URL \(url)")
            
            try SceneLoader().save(entities: [sphere, camera!, myTest], in: self, to: url)
            
            let outputEntities = try SceneLoader().load(from: url, into: self)
            
            print("DECODED \(outputEntities.count) \(outputEntities.reduce(0) {$0 + $1.numComponents})")
        } catch {
            print("CODING ERROR \(error)")
        }
        
        exit(0)
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

        var first: Entity? = nil
        for x in -10..<10 {
            for z in -10..<10 {
                let obj = nexus.createEntity()
                let t = obj.add(component: Transform())
                t.position = [Float(x) * 3, 0, Float(z) * 3]
                obj.add(component: RenderMesh(mesh: objMesh))
                obj.add(component: RotationSpeed(seed: 22 * x + z))
                
                if first == nil {
                    first = obj
                }
            }
        }
        
        
        sphere = first!
    }
    
    override func update() {
        playerCameraSystem.update(world: self)
        rotatingSystem.update(world: self)
    }
}

import Foundation

class SceneLoader {
    
    
    func load(from path: URL, into world: World) throws -> [Entity] {
        let data = try Data(contentsOf: path)
        
        let entities = try world.nexus.decode(data: [UInt8](data))

        // Did decode notifications
        for entity in entities {
            for componentIdentifier in world.nexus.get(components: entity.identifier)! {

                if let component = world.nexus.get(component: componentIdentifier, for: entity.identifier),
                    let custom = component as? CustomComponentConvertable {
                    try custom.didDecode(into: world)
                }
            }
        }
        
        return entities
    }
    
    func save(entities: [Entity], in world: World, to path: URL) throws {
        // Will encode notifications
        for entity in entities {
            for componentIdentifier in world.nexus.get(components: entity.identifier)! {
                if let component = world.nexus.get(component: componentIdentifier, for: entity.identifier),
                    let storable = component as? NexusStorable,
                    Nexus.getRegistered(identifier: storable.stableIdentifier) != nil,
                    let custom = storable as? CustomComponentConvertable {
                    
                    try custom.willEncode(from: world)
                }
            }
        }
        
        let bytes = try world.nexus.encode(entities: entities)
        let data = Data(bytes)
        
        try data.write(to: path)
        
        print("ENCODED \(data)")
    }
    
}
