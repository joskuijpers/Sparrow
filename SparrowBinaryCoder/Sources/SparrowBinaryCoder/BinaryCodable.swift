//
//  BinaryCodable.swift
//  SparrowBinaryCoder
//
//  Created by Jos Kuijpers on 09/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/// A type that can convert itself into and out of a binary representation.
///
/// `BinaryCodable` is a type alias for the `BinaryEncodable` and `BinaryDecodable` protocols.
/// When you use `BinaryCodable` as a type or a generic constraint, it matches
/// any type that conforms to both protocols.
///
/// Arbitrary implementations of Codable cannot be trusted to work for the binary encoding
/// so we need our own protocol.
public typealias BinaryCodable = BinaryEncodable & BinaryDecodable

