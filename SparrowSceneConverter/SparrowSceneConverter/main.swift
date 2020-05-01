//
//  main.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation
import simd

print("Some Sponza OBJ info:")

let scene: AiScene = try AiScene(file: "/Users/joskuijpers/Development/ISOGame/SparrowEngine/SparrowEngine/Models/SPONZA/sponza.obj",
                                 flags: [.removeRedundantMaterials, .genSmoothNormals])

print("Num meshes: \(scene.meshes.count)")
print("Num materials: \(scene.materials.count)")
print("Num lights: \(scene.lights.count)")
print("Num cameras: \(scene.cameras.count)")
print("Num animations: \(scene.animations.count)")


//for mesh in scene.meshes {
//    print("Mesh \(mesh.name): material \(mesh.materialIndex)")
//}

for material in scene.materials {
    print("Material \(material.name)")

    print("Albedo \(material.getMaterialTexture(texType: .diffuse, texIndex: 0))")
    print("Albedo (color) \(material.getMaterialColor(.COLOR_DIFFUSE))")
    print("Normals \(material.getMaterialTexture(texType: .height, texIndex: 0))") // .normals
    
    print("Metalness \(material.getMaterialTexture(texType: .ambient, texIndex: 0))")
    print("Roughness \(material.getMaterialTexture(texType: .specular, texIndex: 0))")
    
    print("Opacity \(material.getMaterialTexture(texType: .opacity, texIndex: 0))")
    
    print("")
//    print("AO \(material.getMaterialTexture(texType: .ambientOcclusion, texIndex: 0))")
}
