//
//  BinaryCodable.swift
//  SparrowBinaryCoder
//
//  Created by Jos Kuijpers on 09/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/**
https://www.mikeash.com/pyblog/friday-qa-2017-07-28-a-binary-coder-for-swift.html
Arbitrary implementations of Codable cannot be trusted to work for the binary encoding by default,
so we need our own protocol.
*/
public typealias BinaryCodable = BinaryEncodable & BinaryDecodable

