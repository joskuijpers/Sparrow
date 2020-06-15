//
//  NexusStorable.swift
//  SparrowECS
//
//  Created by Jos Kuijpers on 15/06/2020.
//

/// A component that can be stored.
///
/// Requires Codable conformance so it can be encoded/decoded.
public protocol NexusStorable: Component, Codable {
    /// An identifier that is consistent across restarts, rebuilds, and application versions.
    ///
    /// Used for encoding and decoding.
    static var stableIdentifier: StableIdentifier { get }
    
    /// An identifier that is consistent across restarts, rebuilds, and application versions.
    ///
    /// Used for encoding and decoding. Already implemented
    var stableIdentifier: StableIdentifier { get }
}

extension NexusStorable {
    
    public static var stableIdentifier: StableIdentifier {
        let str = String(describing: self)
        return UInt64(truncatingIfNeeded: str.hashValue)
    }
    
    // Implementation of instance identifier, returning type identifier.
    public var stableIdentifier: StableIdentifier {
        Self.stableIdentifier
    }
}

/// Alias, adding conformance to Codable and NexusStorable.
public typealias Storable = NexusStorable & Codable

