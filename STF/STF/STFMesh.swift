//
//  STFModel.swift
//  STF
//
//  Created by Jos Kuijpers on 29/12/2019.
//  Copyright © 2019 Jos Kuijpers. All rights reserved.
//

import Foundation

public class STFMesh {
    var submeshes = [STFSubmesh]()
    public let name: String
    
    init(json: JSONMesh) {
        self.name = json.name ?? "untitled"
        // extras, extensions
        
        print("LOAD MESH \(name)")
    }
}
