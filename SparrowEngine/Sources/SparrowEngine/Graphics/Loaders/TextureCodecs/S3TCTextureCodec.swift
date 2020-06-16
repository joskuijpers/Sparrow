//
//  File.swift
//  
//
//  Created by Jos Kuijpers on 16/06/2020.
//

import Foundation
import Metal

struct S3TCTextureCodec: TextureCodec {
    
    enum Error: Swift.Error {
        case error
    }
    
    static func isContained(in data: Data) -> Bool {
        return false
    }
    
    func load(from data: Data) throws -> TextureDescriptor {
        
        throw Error.error
    }
    
    
}

//S3TC
//MTLPixelFormatBC1_RGBA
//MTLPixelFormatBC1_RGBA_sRGB
//MTLPixelFormatBC2_RGBA
//MTLPixelFormatBC2_RGBA_sRGB
//MTLPixelFormatBC3_RGBA
//MTLPixelFormatBC3_RGBA_sRGB
//
///* RGTC */
//MTLPixelFormatBC4_RUnorm
//MTLPixelFormatBC4_RSnorm
//MTLPixelFormatBC5_RGUnorm
//MTLPixelFormatBC5_RGSnorm
//
///* BPTC */
//MTLPixelFormatBC6H_RGBFloat
//MTLPixelFormatBC6H_RGBUfloat
//MTLPixelFormatBC7_RGBAUnorm
//MTLPixelFormatBC7_RGBAUnorm_sRGB
