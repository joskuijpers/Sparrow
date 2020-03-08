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
    var screenSize: CGSize
    var camera: Camera?

    init(screenSize: CGSize) {
        self.screenSize = screenSize
        // setup scene
//        screenSizeWillChange(to: screenSize)
    }
    
    /**
     Scene projection size changed. Update all dependent objects (mostly cameras)
     */
    func screenSizeWillChange(to size: CGSize) {
        camera?.onScreenSizeWillChange(to: size)

        screenSize = size
    }
}
