//
//  Array+Tools.swift
//  SparrowEngine
//
//  Created by Jos Kuijpers on 21/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

extension Array where Element : Hashable {
    
    /// Get only unique elements. Order is not defined.
    @inlinable
    var unique: [Element] {
        return Array(Set(self))
    }
}

extension Array where Element : Equatable {
    
    /// Get only unique elements. Order is kept but implementation is slower than `unique`.
    @inlinable
    var uniqueKeepingOrder: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            if !uniqueValues.contains(item) {
                uniqueValues += [item]
            }
        }
        return uniqueValues
    }
}

extension Array {
    /// Get an array with given element appended
    @inlinable
    func appending(_ element: Element) -> [Element] {
        return self + [element]
    }
}
