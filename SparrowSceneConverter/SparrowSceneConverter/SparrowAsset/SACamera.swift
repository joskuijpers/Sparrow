//
//  SACamera.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 02/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

struct SACamera: Codable {
    var type: SACameraType
    
    var aspectRatio: Float
    var yfox: Float
    var zfar: Float
    var znear: Float
    
//    var xmag: Float
//    var ymag: Float
}

enum SACameraType {
    case perspective
//    case orthographic
}

extension SACameraType: Codable {
    enum Key: CodingKey {
        case rawValue
    }
    
    enum CodingError: Error {
       case unknownValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .perspective
        default:
            throw CodingError.unknownValue
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .perspective:
            try container.encode(0, forKey: .rawValue)
        }
    }
}
