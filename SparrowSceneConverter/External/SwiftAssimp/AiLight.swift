//
//  AiLight.swift
//
//
//  Created by Christian Treffs on 21.06.19.
//

public struct AiLight {
    let light: aiLight

    init(_ aiLight: aiLight) {
        light = aiLight
    }

    public var name: String? {
        String(aiString: light.mName)
    }
}
