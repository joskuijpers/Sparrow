//
//  Scene.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 27/11/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import MetalKit

enum RenderPass {
    case depthPrePass
    case ssao
    case shadow
    case geometry
    case postfx
}

class Scene {
//    var inputController = InputController()

    var screenSize: CGSize
    var camera: ArcballCamera?
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        // setup scene
//        screenSizeWillChange(to: screenSize)
    }
    
    func updateUniforms() {
        if let camera = camera {
            uniforms.projectionMatrix = camera.projectionMatrix
            uniforms.viewMatrix = camera.viewMatrix
            fragmentUniforms.cameraPosition = camera.transform!.position
        }
    }
    
    /**
     Scene projection size changed. Update all dependent objects (mostly cameras)
     */
    func screenSizeWillChange(to size: CGSize) {
        camera?.screenSizeWillChange(to: size)

        screenSize = size
    }
}
