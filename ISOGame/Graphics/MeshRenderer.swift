//
//  MeshRenderer.swift
//  ISOGame
//
//  Created by Jos Kuijpers on 16/02/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

class MeshRenderer: Component {
    
    
    
    
    func render() {
        let mesh = get(component: MeshSelector.self)?.mesh
        print("[MeshRenderer] Render mesh \(mesh.debugDescription)")
    }
}
