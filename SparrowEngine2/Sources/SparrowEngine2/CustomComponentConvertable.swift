//
//  ComponentStorableInitializing.swift
//  SparrowECS
//
//  Created by Jos Kuijpers on 15/06/2020.
//

/// Indicate that a didDecode step should be executed after decoding.
public protocol CustomComponentConvertable {
    /// The component will be encoded.
    ///
    /// Set any properties that are to be encoded that depend on state.
    func willEncode(from: World) throws
    
    /// The component was successfully decoded.
    ///
    /// Read any properties that influence other properties.
    func didDecode(into: World) throws
}

// Default implementations
extension CustomComponentConvertable {
    func willEncode(from: World) {}
    func didDecode(into: World) throws {}
}
