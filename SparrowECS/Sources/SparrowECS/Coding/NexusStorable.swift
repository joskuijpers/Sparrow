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
    
    // Implementation of instance identifier, returning type identifier.
    public var stableIdentifier: StableIdentifier {
        Self.stableIdentifier
    }
}
